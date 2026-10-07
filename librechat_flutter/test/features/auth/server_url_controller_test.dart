import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';
import 'package:librechat_flutter/core/network/server_url.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/features/auth/server_url_controller.dart';

import '../../support/fakes.dart';

void main() {
  late Directory logDir;
  late CacheDb db;
  late SecureStore secure;
  late AuthService auth;
  late FakeConfigRepository repository;
  late ProviderContainer container;

  Future<void> start({Map<String, String> stored = const {}}) async {
    // The mock storage writes into this map, so it must be modifiable.
    FlutterSecureStorage.setMockInitialValues({...stored});
    secure = SecureStore();
    await secure.load();
    auth = AuthService(secure: secure, cache: db);
    await auth.load();
    repository = FakeConfigRepository();
    final log = await DiagnosticLog.open(directory: logDir);
    container = ProviderContainer(
      overrides: [
        diagnosticLogProvider.overrideWithValue(log),
        secureStoreProvider.overrideWithValue(secure),
        authServiceProvider.overrideWith((ref) => auth),
        configRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the autoDispose controller alive for the whole test.
    container.listen(serverUrlControllerProvider, (_, _) {});
  }

  ServerUrlController controller() =>
      container.read(serverUrlControllerProvider.notifier);
  ServerUrlState state() => container.read(serverUrlControllerProvider);

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('server_url_test');
    db = CacheDb(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await logDir.delete(recursive: true);
  });

  test('prefills the stored Server_URL and headers, Advanced open', () async {
    await start(
      stored: {
        SecureStore.serverUrlKey: 'https://chat.example.com',
        SecureStore.customHeadersKey: jsonEncode({'CF-Access-Client-Id': 'id'}),
      },
    );
    expect(state().url, 'https://chat.example.com');
    expect(state().rows, [('CF-Access-Client-Id', 'id')]);
    expect(state().advancedOpen, isTrue);
  });

  test(
    'a URL rejection shows the reason, keeps the input, sends nothing',
    () async {
      await start();
      expect(state().advancedOpen, isFalse);
      controller().setUrl('ftp://example.com');
      await controller().submit();
      expect(state().urlProblem, UrlProblem.scheme);
      expect(state().url, 'ftp://example.com');
      expect(repository.probes, isEmpty);
    },
  );

  test('rejected header rows block the probe and open Advanced', () async {
    await start();
    controller()
      ..setUrl('chat.example.com')
      ..setRows([('Authorization', 'Bearer x'), ('', ''), ('X-Ok', 'ok')]);
    await controller().submit();
    expect(state().rowProblems, {0: HeaderProblem.reserved});
    expect(state().advancedOpen, isTrue);
    expect(state().rows, hasLength(3));
    expect(repository.probes, isEmpty);
  });

  test('http:// waits for "Connect anyway"', () async {
    await start();
    controller().setUrl('http://LOCALHOST:3080/');
    await controller().submit();
    expect(state().insecureUrl, 'http://localhost:3080');
    expect(repository.probes, isEmpty);

    controller().cancelInsecure();
    expect(state().insecureUrl, isNull);
    expect(repository.probes, isEmpty);

    await controller().submit();
    await controller().confirmInsecure();
    expect(state().insecureUrl, isNull);
    expect(repository.probes.single.$1, 'http://localhost:3080');
    expect(state().failure, isNull);
    expect(auth.serverUrl, 'http://localhost:3080');
  });

  test(
    'success saves the server, caches the config, blocks a double submit',
    () async {
      await start();
      controller()
        ..setUrl('  Chat.Example.com:443/lc/ ')
        ..setRows([(' X-Gate ', ' secret '), ('', '')]);
      repository.probeGate = Completer();
      final first = controller().submit();
      expect(state().probing, isTrue);
      await controller().submit();
      repository.probeGate!.complete();
      await first;

      final (url, headers) = repository.probes.single;
      expect(url, 'https://chat.example.com/lc');
      expect(headers, {'X-Gate': 'secret'});
      expect(auth.serverUrl, 'https://chat.example.com/lc');
      expect(secure.customHeaders, {'X-Gate': 'secret'});
      expect(repository.savedConfigs.single.appTitle, 'Probed');
      expect(state().probing, isFalse);
      expect(state().connected, isTrue);
    },
  );

  test('failure shows the message and keeps the input', () async {
    await start();
    repository.probeError = AppException(FailureKind.gateway, signedIn: false);
    controller()
      ..setUrl('chat.example.com')
      ..setRows([('CF-Access-Client-Id', 'id')]);
    await controller().submit();

    expect(state().failure, userMessage(repository.probeError!));
    expect(state().failure, contains('under Advanced'));
    expect(state().url, 'chat.example.com');
    expect(state().rows, [('CF-Access-Client-Id', 'id')]);
    expect(state().probing, isFalse);
    expect(state().connected, isFalse);
    expect(auth.serverUrl, isNull);
    expect(repository.savedConfigs, isEmpty);
  });
}
