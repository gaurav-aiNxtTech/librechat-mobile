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
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/theme/app_theme.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../support/fakes.dart';

/// The AppShell layouts around the 600 dp breakpoint (Req 14.1–14.3), on the
/// real [routerProvider] with a signed-in [FakeAuthService].
void main() {
  const server = 'https://chat.example.com';
  const session = Session(
    accessToken: 'a',
    refreshToken: 'r',
    user: User(id: 'u1'),
  );
  const menuTooltip = 'Open navigation drawer';

  late FakeAuthService auth;

  setUp(
    () => auth = FakeAuthService()..emit(serverUrl: server, session: session),
  );

  void setWidth(WidgetTester tester, double width) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
  }

  Future<GoRouter> pump(WidgetTester tester, {required double width}) async {
    setWidth(tester, width);
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
        // The landing's Composer reads its draft.
        messagesRepositoryProvider.overrideWithValue(FakeMessagesRepository()),
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

  String path(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  bool settingsSelected(WidgetTester tester) => tester
      .widget<ListTile>(find.widgetWithText(ListTile, 'Settings'))
      .selected;

  group('below 600 dp', () {
    testWidgets('the menu button opens a modal drawer', (tester) async {
      final router = await pump(tester, width: 599);
      expect(path(router), Routes.newChat);
      expect(find.byKey(AppShell.sidebarKey), findsNothing);
      expect(find.byType(Drawer), findsNothing);

      await tester.tap(find.byTooltip(menuTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(settingsSelected(tester), isFalse);
    });

    testWidgets('a drawer tap closes the drawer and navigates', (tester) async {
      final router = await pump(tester, width: 599);
      await tester.tap(find.byTooltip(menuTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(path(router), Routes.settingsGeneral);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('General'), findsOneWidget);
      expect(find.byTooltip(menuTooltip), findsOneWidget);

      await tester.tap(find.byTooltip(menuTooltip));
      await tester.pumpAndSettle();
      expect(settingsSelected(tester), isTrue);
      await tester.tap(find.text('New Chat'));
      await tester.pumpAndSettle();
      expect(path(router), Routes.newChat);
      expect(find.byType(Drawer), findsNothing);
    });
  });

  group('from 600 dp', () {
    testWidgets('a 320 dp sidebar shows and the menu button is gone', (
      tester,
    ) async {
      final router = await pump(tester, width: 600);
      final sidebar = find.byKey(AppShell.sidebarKey);
      expect(sidebar, findsOneWidget);
      expect(tester.getSize(sidebar).width, 320);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.byTooltip(menuTooltip), findsNothing);
      expect(settingsSelected(tester), isFalse);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(path(router), Routes.settingsGeneral);
      expect(find.text('General'), findsOneWidget);
      expect(find.byTooltip(menuTooltip), findsNothing);
      expect(settingsSelected(tester), isTrue);
    });

    testWidgets('the sidebar is in the semantics tree beside the screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, width: 600);
      // The screen's Navigator would otherwise block the sidebar's semantics.
      expect(find.bySemanticsLabel('New Chat'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(
        find.bySemanticsLabel('How can I help you today?'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('resizing to 599 dp keeps the location', (tester) async {
      final router = await pump(tester, width: 600);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      setWidth(tester, 599);
      await tester.pumpAndSettle();
      expect(path(router), Routes.settingsGeneral);
      expect(find.byKey(AppShell.sidebarKey), findsNothing);
      expect(find.text('General'), findsOneWidget);
      expect(find.byTooltip(menuTooltip), findsOneWidget);
    });
  });

  for (final width in [599.0, 600.0]) {
    testWidgets('tap targets meet the guidelines at ${width.toInt()} dp', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, width: width);
      if (width < 600) {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await tester.tap(find.byTooltip(menuTooltip));
        await tester.pumpAndSettle();
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
