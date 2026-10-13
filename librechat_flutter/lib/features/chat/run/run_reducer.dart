/// The pure reducer that builds a Run's live reply from its Stream's events
/// (Req 18.7, 19.4). RunService batches deltas and calls [reduce] for each
/// event; the ends of a Run (Final, error, expiry) are RunService's.
library;

import '../../../core/models/attachment.dart';
import '../../../core/models/content_part.dart';
import '../../../core/stream/stream_events.dart';
import 'run_state.dart';

/// [s] after [e].
///
/// - Deltas append to the last part when it has the same type and
///   `agentId`, otherwise they add a part, so two agents' interleaved
///   steps stay apart for the comparison panes.
/// - Tool events upsert a `tool_call` part by its id. A closed step's
///   terminal status goes to the part's `status`.
/// - Attachments upsert by `file_id`; a later event's fields win, which
///   moves an office preview from pending to ready or failed.
/// - A Sync_Frame's snapshot replaces the parts and clears the
///   Pending_Action, which the same frame sends again when one is open.
/// - Any wire event ends a reconnect.
RunState reduce(RunState s, StreamEvent e) {
  final run = _isWire(e) && s.phase == RunPhase.reconnecting
      ? s.copyWith(phase: RunPhase.streaming, attempt: 0)
      : s;
  return switch (e) {
    TextDelta(:final text, :final agentId) => run.copyWith(
      parts: _appendDelta(run.parts, ContentPartType.text, text, agentId),
    ),
    ThinkDelta(:final think, :final agentId) => run.copyWith(
      parts: _appendDelta(run.parts, ContentPartType.think, think, agentId),
    ),
    ToolCallStarted(:final id, :final name, :final args, :final agentId) =>
      run.copyWith(
        parts: _upsertTool(
          run.parts,
          id,
          agentId,
          (p) => p.copyWith(
            toolCall: (p.toolCall ?? ToolCall(id: id)).copyWith(
              name: name ?? p.toolCall?.name,
              args: args ?? p.toolCall?.args,
            ),
          ),
        ),
      ),
    ToolCallCompleted(:final toolCallId, :final output, :final agentId) =>
      run.copyWith(
        parts: _upsertTool(
          run.parts,
          toolCallId,
          agentId,
          (p) => p.copyWith(
            toolCall: (p.toolCall ?? ToolCall(id: toolCallId)).copyWith(
              output: output,
            ),
          ),
        ),
      ),
    // A close for a call the reply never showed has nothing to mark.
    ToolCallClosed(:final toolCallId, :final status) => run.copyWith(
      parts: [
        for (final p in run.parts)
          _isTool(p, toolCallId) ? p.copyWith(status: status) : p,
      ],
    ),
    SummaryEvent(:final text, :final agentId) => run.copyWith(
      parts: [
        ...run.parts,
        ContentPart(
          type: ContentPartType.summary,
          content: text,
          agentId: agentId,
        ),
      ],
    ),
    SteerApplied(:final part?, :final index) => run.copyWith(
      parts: [...run.parts]
        ..insert((index ?? run.parts.length).clamp(0, run.parts.length), part),
    ),
    AttachmentEvent(:final attachment) => run.copyWith(
      attachments: _upsertAttachment(run.attachments, attachment),
    ),
    SyncSnapshot(:final parts) => run.copyWith(
      parts: parts,
      pendingAction: null,
    ),
    PendingActionEvent(:final action) => run.copyWith(pendingAction: action),
    SubagentUpdate() => _subagent(run, e),
    TitleEvent(:final title) => run.copyWith(title: title),
    CreatedEvent(:final conversationId, :final messageId) => run.copyWith(
      conversationId: conversationId ?? run.conversationId,
      requestMessageId: messageId ?? run.requestMessageId,
    ),
    StreamError(:final text) => run.copyWith(error: text),
    StreamReconnecting(:final attempt) => run.copyWith(
      phase: RunPhase.reconnecting,
      attempt: attempt,
    ),
    _ => run,
  };
}

/// Whether [e] came from the Server rather than from StreamClient's
/// reports about the connection.
bool _isWire(StreamEvent e) => switch (e) {
  StreamReconnecting() ||
  StreamExpired() ||
  StreamRetryExhausted() ||
  StreamFailed() => false,
  _ => true,
};

List<ContentPart> _appendDelta(
  List<ContentPart> parts,
  String type,
  String delta,
  String? agentId,
) {
  final last = parts.isEmpty ? null : parts.last;
  final isThink = type == ContentPartType.think;
  if (last != null && last.type == type && last.agentId == agentId) {
    return [
      ...parts.take(parts.length - 1),
      isThink
          ? last.copyWith(think: (last.think ?? '') + delta)
          : last.copyWith(text: (last.text ?? '') + delta),
    ];
  }
  return [
    ...parts,
    ContentPart(
      type: type,
      text: isThink ? null : delta,
      think: isThink ? delta : null,
      agentId: agentId,
    ),
  ];
}

bool _isTool(ContentPart p, String id) =>
    p.type == ContentPartType.toolCall && p.toolCall?.id == id;

/// Applies [update] to the `tool_call` part for [id], or to a new one added
/// at the end.
List<ContentPart> _upsertTool(
  List<ContentPart> parts,
  String id,
  String? agentId,
  ContentPart Function(ContentPart) update,
) {
  final i = parts.indexWhere((p) => _isTool(p, id));
  if (i < 0) {
    return [
      ...parts,
      update(
        ContentPart(
          type: ContentPartType.toolCall,
          toolCall: ToolCall(id: id),
          agentId: agentId,
        ),
      ),
    ];
  }
  return [...parts]..[i] = update(parts[i]);
}

/// Replaces the attachment with [next]'s `file_id`, keeping the fields
/// [next] leaves out. One without a `file_id` is added.
List<Attachment> _upsertAttachment(List<Attachment> list, Attachment next) {
  final id = next.fileId;
  final i = id == null ? -1 : list.indexWhere((a) => a.fileId == id);
  if (i < 0) return [...list, next];
  final merged = Attachment.fromJson({
    ...list[i].toJson(),
    ...next.toJson()..removeWhere((_, v) => v == null),
  });
  return [...list]..[i] = merged;
}

/// `start` and content phases mean running, `stop` done and `error`
/// failed. A content phase never revives a finished subagent.
RunState _subagent(RunState s, SubagentUpdate e) {
  final id = e.subagentRunId ?? e.parentToolCallId;
  if (id == null) return s;
  final old = s.subagents[id];
  final status = switch (e.phase) {
    'start' => SubagentStatus.running,
    'stop' => SubagentStatus.done,
    'error' => SubagentStatus.failed,
    _ => old?.status ?? SubagentStatus.running,
  };
  return s.copyWith(
    subagents: {
      ...s.subagents,
      id: SubagentProgress(
        status: status,
        parentToolCallId: e.parentToolCallId ?? old?.parentToolCallId,
        label: e.label ?? old?.label,
        type: e.subagentType ?? old?.type,
      ),
    },
  );
}
