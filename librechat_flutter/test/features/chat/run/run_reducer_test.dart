// Reducer and final merge examples (Task 15.2).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/pending_action.dart';
import 'package:librechat_flutter/core/stream/stream_events.dart';
import 'package:librechat_flutter/features/chat/run/final_merge.dart';
import 'package:librechat_flutter/features/chat/run/run_reducer.dart';
import 'package:librechat_flutter/features/chat/run/run_state.dart';
import 'package:librechat_flutter/features/chat/send/chat_turn.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';

const run = RunState(
  key: 'c',
  kind: TurnKind.send,
  selection: ChatSelection(endpoint: 'agents'),
);

RunState reduceAll(List<StreamEvent> events, [RunState s = run]) =>
    events.fold(s, reduce);

const reply = [ContentPart(type: ContentPartType.text, text: 'ok')];

void main() {
  group('reduce', () {
    test('deltas join per type and agent', () {
      final s = reduceAll(const [
        TextDelta('Hel'),
        TextDelta('lo'),
        ThinkDelta('hm'),
        TextDelta('a', agentId: 'x'),
        TextDelta('b', agentId: 'y'),
        TextDelta('c', agentId: 'y'),
      ]);
      expect(s.parts, const [
        ContentPart(type: ContentPartType.text, text: 'Hello'),
        ContentPart(type: ContentPartType.think, think: 'hm'),
        ContentPart(type: ContentPartType.text, text: 'a', agentId: 'x'),
        ContentPart(type: ContentPartType.text, text: 'bc', agentId: 'y'),
      ]);
      expect(s.hasContent, isTrue);
    });

    test('tool events upsert one part by id', () {
      final s = reduceAll(const [
        ToolCallStarted(id: 't1', name: 'search', args: {'q': 1}),
        TextDelta('x'),
        ToolCallCompleted(toolCallId: 't1', output: 'done'),
        ToolCallClosed(toolCallId: 't1', status: 'completed'),
        ToolCallClosed(toolCallId: 'unknown', status: 'failed'),
      ]);
      expect(s.parts, hasLength(2));
      expect(
        s.parts.first,
        const ContentPart(
          type: ContentPartType.toolCall,
          toolCall: ToolCall(
            id: 't1',
            name: 'search',
            args: {'q': 1},
            output: 'done',
          ),
          status: 'completed',
        ),
      );
    });

    test('attachments upsert by file id, keeping earlier fields', () {
      final s = reduceAll(const [
        AttachmentEvent(
          Attachment(fileId: 'f', filename: 'a.docx', status: 'pending'),
        ),
        AttachmentEvent(Attachment(fileId: 'f', status: 'ready')),
        AttachmentEvent(Attachment(filename: 'b.png')),
      ]);
      expect(s.attachments, const [
        Attachment(fileId: 'f', filename: 'a.docx', status: 'ready'),
        Attachment(filename: 'b.png'),
      ]);
    });

    test('a Sync_Frame replaces parts and the Pending_Action', () {
      const action = PendingAction(actionId: 'a');
      final s = reduceAll([
        const TextDelta('stale'),
        const PendingActionEvent(action),
        const StreamReconnecting(2),
      ]);
      expect((s.phase, s.attempt), (RunPhase.reconnecting, 2));
      final synced = reduceAll(const [SyncSnapshot(reply)], s);
      expect(synced.parts, reply);
      expect(synced.pendingAction, isNull);
      expect((synced.phase, synced.attempt), (RunPhase.streaming, 0));
    });

    test('a steer part goes in at its index, clamped', () {
      const steer = ContentPart(type: ContentPartType.steer, steer: 's');
      final s = reduceAll(const [
        TextDelta('a'),
        ThinkDelta('b'),
        SteerApplied(steerId: '1', index: 1, part: steer),
        SteerApplied(steerId: '2', index: 99, part: steer),
        SteerApplied(steerId: '3'),
      ]);
      expect(s.parts.map((p) => p.type), [
        ContentPartType.text,
        ContentPartType.steer,
        ContentPartType.think,
        ContentPartType.steer,
      ]);
    });

    test('run fields', () {
      final s = reduceAll(const [
        CreatedEvent(conversationId: 'c2', messageId: 'u1'),
        TitleEvent(title: 'T'),
        SubagentUpdate(phase: 'start', subagentRunId: 'r', label: 'L'),
        SubagentUpdate(phase: 'stop', subagentRunId: 'r'),
        SubagentUpdate(phase: 'content', subagentRunId: 'r'),
        StreamError('boom'),
      ]);
      expect(s.conversationId, 'c2');
      expect(s.requestMessageId, 'u1');
      expect(s.title, 'T');
      expect(
        s.subagents['r'],
        const SubagentProgress(status: SubagentStatus.done, label: 'L'),
      );
      expect(s.error, 'boom');
    });
  });

  group('finalTurn', () {
    final optimistic = Message(
      messageId: 'opt',
      conversationId: 'c',
      parentMessageId: rootParentId,
      text: 'hi',
      isCreatedByUser: true,
      files: const [Attachment(fileId: 'f')],
    );
    const request = Message(
      messageId: 'u1',
      conversationId: 'c',
      parentMessageId: rootParentId,
      text: 'hi',
      isCreatedByUser: true,
    );
    const response = Message(
      messageId: 'r1',
      conversationId: 'c',
      parentMessageId: 'u1',
      content: reply,
    );

    test('matches by parent and text, fills files, selects the turn', () {
      final t = finalTurn(
        const FinalEvent(requestMessage: request, responseMessage: response),
        optimistic,
      );
      expect(t.messages, [request.copyWith(files: optimistic.files), response]);
      expect(t.local, isEmpty);
      expect(t.selection, {rootParentId: 'u1', 'u1': 'r1'});
      expect(t.justSettledId, 'r1');
    });

    test('matches by id even when the text differs', () {
      final t = finalTurn(
        FinalEvent(requestMessage: request.copyWith(messageId: 'opt')),
        optimistic.copyWith(text: 'other'),
      );
      expect(t.messages.single.files, optimistic.files);
    });

    test('an unmatched Optimistic_Message is dropped', () {
      final t = finalTurn(
        const FinalEvent(requestMessage: request),
        optimistic.copyWith(text: 'other'),
      );
      expect(t.messages, [request]);
      expect(t.local, isEmpty);
    });

    test('the abort contract drops a reply the Server did not save', () {
      for (final r in [
        response.copyWith(content: const []),
        response.copyWith(content: null),
        response.copyWith(messageId: 'u1_'),
      ]) {
        final t = finalTurn(
          FinalEvent(
            requestMessage: request,
            responseMessage: r,
            aborted: true,
          ),
          optimistic,
        );
        expect(t.messages, hasLength(1), reason: '$r');
        expect(t.justSettledId, isNull);
        expect(t.selection, {rootParentId: 'u1'});
      }
      // Without the abort the same reply is kept.
      final kept = finalTurn(
        FinalEvent(
          requestMessage: request,
          responseMessage: response.copyWith(content: const []),
        ),
        optimistic,
      );
      expect(kept.justSettledId, 'r1');
    });

    test('aborted without a request keeps the Optimistic_Message local', () {
      final t = finalTurn(
        const FinalEvent(responseMessage: response, aborted: true),
        optimistic,
      );
      expect(t.messages, isEmpty);
      expect(t.local, [optimistic]);
    });

    test('earlyAbort stores nothing', () {
      final t = finalTurn(
        const FinalEvent(
          requestMessage: request,
          responseMessage: response,
          aborted: true,
          earlyAbort: true,
        ),
        optimistic,
      );
      expect(t.messages, isEmpty);
      expect(t.local, isEmpty);
    });
  });
}
