import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

import '../../support/test_server.dart';

/// Refresh, retry and session-exchange paths beyond `auth_flow_test.dart`.
void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late SecureStore secure;
  late CacheDb db;
  late AuthService auth;
  late ApiClient api;

  const user = {'_id': 'u1', 'email': 'user@example.com'};

  /// Wires AuthService, ApiClient and AuthApi the way `main()` does, on
  /// [server], with a stored session when [signedIn] and one cache entry.
  Future<void> start({required bool signedIn}) async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: server.uri.toString(),
      SecureStore.customHeadersKey: jsonEncode({'X-Gate': 'g'}),
      if (signedIn)
        SecureStore.sessionKey: jsonEncode({
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'user': user,
        }),
    });
    secure = SecureStore();
    await secure.load();
    db = CacheDb(NativeDatabase.memory());
    await db
        .into(db.cacheEntries)
        .insert(
          CacheEntriesCompanion.insert(key: 'config', json: '{}', updatedAt: 1),
        );
    auth = AuthService(secure: secure, cache: db);
    api = ApiClient(secure: secure, auth: auth, log: log);
    auth.api = AuthApi(api);
    await auth.load();
  }

  /// The session as a fresh SecureStore reads it back from storage.
  Future<Map<String, Object?>?> storedSession() async {
    final reread = SecureStore();
    await reread.load();
    return reread.session;
  }

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('auth_refresh_test');
    log = await DiagnosticLog.open(directory: logDir);
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  Matcher failsWith(FailureKind kind, {int? status}) => throwsA(
    isA<AppException>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.status, 'status', status),
  );

  TestHandler refreshOk({String token = 'access-2', String? cookie}) =>
      respondJson(
        {'token': token, 'user': user},
        headers: {
          if (cookie != null) 'set-cookie': 'refreshToken=$cookie; Path=/',
        },
      );

  test('a second 401 after a successful refresh returns a server 401 and '
      'keeps the session (Req 12.9)', () async {
    await start(signedIn: true);
    server
      ..on('GET', '/api/convos', respond(status: 401))
      ..on('POST', '/api/auth/refresh', refreshOk(cookie: 'refresh-2'));

    await expectLater(
      api.send('GET', '/api/convos'),
      failsWith(FailureKind.server, status: 401),
    );

    expect(server.requestsTo('/api/convos'), hasLength(2));
    expect(server.requestsTo('/api/auth/refresh'), hasLength(1));
    expect(auth.session?.accessToken, 'access-2');
    expect(auth.expired, isFalse);
    expect((await storedSession())?['accessToken'], 'access-2');
    expect(await db.select(db.cacheEntries).get(), hasLength(1));
  });

  group('a failed refresh keeps the session and fails the waiting requests '
      'with its error (Req 12.8)', () {
    final failures = <String, (TestHandler, FailureKind, int?)>{
      '500': (
        respond(status: 500, delay: const Duration(milliseconds: 100)),
        FailureKind.server,
        500,
      ),
      'a non-LibreChat 403': (
        respond(
          status: 403,
          body: '<html><body>Blocked by WAF</body></html>',
          delay: const Duration(milliseconds: 100),
        ),
        FailureKind.server,
        403,
      ),
      'a network failure': (
        (request, response) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await dropConnection()(request, response);
        },
        FailureKind.network,
        null,
      ),
    };

    for (final MapEntry(key: name, value: (handler, kind, status))
        in failures.entries) {
      test(name, () async {
        await start(signedIn: true);
        server
          ..enqueue('GET', '/api/convos', respond(status: 401))
          ..enqueue('GET', '/api/convos', respond(status: 401))
          ..on('POST', '/api/auth/refresh', handler);

        final errors = await Future.wait([
          for (var i = 0; i < 2; i++)
            api
                .send('GET', '/api/convos')
                .then<Object?>((_) => null, onError: (Object e) => e),
        ]);

        for (final error in errors) {
          expect(
            error,
            isA<AppException>()
                .having((e) => e.kind, 'kind', kind)
                .having((e) => e.status, 'status', status),
          );
        }
        // Both waited on the one refresh and got its error.
        expect(identical(errors[0], errors[1]), isTrue);
        expect(server.requestsTo('/api/auth/refresh'), hasLength(1));
        expect(server.requestsTo('/api/convos'), hasLength(2));
        expect(auth.session?.accessToken, 'access-1');
        expect(auth.session?.refreshToken, 'refresh-1');
        expect(auth.expired, isFalse);
        expect((await storedSession())?['refreshToken'], 'refresh-1');
        expect(await db.select(db.cacheEntries).get(), hasLength(1));
      });
    }
  });

  group('the stored Refresh_Token after a refresh (Req 12.6)', () {
    test('a rotated cookie replaces it in the Secure_Store', () async {
      await start(signedIn: true);
      server
        ..enqueue('GET', '/api/convos', respond(status: 401))
        ..on('GET', '/api/convos', respondJson({'conversations': []}))
        ..on('POST', '/api/auth/refresh', refreshOk(cookie: 'refresh-2'));

      await api.send('GET', '/api/convos');

      final stored = await storedSession();
      expect(stored?['accessToken'], 'access-2');
      expect(stored?['refreshToken'], 'refresh-2');
      expect(auth.session?.refreshToken, 'refresh-2');
    });

    test('without a cookie the old token stays', () async {
      await start(signedIn: true);
      server
        ..enqueue('GET', '/api/convos', respond(status: 401))
        ..on('GET', '/api/convos', respondJson({'conversations': []}))
        ..on('POST', '/api/auth/refresh', respondJson({'token': 'access-2'}));

      await api.send('GET', '/api/convos');

      final stored = await storedSession();
      expect(stored?['accessToken'], 'access-2');
      expect(stored?['refreshToken'], 'refresh-1');
      // No `user` in the reply keeps the stored user.
      expect((stored?['user'] as Map?)?['_id'], 'u1');
      expect(auth.session?.refreshToken, 'refresh-1');
    });
  });

  group('auth routes never refresh on 401 (Req 12.3)', () {
    for (final path in const [
      '/api/auth/login',
      '/api/auth/refresh',
      '/api/auth/logout',
      '/api/auth/2fa/verify-temp',
    ]) {
      test(path, () async {
        await start(signedIn: true);
        server.on('POST', path, respond(status: 401));

        await expectLater(
          api.send('POST', path),
          failsWith(FailureKind.server, status: 401),
        );

        expect(server.requests.map((r) => r.path), [path]);
        expect(auth.session?.accessToken, 'access-1');
      });
    }
  });

  test('a request with a serverUrl override (the probe) never '
      'refreshes', () async {
    await start(signedIn: true);
    server.on('GET', '/api/config', respond(status: 401));

    await expectLater(
      api.send('GET', '/api/config', serverUrl: server.uri.toString()),
      failsWith(FailureKind.server, status: 401),
    );

    expect(server.requests.map((r) => r.path), ['/api/config']);
    expect(auth.session?.accessToken, 'access-1');
  });

  test('the retry carries the new bearer and repeats a POST JSON '
      'body', () async {
    await start(signedIn: true);
    const path = '/api/agents/chat/abort';
    server
      ..enqueue('POST', path, respond(status: 401))
      ..on('POST', path, respondJson({'ok': true}))
      ..on('POST', '/api/auth/refresh', refreshOk());

    final response = await api.send(
      'POST',
      path,
      data: {
        'conversationId': 'c1',
        'tags': ['a', 'b'],
      },
    );

    expect(response.statusCode, 200);
    final [first, retry] = server.requestsTo(path);
    expect(first.header('authorization'), 'Bearer access-1');
    expect(retry.header('authorization'), 'Bearer access-2');
    expect(retry.method, 'POST');
    expect(retry.header('x-gate'), 'g');
    expect(retry.json, {
      'conversationId': 'c1',
      'tags': ['a', 'b'],
    });
    expect(retry.body, first.body);
  });

  test('the retry repeats an Arg_Envelope body without wrapping it '
      'twice', () async {
    await start(signedIn: true);
    const path = '/api/convos/update';
    server
      ..enqueue('POST', path, respond(status: 401))
      ..on('POST', path, respondJson({'conversationId': 'c1'}))
      ..on('POST', '/api/auth/refresh', refreshOk());

    await api.send('POST', path, data: {'conversationId': 'c1', 'title': 'T'});

    final [first, retry] = server.requestsTo(path);
    const expected = {
      'arg': {'conversationId': 'c1', 'title': 'T'},
    };
    expect(first.json, expected);
    expect(retry.json, expected);
    expect(retry.header('authorization'), 'Bearer access-2');
  });

  group('exchangeSsoToken (Req 13.6)', () {
    test('refreshes with the captured cookie, loads the user with the new '
        'bearer, stores the session and notifies', () async {
      await start(signedIn: false);
      server
        ..on(
          'POST',
          '/api/auth/refresh',
          refreshOk(token: 'access-sso', cookie: 'refresh-rotated'),
        )
        ..on('GET', '/api/user', respondJson({...user, 'name': 'Sam'}));
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.exchangeSsoToken('captured');

      final refresh = server.requestsTo('/api/auth/refresh').single;
      expect(refresh.header('cookie'), 'refreshToken=captured');
      expect(refresh.header('authorization'), isNull);
      expect(
        server.requestsTo('/api/user').single.header('authorization'),
        'Bearer access-sso',
      );
      expect(auth.session?.accessToken, 'access-sso');
      expect(auth.session?.refreshToken, 'refresh-rotated');
      expect(auth.session?.user.name, 'Sam');
      final stored = await storedSession();
      expect(stored?['accessToken'], 'access-sso');
      expect(stored?['refreshToken'], 'refresh-rotated');
      expect(notified, 1);
    });

    test('keeps the captured token when no cookie comes back', () async {
      await start(signedIn: false);
      server
        ..on('POST', '/api/auth/refresh', refreshOk(token: 'access-sso'))
        ..on('GET', '/api/user', respondJson(user));

      await auth.exchangeSsoToken('captured');

      expect(auth.session?.refreshToken, 'captured');
      expect((await storedSession())?['refreshToken'], 'captured');
    });

    for (final (name, handler) in [
      (
        'a rejected refresh',
        respond(status: 401, body: 'Invalid refresh token'),
      ),
      ('a failed refresh', respond(status: 502)),
    ]) {
      test('$name leaves the App signed out and throws', () async {
        await start(signedIn: false);
        server
          ..on('POST', '/api/auth/refresh', handler)
          ..on('GET', '/api/user', respondJson(user));
        var notified = 0;
        auth.addListener(() => notified++);

        await expectLater(
          auth.exchangeSsoToken('captured'),
          throwsA(isA<AppException>()),
        );

        expect(auth.session, isNull);
        expect(await storedSession(), isNull);
        expect(server.requestsTo('/api/user'), isEmpty);
        expect(notified, 0);
      });
    }

    test('a failing GET /api/user leaves the App signed out and '
        'throws', () async {
      await start(signedIn: false);
      server
        ..on('POST', '/api/auth/refresh', refreshOk(cookie: 'r2'))
        ..on('GET', '/api/user', respond(status: 500));
      var notified = 0;
      auth.addListener(() => notified++);

      await expectLater(
        auth.exchangeSsoToken('captured'),
        failsWith(FailureKind.server, status: 500),
      );

      expect(auth.session, isNull);
      expect(await storedSession(), isNull);
      expect(notified, 0);
    });
  });

  group('verifyTwoFactor (Req 10.1–10.3)', () {
    for (final (name, backup, field) in [
      ('a code', false, 'token'),
      ('a backup code', true, 'backupCode'),
    ]) {
      test('sends {tempToken, $field} for $name and stores the '
          'session', () async {
        await start(signedIn: false);
        server.on(
          'POST',
          '/api/auth/2fa/verify-temp',
          respondJson(
            {'token': 'access-2fa', 'user': user},
            headers: {'set-cookie': 'refreshToken=refresh-2fa; Path=/'},
          ),
        );

        await auth.verifyTwoFactor('temp-1', '123456', backupCode: backup);

        expect(server.requestsTo('/api/auth/2fa/verify-temp').single.json, {
          'tempToken': 'temp-1',
          field: '123456',
        });
        expect(auth.session?.accessToken, 'access-2fa');
        expect(auth.session?.refreshToken, 'refresh-2fa');
        final stored = await storedSession();
        expect(stored?['accessToken'], 'access-2fa');
        expect(stored?['refreshToken'], 'refresh-2fa');
      });
    }
  });
}
