import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../log/diagnostic_log.dart';
import '../network/api_client.dart';
import '../network/app_exception.dart';
import '../network/server_url.dart';
import 'event_mapper.dart';
import 'sse_parser.dart';
import 'stream_events.dart';

/// The app's [StreamClient]. `main()` builds it and overrides this provider.
final streamClientProvider = Provider<StreamClient>(
  (ref) => throw UnimplementedError('streamClientProvider is not overridden'),
);

Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

/// Opens a Run's SSE stream, `GET /api/agents/chat/stream/:streamId`, and
/// reconnects with `?resume=true` when it drops (Req 19.1–19.3).
///
/// Each [open] uses its own dart:io [HttpClient], closed with `force: true`
/// when the stream ends or its subscription is cancelled, so cancelling
/// closes the socket. Headers come from [ApiClient.headersFor], so the
/// bearer token and the Custom_Headers match the REST requests.
class StreamClient {
  /// [backoff] waits before each reconnect; tests record the delays instead
  /// of sleeping.
  StreamClient({
    required this._api,
    required this._auth,
    required this._log,
    this._backoff = _sleep,
  });

  /// The wait before reconnect N is `reconnectDelays[N - 1]`; after the last
  /// one fails the stream gives up (Req 19.2).
  static const reconnectDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 8),
  ];

  final ApiClient _api;
  final AuthService _auth;
  final DiagnosticLog _log;
  final Future<void> Function(Duration delay) _backoff;

  /// The events of [streamId]'s Run, decoded by [mapper] (one per Run, so
  /// its step attribution survives reconnects).
  ///
  /// - Completes right after a [FinalEvent] or a [StreamError].
  /// - A 401 refreshes once through AuthService and retries the same
  ///   attempt; a refresh rejection yields [StreamFailed] with
  ///   [FailureKind.sessionExpired], and a 401 after the refresh a server
  ///   401. A refresh that fails otherwise counts as a failed attempt.
  /// - A 404 yields [StreamExpired] (Req 19.5).
  /// - An Access_Gateway_Error on any response, a 3xx included, yields
  ///   [StreamFailed] with [FailureKind.gateway] and never retries (Req 5.9).
  /// - Any other status, a network error, or a body that ends without a
  ///   Final_Frame is a failed attempt: [StreamReconnecting] with the attempt
  ///   number, the [backoff] wait, then a reconnect with `?resume=true`.
  ///   Every parsed SSE event resets the count (Req 19.3); after
  ///   [reconnectDelays] runs out, [StreamRetryExhausted].
  ///
  /// [resume] sends `?resume=true` on the first request too.
  Stream<StreamEvent> open(
    String streamId,
    EventMapper mapper, {
    bool resume = false,
  }) {
    final client = HttpClient()..connectionTimeout = ApiClient.connectTimeout;
    final cancel = Completer<void>();
    StreamSubscription<StreamEvent>? run;
    late final StreamController<StreamEvent> controller;
    controller = StreamController<StreamEvent>(
      onListen: () {
        run = _run(client, streamId, mapper, resume, cancel).listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onPause: () => run?.pause(),
      onResume: () => run?.resume(),
      onCancel: () {
        // An async* generator only stops at its next yield, which an idle
        // body or a backoff wait may not reach for a while; closing the
        // client ends the read now, so cancelling always closes the socket.
        cancel.complete();
        client.close(force: true);
        return run?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<StreamEvent> _run(
    HttpClient client,
    String streamId,
    EventMapper mapper,
    bool resume,
    Completer<void> cancel,
  ) async* {
    final serverUrl = _auth.serverUrl;
    if (serverUrl == null) throw StateError('No Server_URL to stream from');
    final path = '/api/agents/chat/stream/${Uri.encodeComponent(streamId)}';
    var attempt = 0;
    var reconnect = resume;
    try {
      while (!cancel.isCompleted) {
        final uri = serverUri(
          serverUrl,
          reconnect ? '$path?resume=true' : path,
        );
        var refreshed = false;
        // One pass per request; a 401 refresh repeats it for the same attempt.
        var retrySameAttempt = true;
        while (retrySameAttempt && !cancel.isCompleted) {
          retrySameAttempt = false;
          final sentToken = _auth.session?.accessToken;
          int? status;
          var outcome = 'cancelled';
          try {
            final request = await client.getUrl(uri);
            request.followRedirects = false;
            _api.headersFor(uri).forEach(request.headers.set);
            request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
            final response = await request.close();
            status = response.statusCode;

            // Gateway first, on every response (Req 5.9).
            if (_isGateway(response.headers)) {
              outcome = 'gateway';
              await _drain(response);
              yield StreamFailed(
                AppException(
                  FailureKind.gateway,
                  status: status,
                  signedIn: _auth.session != null,
                ),
              );
              return;
            }

            if (status >= 200 && status < 300) {
              await for (final sse in response.transform(const SseParser())) {
                attempt = 0;
                for (final event in mapper.map(sse)) {
                  if (event is FinalEvent || event is StreamError) {
                    outcome = event is FinalEvent ? 'final' : 'error';
                    yield event;
                    return;
                  }
                  yield event;
                }
              }
              // A clean end without a Final_Frame falls through to a retry.
              outcome = 'ended';
            } else if (status == 401) {
              await _drain(response);
              if (refreshed || sentToken == null) {
                outcome = 'unauthorized';
                yield StreamFailed(
                  AppException(FailureKind.server, status: 401),
                );
                return;
              }
              refreshed = true;
              try {
                // Another request's refresh may already have replaced it.
                if (_auth.session?.accessToken == sentToken) {
                  await _auth.refresh();
                }
              } on AppException catch (e) {
                if (e.kind != FailureKind.sessionExpired) {
                  outcome = 'refresh_failed';
                  rethrow;
                }
                outcome = 'session_expired';
                yield StreamFailed(e);
                return;
              }
              if (_auth.session == null) {
                outcome = 'session_expired';
                yield StreamFailed(
                  AppException(FailureKind.sessionExpired, signedIn: false),
                );
                return;
              }
              outcome = 'refreshed';
              retrySameAttempt = true;
            } else if (status == 404) {
              outcome = 'expired';
              await _drain(response);
              yield const StreamExpired();
              return;
            } else {
              outcome = 'status';
              await _drain(response);
            }
          } on AppException {
            // A refresh that failed without a rejection: a failed attempt.
          } on IOException {
            outcome = 'network';
          } on TimeoutException {
            outcome = 'network';
          } finally {
            // One line per request; never the URL, which names the stream.
            _log.info('stream', 'attempt', {
              'attempt': attempt,
              'status': status,
              'outcome': cancel.isCompleted ? 'cancelled' : outcome,
            });
          }
        }
        // A read that the cancel broke off is not a failed attempt.
        if (cancel.isCompleted) return;

        attempt++;
        if (attempt > reconnectDelays.length) {
          yield const StreamRetryExhausted();
          return;
        }
        yield StreamReconnecting(attempt);
        await Future.any([
          _backoff(reconnectDelays[attempt - 1]),
          cancel.future,
        ]);
        reconnect = true;
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Discards a body the stream does not read, so the connection frees up.
  static Future<void> _drain(HttpClientResponse response) async {
    try {
      await response.drain<void>();
    } on IOException {
      // The body broke off; nothing in it was needed.
    }
  }

  /// An Access_Gateway_Error, checked as ApiClient checks it.
  static bool _isGateway(HttpHeaders headers) =>
      ApiClient.isGatewayChallenge(headers[HttpHeaders.wwwAuthenticateHeader]);
}
