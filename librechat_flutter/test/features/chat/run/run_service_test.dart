import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/pending_action.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/stream/stream_events.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/conversation_messages.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/run/run_service.dart';
import 'package:librechat_flutter/features/chat/run/run_state.dart';
import 'package:librechat_flutter/features/chat/send/chat_turn.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../../support/fakes.dart';

const _selection = ChatSelection(endpoint: 'openAI', model: 'gpt-4o');

ChatTurn _send(String text, {String? parent, bool temporary = false}) =>
    ChatTurn(
      kind: TurnKind.send,
      selection: _selection,
      text: text,
      parentMessageId: parent,
      isTemporary: temporary,
    );

Message _message(
  String id, {
  String? parent,
  String text = '',
  bool user = false,
}) => Message(
  messageId: id,
  conversationId: 'c1',
  parentMessageId: parent ?? rootParentId,
  text: text,
  isCreatedByUser: user,
  content: user ? null : [ContentPart(type: 'text', text: text)],
);

/// A Final_Frame for the request [request] (the Optimistic_Message's id).
FinalEvent _final(
  String request, {
  bool aborted = false,
  bool earlyAbort = false,
  String text = 'Hi',
}) => FinalEvent(
  conversation: const Conversation(conversationId: 'c1', title: 'New Chat'),
  requestMessage: _message(request, text: text, user: true),
  responseMessage: _message('r1', parent: request, text: 'Hello'),
  aborted: aborted,
  earlyAbort: earlyAbort,
);

/// The status route's answer for an active Run on Stream `s1`.
const RunStatus _active = (
  active: true,
  streamId: 's1',
  createdAt: 9,
  pendingAction: null,
);

