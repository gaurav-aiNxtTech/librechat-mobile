import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../auth/auth_service.dart';
import '../config/feature_gate.dart';
import '../log/diagnostic_log.dart';
import '../storage/secure_store.dart';
import 'app_exception.dart';
import 'custom_headers.dart';
import 'server_url.dart';

/// The app's [ApiClient]. `main()` builds it and overrides this provider.
final apiClientProvider = Provider<ApiClient>(
  (ref) => throw UnimplementedError('apiClientProvider is not overridden'),
);

/// Sent on every request (Req 4.2). KMP `LibreChatHttpClient.kt`
/// `BROWSER_USER_AGENT`: the Server's ua-parser-js reads it as Chrome.
const browserUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

/// Routes whose body the Server reads from `req.body.arg` (Req 4.5).
const _argEnvelopeRoutes = {
  'POST /api/convos/update',
  'POST /api/convos/archive',
  'POST /api/convos/pin',
  'DELETE /api/convos',
};

/// [data] wrapped as `{"arg": data}` on the Arg_Envelope routes, otherwise
/// [data] unchanged. The query, if any, is ignored when matching [path].
Object? argEnvelope(String method, String path, Object? data) {
  final route = '${method.toUpperCase()} ${path.split('?').first}';
  return _argEnvelopeRoutes.contains(route) ? {'arg': data} : data;
}

/// The one REST transport. Every REST, image and download request goes
/// through [send]; StreamClient shares [headersFor].
///
/// One dio instance with a 10 s connect timeout (Req 4.9) and no
/// interceptors. Redirects are followed here, hop by hop, so each hop gets
/// its own headers (Req 4.3) and its own gateway check (Req 5.9). TLS uses
/// Dart's default context, which trusts only the system store (Req 46.2).
class ApiClient {
  /// [requestTimeout] is the overall limit for requests other than
  /// transfers (Req 4.10); tests shorten it.
  ApiClient({
    required this._secure,
    required this._auth,
    required this._log,
    this._requestTimeout = const Duration(seconds: 30),
  });

  static const int maxRedirects = 5;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const _redirectStatuses = {301, 302, 303, 307, 308};

  final SecureStore _secure;
  final AuthService _auth;
  final DiagnosticLog _log;
  final Duration _requestTimeout;
  final Dio _dio = Dio(BaseOptions(connectTimeout: connectTimeout));

  /// Features whose route answered 404 since the App started (Req 6.7).
  /// The Feature_Gate listens to this.
  final ValueNotifier<Set<Feature>> missingFeatures = ValueNotifier(const {});

  /// The stored Server_URL that relative paths resolve against, if any.
  /// ImageLoader keys its caches by the resolved absolute URL.
  String? get serverUrl => _auth.serverUrl;

  /// Sends one request and returns its 2xx response (or the 3xx itself when
  /// [followRedirects] is false). Failures throw [AppException]; a request
  /// the user cancels through [cancelToken] rethrows dio's cancel error,
  /// which `CancelToken.isCancel` recognises and the UI does not show.
  ///
  /// - [transfer]: uploads, downloads and images skip the 30 s timer.
  /// - [feature]: a 404 that isn't an item-not-found marks it missing.
  /// - [refreshCookie]: sent as the `refreshToken` cookie (refresh route).
  /// - [serverUrl], [customHeaders]: the onboarding probe's typed URL and
  ///   rows instead of the stored ones; no session is sent with them.
  Future<Response<Object?>> send(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? query,
    ResponseType type = ResponseType.json,
    bool transfer = false,
    bool followRedirects = true,
    Feature? feature,
    String? refreshCookie,
    String? serverUrl,
    Map<String, String>? customHeaders,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    // 1. Resolve against the Server_URL, keeping its subpath (Req 4.1).
    final base = serverUrl ?? _auth.serverUrl;
    var uri = serverUri(base ?? '', path);
    if (!uri.hasScheme) throw StateError('No Server_URL to resolve $path');
    final params = <String, Object>{
      for (final MapEntry(:key, :value) in (query ?? const {}).entries)
        if (value != null)
          key: value is Iterable ? [for (final v in value) '$v'] : '$value',
    };
    if (params.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {...uri.queryParametersAll, ...params},
      );
    }

