import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/ui/otp_field.dart';
import 'package:librechat_flutter/features/auth/two_factor_screen.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('a rejected code stays here and shows the message', (
    tester,
  ) async {
    final auth = FakeAuthService()
      ..verifyError = AppException(
        FailureKind.server,
        status: 401,
        message: 'Invalid 2FA code.',
        signedIn: false,
      );
    final router = GoRouter(
      initialLocation: Routes.twoFactor,
      initialExtra: 'temp-1',
      routes: [
        GoRoute(path: Routes.login, builder: (_, _) => const Text('login')),
        GoRoute(
          path: Routes.twoFactor,
          builder: (_, state) =>
              TwoFactorScreen(tempToken: state.extra! as String),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((ref) => auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // A full code submits itself.
    await tester.enterText(find.byType(OtpField), '123456');
    await tester.pumpAndSettle();
    expect(auth.verifications, [('temp-1', '123456', false)]);
    expect(find.text('Invalid 2FA code.'), findsOneWidget);
    expect(find.byType(TwoFactorScreen), findsOneWidget);

    await tester.tap(find.text('Use backup code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Backup code'),
      'abcd-1234',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(auth.verifications.last, ('temp-1', 'abcd-1234', true));
    expect(find.text('Invalid 2FA code.'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      Routes.twoFactor,
    );
  });
}
