import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/theme/app_theme.dart';

import '../support/fakes.dart';

/// The real [routerProvider], driven by a [FakeAuthService].
void main() {
  const server = 'https://chat.example.com';
  const session = Session(
    accessToken: 'a',
    refreshToken: 'r',
    user: User(id: 'u1'),
  );

  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<GoRouter> pump(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final secure = SecureStore();
    await secure.load();
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        secureStoreProvider.overrideWithValue(secure),
        settingsProvider.overrideWith(FakeSettingsStore.new),
        wallpaperSchemesProvider.overrideWithValue(null),
        serverConfigProvider.overrideWith(
          () => FakeServerConfig(const ServerInfo(config: StartupConfig())),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Uri location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri;

  testWidgets('no Server_URL opens /server-url', (tester) async {
    final router = await pump(tester);
    expect(location(router).path, Routes.serverUrl);
    expect(find.text('Connect to LibreChat'), findsOneWidget);
  });

  testWidgets('a Server_URL without a session opens /login', (tester) async {
    auth.emit(serverUrl: server);
    final router = await pump(tester);
    expect(location(router).path, Routes.login);
  });

  testWidgets('a session opens the signed-in stand-in', (tester) async {
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    // `/chat` until Task 7.4 declares it.
    expect(location(router).path, Routes.settingsGeneral);
    expect(find.text('General'), findsOneWidget);
  });

  testWidgets('signing out moves to /login', (tester) async {
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    auth.emit(serverUrl: server);
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.login);
  });

  testWidgets('NeedsVerification on /login opens /verify-email', (
    tester,
  ) async {
    auth
      ..emit(serverUrl: server)
      ..loginResult = const NeedsVerification();
    final router = await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pw');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(location(router).path, Routes.verifyEmail);
    expect(location(router).queryParameters, {'email': 'user@example.com'});
    expect(find.text('Verify Email'), findsWidgets);
  });
}