/// The test's Stop watchdog, standing in for 15 s.
const _watchdog = Duration(milliseconds: 50);

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late FakeChatApi chatApi;
  late FakeStreamClient streams;
  late FakeMessagesRepository messages;
  late FakeConversationsRepository conversations;
  late StreamController<bool> online;
  late ProviderContainer container;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('run_service_test');
    log = await DiagnosticLog.open(directory: logDir);
    chatApi = FakeChatApi();
    streams = FakeStreamClient();
    messages = FakeMessagesRepository();
    conversations = FakeConversationsRepository();
    online = StreamController<bool>();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authServiceProvider.overrideWith((ref) => FakeAuthService()),
        diagnosticLogProvider.overrideWithValue(log),
        chatApiProvider.overrideWithValue(chatApi),
        streamClientProvider.overrideWithValue(streams),
        messagesRepositoryProvider.overrideWithValue(messages),
        conversationsRepositoryProvider.overrideWithValue(conversations),
        deviceTimeZoneProvider.overrideWith((ref) async => 'Europe/Berlin'),
        onlineProvider.overrideWith((ref) => online.stream),
        stopWatchdogProvider.overrideWithValue(_watchdog),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await online.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  RunService service() => container.read(runServiceProvider.notifier);
  ConversationRuns runs() => container.read(runServiceProvider);

  /// Keeps `conversationMessagesProvider(id)` alive, as an open screen does.
  Future<void> openScreen(String id) async {
    container.listen(conversationMessagesProvider(id), (_, _) {});
    await container.read(conversationMessagesProvider(id).future);
  }

  ConversationMessages screen(String id) =>
      container.read(conversationMessagesProvider(id)).requireValue;

  test('shows the Optimistic_Message at once, then starts and opens the '
      'Stream', () async {
    messages.drafts['c1'] = 'Hi';
    chatApi.startGate = Completer<void>();
    final sent = service().send('c1', _send('Hi', parent: 'p1'));

    final run = runs().runs['c1']!;
    expect(run.phase, RunPhase.starting);
    expect(run.hasContent, isFalse);
    expect(run.optimistic!.text, 'Hi');
    expect(run.optimistic!.parentMessageId, 'p1');
    expect(run.optimistic!.isCreatedByUser, isTrue);
    expect(run.anchorId, run.optimistic!.messageId);
    await pumpEventQueue();
    expect(messages.drafts, isEmpty);

    chatApi.startGate!.complete();
    await sent;
    final (endpoint, body) = chatApi.starts.single;
    expect(endpoint, 'openAI');
    expect(body['text'], 'Hi');
    expect(body['conversationId'], 'c1');
    expect(body['parentMessageId'], 'p1');
    expect(body['messageId'], run.optimistic!.messageId);
    expect(body['timezone'], 'Europe/Berlin');
    expect(body['clientRequestId'], isA<String>());
    expect(streams.opens, [('s1', false)]);
    final started = runs().runs['c1']!;
    expect(started.phase, RunPhase.streaming);
    expect(started.streamId, 's1');
    expect(started.generationCreatedAt, 7);
  });

  test('batches deltas for 50 ms and flushes them before any other '
      'event', () async {
    await service().send('c1', _send('Hi'));
    var updates = 0;
    container.listen(runServiceProvider, (_, _) => updates++);

    await streams.emit([
      const TextDelta('a'),
      const TextDelta('b'),
      const ThinkDelta('t'),
    ]);
    expect(runs().runs['c1']!.parts, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(updates, 1);
    expect(runs().runs['c1']!.parts.map((p) => p.text ?? p.think), ['ab', 't']);

    await streams.emit([
      const TextDelta('c'),
      const ToolCallStarted(id: 'call1', name: 'search'),
    ]);
    final parts = runs().runs['c1']!.parts;
    expect(parts.map((p) => p.type), ['text', 'think', 'text', 'tool_call']);
    expect(parts[2].text, 'c');
  });

  test('created moves a new chat\'s Run to its conversation id', () async {
    final key = newChatRunKey();
    await service().send(key, _send('Hi'));
    expect(chatApi.starts.single.$2.containsKey('conversationId'), isFalse);
    expect(chatApi.starts.single.$2['parentMessageId'], rootParentId);

    await streams.emit([
      const CreatedEvent(conversationId: 'c9', messageId: 'm1'),
    ]);
    final state = runs();
    expect(state.runs.keys, ['c9']);
    expect(state.movedTo, {key: 'c9'});
    final run = state.runs['c9']!;
    expect(run.key, 'c9');
    expect(run.requestMessageId, 'm1');
    expect(run.firstRunOfNewChat, isTrue);
    expect(run.optimistic!.conversationId, 'c9');

    // The Run keeps streaming under its new key.
    await streams.emit([const ToolCallStarted(id: 't1')]);
    expect(runs().runs['c9']!.parts, hasLength(1));
  });

  test('a Final_Frame swaps the live reply for the Server\'s turn in one '
      'synchronous block, then caches it and generates the title', () async {
    final key = newChatRunKey();
    await service().send(key, _send('Hi'));
    await streams.emit([const CreatedEvent(conversationId: 'c1')]);
    await openScreen('c1');
    final optimisticId = runs().runs['c1']!.optimistic!.messageId;

    // When the Run goes, the Server's messages are already there.
    List<String>? shownWhenRunEnded;
    container.listen(runServiceProvider, (_, next) {
      if (!next.runs.containsKey('c1')) {
        shownWhenRunEnded = [
          for (final m in screen('c1').messages) m.messageId,
        ];
      }
    });
    await streams.emit([const TextDelta('Hel'), _final(optimisticId)]);
    expect(shownWhenRunEnded, [optimisticId, 'r1']);
    expect(screen('c1').justSettledId, 'r1');
    expect(streams.cancels, 1);

    await pumpEventQueue();
    expect(messages.cached['c1']!.map((m) => m.messageId), [
      optimisticId,
      'r1',
    ]);
    expect(chatApi.titleRequests, ['c1']);
    final rows = [
      for (final [row] in conversations.callsTo('upsert'))
        (row! as Conversation).title,
    ];
    expect(rows, ['New Chat', 'Generated']);
  });

  test('a title event wins, and no title is generated', () async {
    final key = newChatRunKey();
    await service().send(key, _send('Hi'));
    final id = runs().runs[key]!.optimistic!.messageId;
    await streams.emit([
      const CreatedEvent(conversationId: 'c1'),
      const TitleEvent(conversationId: 'c1', title: 'Streamed'),
      _final(id),
    ]);
    await pumpEventQueue();
    expect(chatApi.titleRequests, isEmpty);
    final [[row]] = conversations.callsTo('upsert');
    expect((row! as Conversation).title, 'Streamed');
  });

  test('only the first non-aborted Run of a new chat generates a '
      'title', () async {
    await service().send('c1', _send('Hi'));
    await streams.emit([_final(runs().runs['c1']!.optimistic!.messageId)]);
    await pumpEventQueue();

    final key = newChatRunKey();
    await service().send(key, _send('Hi'));
    conversations.fakeApi.conversations['c1'] = const Conversation(
      conversationId: 'c1',
      title: 'Saved',
    );
    await streams.emit([
      const CreatedEvent(conversationId: 'c1'),
      _final(runs().runs[key]!.optimistic!.messageId, aborted: true),
    ]);
    await pumpEventQueue();
    expect(chatApi.titleRequests, isEmpty);
    // An aborted new chat's row comes from the Server.
    expect(conversations.fakeApi.callsTo('get'), [
      ['c1'],
    ]);
  });

  test('a temporary chat stays in memory and out of the Cache', () async {
    final key = newChatRunKey();
    await service().send(key, _send('Hi', temporary: true));
    expect(chatApi.starts.single.$2['isTemporary'], isTrue);
    await streams.emit([const CreatedEvent(conversationId: 'c1')]);
    expect(service().isTemporary('c1'), isTrue);
    expect(container.read(isTemporaryChatProvider('c1')), isTrue);

    await openScreen('c1');
    await streams.emit([_final(runs().runs['c1']!.optimistic!.messageId)]);
    await pumpEventQueue();
    expect(screen('c1').messages, hasLength(2));
    expect(messages.cached['c1'], isNull);
    expect(conversations.calls, isEmpty);
    expect(chatApi.titleRequests, isEmpty);
  });

  test('an error event keeps the Optimistic_Message and the partial reply '
      'with the error', () async {
    await openScreen('c1');
    await service().send('c1', _send('Hi'));
    final optimistic = runs().runs['c1']!.optimistic!;
    await streams.emit([
      const TextDelta('Half'),
      const StreamError('Rate limited'),
    ]);
    expect(runs().runs, isEmpty);
    final shown = screen('c1');
    expect(shown.messages.first, optimistic);
    final partial = shown.messages.last;
    expect(partial.parentMessageId, optimistic.messageId);
    expect(partial.error, isTrue);
    expect(partial.content!.first.text, 'Half');
    expect(partial.content!.last.error, 'Rate limited');
    expect(shown.localIds, hasLength(2));
    expect(streams.cancels, 1);
  });

  test('a failed start un-sends: the Run goes, the text comes back and the '
      'error shows', () async {
    chatApi.startError = AppException(FailureKind.network);
    await service().send('c1', _send('Hi'));
    await pumpEventQueue();
    expect(runs().runs, isEmpty);
    expect(runs().errors['c1'], userMessage(AppException(FailureKind.network)));
    expect(messages.drafts['c1'], 'Hi');
    expect(streams.opens, isEmpty);

    service().dismissError('c1');
    expect(runs().errors, isEmpty);
  });

  test('an earlyAbort stores nothing and puts the text back', () async {
    await openScreen('c1');
    await service().send('c1', _send('Draft'));
    await streams.emit([
      _final(runs().runs['c1']!.optimistic!.messageId, earlyAbort: true),
    ]);
    await pumpEventQueue();
    expect(runs().runs, isEmpty);
    expect(screen('c1').messages, isEmpty);
    expect(messages.cached['c1'], isEmpty);
    expect(messages.drafts['c1'], 'Draft');
    expect(conversations.calls, isEmpty);
  });

  group('stop', () {
    test('sends the abort, disables Stop and keeps reading until the '
        'aborted Final', () async {
      await openScreen('c1');
      await service().send('c1', _send('Hi'));
      final id = runs().runs['c1']!.optimistic!.messageId;
      expect(runs().runs['c1']!.canStop, isTrue);

      await service().stop('c1');
      expect(chatApi.aborts, [('s1', false, 7)]);
      expect(runs().runs['c1']!.stopping, isTrue);
      expect(runs().runs['c1']!.canStop, isFalse);
      expect(streams.cancels, 0);

      // A pending Stop ignores another tap.
      await service().stop('c1');
      expect(chatApi.aborts, hasLength(1));

      await streams.emit([const TextDelta('Hel'), _final(id, aborted: true)]);
      expect(runs().runs, isEmpty);
      expect(screen('c1').messages.map((m) => m.messageId), [id, 'r1']);
      await Future<void>.delayed(_watchdog * 2);
      await pumpEventQueue();
      expect(chatApi.titleRequests, isEmpty);
    });

    test('without a Final within the watchdog, closes the Stream and keeps '
        'the partial reply', () async {
      await openScreen('c1');
      await service().send('c1', _send('Hi'));
      final optimistic = runs().runs['c1']!.optimistic!;
      await streams.emit([const TextDelta('Half')]);
      await service().stop('c1');
      expect(runs().runs['c1'], isNotNull);

      await Future<void>.delayed(_watchdog * 2);
      expect(runs().runs, isEmpty);
      expect(streams.cancels, 1);
      final shown = screen('c1');
      expect(shown.messages.first, optimistic);
      final partial = shown.messages.last;
      expect(partial.error, isFalse);
      expect(partial.content!.single.text, 'Half');
      expect(shown.localIds, hasLength(2));
    });

    test('a failed abort keeps the partial reply at once', () async {
      await openScreen('c1');
      await service().send('c1', _send('Hi'));
      await streams.emit([const ToolCallStarted(id: 't1')]);
      chatApi.abortError = AppException(FailureKind.network);
      await service().stop('c1');
      expect(runs().runs, isEmpty);
      expect(streams.cancels, 1);
      expect(screen('c1').messages, hasLength(2));
    });

    test('a Stop while starting sends the abort once the start returns, '
        'and an unknown Stream id goes as "new"', () async {
      chatApi.startGate = Completer<void>();
      final key = newChatRunKey();
      final sent = service().send(key, _send('Hi'));
      await service().stop(key);
      expect(runs().runs[key]!.stopping, isTrue);
      expect(chatApi.aborts, isEmpty);

      chatApi.startGate!.complete();
      await sent;
      await pumpEventQueue();
      expect(chatApi.aborts, [('s1', false, 7)]);
    });
  });

  group('recovery', () {
    test('after the ladder, an active Run resumes once, then '
        'detaches', () async {
      await service().send('c1', _send('Hi'));
      await streams.emit([
        const TextDelta('Half'),
        const StreamReconnecting(5),
      ]);
      chatApi.statusReply = _active;
      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      expect(chatApi.statusRequests, ['c1']);
      expect(streams.opens, [('s1', false), ('s1', true)]);
      var run = runs().runs['c1']!;
      expect(run.phase, RunPhase.streaming);
      expect(run.resumedOnce, isTrue);
      expect(run.generationCreatedAt, 9);

      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      run = runs().runs['c1']!;
      expect(run.phase, RunPhase.detached);
      expect(run.error, userMessage(AppException(FailureKind.network)));
      expect(run.parts.single.text, 'Half');
      expect(streams.opens, hasLength(2));
    });

    test('after the ladder, an ended Run reloads the messages', () async {
      await openScreen('c1');
      expect(messages.fakeApi.requests, ['c1']);
      await service().send('c1', _send('Hi'));
      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      expect(runs().runs, isEmpty);
      expect(messages.fakeApi.requests, ['c1', 'c1']);
    });

    test('a failed status check detaches the Run, and the network coming '
        'back resumes it, with no screen watching', () async {
      online.add(true);
      await service().send('c1', _send('Hi'));
      await streams.emit([const TextDelta('Half')]);
      chatApi.statusError = AppException(FailureKind.network);
      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      expect(runs().runs['c1']!.phase, RunPhase.detached);
      expect(runs().runs['c1']!.parts.single.text, 'Half');

      chatApi
        ..statusError = null
        ..statusReply = _active;
      online.add(false);
      await pumpEventQueue();
      expect(chatApi.statusRequests, hasLength(1));
      online.add(true);
      await pumpEventQueue();
      expect(chatApi.statusRequests, hasLength(2));
      expect(streams.opens.last, ('s1', true));
      final run = runs().runs['c1']!;
      expect(run.phase, RunPhase.streaming);
      expect(run.error, isNull);

      // The Sync_Frame rebuilds the reply.
      await streams.emit([
        const SyncSnapshot([ContentPart(type: 'text', text: 'Whole')]),
      ]);
      expect(runs().runs['c1']!.parts.single.text, 'Whole');
    });

    test('onOpen checks a detached Run again', () async {
      await service().send('c1', _send('Hi'));
      chatApi.statusError = AppException(FailureKind.network);
      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      expect(runs().runs['c1']!.phase, RunPhase.detached);

      // Still failing: the Run stays detached.
      await service().onOpen('c1');
      expect(runs().runs['c1']!.phase, RunPhase.detached);

      chatApi.statusError = null;
      await service().onOpen('c1');
      expect(runs().runs, isEmpty);
    });

    test('a Stop on a detached Run reloads after the ack', () async {
      await openScreen('c1');
      await service().send('c1', _send('Hi'));
      chatApi.statusError = AppException(FailureKind.network);
      await streams.emit([const StreamRetryExhausted()]);
      await pumpEventQueue();
      await service().stop('c1');
      await pumpEventQueue();
      expect(runs().runs, isEmpty);
      expect(messages.fakeApi.requests, ['c1', 'c1']);
    });
  });

  group('onOpen', () {
    test('attaches to the Server\'s active Run with resume', () async {
      conversations.rows = [
        const Conversation(
          conversationId: 'c1',
          endpoint: 'anthropic',
          model: 'claude',
        ),
      ];
      chatApi.statusReply = (
        active: true,
        streamId: 'c1',
        createdAt: 9,
        pendingAction: const PendingAction(actionId: 'a1'),
      );
      await service().onOpen('c1');
      expect(streams.opens, [('c1', true)]);
      final run = runs().runs['c1']!;
      expect(run.kind, TurnKind.attach);
      expect(run.phase, RunPhase.streaming);
      expect(run.optimistic, isNull);
      expect(run.streamId, 'c1');
      expect(run.generationCreatedAt, 9);
      expect(run.selection.endpoint, 'anthropic');
      expect(run.selection.model, 'claude');
      expect(run.pendingAction!.actionId, 'a1');

      await streams.emit([const TextDelta('More')]);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(runs().runs['c1']!.parts.single.text, 'More');

      // A streaming Run needs no check.
      await service().onOpen('c1');
      expect(chatApi.statusRequests, ['c1']);
    });

    test('does nothing when the Server has no active Run, or the request '
        'fails', () async {
      await service().onOpen('c1');
      expect(runs().runs, isEmpty);
      chatApi.statusError = AppException(FailureKind.network);
      await service().onOpen('c1');
      expect(runs().runs, isEmpty);
      expect(streams.opens, isEmpty);
    });
  });
}
