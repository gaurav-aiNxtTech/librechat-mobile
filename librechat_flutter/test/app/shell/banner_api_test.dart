import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/app/shell/banners.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

import '../../support/test_server.dart';

/// [bannerProvider] against a scripted Server (Req 14.4).
void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late CacheDb db;
  late ProviderContainer container;

  /// Wires AuthService and ApiClient the way `main()` does.
  Future<void> start({required bool signedIn}) async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: server.uri.toString(),
      if (signedIn)
        SecureStore.sessionKey: jsonEncode({
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'user': {'_id': 'u1', 'role': 'USER'},
        }),
    });
    final secure = SecureStore();
    await secure.load();
    final auth = AuthService(secure: secure, cache: db);
    final api = ApiClient(secure: secure, auth: auth, log: log);
    auth.api = AuthApi(api);
    await auth.load();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        apiClientProvider.overrideWithValue(api),
      ],
    );
  }

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('banner_api_test');
    log = await DiagnosticLog.open(directory: logDir);
    db = CacheDb(NativeDatabase.memory());
  });

  tearDown(() async {
    container.dispose();
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  test('an empty body without a Content-Type is no banner', () async {
    await start(signedIn: true);
    server.on('GET', '/api/banner', (_, response) async {
      response.headers.removeAll(HttpHeaders.contentTypeHeader);
      await response.close();
    });

    expect(await container.read(bannerProvider.future), isNull);
    final request = server.requestsTo('/api/banner').single;
    expect(request.method, 'GET');
    expect(request.header('authorization'), 'Bearer access-1');
  });

  test('a JSON object decodes to a ServerBanner', () async {
    await start(signedIn: true);
    server.on(
      'GET',
      '/api/banner',
      respondJson({
        '_id': 'x',
        'bannerId': 'b1',
        'message': 'Hi',
        'type': 'banner',
        'persistable': true,
        'displayFrom': '2026-10-01T00:00:00.000Z',
        'displayTo': null,
        'isPublic': false,
      }),
    );

    final banner = await container.read(bannerProvider.future);

    expect(banner?.bannerId, 'b1');
    expect(banner?.message, 'Hi');
    expect(banner?.type, 'banner');
    expect(banner?.persistable, isTrue);
    expect(banner?.displayFrom, DateTime.utc(2026, 10));
    expect(banner?.displayTo, isNull);
    expect(
      server.requestsTo('/api/banner').single.header('authorization'),
      'Bearer access-1',
    );
  });

  test('signed out, nothing is fetched', () async {
    await start(signedIn: false);
    server.on('GET', '/api/banner', respondJson({'bannerId': 'b1'}));

    expect(await container.read(bannerProvider.future), isNull);
    expect(server.requests, isEmpty);
  });
}
