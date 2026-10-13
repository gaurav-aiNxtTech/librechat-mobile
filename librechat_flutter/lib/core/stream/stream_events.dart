import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/attachment.dart';
import '../models/content_part.dart';
import '../models/context_usage.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/pending_action.dart';
import '../models/pending_steer.dart';
import '../models/token_usage.dart';
import '../network/app_exception.dart';

part 'stream_events.freezed.dart';

/// What a Run's stream reports: the wire events that EventMapper decodes from
/// SSE frames, plus four that StreamClient emits about the connection itself
/// ([StreamReconnecting], [StreamExpired], [StreamRetryExhausted] and
/// [StreamFailed]).
///
/// `agentId` on content events is the agent that produced them, resolved by
/// EventMapper's step attribution, so comparison panes can split two agents'
/// interleaved steps.
@freezed
sealed class StreamEvent with _$StreamEvent {
  /// `on_message_delta` (joined `text` parts) or a legacy `content`/`text`
  /// frame.
  const factory StreamEvent.textDelta(String text, {String? agentId}) =
      TextDelta;

  /// `on_reasoning_delta` (joined `think` parts) or a legacy
  /// `thinking`/`think` frame.
  const factory StreamEvent.thinkDelta(String think, {String? agentId}) =
      ThinkDelta;

  /// `on_run_step` announcing a tool call, or a legacy `tool_call_start`.
  /// [args] is raw: a map mid-stream or a JSON string.
  const factory StreamEvent.toolCallStarted({
    required String id,
    String? name,
    Object? args,
    String? agentId,
  }) = ToolCallStarted;

  /// `on_run_step_completed` (`result.tool_call`), or a legacy
  /// `tool_call_complete`. A non-string output arrives JSON-encoded.
  const factory StreamEvent.toolCallCompleted({
    required String toolCallId,
    String? output,
    String? agentId,
  }) = ToolCallCompleted;

  /// `on_run_step_closed`: the step announced for [toolCallId] reached a
  /// terminal [status] such as `completed` or `cancelled`.
  const factory StreamEvent.toolCallClosed({
    required String toolCallId,
    required String status,
    String? agentId,
  }) = ToolCallClosed;

  /// `on_summarize_complete`: the text parts of `data.summary.content`.
  const factory StreamEvent.summary(String text, {String? agentId}) =
      SummaryEvent;

  /// `on_subagent_update`: one step of a subagent's trace.
  const factory StreamEvent.subagentUpdate({
    required String phase,
    String? parentToolCallId,
    String? subagentRunId,
    String? subagentType,
    String? label,
  }) = SubagentUpdate;

  /// SSE `event: attachment` / `librechat:attachment`, or the LangGraph
  /// `attachment` event. An office preview's `status`, `text`, `textFormat`
  /// and `previewError` ride on the [Attachment].
  const factory StreamEvent.attachment(Attachment attachment) = AttachmentEvent;

  /// `title`: the Server named the conversation mid-stream.
  const factory StreamEvent.title({
    String? conversationId,
    required String title,
  }) = TitleEvent;

  /// `on_token_usage`.
  const factory StreamEvent.tokenUsage(TokenUsage usage) = TokenUsageEvent;

  /// `on_context_usage`.
  const factory StreamEvent.contextUsage(ContextUsage usage) =
      ContextUsageEvent;

  /// `on_pending_action`, or a Sync_Frame's `resumeState.pendingAction`.
  const factory StreamEvent.pendingAction(PendingAction action) =
      PendingActionEvent;

  /// `on_steer_applied`: a queued steer went into the live run. [part] is
  /// the injected `steer` content part.
  const factory StreamEvent.steerApplied({
    required String steerId,
    String? clientSteerId,
    int? index,
    ContentPart? part,
  }) = SteerApplied;

  /// A Sync_Frame's `resumeState.aggregatedContent`: the reply so far.
  const factory StreamEvent.syncSnapshot(List<ContentPart> parts) =
      SyncSnapshot;

  /// A Sync_Frame's `resumeState.pendingSteers`: every steer still queued.
  /// Empty when the key is absent, because the Server omits an empty queue.
  const factory StreamEvent.steersSynced(List<PendingSteer> steers) =
      SteersSynced;

  /// `{"final": true, …}`: the Run ended. [responseMessage] falls back to the
  /// frame's `message`. [pendingSteers] are steers the run never injected.
  const factory StreamEvent.finalFrame({
    Conversation? conversation,
    Message? requestMessage,
    Message? responseMessage,
    @Default(false) bool aborted,
    @Default(false) bool earlyAbort,
    @Default(<PendingSteer>[]) List<PendingSteer> pendingSteers,
  }) = FinalEvent;

  /// `created`: the Server stored the request message.
  const factory StreamEvent.created({
    String? conversationId,
    String? messageId,
    String? parentMessageId,
  }) = CreatedEvent;

  /// An `error` key: the Server's error text.
  const factory StreamEvent.streamError(String text) = StreamError;

  /// StreamClient: attempt [attempt] (1–5) failed and a reconnect follows.
  const factory StreamEvent.reconnecting(int attempt) = StreamReconnecting;

  /// StreamClient: the stream is gone (HTTP 404).
  const factory StreamEvent.expired() = StreamExpired;

  /// StreamClient: the fifth reconnect failed.
  const factory StreamEvent.retryExhausted() = StreamRetryExhausted;

  /// StreamClient: a failure no reconnect can fix, such as a rejected
  /// refresh or an access gateway.
  const factory StreamEvent.failed(AppException error) = StreamFailed;
}
