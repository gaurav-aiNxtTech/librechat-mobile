import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/server_url.dart';
import 'sso_controller.dart';

/// The SSO_Screen (Req 13): the whole OAuth round-trip for [provider] in an
/// embedded WebView, ported from KMP `SsoLoginScreen` and the Android
/// `SsoWebView`. [SsoController] holds the flow; this widget only wires the
/// WebView to it. The WebView sends no Custom_Headers. A successful exchange
/// needs no navigation here: the router's redirect opens `/chat`.
class SsoScreen extends ConsumerStatefulWidget {
  const SsoScreen({super.key, required this.provider});

  final String provider;

  @override
  ConsumerState<SsoScreen> createState() => _SsoScreenState();
}

class _SsoScreenState extends ConsumerState<SsoScreen> {
  final _cookies = WebViewCookieManager();
  late final WebViewController _web;
  late final SsoController _flow;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authServiceProvider);
    final serverUrl = auth.serverUrl ?? '';
    _web = WebViewController();
    _flow = SsoController(
      serverUrl: serverUrl,
      provider: widget.provider,
      clearCookies: _cookies.clearCookies,
      // Android returns the HttpOnly cookies too.
      readCookies: () async => {
        for (final cookie in await _cookies.getCookies(
          domain: serverUri(serverUrl, ''),
        ))
          cookie.name.trim(): cookie.value,
      },
      load: _web.loadRequest,
      exchange: auth.exchangeSsoToken,
    );
    unawaited(_open());
  }

  /// Configures the WebView before the first load, so the first request
  /// already carries the SSO User-Agent (Req 13.3).
  Future<void> _open() async {
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _web.setUserAgent(ssoAndroidUserAgent);
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) =>
            _flow.onNavigationRequest(
              request.url,
              isMainFrame: request.isMainFrame,
            )
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onUrlChange: (change) => _flow.onUrlChange(change.url),
        onPageFinished: _flow.onPageFinished,
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? false) _flow.onMainFrameError();
        },
        onHttpError: (error) =>
            _flow.onHttpError(error.response?.uri ?? error.request?.uri),
      ),
    );
    if (mounted) await _flow.start();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  /// Back to the Login_Screen (Req 13.8).
  void _close() => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close', // New copy.
            onPressed: _close,
          ),
        ),
        body: ListenableBuilder(
          listenable: _flow,
          builder: (context, _) => Stack(
            children: [
              WebViewWidget(controller: _web),
              if (_flow.failure case final failure?)
                SsoFailurePane(
                  failure: failure,
                  onRetry: () => unawaited(_flow.start()),
                  onBack: _close,
                )
              else if (_flow.exchanging)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Signing in', // New copy.
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The failed round-trip, opaque over the WebView so its blank page doesn't
/// show through (Req 13.7). Copy from KMP `SsoLoginScreen`.
class SsoFailurePane extends StatelessWidget {
  const SsoFailurePane({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.onBack,
  });

  final SsoFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = failure.code;
    return Material(
      child: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Semantics(
                liveRegion: true,
                child: Text(
                  failure.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (code != null) ...[
                const SizedBox(height: 4),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
