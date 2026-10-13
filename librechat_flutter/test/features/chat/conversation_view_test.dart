// ChatScreen conversation view (Task 11.4): cache first, loading, errors,
// SiblingNavigator, pinned auto-scroll and scroll-to-bottom.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/chat_screen.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../support/fakes.dart';

Message m(
  String id, {
  String? parent,
  int minute = 0,
  String? text,
  bool user = false,
}) => Message(
  messageId: id,
  conversationId: 'c1',
  parentMessageId: parent ?? rootParentId,
  text: text ?? 'text of $id',
  isCreatedByUser: user,
  createdAt: DateTime.utc(2026, 3, 1, 0, minute),
);

Finder text(String s) => find.text(s, findRichText: true);

void main() {
  late FakeMessagesRepository messages;
  late FakeConversationsRepository conversations;
  late FakePlatformActions platform;
  late FakeChatApi chatApi;
  late AppSettings settings;

  setUp(() {
    messages = FakeMessagesRepository();
    conversations = FakeConversationsRepository();
    platform = FakePlatformActions();
    chatApi = FakeChatApi();
    settings = const AppSettings();
  });

  Future<void> open(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(messages),
          conversationsRepositoryProvider.overrideWithValue(conversations),
          platformActionsProvider.overrideWithValue(platform),
          settingsProvider.overrideWith(() => FakeSettingsStore(settings)),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(const ServerInfo(config: StartupConfig())),
          ),
          authServiceProvider.overrideWith((ref) => FakeAuthService()),
          chatApiProvider.overrideWithValue(chatApi),
          streamClientProvider.overrideWithValue(FakeStreamClient()),
          onlineProvider.overrideWith((ref) => Stream.value(true)),
          missingFeaturesProvider.overrideWithValue(ValueNotifier(const {})),
        ],
        child: const MaterialApp(home: ChatScreen(conversationId: 'c1')),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('checks the conversation\'s Run on open and when the App '
      'returns to the foreground', (tester) async {
    await open(tester);
    expect(chatApi.statusRequests, ['c1']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(chatApi.statusRequests, ['c1', 'c1']);
  });

  testWidgets('shows a loading indicator until the first fetch ends', (
    tester,
  ) async {
    final gate = Completer<void>();
    messages.fakeApi
      ..messages['c1'] = [m('u1', text: 'Hi')]
      ..gate = gate;
    await open(tester, settle: false);
    await tester.pump();
    expect(find.bySemanticsLabel('Loading messages'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Loading messages'), findsNothing);
    expect(text('Hi'), findsOneWidget);
  });

  testWidgets('shows the cached messages first, then the Server\'s', (
    tester,
  ) async {
    final gate = Completer<void>();
    messages.cached['c1'] = [m('u1', text: 'Cached')];
    messages.fakeApi
      ..messages['c1'] = [m('u1', text: 'From server')]
      ..gate = gate;
    await open(tester, settle: false);
    await tester.pump();
    await tester.pump();
    expect(text('Cached'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading messages'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(text('From server'), findsOneWidget);
    expect(text('Cached'), findsNothing);
  });

  testWidgets('a failed first load with no cache offers Retry', (tester) async {
    messages.fakeApi
      ..messages['c1'] = [m('u1', text: 'Back again')]
      ..error = AppException(FailureKind.network);
    await open(tester);
    expect(find.text('Could not load messages'), findsOneWidget);
    messages.fakeApi.error = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(text('Back again'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the cached messages under a banner', (
    tester,
  ) async {
    messages.cached['c1'] = [m('u1', text: 'Cached')];
    messages.fakeApi.error = AppException(FailureKind.network);
    await open(tester);
    expect(text('Cached'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('the app bar shows the cached conversation title', (
    tester,
  ) async {
    conversations.rows = [
      const Conversation(conversationId: 'c1', title: 'Trip plans'),
    ];
    await open(tester);
    expect(find.widgetWithText(AppBar, 'Trip plans'), findsOneWidget);
  });

  testWidgets('SiblingNavigator switches replies and resets lower levels', (
    tester,
  ) async {
    // u1 ─ a1 ─ u2
    //   └─ a2
    messages.fakeApi.messages['c1'] = [
      m('u1', user: true, text: 'Question'),
      m('a1', parent: 'u1', minute: 1, text: 'First answer'),
      m('u2', parent: 'a1', minute: 2, user: true, text: 'Follow-up'),
      m('a2', parent: 'u1', minute: 3, text: 'Second answer'),
    ];
    await open(tester);
    expect(text('Second answer'), findsOneWidget);
    expect(text('First answer'), findsNothing);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous response'));
    await tester.pumpAndSettle();
    expect(text('First answer'), findsOneWidget);
    expect(text('Follow-up'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left),
    );
    expect(previous.onPressed, isNull);
  });

  group('scrolling', () {
    final long = List.filled(40, 'word').join(' ');

    /// A chain of [count] messages, each a few lines long.
    List<Message> chain(int count) => [
      for (var i = 0; i < count; i++)
        m('m$i', parent: i == 0 ? null : 'm${i - 1}', minute: i, text: long),
    ];

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    Finder jumpButton() => find.byTooltip('Scroll to bottom');

    testWidgets('opens pinned to the newest message', (tester) async {
      messages.fakeApi.messages['c1'] = chain(30);
      await open(tester);
      expect(position(tester).extentAfter, 0);
      expect(jumpButton(), findsNothing);
    });

    testWidgets('a new message keeps the newest content in view', (
      tester,
    ) async {
      final rows = chain(30);
      messages.fakeApi.messages['c1'] = rows;
      await open(tester);
      messages.emit('c1', [
        ...rows,
        m('new', parent: 'm29', minute: 30, text: long),
      ]);
      await tester.pumpAndSettle();
      expect(position(tester).extentAfter, 0);
    });

    testWidgets('scrolling away shows the button and stops following', (
      tester,
    ) async {
      final rows = chain(30);
      messages.fakeApi.messages['c1'] = rows;
      await open(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(jumpButton(), findsOneWidget);
      final pixels = position(tester).pixels;

      messages.emit('c1', [
        ...rows,
        m('new', parent: 'm29', minute: 30, text: long),
      ]);
      await tester.pumpAndSettle();
      expect(position(tester).pixels, pixels);

      await tester.tap(jumpButton());
      await tester.pumpAndSettle();
      expect(position(tester).extentAfter, 0);
      expect(jumpButton(), findsNothing);
    });

    testWidgets('with auto-scroll off the list opens at the top', (
      tester,
    ) async {
      settings = const AppSettings(autoScroll: false);
      messages.fakeApi.messages['c1'] = chain(30);
      await open(tester);
      expect(position(tester).pixels, 0);
      expect(jumpButton(), findsOneWidget);
    });
  });
}
