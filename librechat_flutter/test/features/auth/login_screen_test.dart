import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/features/auth/login_screen.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeSettingsStore settings;

  setUp(() {
    auth = FakeAuthService();
    // Acknowledged, so the social buttons open /sso directly.
    settings = FakeSettingsStore(
      const AppSettings(ssoWarningAcknowledged: true),
    );
  });

  /// The Login_Screen at `/login`, with stub destinations that show what
  /// they received.
  Future<GoRouter> pump(
    WidgetTester tester, {
    StartupConfig config = const StartupConfig(),
  }) async {
    final router = GoRouter(
      initialLocation: Routes.login,
      routes: [
        GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
        for (final path in [
          Routes.twoFactor,
          Routes.verifyEmail,
          Routes.ssoLogin,
        ])
          GoRoute(path: path, builder: (_, state) => Text('${state.extra}')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          settingsProvider.overrideWith(() => settings),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(ServerInfo(config: config)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Uri location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri;

  Future<void> signIn(WidgetTester tester, String identifier) async {
    await tester.enterText(find.widgetWithText(TextField, 'Email'), identifier);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'pw');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('SignedIn leaves navigation to the redirect', (tester) async {
    final router = await pump(tester);
    await signIn(tester, ' user@example.com ');
    expect(auth.logins, [('user@example.com', 'pw')]);
    expect(location(router).path, Routes.login);
  });

  testWidgets('NeedsTwoFactor opens /two-factor with the tempToken', (
    tester,
  ) async {
    auth.loginResult = const NeedsTwoFactor('temp-1');
    final router = await pump(tester);
    await signIn(tester, 'user@example.com');
    // Pushed over /login, so the top match carries the location.
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      Routes.twoFactor,
    );
    expect(find.text('temp-1'), findsOneWidget);
  });

  testWidgets('NeedsVerification opens /verify-email for the email', (
    tester,
  ) async {
    auth.loginResult = const NeedsVerification();
    final router = await pump(tester);
    await signIn(tester, 'a+b@example.com');
    expect(location(router).path, Routes.verifyEmail);
    expect(location(router).queryParameters, {'email': 'a+b@example.com'});
  });

  testWidgets('a failure shows the message and keeps the identifier', (
    tester,
  ) async {
    auth.loginError = AppException(
      FailureKind.server,
      status: 422,
      message: 'Incorrect password.',
      signedIn: false,
    );
    final router = await pump(tester);
    await signIn(tester, 'user@example.com');
    expect(location(router).path, Routes.login);
    expect(find.text('Incorrect password.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'user@example.com'), findsOneWidget);
  });

  testWidgets('LDAP username mode and an OpenID button', (tester) async {
    final router = await pump(
      tester,
      config: const StartupConfig(
        ldap: LdapConfig(enabled: true, username: true),
        socialLogins: ['openid', 'google'],
        openidLoginEnabled: true,
        openidLabel: 'Company SSO',
      ),
    );
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    // Google is listed but not enabled.
    expect(find.text('Continue with Google'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Company SSO'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.ssoLogin);
    expect(location(router).queryParameters, {'provider': 'openid'});
  });

  testWidgets('the first social sign-in warns once, then opens /sso', (
    tester,
  ) async {
    settings = FakeSettingsStore();
    final router = await pump(
      tester,
      config: const StartupConfig(
        socialLogins: ['github'],
        githubLoginEnabled: true,
      ),
    );
    final github = find.widgetWithText(OutlinedButton, 'Continue with GitHub');

    // Cancel stays on /login and keeps the warning for next time.
    await tester.tap(github);
    await tester.pumpAndSettle();
    expect(find.text('Sign in with an in-app browser?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.login);
    expect(settings.saved, isEmpty);

    await tester.tap(github);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.ssoLogin);
    expect(location(router).queryParameters, {'provider': 'github'});
    expect(settings.saved.single.ssoWarningAcknowledged, isTrue);

    // Acknowledged: the next start skips it.
    router.go(Routes.login);
    await tester.pumpAndSettle();
    await tester.tap(github);
    await tester.pumpAndSettle();
    expect(find.text('Sign in with an in-app browser?'), findsNothing);
    expect(location(router).path, Routes.ssoLogin);
  });
}
