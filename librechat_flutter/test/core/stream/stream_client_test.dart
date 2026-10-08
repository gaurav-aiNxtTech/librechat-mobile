// StreamClient (Req 5.9, 19.1-19.3, 19.5) against a scripted server, with the
// real SecureStore, AuthService, ApiClient and AuthApi wired as in
// `test/core/auth/auth_refresh_test.dart`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/core/stream/event_mapper.dart';
import 'package:librechat_flutter/core/stream/sse_parser.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/stream/stream_events.dart';

import '../../support/sse_formatter.dart';
import '../../support/test_server.dart';

void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late CacheDb db;
  late AuthService auth;
  late ApiClient api;
  late StreamClient client;
  late List<Duration> waits;

  const path = '/api/agents/chat/stream/s1';
  const user = {'_id': 'u1', 'email': 'user@example.com'};

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('stream_client_test');
    log = await DiagnosticLog.open(directory: logDir);
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: server.uri.toString(),
      SecureStore.customHeadersKey: jsonEncode({'X-Gate': 'g'}),
      SecureStore.sessionKey: jsonEncode({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': user,
      }),
    });
    final secure = SecureStore();
    await secure.load();
    db = CacheDb(NativeDatabase.memory());
    auth = AuthService(secure: secure, cache: db);
    api = ApiClient(secure: secure, auth: auth, log: log);
    auth.api = AuthApi(api);
    await auth.load();
    waits = [];
    client = StreamClient(
      api: api,
      auth: auth,
      log: log,
      backoff: (d) async => waits.add(d),
    );
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  /// A LangGraph text delta frame.
  String text(String value) => sseJson({
    'event': 'on_message_delta',
    'data': {
      'id': 'step_1',
      'delta': {
        'content': [
          {'type': 'text', 'text': value},
        ],
      },
    },
  });

  final finalFrame = sseJson({
    'final': true,
    'responseMessage': {
      'messageId': 'm1',
      'conversationId': 'c1',
      'text': 'Hello',
    },
  });
  const finalEvent = FinalEvent(
    responseMessage: Message(
      messageId: 'm1',
      conversationId: 'c1',
      text: 'Hello',
    ),
  );

  Future<List<StreamEvent>> open({bool resume = false}) =>
      client.open('s1', EventMapper(log: log), resume: resume).toList();

  Matcher failed(FailureKind kind, {int? status}) => isA<StreamFailed>()
      .having((e) => e.error.kind, 'kind', kind)
      .having((e) => e.error.status, 'status', status);

  String? resumeOf(RecordedRequest r) => r.uri.queryParameters['resume'];

  /// [handler] for a client that hangs up mid-body, as StreamClient does
  /// after a Final_Frame or a cancel: the write to the closed socket fails,
  /// and that failure is expected.
  TestHandler hungUpOn(TestHandler handler) => (request, response) async {
    try {
      await handler(request, response);
    } on SocketException {
      // The client closed the connection.
    }
  };

  test('the first request carries the SSE, bearer and custom headers and '
      'no resume', () async {
    server.on('GET', path, respondChunks([finalFrame]));

    expect(await open(), [finalEvent]);

    final request = server.requests.single;
    expect(request.path, path);
    expect(request.uri.query, isEmpty);
    expect(request.header('accept'), 'text/event-stream');
    expect(request.header('authorization'), 'Bearer access-1');
    expect(request.header('x-gate'), 'g');
    expect(request.header('user-agent'), browserUserAgent);
  });

  test('resume: true sends ?resume=true on the first request', () async {
    server.on('GET', path, respondChunks([finalFrame]));

    await open(resume: true);

    expect(resumeOf(server.requests.single), 'true');
  });

  test('maps events and completes right after a FinalEvent', () async {
    server.on(
      'GET',
      path,
      hungUpOn(
        respondChunks([
          text('Hel'),
          formatSse([
            SseEvent(data: jsonEncode({'type': 'text', 'text': 'lo'})),
          ]),
          finalFrame,
          text('late'),
        ], gap: const Duration(milliseconds: 50)),
      ),
    );

    expect(await open(), [
      const TextDelta('Hel'),
      const TextDelta('lo'),
      finalEvent,
    ]);
    expect(server.requests, hasLength(1));
    expect(waits, isEmpty);
  });

  test('a StreamError ends the stream', () async {
    server.on(
      'GET',
      path,
      hungUpOn(
        respondChunks([
          text('a'),
          sseJson({'error': 'Rate limit exceeded'}),
          text('late'),
        ], gap: const Duration(milliseconds: 50)),
      ),
    );

    expect(await open(), [
      const TextDelta('a'),
      const StreamError('Rate limit exceeded'),
    ]);
    expect(server.requests, hasLength(1));
  });

  for (final (name, dropAtEnd) in [
    ('a clean end without a Final', false),
    ('a dropped connection', true),
  ]) {
    test('$name reconnects with resume=true', () async {
      server
        ..enqueue('GET', path, respondChunks([text('a')], dropAtEnd: dropAtEnd))
        ..on('GET', path, respondChunks([finalFrame]));

      expect(await open(), [
        const TextDelta('a'),
        const StreamReconnecting(1),
        finalEvent,
      ]);
      expect(waits, [const Duration(seconds: 1)]);
      expect(server.requests.map(resumeOf), [null, 'true']);
    });
  }

  test('every attempt failing walks the 1, 2, 4, 8, 8 s ladder, then gives '
      'up', () async {
    server.on('GET', path, respond(status: 500));

    expect(await open(), [
      for (var n = 1; n <= 5; n++) StreamReconnecting(n),
      const StreamRetryExhausted(),
    ]);
    expect(waits, StreamClient.reconnectDelays);
    expect(server.requests.map(resumeOf), [
      null,
      for (var i = 0; i < 5; i++) 'true',
    ]);
  });

  test('a parsed event resets the attempt count (Req 19.3)', () async {
    server
      ..enqueue('GET', path, respond(status: 500))
      ..enqueue('GET', path, respondChunks([text('a')], dropAtEnd: true))
      ..enqueue('GET', path, respond(status: 503))
      ..on('GET', path, respondChunks([finalFrame]));

    expect(await open(), [
      const StreamReconnecting(1),
      const TextDelta('a'),
      const StreamReconnecting(1),
      const StreamReconnecting(2),
      finalEvent,
    ]);
    expect(waits, const [
      Duration(seconds: 1),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ]);
    expect(server.requests, hasLength(4));
  });

  test('a 404 yields StreamExpired without retrying (Req 19.5)', () async {
    server.on('GET', path, respond(status: 404));

    expect(await open(), [const StreamExpired()]);
    expect(server.requests, hasLength(1));
    expect(waits, isEmpty);
  });

  group('401', () {
    TestHandler refreshOk() => respondJson({'token': 'access-2', 'user': user});

    test('refreshes once and retries the same attempt with the new '
        'bearer', () async {
      server
        ..enqueue('GET', path, respond(status: 401))
        ..on('GET', path, respondChunks([finalFrame]))
        ..on('POST', '/api/auth/refresh', refreshOk());

      expect(await open(), [finalEvent]);

      expect(server.requestsTo('/api/auth/refresh'), hasLength(1));
      final [first, retry] = server.requestsTo(path);
      expect(first.header('authorization'), 'Bearer access-1');
      expect(retry.header('authorization'), 'Bearer access-2');
      expect(resumeOf(retry), isNull);
      expect(waits, isEmpty);
    });

    test('a rejected refresh yields StreamFailed(sessionExpired)', () async {
      server
        ..on('GET', path, respond(status: 401))
        ..on(
          'POST',
          '/api/auth/refresh',
          respond(status: 401, body: 'Invalid refresh token'),
        );

      expect(await open(), [failed(FailureKind.sessionExpired)]);
      expect(server.requestsTo(path), hasLength(1));
      expect(auth.session, isNull);
      expect(waits, isEmpty);
    });

    test('a 401 after the refresh yields StreamFailed(server 401)', () async {
      server
        ..on('GET', path, respond(status: 401))
        ..on('POST', '/api/auth/refresh', refreshOk());

      expect(await open(), [failed(FailureKind.server, status: 401)]);
      expect(server.requestsTo(path), hasLength(2));
      expect(server.requestsTo('/api/auth/refresh'), hasLength(1));
      expect(auth.session?.accessToken, 'access-2');
    });

    test('a refresh that fails without a rejection is a failed '
        'attempt', () async {
      server
        ..enqueue('GET', path, respond(status: 401))
        ..on('GET', path, respondChunks([finalFrame]))
        ..on('POST', '/api/auth/refresh', respond(status: 500));

      expect(await open(), [const StreamReconnecting(1), finalEvent]);
      expect(auth.session?.accessToken, 'access-1');
      expect(server.requests.map(resumeOf), [null, null, 'true']);
    });
  });

  for (final status in [200, 302]) {
    test('a gateway on a $status yields StreamFailed(gateway) without retry '
        'or redirect (Req 5.9)', () async {
      server.on(
        'GET',
        path,
        respond(
          status: status,
          headers: {
            'www-authenticate': 'Cloudflare-Access realm="team"',
            if (status == 302) 'location': '/cdn-cgi/access/login',
          },
        ),
      );

      final events = await open();

      expect(events, [failed(FailureKind.gateway, status: status)]);
      expect((events.single as StreamFailed).error.signedIn, isTrue);
      expect(server.requests, hasLength(1));
      expect(waits, isEmpty);
    });
  }

  group('cancelling', () {
    test('after the first event completes without further requests', () async {
      server.on(
        'GET',
        path,
        hungUpOn(
          respondChunks([
            text('a'),
            finalFrame,
          ], gap: const Duration(milliseconds: 300)),
        ),
      );

      final first = await client.open('s1', EventMapper(log: log)).first;

      expect(first, const TextDelta('a'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(server.requests, hasLength(1));
      expect(waits, isEmpty);
    });

    test('while the body is idle closes the stream promptly', () async {
      server.on(
        'GET',
        path,
        hungUpOn(
          respondChunks([
            text('a'),
            finalFrame,
          ], gap: const Duration(seconds: 3)),
        ),
      );
      final received = Completer<void>();
      final subscription = client
          .open('s1', EventMapper(log: log))
          .listen((_) => received.complete());
      await received.future;
      // Let the client wait on the next chunk, then cancel.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final stopwatch = Stopwatch()..start();
      await subscription.cancel();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      expect(server.requests, hasLength(1));
      expect(waits, isEmpty);
    });

    test('during a backoff wait ends it without reconnecting', () async {
      server.on('GET', path, respond(status: 500));
      final waiting = Completer<void>();
      final stalled = StreamClient(
        api: api,
        auth: auth,
        log: log,
        backoff: (_) {
          waiting.complete();
          return Completer<void>().future;
        },
      );
      final events = <StreamEvent>[];
      final subscription = stalled
          .open('s1', EventMapper(log: log))
          .listen(events.add);
      await waiting.future;

      await subscription.cancel().timeout(const Duration(seconds: 1));

      expect(events, [const StreamReconnecting(1)]);
      expect(server.requests, hasLength(1));
    });
  });
}
