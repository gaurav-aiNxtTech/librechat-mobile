import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/app/router.dart';
import 'package:librechat_flutter/app/routes.dart';

void main() {
  String? redirect(
    String path, {
    bool hasServerUrl = true,
    bool signedIn = false,
    bool expired = false,
  }) => authRedirect(
    hasServerUrl: hasServerUrl,
    signedIn: signedIn,
    expired: expired,
    path: path,
  );

  group('authRedirect', () {
    test('without a Server_URL every path goes to /server-url', () {
      for (final path in [Routes.newChat, Routes.login, Routes.settings]) {
        expect(redirect(path, hasServerUrl: false), Routes.serverUrl);
        expect(
          redirect(path, hasServerUrl: false, signedIn: true),
          Routes.serverUrl,
        );
      }
      expect(redirect(Routes.serverUrl, hasServerUrl: false), isNull);
    });

    test('signed out keeps the auth routes and sends the rest to /login', () {
      for (final path in authRoutes) {
        expect(redirect(path), isNull, reason: path);
      }
      expect(redirect('${Routes.ssoLogin}/openid'), isNull);
      for (final path in [
        Routes.newChat,
        Routes.chat('c1'),
        Routes.settingsGeneral,
        Routes.terms,
        Routes.artifactFullscreen,
      ]) {
        expect(redirect(path), Routes.login, reason: path);
      }
    });

    test('an expired session stays on a shell route only', () {
      expect(redirect(Routes.chat('c1'), expired: true), isNull);
      expect(redirect(Routes.settingsGeneral, expired: true), isNull);
      expect(redirect(Routes.terms, expired: true), Routes.login);
      expect(redirect(Routes.artifactFullscreen, expired: true), Routes.login);
      expect(redirect(Routes.login, expired: true), isNull);
    });

    test('signed in, an auth route goes to /chat and the rest stays', () {
      for (final path in authRoutes) {
        expect(redirect(path, signedIn: true), Routes.newChat, reason: path);
      }
      for (final path in [Routes.chat('c1'), Routes.terms, Routes.settings]) {
        expect(redirect(path, signedIn: true), isNull, reason: path);
      }
    });
  });

  test('routerRedirect stands in for the undeclared routes', () {
    String? go(String path, {bool signedIn = false}) => routerRedirect(
      hasServerUrl: true,
      signedIn: signedIn,
      expired: false,
      path: path,
    );
    expect(go(Routes.newChat), Routes.login);
    expect(go(Routes.login), isNull);
    for (final path in [
      Routes.twoFactor,
      Routes.register,
      Routes.forgotPassword,
      Routes.resetPassword,
      Routes.verifyEmail,
    ]) {
      expect(go(path), isNull, reason: path);
      expect(go(path, signedIn: true), Routes.settingsGeneral, reason: path);
    }
    expect(go(Routes.ssoLogin), Routes.login);
    expect(go(Routes.ssoLogin, signedIn: true), Routes.settingsGeneral);
    expect(go(Routes.serverUrl), isNull);
    expect(go(Routes.newChat, signedIn: true), Routes.settingsGeneral);
    expect(go(Routes.serverUrl, signedIn: true), Routes.settingsGeneral);
    expect(go(Routes.settingsGeneral, signedIn: true), isNull);
  });
}
