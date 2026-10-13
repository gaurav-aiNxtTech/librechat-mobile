// Message actions on the Chat_Screen (Task 21.3): the feedback, fork and
// edit request shapes, and the controls a Run disables rather than hides
// (Req 25.3, 25.6, 25.7, 25.9, 25.11, 25.14).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/chat_screen.dart';
import 'package:librechat_flutter/features/chat/composer/composer_bar.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/messages_api.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/render/find_matches.dart';
import 'package:librechat_flutter/features/chat/render/message_actions.dart';
import 'package:librechat_flutter/features/chat/run/run_service.dart';
import 'package:librechat_flutter/features/chat/sibling_navigator.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../../support/fakes.dart';

Message _m(
  String id, {
  String? parent,
  int minute = 0,
  String text = '',
  bool user = false,
  List<ContentPart>? content,
  MessageFeedback? feedback,
}) => Message(
  messageId: id,
  conversationId: 'c1',
  parentMessageId: parent,
  text: text,
  isCreatedByUser: user,
  content: content,
  feedback: feedback,
  createdAt: DateTime.utc(2026, 3, 1, 0, minute),
);

/// u1 ─ a1 ─ u2, where the reply carries its answer in a content part, so
/// an edit addresses that part by index (Req 25.3).
List<Message> _thread({MessageFeedback? feedback}) => [
  _m('u1', user: true, text: 'Plan a trip'),
  _m(
    'a1',
    parent: 'u1',
    minute: 1,
    feedback: feedback,
    content: const [
      ContentPart(type: ContentPartType.think, think: 'Checking flights'),
      ContentPart(type: ContentPartType.text, text: 'First answer'),
    ],
  ),
  _m('u2', parent: 'a1', minute: 2, user: true, text: 'Follow-up'),
];

/// u1 with two replies, so the newest shows under a SiblingNavigator.
List<Message> _branched() => [
  _m('u1', user: true, text: 'Plan a trip'),
  _m('a1', parent: 'u1', minute: 1, text: 'First answer'),
  _m('a2', parent: 'u1', minute: 2, text: 'Second answer'),
];