    // 2. Arg_Envelope (Req 4.5). Models already omit unset fields (Req 4.6).
    var hopMethod = method.toUpperCase();
    var body = argEnvelope(hopMethod, path, data);

    // One token for the whole send: the 30 s timer and the caller's token
    // both cancel through it, and [timedOut] tells them apart.
    final token = CancelToken();
    var timedOut = false;
    final timer = transfer
        ? null
        : Timer(_requestTimeout, () {
            timedOut = true;
            token.cancel('timeout');
          });
    if (cancelToken != null) {
      unawaited(cancelToken.whenCancel.then((_) => token.cancel()));
    }

    final stopwatch = Stopwatch()..start();
    var hop = uri;
    var hops = 0;
    int? status;
    var outcome = 'ok';
    try {
      while (true) {
        // 3–4. Headers for this hop, then one request with redirects off.
        final response = await _dio.requestUri<Object?>(
          hop,
          data: body,
          options: Options(
            method: hopMethod,
            headers: headersFor(
              hop,
              refreshCookie: refreshCookie,
              serverUrl: serverUrl,
              customHeaders: customHeaders,
            ),
            responseType: type,
            followRedirects: false,
            validateStatus: (_) => true,
          ),
          cancelToken: token,
          onSendProgress: onSendProgress,
        );
        status = response.statusCode;

        // 5. Gateway, on every response including a 3xx (Req 5.9).
        if (_isGateway(response.headers)) {
          throw AppException(
            FailureKind.gateway,
            status: status,
            signedIn: serverUrl == null && _auth.session != null,
          );
        }

        // 6. Redirects, at most [maxRedirects] hops.
        final location = response.headers['location']?.first;
        if (followRedirects &&
            _redirectStatuses.contains(status) &&
            location != null) {
          if (hops == maxRedirects) {
            throw AppException(FailureKind.malformed, status: status);
          }
          hops++;
          hop = hop.resolve(location);
          if (status! <= 303) {
            hopMethod = 'GET';
            body = null;
          } else if (body is FormData) {
            body = body.clone();
          }
          continue;
        }

        // 7. 401: refresh once and repeat from step 3 (Task 5.1).

        // 8. Map the status.
        return _check(response, path, feature, followRedirects);
      }
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel && !timedOut) {
        outcome = 'cancelled';
        rethrow;
      }
      final kind = timedOut ? FailureKind.timeout : _kindOf(e);
      outcome = kind.name;
      Error.throwWithStackTrace(AppException(kind, status: status), st);
    } on AppException catch (e) {
      outcome = e.kind.name;
      rethrow;
    } finally {
      timer?.cancel();
      // 9. One line per request; DiagnosticLog redacts the values.
      _log.info('api', 'request', {
        'method': method.toUpperCase(),
        'path': uri.path,
        'status': status,
        'duration': stopwatch.elapsed,
        'hops': hops,
        'outcome': outcome,
      });
    }
  }

  /// [send], then [decode] of the JSON body. A body that doesn't decode
  /// throws [FailureKind.malformed] (Req 4.7 keeps unknown fields and enum
  /// values from failing). A JSON body sent as text is parsed here.
  Future<T> json<T>(
    String method,
    String path,
    T Function(Object? json) decode, {
    Object? data,
    Map<String, Object?>? query,
    bool transfer = false,
    bool followRedirects = true,
    Feature? feature,
    String? refreshCookie,
    String? serverUrl,
    Map<String, String>? customHeaders,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final response = await send(
      method,
      path,
      data: data,
      query: query,
      transfer: transfer,
      followRedirects: followRedirects,
      feature: feature,
      refreshCookie: refreshCookie,
      serverUrl: serverUrl,
      customHeaders: customHeaders,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    try {
      final raw = response.data;
      final body = raw is String
          ? (raw.trim().isEmpty ? null : jsonDecode(raw))
          : raw;
      return decode(body);
    } on FormatException {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    } on TypeError {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    } on CheckedFromJsonException {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    }
  }

  /// The headers for one hop to [uri]. The Browser_User_Agent always goes
  /// (Req 4.2). Only on the Server_Authority (Req 4.3) do the Custom_Headers
  /// (Req 5.7, 5.10), the bearer token and the `Cookie` header go.
  ///
  /// `Cookie` merges the custom Cookie with the `refreshToken` cookie
  /// (Req 5.8) for [refreshCookie] and for `{Server_URL}/images/…` (Req 4.4).
  /// With a [serverUrl] override (the onboarding probe) no session is sent,
  /// and the refresh route sends only its cookie, no bearer token.
  Map<String, String> headersFor(
    Uri uri, {
    String? refreshCookie,
    String? serverUrl,
    Map<String, String>? customHeaders,
  }) {
    final headers = <String, String>{'User-Agent': browserUserAgent};
    final base = serverUrl ?? _auth.serverUrl;
    if (base == null || !isServerAuthority(uri, base)) return headers;

    String? customCookie;
    for (final MapEntry(:key, :value)
        in (customHeaders ?? _secure.customHeaders).entries) {
      if (key.toLowerCase() == 'cookie') {
        customCookie = value;
      } else {
        headers[key] = value;
      }
    }

    final session = serverUrl == null ? _auth.session : null;
    if (session != null && refreshCookie == null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    final refreshToken =
        refreshCookie ??
        (session != null && _isImagePath(uri, base)
            ? session.refreshToken
            : null);
    if (refreshToken != null) {
      headers['Cookie'] = mergeCookieHeader(customCookie, refreshToken);
    } else if (customCookie != null) {
      headers['Cookie'] = customCookie;
    }
    return headers;
  }

  /// Returns a 2xx (or an unfollowed 3xx) and throws for everything else.
  ///
  /// A 404, or an HTML page where an `/api/` route should answer JSON (the
  /// Server's web-app fallback for unknown routes), is not found. On a
  /// [feature] call without a JSON `message` or `error`, that means the
  /// Server lacks the route (Req 6.7).
  Response<Object?> _check(
    Response<Object?> response,
    String path,
    Feature? feature,
    bool followRedirects,
  ) {
    final status = response.statusCode ?? 0;
    final ok = status >= 200 && status < 300;
    final notFound =
        status == 404 ||
        (ok && path.startsWith('/api/') && _isHtml(response.data));
    if (notFound) {
      final message = _errorText(response.data);
      if (feature != null && message == null) {
        missingFeatures.value = {...missingFeatures.value, feature};
        throw AppException(FailureKind.unsupported, status: 404);
      }
      throw AppException(FailureKind.server, status: 404, message: message);
    }
    if (ok) return response;
    if (!followRedirects && status >= 300 && status < 400) return response;
    throw AppException(
      FailureKind.server,
      status: status,
      message: _errorText(response.data),
    );
  }

  static FailureKind _kindOf(DioException e) => switch (e.type) {
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => FailureKind.timeout,
    DioExceptionType.unknown when e.error is FormatException =>
      FailureKind.malformed,
    _ => FailureKind.network,
  };

  static bool _isGateway(Headers headers) =>
      (headers['www-authenticate'] ?? const <String>[]).any(
        (v) => v.toLowerCase().contains('cloudflare-access'),
      );

  static bool _isHtml(Object? data) {
    if (data is! String) return false;
    final head = data.trimLeft().toLowerCase();
    return head.startsWith('<!doctype html') || head.startsWith('<html');
  }

  /// The body's `message`, `error` or `error_message` text, if it has one.
  static String? _errorText(Object? data) {
    var body = data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is! Map) return null;
    for (final key in const ['message', 'error', 'error_message']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static bool _isImagePath(Uri uri, String serverUrl) {
    final basePath = Uri.parse(serverUrl).path.replaceFirst(_slashes, '');
    return uri.path.startsWith('$basePath/images/');
  }

  static final _slashes = RegExp(r'/+$');
}
