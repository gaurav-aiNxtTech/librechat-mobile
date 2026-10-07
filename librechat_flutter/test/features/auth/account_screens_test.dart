import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/features/auth/forgot_password_screen.dart';
import 'package:librechat_flutter/features/auth/register_screen.dart';
import 'package:librechat_flutter/features/auth/reset_password_screen.dart';
import 'package:librechat_flutter/features/auth/verify_email_screen.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  /// The account screens at [initial], with a stub `/login`.
  Future<GoRouter> pump(
    WidgetTester tester,
    String initial, {
    StartupConfig config = const StartupConfig(),
    Duration cooldown = const Duration(seconds: 60),
  }) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        // A Scaffold, so a SnackBar shown on the way here appears.
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
        GoRoute(
          path: Routes.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: Routes.resetPassword,
          builder: (_, state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          ),
        ),
        GoRoute(
          path: Routes.verifyEmail,
          builder: (_, state) => VerifyEmailScreen(
            email: state.uri.queryParameters['email'] ?? '',
            cooldown: cooldown,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
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

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('resetParamsFromLink', () {
    test('reads token and userId from a full link', () {
      expect(
        resetParamsFromLink(
          'https://chat.example.com/reset-password?token=t1&userId=u1',
        ),
        (token: 't1', userId: 'u1'),
      );
    });

    test('reads a link under a subpath and decodes the values', () {
      expect(
        resetParamsFromLink(
          'http://host:3080/librechat/reset-password?userId=u%2B1&token=a%20b',
        ),
        (token: 'a b', userId: 'u+1'),
      );
    });

    test('is null when either parameter is missing or empty', () {
      for (final link in [
        'https://h/reset-password?token=t1',
        'https://h/reset-password?userId=u1',
        'https://h/reset-password?token=&userId=u1',
        'https://h/reset-password',
        '',
      ]) {
        expect(resetParamsFromLink(link), isNull, reason: link);
      }
    });
  });

  group('Register_Screen', () {
    Future<void> fill(
      WidgetTester tester, {
      required String password,
      required String confirm,
    }) async {
      await tester.enterText(field('Full name'), ' Ada ');
      await tester.enterText(field('Username'), 'ada');
      await tester.enterText(field('Email'), 'ada@example.com');
      await tester.enterText(field('Password'), password);
      await tester.enterText(field('Confirm password'), confirm);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pumpAndSettle();
    }

    testWidgets('a short password or a mismatch sends nothing', (tester) async {
      await pump(
        tester,
        Routes.register,
        config: const StartupConfig(minPasswordLength: 10),
      );
      await fill(tester, password: 'short', confirm: 'other');
      expect(
        find.text('Password must be at least 10 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);

      await fill(tester, password: '0123456789', confirm: '012345678x');
      expect(
        find.text('Password must be at least 10 characters'),
        findsNothing,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.authApi.registrations, isEmpty);
    });

    testWidgets('without minPasswordLength the minimum is 8', (tester) async {
      await pump(tester, Routes.register);
      await fill(tester, password: '1234567', confirm: '1234567');
      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(auth.authApi.registrations, isEmpty);
    });

    testWidgets('success sends once, shows the message and opens /login', (
      tester,
    ) async {
      final router = await pump(tester, Routes.register);
      await fill(tester, password: 'password1', confirm: 'password1');
      expect(auth.authApi.registrations, [
        {
          'name': 'Ada',
          'username': 'ada',
          'email': 'ada@example.com',
          'password': 'password1',
          'confirmPassword': 'password1',
        },
      ]);
      expect(location(router).path, Routes.login);
      expect(find.text('Registered.'), findsOneWidget);
    });

    testWidgets('failure shows the message and keeps the input', (
      tester,
    ) async {
      auth.authApi.error = AppException(
        FailureKind.server,
        status: 400,
        message: 'Email is already in use.',
        signedIn: false,
      );
      final router = await pump(tester, Routes.register);
      await fill(tester, password: 'password1', confirm: 'password1');
      expect(location(router).path, Routes.register);
      expect(find.text('Email is already in use.'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'ada@example.com'), findsOneWidget);
    });
  });

  testWidgets('Forgot_Password opens the reset screen for a link', (
    tester,
  ) async {
    auth.authApi.resetRequestReply = (
      message: null,
      link: 'https://h/sub/reset-password?token=tok&userId=uid',
    );
    final router = await pump(tester, Routes.forgotPassword);
    await tester.enterText(field('Email'), ' ada@example.com ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(auth.authApi.resetRequests, ['ada@example.com']);
    expect(location(router).path, Routes.resetPassword);
    expect(location(router).queryParameters, {'token': 'tok', 'userId': 'uid'});
    expect(find.text('Set new password'), findsOneWidget);
  });

  testWidgets('Forgot_Password shows the confirmation without a link', (
    tester,
  ) async {
    await pump(tester, Routes.forgotPassword);
    await tester.enterText(field('Email'), 'ada@example.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Check your inbox.'), findsOneWidget);
  });

  testWidgets('Reset_Password without token offers Forgot password', (
    tester,
  ) async {
    final router = await pump(tester, '${Routes.resetPassword}?userId=u1');
    expect(
      find.text('Invalid reset link. Please request a new one.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(location(router).path, Routes.forgotPassword);
  });

  testWidgets('Reset_Password sends the reset and opens /login', (
    tester,
  ) async {
    final router = await pump(
      tester,
      '${Routes.resetPassword}?token=tok&userId=uid',
    );
    await tester.enterText(field('New password'), 'password1');
    await tester.enterText(field('Confirm new password'), 'password1');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();
    expect(auth.authApi.resets, [
      {
        'userId': 'uid',
        'token': 'tok',
        'password': 'password1',
        'confirmPassword': 'password1',
      },
    ]);
    expect(location(router).path, Routes.login);
    expect(find.text('Password reset.'), findsOneWidget);
  });

  testWidgets('Verify_Email disables resend for the countdown', (tester) async {
    await pump(
      tester,
      '${Routes.verifyEmail}?email=ada%40example.com',
      cooldown: const Duration(seconds: 3),
    );
    expect(find.text('ada@example.com'), findsOneWidget);
    OutlinedButton button() =>
        tester.widget<OutlinedButton>(find.byType(OutlinedButton));

    await tester.tap(find.text('Resend verification email'));
    await tester.pump();
    expect(auth.authApi.resends, ['ada@example.com']);
    expect(find.text('Sent again.'), findsOneWidget);
    expect(find.text('Resend in 3s'), findsOneWidget);
    expect(button().onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend in 2s'), findsOneWidget);
    expect(button().onPressed, isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Resend verification email'), findsOneWidget);
    expect(button().onPressed, isNotNull);
  });
}
