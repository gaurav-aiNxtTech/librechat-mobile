import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/app/shell/banners.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/config/server_version.dart';
import 'package:librechat_flutter/core/models/banner.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/theme/app_theme.dart';

import '../../support/fakes.dart';

/// The AppShell's banners (Req 6.8–6.10, 14.4–14.6, 14.8), session-expired
/// dialog (Req 14.7) and terms check (Req 11.8), on the real
/// [routerProvider] with a signed-in [FakeAuthService].
void main() {
  const server = 'https://chat.example.com';
  const session = Session(
    accessToken: 'a',
    refreshToken: 'r',
    user: User(id: 'u1'),
  );
  const offlineText = 'No internet connection';
  const dismissBanner = 'Dismiss banner';
  const versionText =
      'This app was built for LibreChat v0.8.8-rc4, but your server is '
      'running v0.8.7. Some features may not work correctly.';
  const expiredText = 'Your session has expired. Sign in again to continue.';

  late FakeAuthService auth;
  late FakeSettingsStore settings;

  setUp(
    () => auth = FakeAuthService()..emit(serverUrl: server, session: session),
  );

  Future<GoRouter> pump(
    WidgetTester tester, {
    bool online = true,
    ServerBanner? banner,
    AppSettings initial = const AppSettings(),
    StartupConfig config = const StartupConfig(),
    AuthService Function(SecureStore secure)? authFor,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    final secure = SecureStore();
    await secure.load();
    settings = FakeSettingsStore(initial);
    final service = authFor?.call(secure) ?? auth;
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((ref) => service),
        secureStoreProvider.overrideWithValue(secure),
        settingsProvider.overrideWith(() => settings),
        wallpaperSchemesProvider.overrideWithValue(null),
        serverConfigProvider.overrideWith(
          () => FakeServerConfig(ServerInfo(config: config)),
        ),
        missingFeaturesProvider.overrideWithValue(
          ValueNotifier<Set<Feature>>(const {}),
        ),
        onlineProvider.overrideWith((ref) => Stream.value(online)),
        bannerProvider.overrideWith((ref) async => banner),
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

  /// The live-region node around the banner showing [text].
  bool isLiveRegion(WidgetTester tester, String text) {
    final region = find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
    );
    return tester
        .getSemantics(region.first)
        .getSemanticsData()
        .flagsCollection
        .isLiveRegion;
  }

  group('offline banner', () {
    testWidgets('shows while offline, with no close button', (tester) async {
      await pump(tester, online: false);
      expect(find.text(offlineText), findsOneWidget);
      expect(find.byTooltip(dismissBanner), findsNothing);
    });

    testWidgets('is hidden while online', (tester) async {
      await pump(tester);
      expect(find.text(offlineText), findsNothing);
    });
  });

  group('server banner', () {
    const banner = ServerBanner(bannerId: 'b1', message: 'Maintenance tonight');

    testWidgets('dismissing it stores the id and hides it', (tester) async {
      await pump(tester, banner: banner);
      expect(find.text('Maintenance tonight'), findsOneWidget);

      await tester.tap(find.byTooltip(dismissBanner));
      await tester.pumpAndSettle();
      expect(find.text('Maintenance tonight'), findsNothing);
      expect(settings.saved.last.dismissedBannerIds, ['b1']);
    });

    testWidgets('an already dismissed id stays hidden (Req 14.6)', (
      tester,
    ) async {
      await pump(
        tester,
        banner: banner,
        initial: const AppSettings(dismissedBannerIds: ['b1']),
      );
      expect(find.text('Maintenance tonight'), findsNothing);
    });

    testWidgets('a persistable banner has no close button and ignores a '
        'stored dismissal (Req 14.5)', (tester) async {
      await pump(
        tester,
        banner: banner.copyWith(persistable: true),
        initial: const AppSettings(dismissedBannerIds: ['b1']),
      );
      expect(find.text('Maintenance tonight'), findsOneWidget);
      expect(find.byTooltip(dismissBanner), findsNothing);
    });

    testWidgets('no id is hidden', (tester) async {
      await pump(tester, banner: const ServerBanner(message: 'No id'));
      expect(find.text('No id'), findsNothing);
    });

    testWidgets('a blank message is hidden', (tester) async {
      await pump(
        tester,
        banner: const ServerBanner(bannerId: 'b2', message: '  '),
      );
      expect(find.byTooltip(dismissBanner), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });

  testWidgets('banners are live regions, stacked offline, server, version', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      online: false,
      banner: const ServerBanner(bannerId: 'b1', message: 'Maintenance'),
      config: const StartupConfig(version: '0.8.7'),
    );

    for (final text in [offlineText, 'Maintenance', versionText]) {
      expect(isLiveRegion(tester, text), isTrue, reason: text);
    }
    final offlineY = tester.getTopLeft(find.text(offlineText)).dy;
    final serverY = tester.getTopLeft(find.text('Maintenance')).dy;
    final versionY = tester.getTopLeft(find.text(versionText)).dy;
    expect(offlineY, lessThan(serverY));
    expect(serverY, lessThan(versionY));
    handle.dispose();
  });

  group('the landing scrolls instead of overflowing below banners', () {
    for (final (name, size, offline, withBanners) in [
      ('three banners at 800x600', const Size(800, 600), true, true),
      ('the offline banner at 640x360', const Size(640, 360), true, false),
    ]) {
      testWidgets(name, (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size;
        addTearDown(tester.view.reset);
        await pump(
          tester,
          online: !offline,
          banner: withBanners
              ? const ServerBanner(bannerId: 'b1', message: 'Maintenance')
              : null,
          config: withBanners
              ? const StartupConfig(version: '0.8.7')
              : const StartupConfig(),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(offlineText), findsOneWidget);
        expect(find.text('How can I help you today?'), findsOneWidget);
      });
    }
  });

  group('version banner', () {
    testWidgets('names both versions for a server off the target release', (
      tester,
    ) async {
      await pump(tester, config: const StartupConfig(version: '0.8.7'));
      expect(find.text(versionText), findsOneWidget);
    });

    testWidgets('is hidden for an unknown version', (tester) async {
      await pump(tester);
      expect(find.textContaining('This app was built for'), findsNothing);
    });

    testWidgets('is hidden on the target release line', (tester) async {
      await pump(tester, config: const StartupConfig(version: '0.8.8'));
      expect(find.textContaining('This app was built for'), findsNothing);
    });

    testWidgets('Dismiss hides it without saving', (tester) async {
      await pump(tester, config: const StartupConfig(version: '0.8.7'));
      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(versionText), findsNothing);
      expect(settings.saved, isEmpty);
    });

    testWidgets("Don't show again stores the version", (tester) async {
      await pump(tester, config: const StartupConfig(version: '0.8.7'));
      await tester.tap(find.widgetWithText(TextButton, "Don't show again"));
      await tester.pumpAndSettle();
      expect(find.text(versionText), findsNothing);
      expect(settings.saved.last.dismissedVersionBanner, '0.8.7');
    });

    testWidgets('a stored dismissal hides that version', (tester) async {
      await pump(
        tester,
        config: const StartupConfig(version: '0.8.7'),
        initial: const AppSettings(dismissedVersionBanner: '0.8.7'),
      );
      expect(find.text(versionText), findsNothing);
    });

    testWidgets('a stored dismissal of another version does not hide it', (
      tester,
    ) async {
      await pump(
        tester,
        config: const StartupConfig(version: '0.8.7'),
        initial: const AppSettings(dismissedVersionBanner: '0.8.6'),
      );
      expect(find.text(versionText), findsOneWidget);
    });

    test('showVersionBanner', () {
      final v087 = Version.parse('0.8.7');
      expect(showVersionBanner(null), isFalse);
      expect(showVersionBanner(v087), isTrue);
      expect(showVersionBanner(Version.parse('0.8.8')), isFalse);
      expect(showVersionBanner(Version.parse('0.8.8-rc1')), isFalse);
      expect(showVersionBanner(Version.parse('0.8.9')), isTrue);
      expect(showVersionBanner(v087, stored: '0.8.7'), isFalse);
      expect(showVersionBanner(v087, stored: '0.8.6'), isTrue);
      expect(showVersionBanner(v087, dismissedThisLaunch: '0.8.7'), isFalse);
    });
  });

  test('shouldShowBanner', () {
    const b = ServerBanner(bannerId: 'b1', message: 'Hi');
    expect(shouldShowBanner(null, const []), isFalse);
    expect(shouldShowBanner(b, const []), isTrue);
    expect(shouldShowBanner(b, const ['b1']), isFalse);
    expect(
      shouldShowBanner(b.copyWith(persistable: true), const ['b1']),
      isTrue,
    );
    expect(shouldShowBanner(b.copyWith(bannerId: null), const []), isFalse);
    expect(shouldShowBanner(b.copyWith(message: ' '), const []), isFalse);
    expect(shouldShowBanner(b.copyWith(message: null), const []), isFalse);
  });

  group('session expiry (Req 14.7)', () {
    Future<GoRouter> expire(WidgetTester tester) async {
      final router = await pump(tester);
      expect(path(router), Routes.newChat);
      auth.emit(serverUrl: server, expired: true);
      await tester.pumpAndSettle();
      expect(path(router), Routes.newChat);
      expect(find.text('Signed out'), findsOneWidget);
      expect(find.text(expiredText), findsOneWidget);
      return router;
    }

    testWidgets('the dialog stays until Dismiss, which opens /login', (
      tester,
    ) async {
      final router = await expire(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text(expiredText), findsOneWidget);
      expect(auth.expiryAcknowledgements, 0);

      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text(expiredText), findsNothing);
      expect(auth.expiryAcknowledgements, 1);
      expect(path(router), Routes.login);
    });

    testWidgets('system Back acts like Dismiss', (tester) async {
      final router = await expire(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(expiredText), findsNothing);
      expect(auth.expiryAcknowledgements, 1);
      expect(path(router), Routes.login);
    });

    testWidgets('an expiry on /terms, then a new sign-in, leaves a later '
        'sign-out from /chat without the dialog', (tester) async {
      // A real AuthService, so the expiry flag follows its own rules.
      final api = auth.authApi..termsAcceptedReply = false;
      late AuthService real;
      final router = await pump(
        tester,
        config: const StartupConfig(
          interfaceConfig: InterfaceConfig(
            termsOfService: TermsOfServiceConfig(modalAcceptance: true),
          ),
        ),
        authFor: (secure) =>
            real = AuthService(secure: secure, cache: FakeCacheDb())..api = api,
      );
      expect(path(router), Routes.serverUrl);
      await real.saveServer(server, const {});
      await real.login('user@example.com', 'pw');
      await tester.pumpAndSettle();
      expect(path(router), Routes.terms);

      await expectLater(real.refresh(), throwsA(isA<AppException>()));
      await tester.pumpAndSettle();
      expect(real.expired, isTrue);
      expect(path(router), Routes.login);
      expect(find.text(expiredText), findsNothing);

      api.termsAcceptedReply = true;
      await real.login('user@example.com', 'pw');
      await tester.pumpAndSettle();
      expect(real.expired, isFalse);
      expect(path(router), Routes.newChat);

      await real.signOut();
      await tester.pumpAndSettle();
      expect(api.logouts, 1);
      expect(path(router), Routes.login);
      expect(find.text(expiredText), findsNothing);
    });
  });

  group('terms check (Req 11.8)', () {
    const required = StartupConfig(
      interfaceConfig: InterfaceConfig(
        termsOfService: TermsOfServiceConfig(modalAcceptance: true),
      ),
    );

    testWidgets('unaccepted terms open /terms, and accepting returns to '
        '/chat for good', (tester) async {
      auth.authApi.termsAcceptedReply = false;
      final router = await pump(tester, config: required);
      expect(path(router), Routes.terms);
      expect(auth.authApi.termsChecks, 1);

      await tester.tap(find.widgetWithText(FilledButton, 'I Accept'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(path(router), Routes.newChat);
      expect(auth.authApi.termsAccepts, 1);
    });

    testWidgets('accepted terms stay on /chat', (tester) async {
      final router = await pump(tester, config: required);
      expect(path(router), Routes.newChat);
      expect(auth.authApi.termsChecks, 1);
    });

    testWidgets('without modalAcceptance nothing is checked', (tester) async {
      final router = await pump(tester);
      expect(path(router), Routes.newChat);
      expect(auth.authApi.termsChecks, 0);
    });
  });
}
