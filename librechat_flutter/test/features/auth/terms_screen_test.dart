import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/features/auth/terms_screen.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Future<GoRouter> pump(WidgetTester tester, {Object? content}) async {
    final router = GoRouter(
      initialLocation: Routes.terms,
      routes: [
        GoRoute(path: Routes.terms, builder: (_, _) => const TermsScreen()),
        GoRoute(path: Routes.newChat, builder: (_, _) => const Text('chat')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(
              ServerInfo(
                config: StartupConfig(
                  interfaceConfig: InterfaceConfig(
                    termsOfService: TermsOfServiceConfig(
                      modalTitle: 'Our terms',
                      modalContent: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows the terms and Accept records it, then opens /chat', (
    tester,
  ) async {
    final router = await pump(tester, content: ['Line one', 'Line two']);
    expect(find.text('Our terms'), findsOneWidget);
    expect(find.text('Line one\nLine two'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'I Accept'));
    await tester.pumpAndSettle();
    expect(auth.authApi.termsAccepts, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.newChat);
    expect(auth.signOuts, 0);
  });

  testWidgets('Decline signs out', (tester) async {
    await pump(tester, content: 'Be nice.');
    await tester.tap(find.widgetWithText(TextButton, 'Decline'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(auth.authApi.termsAccepts, 0);
  });
}
