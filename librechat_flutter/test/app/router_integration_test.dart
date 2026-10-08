import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/app/shell/app_shell.dart';
import 'package:librechat_flutter/app/shell/banners.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/features/chat/chat_screen.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/theme/app_theme.dart';
import 'package:librechat_flutter/features/conversations/archived_screen.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

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
        missingFeaturesProvider.overrideWithValue(
          ValueNotifier<Set<Feature>>(const {}),
        ),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        bannerProvider.overrideWith((ref) async => null),
        conversationsRepositoryProvider.overrideWithValue(
          FakeConversationsRepository(),
        ),
        conversationsApiProvider.overrideWithValue(FakeConversationsApi()),
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

  testWidgets('a session opens /chat in the AppShell', (tester) async {
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    expect(location(router).path, Routes.newChat);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('/conversations/archived renders inside the AppShell with its '
      'drawer entry selected', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 800);
    addTearDown(tester.view.reset);
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    await tester.tap(find.text('Archived Conversations'));
    await tester.pumpAndSettle();

    expect(location(router).path, Routes.archivedConversations);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ArchivedScreen), findsOneWidget);
    expect(find.text('No archived conversations'), findsOneWidget);
    final entry = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Archived Conversations'),
    );
    expect(entry.selected, isTrue);
  });

  testWidgets('/chat/c/<id> lands on /chat until Task 11.4 (stand-in)', (
    tester,
  ) async {
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    router.go(Routes.chat('x'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.newChat);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('Terms I Accept opens /chat', (tester) async {
    auth.emit(serverUrl: server, session: session);
    final router = await pump(tester);
    router.go(Routes.terms);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'I Accept'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.newChat);
    expect(auth.authApi.termsAccepts, 1);
    expect(find.byType(ChatScreen), findsOneWidget);
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
