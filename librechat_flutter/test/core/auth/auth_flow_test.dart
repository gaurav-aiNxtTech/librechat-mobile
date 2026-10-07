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
  /// [server], with a stored session when [signedIn].
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

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('auth_flow_test');
    log = await DiagnosticLog.open(directory: logDir);
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  Matcher failsWith(FailureKind kind) =>
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

  test('login stores the token and the Set-Cookie refreshToken', () async {
    await start(signedIn: false);
    server.on(
      'POST',
      '/api/auth/login',
      respondJson(
        {'token': 'access-9', 'user': user},
        headers: {'set-cookie': 'refreshToken=refresh-9; Path=/; HttpOnly'},
      ),
    );
    var notified = 0;
    auth.addListener(() => notified++);

    final result = await auth.login('ldap-user', 'pw');

    expect(result, isA<SignedIn>());
    expect(server.requestsTo('/api/auth/login').single.json, {
      'email': 'ldap-user',
      'password': 'pw',
    });
    expect(auth.session?.accessToken, 'access-9');
    expect(auth.session?.refreshToken, 'refresh-9');
    expect(secure.session?['refreshToken'], 'refresh-9');
    expect(notified, 1);
  });

  test('login reports a pending two-factor step without a session', () async {
    await start(signedIn: false);
    server.on(
      'POST',
      '/api/auth/login',
      respondJson({'twoFAPending': true, 'tempToken': 'temp-1'}),
    );

    final result = await auth.login('user@example.com', 'pw');

    expect(
      result,
      isA<NeedsTwoFactor>().having((r) => r.tempToken, 't', 'temp-1'),
    );
    expect(auth.session, isNull);
  });

  test('login reports an unverified email', () async {
    await start(signedIn: false);
    server.on(
      'POST',
      '/api/auth/login',
      respondJson({'message': 'Email not verified.'}, status: 422),
    );

    expect(
      await auth.login('user@example.com', 'pw'),
      isA<NeedsVerification>(),
    );
  });

  test('concurrent 401s share one refresh, then the retries succeed', () async {
    await start(signedIn: true);
    for (var i = 0; i < 3; i++) {
      server.enqueue('GET', '/api/convos', respond(status: 401));
    }
    server
      ..on('GET', '/api/convos', respondJson({'conversations': []}))
      ..on(
        'POST',
        '/api/auth/refresh',
        respondJson(
          {'token': 'access-2', 'user': user},
          headers: {'set-cookie': 'refreshToken=refresh-2; Path=/'},
          delay: const Duration(milliseconds: 100),
        ),
      );

    final responses = await Future.wait([
      for (var i = 0; i < 3; i++) api.send('GET', '/api/convos'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    final refresh = server.requestsTo('/api/auth/refresh').single;
    expect(refresh.header('cookie'), 'refreshToken=refresh-1');
    expect(refresh.header('authorization'), isNull);
    final retries = server.requestsTo('/api/convos').skip(3);
    expect(retries.map((r) => r.header('authorization')), [
      for (var i = 0; i < 3; i++) 'Bearer access-2',
    ]);
    expect(auth.session?.refreshToken, 'refresh-2');
    expect(secure.session?['accessToken'], 'access-2');
  });

  test('a rejected refresh clears the session and fails with '
      'sessionExpired', () async {
    await start(signedIn: true);
    server
      ..on('GET', '/api/user', respond(status: 401))
      ..on(
        'POST',
        '/api/auth/refresh',
        respond(status: 403, body: 'Invalid refresh token'),
      );

    await expectLater(
      api.send('GET', '/api/user'),
      failsWith(FailureKind.sessionExpired),
    );

    expect(auth.session, isNull);
    expect(auth.expired, isTrue);
    expect(secure.session, isNull);
    expect(await db.select(db.cacheEntries).get(), isEmpty);
    expect(server.requestsTo('/api/user'), hasLength(1));

    auth.acknowledgeExpiry();
    expect(auth.expired, isFalse);
  });

  test('sign-out clears the session even when logout fails', () async {
    await start(signedIn: true);
    server.on('POST', '/api/auth/logout', respond(status: 500));

    await auth.signOut();

    expect(server.requestsTo('/api/auth/logout'), hasLength(1));
    expect(auth.session, isNull);
    expect(auth.expired, isFalse);
    expect(secure.session, isNull);
    expect(await db.select(db.cacheEntries).get(), isEmpty);
    expect(auth.serverUrl, server.uri.toString());
    expect(secure.customHeaders, {'X-Gate': 'g'});
  });
}
