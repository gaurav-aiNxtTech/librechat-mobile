import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/data/messages_api.dart';
import 'package:librechat_flutter/features/conversations/archived_screen.dart';
import 'package:librechat_flutter/features/conversations/conversation_list_screen.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../support/fakes.dart';

/// The fakes behind a pumped Conversation_List or Archived_Screen.
class ListHarness {
  ListHarness({FakeConversationsRepository? repository})
    : repository = repository ?? FakeConversationsRepository();

  final FakeConversationsRepository repository;
  final platform = FakePlatformActions();
  final messages = FakeMessagesApi();
  final auth = FakeAuthService()
    ..emit(
      serverUrl: 'https://chat.example.com/',
      session: const Session(
        accessToken: 'a',
        refreshToken: 'r',
        user: User(id: 'u1'),
      ),
    );
  late GoRouter router;

  FakeConversationsApi get api => repository.fakeApi;

  String get path => router.routerDelegate.currentConfiguration.uri.path;

  /// Pumps the list in a test shell whose routes include
  /// `/chat/c/:conversationId` and `/conversations/archived`, so taps land
  /// on real locations. With [archived] the Archived_Screen opens instead.
  Future<void> pump(
    WidgetTester tester, {
    StartupConfig config = const StartupConfig(),
    Set<Feature> missing = const {},
    String initialLocation = Routes.newChat,
    bool archived = false,
    bool settle = true,
  }) async {
    router = GoRouter(
      initialLocation: archived
          ? Routes.archivedConversations
          : initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => archived
              ? child
              : Scaffold(
                  body: Row(
                    children: [
                      Expanded(
                        child: ConversationListScreen(onOpen: context.go),
                      ),
                      // Its own container, as in the AppShell, so the
                      // Navigator's route does not hide the list's
                      // semantics.
                      SizedBox(
                        width: 1,
                        child: Semantics(container: true, child: child),
                      ),
                    ],
                  ),
                ),
          routes: [
            GoRoute(
              path: Routes.newChat,
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: '/chat/c/:conversationId',
              builder: (context, state) => const SizedBox(),
            ),
            GoRoute(
              path: Routes.archivedConversations,
              builder: (context, state) => const ArchivedScreen(),
            ),
          ],
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
          missingFeaturesProvider.overrideWithValue(
            ValueNotifier<Set<Feature>>(missing),
          ),
          conversationsRepositoryProvider.overrideWithValue(repository),
          platformActionsProvider.overrideWithValue(platform),
          messagesApiProvider.overrideWithValue(messages),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
}
