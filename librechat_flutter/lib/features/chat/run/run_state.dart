import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/attachment.dart';
import '../../../core/models/content_part.dart';
import '../../../core/models/message.dart';
import '../../../core/models/pending_action.dart';
import '../send/chat_turn.dart';

part 'run_state.freezed.dart';

/// Where a Run's Stream is. `stopping` and `pendingAction` on [RunState]
/// apply in every phase.
enum RunPhase { starting, streaming, reconnecting, detached }

/// A subagent's state, from its `on_subagent_update` phases.
enum SubagentStatus { running, done, failed }

/// One subagent of a Run, shown as a progress card (Req 31.3).
@freezed
abstract class SubagentProgress with _$SubagentProgress {
  const factory SubagentProgress({
    required SubagentStatus status,
    String? parentToolCallId,
    String? label,
    String? type,
  }) = _SubagentProgress;
}

/// One live Run, as RunService holds it under [key]: the conversation id,
/// or a landing visit's `new:<uuid>` until `created` arrives.
///
/// [parts] and [attachments] are the streaming reply, which `reduce` in
/// `run_reducer.dart` builds from the Stream's events. [optimistic] is the
/// Optimistic_Message of a send or edit, and [anchorId] the message the live
/// reply renders under (see `activePath`). [epoch] tells a Run's own timers
/// and callbacks from a stale one's.
@freezed
abstract class RunState with _$RunState {
  const RunState._();

  const factory RunState({
    required String key,
    required TurnKind kind,
    required ChatSelection selection,
    String? conversationId,
    String? streamId,
    String? requestMessageId,
    int? generationCreatedAt,
    @Default(false) bool isTemporary,
    @Default(false) bool isComparison,
    @Default(false) bool firstRunOfNewChat,
    Message? optimistic,
    String? anchorId,
    @Default(RunPhase.starting) RunPhase phase,
    @Default(0) int attempt,
    @Default(false) bool resumedOnce,
    @Default(false) bool stopping,
    @Default(<ContentPart>[]) List<ContentPart> parts,
    @Default(<Attachment>[]) List<Attachment> attachments,
    PendingAction? pendingAction,
    String? actionError,
    @Default(<String, SubagentProgress>{})
    Map<String, SubagentProgress> subagents,
    String? title,
    String? error,
    @Default(0) int epoch,
  }) = _RunState;

  /// Whether the reply has shown anything yet. Until then the Chat_Screen
  /// shows the waiting indicator (Req 18.9).
  bool get hasContent => parts.isNotEmpty || attachments.isNotEmpty;

  /// Whether the Composer's Stop control is enabled. Stop shows for a Run in
  /// every phase, a paused one included (Req 20.1), and is disabled while a
  /// Stop is pending (Req 20.8).
  bool get canStop => !stopping;
}

/// RunService's state.
///
/// - [runs]: the live Runs, by conversation id or a landing visit's
///   `new:<uuid>` key.
/// - [movedTo]: `new:<uuid>` → the conversation id its Run moved to on
///   `created`. The new-chat screen listens to its key and goes to the
///   conversation's route, where the same Run keeps rendering (Req 18.10).
/// - [errors]: the error of a Run that ended with no reply to show it in,
///   by Run key: a failed start, or an error before a new chat's `created`.
///   The Run was un-sent, and the screen shows the error as a banner, then
///   calls `RunService.dismissError`.
@freezed
abstract class ConversationRuns with _$ConversationRuns {
  const factory ConversationRuns({
    @Default(<String, RunState>{}) Map<String, RunState> runs,
    @Default(<String, String>{}) Map<String, String> movedTo,
    @Default(<String, String>{}) Map<String, String> errors,
  }) = _ConversationRuns;
}
