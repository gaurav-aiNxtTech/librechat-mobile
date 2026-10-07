import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/role_permissions.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

import '../../support/test_server.dart';

void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late CacheDb db;
  late ApiClient api;
  late AuthService auth;
  late ProviderContainer container;
  late ConfigRepository repository;

  /// Wires AuthService and ApiClient the way `main()` does, with [server] as
  /// the stored Server_URL unless [serverUrl] is given.
  Future<void> start({required bool signedIn, String? serverUrl}) async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: serverUrl ?? server.uri.toString(),
      SecureStore.customHeadersKey: jsonEncode({'X-Stored': 's'}),
      if (signedIn)
        SecureStore.sessionKey: jsonEncode({
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'user': {'_id': 'u1', 'role': 'USER'},
        }),
    });
    final secure = SecureStore();
    await secure.load();
    auth = AuthService(secure: secure, cache: db);
    api = ApiClient(secure: secure, auth: auth, log: log);
    auth.api = AuthApi(api);
    await auth.load();
    repository = ConfigRepository(api, db);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        apiClientProvider.overrideWithValue(api),
        cacheDbProvider.overrideWithValue(db),
      ],
    );
  }

  Future<Set<String>> cachedKeys() async => {
    for (final row in await db.select(db.cacheEntries).get()) row.key,
  };

  void serveAll() => server
    ..on('GET', '/api/config', respondJson({'appTitle': 'Fresh'}))
    ..on(
      'GET',
      '/api/endpoints',
      respondJson({
        'openAI': {'type': 'openAI', 'order': 0},
      }),
    )
    ..on(
      'GET',
      '/api/models',
      respondJson({
        'openAI': ['gpt-4o'],
      }),
    )
    ..on(
      'GET',
      '/api/roles/USER',
      respondJson({
        'name': 'USER',
        'permissions': {
          'AGENTS': {'USE': true},
        },
      }),
    );

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('server_config_test');
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

  test('probe sends the typed URL and headers, no bearer, and caches '
      'nothing', () async {
    await start(signedIn: true, serverUrl: 'https://stored.invalid');
    server.on('GET', '/api/config', respondJson({'appTitle': 'Probed'}));

    final config = await repository.probe(server.uri.toString(), {
      'X-Typed': 't',
    });

    expect(config.appTitle, 'Probed');
    final request = server.requestsTo('/api/config').single;
    expect(request.header('x-typed'), 't');
    expect(request.header('x-stored'), isNull);
    expect(request.header('authorization'), isNull);
    expect(await cachedKeys(), isEmpty);
  });

  test('signed out, only /api/config is fetched', () async {
    await start(signedIn: false);
    serveAll();

    final info = await container.read(serverConfigProvider.future);

    expect(info.config.appTitle, 'Fresh');
    expect(info.endpoints, isEmpty);
    expect(info.role, isNull);
    expect(info.refreshError, isNull);
    expect(server.requests.map((r) => r.path), ['/api/config']);
    expect(await cachedKeys(), {'config'});
  });

  test('signed in, all four are fetched and cached', () async {
    await start(signedIn: true);
    serveAll();

    final info = await container.read(serverConfigProvider.future);

    expect(info.config.appTitle, 'Fresh');
    expect(info.endpoints['openAI']?.type, 'openAI');
    expect(info.models, {
      'openAI': ['gpt-4o'],
    });
    expect(info.role?.permissions?['AGENTS']?['USE'], isTrue);
    expect(info.refreshError, isNull);
    expect(server.requests.map((r) => r.path).toSet(), {
      '/api/config',
      '/api/endpoints',
      '/api/models',
      '/api/roles/USER',
    });
    expect(server.requests.map((r) => r.header('authorization')).toSet(), {
      'Bearer access-1',
    });
    expect(await cachedKeys(), {'config', 'endpoints', 'models', 'role'});
    final cached = await repository.readCache(signedIn: true);
    expect(cached?.config.appTitle, 'Fresh');
    expect(cached?.models['openAI'], ['gpt-4o']);
    expect(cached?.role?.name, 'USER');
  });

  test('a failed fetch keeps the cached data and sets refreshError', () async {
    await start(signedIn: false);
    await repository.save(config: const StartupConfig(appTitle: 'Cached'));
    server.on('GET', '/api/config', respond(status: 500));

    final seen = <ServerInfo>[];
    final settled = Completer<void>();
    container.listen(serverConfigProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        seen.add(value);
        if (seen.length == 2) settled.complete();
      }
    });
    await settled.future;

    // The cache shows at once, then the failed fetch keeps it.
    expect(seen.first.config.appTitle, 'Cached');
    expect(seen.first.refreshError, isNull);
    expect(seen.last.config.appTitle, 'Cached');
    expect(seen.last.refreshError?.kind, FailureKind.server);
    expect(seen.last.refreshError?.status, 500);
    expect(
      (await repository.readCache(signedIn: false))?.config.appTitle,
      'Cached',
    );
  });

  test('a failed fetch with no cache is an error', () async {
    await start(signedIn: false);
    server.on('GET', '/api/config', respond(status: 503));

    await expectLater(
      container.read(serverConfigProvider.future),
      throwsA(isA<AppException>().having((e) => e.status, 'status', 503)),
    );
    expect(container.read(serverConfigProvider).hasError, isTrue);
  });

  /// The first data state that satisfies [test], from now on.
  Future<ServerInfo> dataWhere(bool Function(ServerInfo info) test) {
    final found = Completer<ServerInfo>();
    container.listen(serverConfigProvider, (_, next) {
      if (next case AsyncData(
        :final value,
      ) when test(value) && !found.isCompleted) {
        found.complete(value);
      }
    }, fireImmediately: true);
    return found.future.timeout(const Duration(seconds: 5));
  }

  test('sign-in rebuilds the provider, which then fetches all four '
      '(Req 6.1)', () async {
    await start(signedIn: false);
    serveAll();
    server.on(
      'POST',
      '/api/auth/login',
      respondJson(
        {
          'token': 'access-9',
          'user': {'_id': 'u1', 'role': 'USER'},
        },
        headers: {'set-cookie': 'refreshToken=refresh-9; Path=/'},
      ),
    );

    final signedOut = await container.read(serverConfigProvider.future);
    expect(signedOut.endpoints, isEmpty);
    expect(server.requests.map((r) => r.path), ['/api/config']);

    await auth.login('user@example.com', 'pw');
    final signedIn = await dataWhere((info) => info.models.isNotEmpty);

    expect(signedIn.endpoints['openAI']?.type, 'openAI');
    expect(signedIn.models['openAI'], ['gpt-4o']);
    expect(signedIn.role?.name, 'USER');
    expect(signedIn.refreshError, isNull);
    final afterLogin = server.requests
        .skipWhile((r) => r.path != '/api/auth/login')
        .skip(1);
    expect(afterLogin.map((r) => r.path).toSet(), {
      '/api/config',
      '/api/endpoints',
      '/api/models',
      '/api/roles/USER',
    });
    expect(afterLogin.map((r) => r.header('authorization')).toSet(), {
      'Bearer access-9',
    });
    expect(await cachedKeys(), {'config', 'endpoints', 'models', 'role'});
  });

  test('a fetch where only /api/models fails keeps the cached models, takes '
      'the fresh rest and sets refreshError (Req 6.2, 45.3)', () async {
    await start(signedIn: true);
    await repository.save(
      config: const StartupConfig(appTitle: 'Cached'),
      endpoints: {
        'cachedEndpoint': EndpointConfig.fromJson({'order': 9}),
      },
      models: {
        'openAI': ['cached-model'],
      },
      role: RolePermissions.fromJson({
        'name': 'USER',
        'permissions': {
          'AGENTS': {'USE': false},
        },
      }),
    );
    serveAll();
    server.on('GET', '/api/models', respond(status: 500));

    final first = await container.read(serverConfigProvider.future);
    expect(first.config.appTitle, 'Cached');
    final info = await dataWhere((info) => info.config.appTitle == 'Fresh');

    expect(info.endpoints.keys, ['openAI']);
    expect(info.models, {
      'openAI': ['cached-model'],
    });
    expect(info.role?.permissions?['AGENTS']?['USE'], isTrue);
    expect(info.refreshError?.kind, FailureKind.server);
    expect(info.refreshError?.status, 500);

    final cached = await repository.readCache(signedIn: true);
    expect(cached?.config.appTitle, 'Fresh');
    expect(cached?.endpoints.keys, ['openAI']);
    expect(cached?.models['openAI'], ['cached-model']);
    expect(cached?.role?.permissions?['AGENTS']?['USE'], isTrue);
  });

  test('refresh() keeps the data on screen while it fetches and when it '
      'fails', () async {
    await start(signedIn: false);
    server.on('GET', '/api/config', respondJson({'appTitle': 'First'}));
    await container.read(serverConfigProvider.future);
    final states = <AsyncValue<ServerInfo>>[];
    container.listen(serverConfigProvider, (_, next) => states.add(next));

    server.on(
      'GET',
      '/api/config',
      respondJson({
        'appTitle': 'Second',
      }, delay: const Duration(milliseconds: 100)),
    );
    final notifier = container.read(serverConfigProvider.notifier);
    final pending = notifier.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final during = container.read(serverConfigProvider);
    expect(during.isLoading, isFalse);
    expect(during.value?.config.appTitle, 'First');
    await pending;
    expect(
      container.read(serverConfigProvider).value?.config.appTitle,
      'Second',
    );

    server.on('GET', '/api/config', respond(status: 502));
    await notifier.refresh();
    final failed = container.read(serverConfigProvider);
    expect(failed.hasError, isFalse);
    expect(failed.value?.config.appTitle, 'Second');
    expect(failed.value?.refreshError?.status, 502);

    expect(states.every((s) => s is AsyncData<ServerInfo>), isTrue);
  });
}