/// The controls a Run turns off, as `(messageId, icon)` (Req 25.14).
const _runSensitive = <(String, IconData)>[
  ('u1', Icons.edit),
  ('a2', Icons.edit),
  ('a2', Icons.refresh),
  ('a2', Icons.play_arrow_outlined),
  ('a2', Icons.thumb_up_outlined),
  ('a2', Icons.thumb_down_outlined),
];

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late FakeMessagesRepository messages;
  late FakeConversationsRepository conversations;
  late FakePlatformActions platform;
  late FakeChatApi chatApi;
  late AppSettings settings;
  late GoRouter router;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('message_actions_test');
    log = await DiagnosticLog.open(directory: logDir);
    messages = FakeMessagesRepository();
    conversations = FakeConversationsRepository(
      rows: const [Conversation(conversationId: 'c1', title: 'Trip plans')],
    );
    platform = FakePlatformActions();
    chatApi = FakeChatApi();
    settings = const AppSettings(lastEndpoint: 'openAI', lastModel: 'gpt-4o');
  });

  tearDown(() async {
    await log.file();
    await logDir.delete(recursive: true);
  });

  /// `c1`'s Chat_Screen, with the conversation route beside it so a fork
  /// can open the new conversation (Req 25.9).
  Future<void> open(
    WidgetTester tester, {
    List<Message>? thread,
    bool feedbackEnabled = true,
  }) async {
    messages.fakeApi.messages['c1'] = thread ?? _thread();
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ChatScreen(conversationId: 'c1'),
        ),
        GoRoute(
          path: '/chat/c/:conversationId',
          builder: (context, state) => Scaffold(
            body: Text('opened ${state.pathParameters['conversationId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(messages),
          // The same fake serves the repository's fetch and the actions'
          // own routes, so a save shows up in the list.
          messagesApiProvider.overrideWithValue(messages.fakeApi),
          conversationsRepositoryProvider.overrideWithValue(conversations),
          platformActionsProvider.overrideWithValue(platform),
          settingsProvider.overrideWith(() => FakeSettingsStore(settings)),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(
              ServerInfo(
                config: StartupConfig(
                  interfaceConfig: InterfaceConfig(feedback: feedbackEnabled),
                ),
              ),
            ),
          ),
          authServiceProvider.overrideWith((ref) => FakeAuthService()),
          chatApiProvider.overrideWithValue(chatApi),
          streamClientProvider.overrideWithValue(FakeStreamClient()),
          diagnosticLogProvider.overrideWithValue(log),
          deviceTimeZoneProvider.overrideWith((ref) async => 'UTC'),
          onlineProvider.overrideWith((ref) => Stream.value(true)),
          missingFeaturesProvider.overrideWithValue(ValueNotifier(const {})),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The action button with [icon] on the message with [messageId].
  Finder action(String messageId, IconData icon) => find.descendant(
    of: find.byKey(ValueKey(messageId)),
    matching: find.widgetWithIcon(IconButton, icon),
  );

  VoidCallback? pressed(WidgetTester tester, Finder button) =>
      tester.widget<IconButton>(button).onPressed;

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder text(String value) => find.text(value, findRichText: true);

  group('feedback (Req 25.6, 25.7)', () {
    testWidgets('a thumb asks for a reason and an optional comment, then '
        'sends {rating, tag, text}', (tester) async {
      await open(tester);

      await tap(tester, action('a1', Icons.thumb_down_outlined));
      expect(find.text('What was the issue with this response?'), findsOne);
      // The Server rejects a rating with no tag.
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Submit'))
            .onPressed,
        isNull,
      );

      await tap(tester, find.text('Inaccurate or incorrect answer'));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.maxLength == maxFeedbackComment,
        ),
        '  Wrong dates  ',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(TextButton, 'Submit'));

      expect(messages.fakeApi.feedbackSets, [
        (
          conversationId: 'c1',
          messageId: 'a1',
          rating: 'thumbsDown',
          tag: 'inaccurate',
          text: 'Wrong dates',
        ),
      ]);
      expect(messages.fakeApi.feedbackClears, isEmpty);
      // The saved rating shows as the filled thumb.
      expect(action('a1', Icons.thumb_down), findsOne);
    });

    testWidgets('a blank comment is left out of the request', (tester) async {
      await open(tester);

      await tap(tester, action('a1', Icons.thumb_up_outlined));
      await tap(tester, find.text('Creative solution'));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.maxLength == maxFeedbackComment,
        ),
        '   ',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(TextButton, 'Submit'));

      expect(messages.fakeApi.feedbackSets.single.rating, 'thumbsUp');
      expect(messages.fakeApi.feedbackSets.single.tag, 'creative_solution');
      expect(messages.fakeApi.feedbackSets.single.text, isNull);
    });

    testWidgets('a dismissed reason sheet sends nothing', (tester) async {
      await open(tester);

      await tap(tester, action('a1', Icons.thumb_up_outlined));
      await tap(tester, find.widgetWithText(TextButton, 'Cancel'));

      expect(messages.fakeApi.feedbackSets, isEmpty);
      expect(messages.fakeApi.feedbackClears, isEmpty);
    });

    testWidgets('tapping the rating that is already selected clears it '
        'without asking for a reason', (tester) async {
      await open(
        tester,
        thread: _thread(
          feedback: const MessageFeedback(
            rating: FeedbackRating.thumbsUp,
            tag: 'creative_solution',
          ),
        ),
      );
      expect(action('a1', Icons.thumb_up), findsOne);

      await tap(tester, action('a1', Icons.thumb_up));

      expect(find.text('What was good about this response?'), findsNothing);
      expect(messages.fakeApi.feedbackClears, [('c1', 'a1')]);
      expect(messages.fakeApi.feedbackSets, isEmpty);
      expect(action('a1', Icons.thumb_up_outlined), findsOne);
    });

    testWidgets('with feedback off the thumbs are not offered', (tester) async {
      await open(tester, feedbackEnabled: false);

      expect(action('a1', Icons.thumb_up_outlined), findsNothing);
      expect(action('a1', Icons.thumb_down_outlined), findsNothing);
      // The rest of the row stays.
      expect(action('a1', Icons.refresh), findsOne);
    });
  });

  group('fork (Req 25.9)', () {
    testWidgets('the sheet starts from the Settings_Screen\'s defaults, and '
        'Fork posts the mode, the split and the path\'s leaf', (tester) async {
      settings = const AppSettings(
        lastEndpoint: 'openAI',
        lastModel: 'gpt-4o',
        forkMode: ForkMode.includeBranches,
        forkSplitAtTarget: true,
      );
      conversations.fakeApi.forkReply = (
        conversation: const Conversation(conversationId: 'fork-1'),
        messages: [_m('f1', text: 'Forked')],
      );
      await open(tester);

      await tap(tester, action('a1', Icons.call_split));
      expect(find.text('Fork Conversation'), findsOne);
      expect(
        tester
            .widget<RadioGroup<ForkMode>>(find.byType(RadioGroup<ForkMode>))
            .groupValue,
        ForkMode.includeBranches,
      );
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );

      await tap(tester, find.widgetWithText(TextButton, 'Fork'));

      // The leaf of the Active_Path, not the forked message.
      expect(conversations.fakeApi.callsTo('fork'), [
        ['c1', 'a1', 'includeBranches', true, 'u2'],
      ]);
      // The new conversation and its messages are cached, and it opens.
      expect(conversations.callsTo('upsert'), [
        [const Conversation(conversationId: 'fork-1')],
      ]);
      expect(messages.cached['fork-1']?.single.messageId, 'f1');
      expect(find.text('opened fork-1'), findsOne);
    });

    testWidgets('a chosen mode and split replace the defaults', (tester) async {
      await open(tester);

      await tap(tester, action('u1', Icons.call_split));
      await tap(tester, find.text('Visible messages'));
      await tap(tester, find.text('Start new conversation from target'));
      await tap(tester, find.widgetWithText(TextButton, 'Fork'));

      expect(conversations.fakeApi.callsTo('fork'), [
        ['c1', 'u1', 'directPath', true, 'u2'],
      ]);
    });

    testWidgets('a dismissed sheet forks nothing', (tester) async {
      await open(tester);

      await tap(tester, action('a1', Icons.call_split));
      await tap(tester, find.widgetWithText(TextButton, 'Cancel'));

      expect(conversations.fakeApi.callsTo('fork'), isEmpty);
      expect(find.text('opened fork-1'), findsNothing);
    });

    test('forkOptionValue names the Server\'s fork modes', () {
      expect(forkOptionValue(ForkMode.directPath), 'directPath');
      expect(forkOptionValue(ForkMode.includeBranches), 'includeBranches');
      expect(forkOptionValue(ForkMode.targetLevel), 'targetLevel');
    });
  });

  group('edit (Req 25.3)', () {
    testWidgets('Save writes the reply\'s text part by index and shows the '
        'saved text', (tester) async {
      await open(tester);
      expect(text('First answer'), findsOne);

      await tap(tester, action('a1', Icons.edit));
      expect(find.byType(InlineMessageEditor), findsOne);
      // The editor opens on the part the bubble shows.
      expect(find.widgetWithText(TextField, 'First answer'), findsOne);

      // A blank edit saves nothing.
      await tester.enterText(find.byType(InlineMessageEditor), '   ');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save & Submit'),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(find.byType(InlineMessageEditor), 'Saved answer');
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(FilledButton, 'Save'));

      expect(messages.fakeApi.updates, [
        (conversationId: 'c1', messageId: 'a1', text: 'Saved answer', index: 1),
      ]);
      // A Save is no Run.
      expect(chatApi.starts, isEmpty);
      expect(find.byType(InlineMessageEditor), findsNothing);
      expect(text('Saved answer'), findsOne);
    });

    testWidgets('a failed Save keeps the editor open with the text', (
      tester,
    ) async {
      await open(tester);
      messages.fakeApi.error = StateError('offline');

      await tap(tester, action('a1', Icons.edit));
      await tester.enterText(find.byType(InlineMessageEditor), 'Saved answer');
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(FilledButton, 'Save'));

      expect(messages.fakeApi.updates, hasLength(1));
      expect(find.byType(InlineMessageEditor), findsOne);
      expect(find.widgetWithText(TextField, 'Saved answer'), findsOne);
    });

    testWidgets('a user message\'s Save & Submit sends the edited text as a '
        'new Sibling instead of saving it', (tester) async {
      await open(tester);

      await tap(tester, action('u1', Icons.edit));
      await tester.enterText(
        find.byType(InlineMessageEditor),
        'Plan a long trip',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(FilledButton, 'Save & Submit'));

      expect(messages.fakeApi.updates, isEmpty, reason: 'no PUT on a submit');
      final (endpoint, payload) = chatApi.starts.single;
      expect(endpoint, 'openAI');
      expect(payload['text'], 'Plan a long trip');
      expect(payload['isEdited'], isTrue);
      expect(payload['parentMessageId'], rootParentId);
    });

    testWidgets('a reply with no parent user message offers Save alone', (
      tester,
    ) async {
      await open(
        tester,
        thread: [
          _m(
            'a1',
            content: const [
              ContentPart(type: ContentPartType.text, text: 'Orphan reply'),
            ],
          ),
        ],
      );

      await tap(tester, action('a1', Icons.edit));

      expect(find.widgetWithText(FilledButton, 'Save'), findsOne);
      expect(find.text('Save & Submit'), findsNothing);
    });
  });

  group('a Run disables the controls instead of hiding them (Req 25.14)', () {
    /// A thread with two replies, so the SiblingNavigator shows, and a Run
    /// the Composer started that never opens its Stream, so it stays live
    /// for the assertions. The Run is a plain send, so every stored
    /// message keeps its place on the Active_Path.
    Future<void> openWithRun(WidgetTester tester) async {
      chatApi.startGate = Completer<void>();
      await open(tester, thread: _branched());
      expect(find.text('2 / 2'), findsOne);
      await tester.enterText(
        find.descendant(
          of: find.byType(ComposerBar),
          matching: find.byType(TextField),
        ),
        'And then?',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Send message'));
    }

    testWidgets('without a Run every control is on', (tester) async {
      await open(tester, thread: _branched());

      for (final (id, icon) in _runSensitive) {
        expect(pressed(tester, action(id, icon)), isNotNull, reason: id);
      }
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('edit, regenerate, continue and feedback are disabled, and '
        'copy and fork still work', (tester) async {
      await openWithRun(tester);

      for (final (id, icon) in _runSensitive) {
        expect(action(id, icon), findsOne, reason: '$id $icon stays on screen');
        expect(pressed(tester, action(id, icon)), isNull, reason: '$id $icon');
      }
      // Copy and fork do not touch the Run.
      expect(pressed(tester, action('a2', Icons.content_copy)), isNotNull);
      expect(pressed(tester, action('a2', Icons.call_split)), isNotNull);
    });

    testWidgets('Sibling switching is disabled', (tester) async {
      await openWithRun(tester);

      expect(find.byType(SiblingNavigator), findsOne);
      expect(find.text('2 / 2'), findsOne);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );
      expect(text('First answer'), findsNothing);
    });

    testWidgets('a disabled thumb tells TalkBack why', (tester) async {
      await openWithRun(tester);

      expect(
        find.byTooltip('Thumbs up, Unavailable while a reply is generating'),
        findsOne,
      );
    });
  });

  group('in-conversation search (Req 25.11)', () {
    testWidgets('highlights the matches, counts them and moves between '
        'them', (tester) async {
      await open(
        tester,
        thread: [
          _m('u1', user: true, text: 'Plan a trip'),
          _m('a1', parent: 'u1', minute: 1, text: 'The plan is a plan'),
        ],
      );

      await tap(tester, find.byTooltip('More options'));
      await tap(tester, find.text('Search in conversation'));
      await tester.enterText(
        find.descendant(
          of: find.byType(ChatSearchField),
          matching: find.byType(TextField),
        ),
        'plan',
      );
      await tester.pumpAndSettle();

      expect(find.text('1/3'), findsOne);
      await tap(tester, find.byTooltip('Next match'));
      expect(find.text('2/3'), findsOne);
      // Wraps at the end.
      await tap(tester, find.byTooltip('Previous match'));
      await tap(tester, find.byTooltip('Previous match'));
      expect(find.text('3/3'), findsOne);

      // The matched text is painted, so the bubble renders spans.
      final spans = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .toList();
      expect(spans, contains('The plan is a plan'));

      await tap(tester, find.byTooltip('Close search'));
      expect(find.text('3/3'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Trip plans'), findsOne);
    });

    testWidgets('a query with no match leaves the controls off', (
      tester,
    ) async {
      await open(tester);

      await tap(tester, find.byTooltip('More options'));
      await tap(tester, find.text('Search in conversation'));
      await tester.enterText(
        find.descendant(
          of: find.byType(ChatSearchField),
          matching: find.byType(TextField),
        ),
        'nowhere',
      );
      await tester.pumpAndSettle();

      expect(find.text('0/0'), findsOne);
      for (final icon in [Icons.keyboard_arrow_down, Icons.keyboard_arrow_up]) {
        final button = find.descendant(
          of: find.byType(ChatSearchField),
          matching: find.widgetWithIcon(IconButton, icon),
        );
        expect(tester.widget<IconButton>(button).onPressed, isNull);
      }
    });
  });
}
