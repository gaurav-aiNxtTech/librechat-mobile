import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/app_exception.dart';
import '../../core/network/server_url.dart';

/// Chrome for Android's reduced User-Agent, for the SSO WebView only
/// (Req 13.3). KMP `SSO_ANDROID_USER_AGENT`, unchanged: the device segment is
/// frozen at `Android 10; K` because every Chrome since M110 reports exactly
/// that, and this string is the one the flow was verified against.
const ssoAndroidUserAgent =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36';

/// The cookie the Server's OAuth callback sets.
const refreshTokenCookie = 'refreshToken';

enum SsoNavigationDecision { allow, stop }

/// Decides when the OAuth round-trip is over, so the WebView can cancel the
/// Server's post-callback redirect before the web app loads and refreshes
/// (and so rotates) the Refresh_Token first (Req 13.4). Ported from KMP
/// `SsoNavigationGate`.
///
/// It arms on `{Server_URL}/oauth/{provider}/callback`, so only providers
/// whose callback is a GET arm it: Apple's and SAML's form_post callbacks
/// never reach a navigation callback, and the cookie probe ends those flows.
class SsoNavigationGate {
  SsoNavigationGate(String serverUrl, String provider)
    : _callback = serverUri(
        serverUrl,
        '/oauth/${Uri.encodeComponent(provider)}/callback',
      ).toString().toLowerCase();

  final String _callback;
  bool _callbackSeen = false;
  bool _stopped = false;

  bool get stopped => _stopped;

  /// The decision for a main-frame navigation to [url]. Once the callback has
  /// been seen, the next navigation and every one after it stop.
  SsoNavigationDecision decide(String url) {
    if (_stopped) return SsoNavigationDecision.stop;
    if (_callbackSeen) {
      _stopped = true;
      return SsoNavigationDecision.stop;
    }
    // A prefix of the same string the start URL was built from, so a subpath
    // matches too. Case-insensitive, because the WebView lower-cases the
    // scheme and host while the stored Server_URL keeps the typed case.
    final path = url.split('?').first.split('#').first.toLowerCase();
    if (path == _callback || path.startsWith('$_callback/')) {
      _callbackSeen = true;
    }
    return SsoNavigationDecision.allow;
  }
}

/// A failed round-trip: [message] for the user and, when the Server's URL
/// carried one, its `error` [code], for diagnosis only.
typedef SsoFailure = ({String message, String? code});

/// KMP `sso_sign_in_failed`.
const ssoSignInFailed = 'Sign-in failed. Please try again.';

/// The SSO_Screen's flow, kept apart from the WebView so tests can drive it
/// with fake cookie and load functions. The screen forwards the WebView's
/// navigation events to [onNavigationRequest], [onUrlChange],
/// [onPageFinished], [onMainFrameError] and [onHttpError].
///
/// Each attempt clears the cookies, loads `{Server_URL}/oauth/{provider}`
/// (Req 13.2) and finishes once: it reads the `refreshToken` cookie, blanks
/// the WebView and either clears the cookies and hands the token to
/// [exchange] (Req 13.5) or shows [failure] (Req 13.7). [start] again is
/// Retry.
class SsoController extends ChangeNotifier {
  SsoController({
    required this.serverUrl,
    required this.provider,
    required this.clearCookies,
    required this.readCookies,
    required this.load,
    required this.exchange,
  });

  final String serverUrl;
  final String provider;

  /// Clears every WebView cookie.
  final Future<void> Function() clearCookies;

  /// The WebView's cookies for the Server_URL, as name and value.
  final Future<Map<String, String>> Function() readCookies;

  /// Loads [uri] in the WebView.
  final Future<void> Function(Uri uri) load;

  /// `AuthService.exchangeSsoToken`.
  final Future<void> Function(String refreshToken) exchange;

  int _attempt = 0;
  bool _finished = false;
  bool _leftServer = false;
  bool _disposed = false;
  late SsoNavigationGate _gate;
  bool _exchanging = false;
  SsoFailure? _failure;

  Uri get startUrl =>
      serverUri(serverUrl, '/oauth/${Uri.encodeComponent(provider)}');

  /// The token exchange is running.
  bool get exchanging => _exchanging;

