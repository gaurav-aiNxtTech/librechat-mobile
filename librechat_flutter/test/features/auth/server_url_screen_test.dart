import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';
import 'package:librechat_flutter/core/network/server_url.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/features/auth/server_url_controller.dart';
import 'package:librechat_flutter/features/auth/server_url_screen.dart';

import '../../support/fakes.dart';

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late FakeAuthService auth;
  late FakeConfigRepository repository;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('server_url_screen_test');
    log = await DiagnosticLog.open(directory: logDir);
    auth = FakeAuthService();
    repository = FakeConfigRepository();
  });

  tearDown(() => logDir.delete(recursive: true));

  /// The Server_URL_Screen at `/server-url`, with a stub `/login`.
  Future<GoRouter> pump(
    WidgetTester tester, {
    Map<String, String> stored = const {},
  }) async {
    // The mock storage writes into this map, so it must be modifiable.
    FlutterSecureStorage.setMockInitialValues({...stored});
    final secure = SecureStore();
    await secure.load();
    final router = GoRouter(
      initialLocation: Routes.serverUrl,
      routes: [
        GoRoute(
          path: Routes.serverUrl,
          builder: (_, _) => const ServerUrlScreen(),
        ),
        GoRoute(path: Routes.login, builder: (_, _) => const Text('login')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticLogProvider.overrideWithValue(log),
          secureStoreProvider.overrideWithValue(secure),
          authServiceProvider.overrideWith((ref) => auth),
          configRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String path(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  final urlField = find.widgetWithText(TextField, 'Server URL');

  Future<void> connect(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Connect');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('a bad URL shows the reason under the field, sends nothing', (
    tester,
  ) async {
    final router = await pump(tester);
    await tester.enterText(urlField, 'ftp://example.com');
    await connect(tester);

    final field = tester.widget<TextField>(urlField);
    expect(field.decoration?.errorText, UrlProblem.scheme.message);
    expect(find.text(UrlProblem.scheme.message), findsOneWidget);
    expect(field.controller?.text, 'ftp://example.com');
    expect(repository.probes, isEmpty);
    expect(path(router), Routes.serverUrl);
  });

  testWidgets('http:// asks first: Cancel sends nothing, "Connect anyway" '
      'probes', (tester) async {
    final router = await pump(tester);
    await tester.enterText(urlField, 'http://localhost:3080');
    await connect(tester);
    expect(find.text('Insecure connection'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Insecure connection'), findsNothing);
    expect(repository.probes, isEmpty);
    expect(path(router), Routes.serverUrl);

    await connect(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Connect anyway'));
    await tester.pumpAndSettle();
    expect(repository.probes.single.$1, 'http://localhost:3080');
    expect(auth.savedServers.single.$1, 'http://localhost:3080');
    expect(path(router), Routes.login);
  });

  testWidgets('a rejected header row shows its reason and blocks the probe', (
    tester,
  ) async {
    final router = await pump(tester);
    // Closed without stored headers (Req 5.1).
    expect(find.text('Custom request headers'), findsNothing);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Add header'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Header name'),
      'Authorization',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Value'), 'Bearer x');
    await tester.enterText(urlField, 'chat.example.com');
    await connect(tester);

    expect(find.text(HeaderProblem.reserved.message), findsOneWidget);
    expect(repository.probes, isEmpty);
    expect(auth.savedServers, isEmpty);
    expect(path(router), Routes.serverUrl);
  });

  testWidgets('a failed probe shows the message and keeps the typed URL', (
    tester,
  ) async {
    final error = AppException(FailureKind.gateway, signedIn: false);
    repository.probeError = error;
    final router = await pump(tester);
    await tester.enterText(urlField, 'chat.example.com');
    await connect(tester);

    expect(repository.probes.single.$1, 'https://chat.example.com');
    expect(find.text(userMessage(error)), findsOneWidget);
    expect(
      tester.widget<TextField>(urlField).controller?.text,
      'chat.example.com',
    );
    expect(auth.savedServers, isEmpty);
    expect(path(router), Routes.serverUrl);
  });

  testWidgets('Advanced opens expanded when headers are stored', (
    tester,
  ) async {
    auth.emit(serverUrl: 'https://chat.example.com');
    await pump(
      tester,
      stored: {
        SecureStore.customHeadersKey: jsonEncode({'CF-Access-Client-Id': 'id'}),
      },
    );
    expect(
      tester.widget<TextField>(urlField).controller?.text,
      'https://chat.example.com',
    );
    expect(find.text('Custom request headers'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'CF-Access-Client-Id'),
      findsOneWidget,
    );
  });
}
