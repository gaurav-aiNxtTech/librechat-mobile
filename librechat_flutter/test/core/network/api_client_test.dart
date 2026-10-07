import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

import '../../support/test_server.dart';

void main() {
  late TestServer server;
  late TestServer other;
  late Directory logDir;
  late DiagnosticLog log;
  final dbs = <CacheDb>[];

  setUp(() async {
    server = await TestServer.start();
    other = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('api_client_test');
    log = await DiagnosticLog.open(directory: logDir);
  });

  tearDown(() async {
    await server.close();
    await other.close();
    for (final db in dbs) {
      await db.close();
    }
    dbs.clear();
    await log.file();
    await logDir.delete(recursive: true);
  });

  // The SecureStore behind the last [client], for writes mid-test.
  late SecureStore secure;

  /// An ApiClient on [server] (or [serverUrl]) with a stored session and
  /// [customHeaders], read through the real SecureStore and AuthService.
  Future<ApiClient> client({
    Duration requestTimeout = const Duration(seconds: 30),
    String? serverUrl,
    Map<String, String> customHeaders = const {'X-Gate': 'gate-secret'},
  }) async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: serverUrl ?? server.uri.toString(),
      SecureStore.customHeadersKey: jsonEncode(customHeaders),
      SecureStore.sessionKey: jsonEncode({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': {'_id': 'u1'},
      }),
    });
    secure = SecureStore();
    await secure.load();
    final db = CacheDb(NativeDatabase.memory());
    dbs.add(db);
    final auth = AuthService(secure: secure, cache: db);
    await auth.load();
    return ApiClient(
      secure: secure,
      auth: auth,
      log: log,
      requestTimeout: requestTimeout,
    );
  }

  Matcher failsWith(FailureKind kind) =>
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

  test('sends the Browser_User_Agent, bearer and Custom_Headers to the '
      'Server_Authority', () async {
    final api = await client();
    server.on('GET', '/api/user', respondJson({'_id': 'u1'}));

    await api.send('GET', '/api/user');

    final request = server.requestsTo('/api/user').single;
    expect(request.header('user-agent'), browserUserAgent);
    expect(request.header('authorization'), 'Bearer access-1');
    expect(request.header('x-gate'), 'gate-secret');
  });

  test('sends only the User-Agent to another host', () async {
    final api = await client();
    other.on('GET', '/avatar.png', respond(body: 'png'));

    await api.send('GET', other.url('/avatar.png').toString(), transfer: true);

    final request = other.requests.single;
    expect(request.header('user-agent'), browserUserAgent);
    expect(request.header('authorization'), isNull);
    expect(request.header('x-gate'), isNull);
    expect(request.header('cookie'), isNull);
  });

  test('a cross-host redirect strips the bearer and Custom_Headers', () async {
    final api = await client();
    server.on(
      'GET',
      '/api/files/download/f1',
      redirect(other.url('/bucket/f1').toString()),
    );
    other.on('GET', '/bucket/f1', respond(body: 'bytes'));

    final response = await api.send(
      'GET',
      '/api/files/download/f1',
      type: ResponseType.bytes,
      transfer: true,
    );

    expect(response.statusCode, 200);
    final first = server.requests.single;
    expect(first.header('authorization'), 'Bearer access-1');
    expect(first.header('x-gate'), 'gate-secret');
    final hop = other.requests.single;
    expect(hop.header('user-agent'), browserUserAgent);
    expect(hop.header('authorization'), isNull);
    expect(hop.header('x-gate'), isNull);
  });

  test('a gateway challenge on a 3xx fails without following it', () async {
    final api = await client();
    server.on(
      'GET',
      '/api/config',
      respond(
        status: 302,
        headers: {
          'location': other.url('/cdn-cgi/access/login').toString(),
          'www-authenticate': 'CLOUDFLARE-ACCESS realm="team"',
        },
      ),
    );

    await expectLater(
      api.send('GET', '/api/config'),
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', FailureKind.gateway)
            .having((e) => e.signedIn, 'signedIn', true),
      ),
    );
    expect(other.requests, isEmpty);
  });

  group('Arg_Envelope', () {
    test('wraps exactly the update, archive, pin and delete routes', () {
      const body = {'conversationId': 'c1'};
      for (final (method, path) in [
        ('POST', '/api/convos/update'),
        ('POST', '/api/convos/archive'),
        ('post', '/api/convos/pin'),
        ('DELETE', '/api/convos'),
        ('DELETE', '/api/convos?x=1'),
      ]) {
        expect(argEnvelope(method, path, body), {'arg': body}, reason: path);
      }
      for (final (method, path) in [
        ('GET', '/api/convos'),
        ('POST', '/api/convos'),
        ('POST', '/api/convos/fork'),
        ('DELETE', '/api/convos/all'),
      ]) {
        expect(argEnvelope(method, path, body), same(body), reason: path);
      }
    });

    test('send puts the body under arg', () async {
      final api = await client();
      server.on('POST', '/api/convos/update', respondJson({'title': 'New'}));

      await api.send(
        'POST',
        '/api/convos/update',
        data: {'conversationId': 'c1', 'title': 'New'},
      );

      expect(server.requestsTo('/api/convos/update').single.json, {
        'arg': {'conversationId': 'c1', 'title': 'New'},
      });
    });
  });

  test('a 404 marks a tagged feature missing; an item 404 does not', () async {
    final api = await client();
    server.on(
      'GET',
      '/api/schedules',
      respond(status: 404, body: '<!DOCTYPE html><pre>Cannot GET</pre>'),
    );
    server.on(
      'GET',
      '/api/schedules/s1',
      respondJson({'message': 'Schedule not found'}, status: 404),
    );

    await expectLater(
      api.send('GET', '/api/schedules', feature: Feature.schedules),
      failsWith(FailureKind.unsupported),
    );
    expect(api.missingFeatures.value, {Feature.schedules});

    await expectLater(
      api.send('GET', '/api/schedules/s1', feature: Feature.prompts),
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', FailureKind.server)
            .having((e) => e.status, 'status', 404),
      ),
    );
    expect(api.missingFeatures.value, {Feature.schedules});
  });

  test('the overall timer fails as timeout; a user cancel rethrows dio\'s '
      'cancel error', () async {
    final api = await client(requestTimeout: const Duration(milliseconds: 200));
    server.on('GET', '/api/slow', hang());

    await expectLater(
      api.send('GET', '/api/slow'),
      failsWith(FailureKind.timeout),
    );

    final token = CancelToken();
    final pending = api.send('GET', '/api/slow', cancelToken: token);
    token.cancel();
    await expectLater(
      pending,
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });

  group('redirects', () {
    test('a same-authority hop keeps the bearer and Custom_Headers', () async {
      final api = await client();
      server.on('GET', '/api/old', redirect('/api/new'));
      server.on('GET', '/api/new', respondJson({'ok': true}));

      await api.send('GET', '/api/old');

      final hop = server.requestsTo('/api/new').single;
      expect(hop.header('authorization'), 'Bearer access-1');
      expect(hop.header('x-gate'), 'gate-secret');
      expect(hop.header('user-agent'), browserUserAgent);
    });

    test(
      'a hop back to the Server_Authority gets the credentials again',
      () async {
        final api = await client();
        server.on(
          'GET',
          '/api/files/download/f1',
          redirect(other.url('/bounce').toString()),
        );
        other.on(
          'GET',
          '/bounce',
          redirect(server.url('/images/u1/f1.png').toString()),
        );
        server.on('GET', '/images/u1/f1.png', respond(body: 'png'));

        await api.send(
          'GET',
          '/api/files/download/f1',
          type: ResponseType.bytes,
          transfer: true,
        );

        final away = other.requestsTo('/bounce').single;
        expect(away.header('authorization'), isNull);
        expect(away.header('x-gate'), isNull);
        expect(away.header('cookie'), isNull);
        final back = server.requestsTo('/images/u1/f1.png').single;
        expect(back.header('authorization'), 'Bearer access-1');
        expect(back.header('x-gate'), 'gate-secret');
        expect(back.header('cookie'), 'refreshToken=refresh-1');
      },
    );

    test('an http downgrade of the same host gets no credentials', () async {
      // The Server_URL is https on the test server's host and port, so the
      // plain-http request reaches the same host:port on another scheme.
      final api = await client(
        serverUrl: 'https://127.0.0.1:${server.uri.port}',
      );
      server.on('GET', '/images/u1/a.png', respond(body: 'png'));

      await api.send(
        'GET',
        server.url('/images/u1/a.png').toString(),
        type: ResponseType.bytes,
        transfer: true,
      );

      final request = server.requestsTo('/images/u1/a.png').single;
      expect(request.header('user-agent'), browserUserAgent);
      expect(request.header('authorization'), isNull);
      expect(request.header('x-gate'), isNull);
      expect(request.header('cookie'), isNull);
    });

    test('five hops are followed and a sixth fails as malformed', () async {
      final api = await client();
      for (var i = 1; i <= 6; i++) {
        server.on('GET', '/api/hop/$i', redirect('/api/hop/${i - 1}'));
      }
      server.on('GET', '/api/hop/0', respondJson({'ok': true}));

      final response = await api.send('GET', '/api/hop/5');
      expect(response.statusCode, 200);
      expect(server.requests, hasLength(6));

      await expectLater(
        api.send('GET', '/api/hop/6'),
        failsWith(FailureKind.malformed),
      );
      // /api/hop/6 down to /api/hop/1; the sixth Location is not followed.
      expect(server.requests, hasLength(12));
      expect(server.requests.last.path, '/api/hop/1');
    });

    test(
      '301–303 switch to GET without a body; 307 and 308 keep both',
      () async {
        final api = await client();
        server.on('GET', '/api/moved', respondJson({'ok': true}));
        server.on('POST', '/api/moved', respondJson({'ok': true}));

        for (final status in [301, 302, 303, 307, 308]) {
          server.enqueue(
            'POST',
            '/api/move',
            redirect('/api/moved', status: status),
          );
          await api.send('POST', '/api/move', data: {'a': 1});

          final hop = server.requestsTo('/api/moved').last;
          if (status <= 303) {
            expect(hop.method, 'GET', reason: '$status');
            expect(hop.bodyBytes, isEmpty, reason: '$status');
          } else {
            expect(hop.method, 'POST', reason: '$status');
            expect(hop.json, {'a': 1}, reason: '$status');
          }
        }
      },
    );
  });

  group('Cookie', () {
    const staleCookie = 'cf_clearance=abc; refreshToken=stale; theme=dark';

    test(
      'on /images/ merges into one header with the session refreshToken',
      () async {
        final api = await client(
          customHeaders: {'X-Gate': 'gate-secret', 'Cookie': staleCookie},
        );
        server.on('GET', '/images/u1/a.png', respond(body: 'png'));

        await api.send(
          'GET',
          '/images/u1/a.png',
          type: ResponseType.bytes,
          transfer: true,
        );

        final request = server.requestsTo('/images/u1/a.png').single;
        final cookies = request.headers['cookie']!;
        expect(cookies, hasLength(1));
        final segments = cookies.single.split('; ');
        expect(segments.where((s) => s.startsWith('refreshToken=')), [
          'refreshToken=refresh-1',
        ]);
        expect(segments, containsAll(['cf_clearance=abc', 'theme=dark']));
      },
    );

    test('elsewhere the custom Cookie goes unchanged', () async {
      final api = await client(
        customHeaders: {'X-Gate': 'gate-secret', 'cookie': staleCookie},
      );
      server.on('GET', '/api/user', respondJson({'_id': 'u1'}));

      await api.send('GET', '/api/user');

      final request = server.requestsTo('/api/user').single;
      expect(request.headers['cookie'], [staleCookie]);
      expect(request.header('authorization'), 'Bearer access-1');
    });

    test('the refresh route sends the merged cookie and no bearer', () async {
      final api = await client(
        customHeaders: {'X-Gate': 'gate-secret', 'Cookie': staleCookie},
      );
      server.on('POST', '/api/auth/refresh', respondJson({'token': 't'}));

      await api.send('POST', '/api/auth/refresh', refreshCookie: 'refresh-new');

      final request = server.requestsTo('/api/auth/refresh').single;
      expect(request.header('authorization'), isNull);
      expect(request.header('x-gate'), 'gate-secret');
      final segments = request.headers['cookie']!.single.split('; ');
      expect(segments.where((s) => s.startsWith('refreshToken=')), [
        'refreshToken=refresh-new',
      ]);
    });
  });

  test('a subpath Server_URL resolves under it and its /images/ gets the '
      'cookie', () async {
    final api = await client(serverUrl: server.url('/librechat').toString());
    server.on('GET', '/librechat/api/config', respondJson({}));
    server.on('GET', '/librechat/images/u1/a.png', respond(body: 'png'));
    server.on('GET', '/images/u1/a.png', respond(body: 'png'));

    await api.send('GET', '/api/config');
    await api.send(
      'GET',
      '/images/u1/a.png',
      type: ResponseType.bytes,
      transfer: true,
    );
    // The root /images/ is outside the subpath, so it is not an image route.
    await api.send(
      'GET',
      server.url('/images/u1/a.png').toString(),
      type: ResponseType.bytes,
      transfer: true,
    );

    final config = server.requestsTo('/librechat/api/config').single;
    expect(config.header('authorization'), 'Bearer access-1');
    expect(config.header('cookie'), isNull);
    expect(
      server.requestsTo('/librechat/images/u1/a.png').single.header('cookie'),
      'refreshToken=refresh-1',
    );
    expect(
      server.requestsTo('/images/u1/a.png').single.header('cookie'),
      isNull,
    );
  });

  test('new Custom_Headers apply to the next request', () async {
    final api = await client();
    server.on('GET', '/api/user', respondJson({'_id': 'u1'}));

    await api.send('GET', '/api/user');
    await secure.writeCustomHeaders({'X-New': 'new-1'});
    await api.send('GET', '/api/user');

    final [before, after] = server.requestsTo('/api/user');
    expect(before.header('x-gate'), 'gate-secret');
    expect(after.header('x-new'), 'new-1');
    expect(after.header('x-gate'), isNull);
  });

  test('a model body sends no null keys', () async {
    final api = await client();
    server.on('POST', '/api/convos/update', respondJson({}));

    await api.send(
      'POST',
      '/api/convos/update',
      data: const Conversation(conversationId: 'c1', title: 'T').toJson(),
    );

    bool hasNull(Object? value) =>
        value == null ||
        (value is Map && value.values.any(hasNull)) ||
        (value is List && value.any(hasNull));
    final wire = server.requestsTo('/api/convos/update').single;
    expect(RegExp(r'\bnull\b').hasMatch(wire.body), isFalse, reason: wire.body);
    expect(hasNull(wire.json), isFalse);
    expect((wire.json! as Map)['arg'], containsPair('conversationId', 'c1'));
  });

  test('query drops null values and repeats list values', () async {
    final api = await client();
    server.on('GET', '/api/convos', respondJson({'conversations': []}));

    await api.send(
      'GET',
      '/api/convos',
      query: {
        'cursor': null,
        'tags': ['a', 'b'],
        'limit': 25,
      },
    );

    final request = server.requestsTo('/api/convos').single;
    expect(request.uri.queryParametersAll, {
      'tags': ['a', 'b'],
      'limit': ['25'],
    });
    expect(request.uri.query, isNot(contains('cursor')));
  });

  group('timeouts and connections', () {
    test('a transfer skips the overall timer', () async {
      final api = await client(
        requestTimeout: const Duration(milliseconds: 200),
      );
      server.on(
        'GET',
        '/api/files/download/f1',
        respond(body: 'bytes', delay: const Duration(milliseconds: 400)),
      );

      final response = await api.send(
        'GET',
        '/api/files/download/f1',
        type: ResponseType.bytes,
        transfer: true,
      );

      expect(response.statusCode, 200);
    });

    test('a refused connection fails as network', () async {
      final api = await client();
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();

      await expectLater(
        api.send('GET', 'http://127.0.0.1:$port/api/config'),
        failsWith(FailureKind.network),
      );
    });
  });

  group('error mapping', () {
    test('a 500 keeps the JSON message', () async {
      final api = await client();
      server.on(
        'GET',
        '/api/user',
        respondJson({'message': 'Database unavailable'}, status: 500),
      );

      await expectLater(
        api.send('GET', '/api/user'),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', FailureKind.server)
              .having((e) => e.status, 'status', 500)
              .having((e) => e.message, 'message', 'Database unavailable'),
        ),
      );
    });

    test('a 2xx HTML page on an /api/ route is not found', () async {
      final api = await client();
      server.on(
        'GET',
        '/api/unknown',
        respond(
          headers: {'content-type': 'text/html'},
          body: '<!DOCTYPE html><html><body>LibreChat</body></html>',
        ),
      );

      await expectLater(
        api.send('GET', '/api/unknown'),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', FailureKind.server)
              .having((e) => e.status, 'status', 404),
        ),
      );
    });

    test('json<T> maps a body that does not decode to malformed', () async {
      final api = await client();
      server.on('GET', '/api/convos/c1', respondJson({'title': 5}));
      server.on(
        'GET',
        '/api/convos/c2',
        respond(headers: {'content-type': 'application/json'}, body: '{oops'),
      );

      Conversation decode(Object? json) =>
          Conversation.fromJson(json! as Map<String, Object?>);
      await expectLater(
        api.json('GET', '/api/convos/c1', decode),
        failsWith(FailureKind.malformed),
      );
      await expectLater(
        api.json('GET', '/api/convos/c2', decode),
        failsWith(FailureKind.malformed),
      );
    });
  });

  group('gateway', () {
    test('a challenge on a second WWW-Authenticate line fails', () async {
      final api = await client();
      server.on('GET', '/api/config', (_, response) async {
        response.headers
          ..noFolding('www-authenticate')
          ..add('www-authenticate', 'Bearer realm="api"')
          ..add('www-authenticate', 'Cloudflare-Access realm="team"');
        await response.close();
      });

      await expectLater(
        api.send('GET', '/api/config'),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', FailureKind.gateway)
              .having((e) => e.signedIn, 'signedIn', true),
        ),
      );
    });

    test('a challenge on a 200 fails; the probe is signed out', () async {
      final api = await client();
      other.on(
        'GET',
        '/api/config',
        respondJson({}, headers: {'www-authenticate': 'Cloudflare-Access'}),
      );

      await expectLater(
        api.send(
          'GET',
          '/api/config',
          serverUrl: other.uri.toString(),
          customHeaders: {'X-Typed': 'typed-1'},
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', FailureKind.gateway)
              .having((e) => e.status, 'status', 200)
              .having((e) => e.signedIn, 'signedIn', false),
        ),
      );
      final probe = other.requestsTo('/api/config').single;
      expect(probe.header('authorization'), isNull);
      expect(probe.header('x-typed'), 'typed-1');
      expect(probe.header('x-gate'), isNull);
    });
  });

  test('the log line has no query, token or header value', () async {
    final api = await client(
      customHeaders: {'X-Gate': 'gate-secret', 'Cookie': 'cf=cookie-secret'},
    );
    server.on('GET', '/api/search', respondJson({}));
    server.on('GET', '/images/u1/a.png', respond(body: 'png'));

    await api.send(
      'GET',
      '/api/search?q=needle-query',
      query: {'token': 'needle-token'},
    );
    await api.send(
      'GET',
      '/images/u1/a.png',
      type: ResponseType.bytes,
      transfer: true,
    );

    final text = await (await log.file()).readAsString();
    final lines = text
        .split('\n')
        .where((l) => l.contains(' api request '))
        .toList();
    expect(lines, hasLength(2));
    expect(lines.first, contains('/api/search'));
    expect(lines.first, contains('GET'));
    expect(lines.first, contains('200'));
    for (final secret in [
      'needle-query',
      'needle-token',
      'access-1',
      'refresh-1',
      'gate-secret',
      'cookie-secret',
    ]) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
    expect(lines.first, isNot(contains('?')));
  });
}