  /// The last attempt failed and waits for Retry.
  SsoFailure? get failure => _failure;

  /// Starts a fresh round-trip: clear, then load (Req 13.2).
  Future<void> start() async {
    final attempt = ++_attempt;
    _finished = false;
    _leftServer = false;
    _gate = SsoNavigationGate(serverUrl, provider);
    _exchanging = false;
    _failure = null;
    _notify();
    try {
      await clearCookies();
      if (attempt != _attempt || _disposed) return;
      await load(startUrl);
    } catch (_) {
      if (attempt == _attempt) _fail(null);
    }
  }

  /// Whether the WebView may follow a navigation to [url] (Req 13.4).
  bool onNavigationRequest(String url, {required bool isMainFrame}) {
    if (!isMainFrame || _isBlank(url)) return true;
    if (_finished) return false;
    _track(url);
    if (_gate.decide(url) == SsoNavigationDecision.stop) {
      unawaited(_finish(url));
      return false;
    }
    return true;
  }

  /// A committed main-frame URL. Feeds the gate, which catches what
  /// [onNavigationRequest] misses, then probes the cookie on the Server.
  void onUrlChange(String? url) {
    if (url == null || _isBlank(url) || _finished) return;
    _track(url);
    if (_gate.decide(url) == SsoNavigationDecision.stop) {
      unawaited(_finish(url));
      return;
    }
    if (_onServer(url)) unawaited(_probe(url, failWithout: false));
  }

  /// A Server page finished: the cookie finishes the flow, and so does its
  /// absence once the WebView has come back from the provider (Req 13.7).
  void onPageFinished(String url) {
    if (_isBlank(url) || _finished || !_onServer(url)) return;
    unawaited(_probe(url, failWithout: _leftServer));
  }

  /// A main-frame load failed, so no navigation will follow.
  void onMainFrameError() {
    if (!_finished) unawaited(_finish(null));
  }

  /// An HTTP error status. Only the Server's OAuth routes end the flow: an
  /// error status is an ordinary step at a provider, and the callback has no
  /// subresources, so this stands in for KMP's main-frame check.
  void onHttpError(Uri? uri) {
    if (uri == null || _finished || !_onServer(uri.toString())) return;
    final oauth = serverUri(serverUrl, '/oauth/').path;
    if (uri.path.startsWith(oauth)) unawaited(_finish(null));
  }

  Future<String?> _readToken() async {
    final value = (await readCookies())[refreshTokenCookie];
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _probe(String url, {required bool failWithout}) async {
    final attempt = _attempt;
    final token = await _readToken().catchError((Object _) => null);
    if (attempt != _attempt || _finished) return;
    if (token != null || failWithout) await _finish(url);
  }

  /// Runs once per attempt, so [exchange] is called at most once each.
  Future<void> _finish(String? url) async {
    if (_finished) return;
    _finished = true;
    final attempt = _attempt;
    try {
      final token = await _readToken();
      if (attempt != _attempt || _disposed) return;
      // Blank it, so the half-loaded redirect target is not left behind.
      await load(Uri.parse('about:blank'));
      if (token == null) {
        _fail(url == null ? null : Uri.tryParse(url)?.queryParameters['error']);
        return;
      }
      // webview_flutter cannot write an HttpOnly cookie, so clearing is how
      // the captured token is expired in the WebView (Req 13.5).
      await clearCookies();
      _exchanging = true;
      _notify();
      // Success needs no navigation: the router's redirect opens /chat.
      await exchange(token);
    } catch (e) {
      if (attempt != _attempt) return;
      _exchanging = false;
      _failure = (
        message: e is AppException ? userMessage(e) : ssoSignInFailed,
        code: null,
      );
      _notify();
    }
  }

  void _fail(String? code) {
    _exchanging = false;
    _failure = (message: ssoSignInFailed, code: code);
    _notify();
  }

  void _track(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return;
    }
    if (!isServerAuthority(uri, serverUrl)) _leftServer = true;
  }

  bool _onServer(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && isServerAuthority(uri, serverUrl);
  }

  static bool _isBlank(String url) => url.startsWith('about:');

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _attempt++;
    super.dispose();
  }
}
