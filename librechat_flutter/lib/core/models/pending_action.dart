import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_action.freezed.dart';
part 'pending_action.g.dart';

/// A run paused for the user: tool approvals or one ask-user question. Comes
/// from the `on_pending_action` stream event, the Sync_Frame's
/// `resumeState.pendingAction` and the run status. [payload] stays raw; the
/// card that renders it reads its fields. [expiresAt] is epoch ms.
@freezed
abstract class PendingAction with _$PendingAction {
  const factory PendingAction({
    String? actionId,
    String? streamId,
    String? conversationId,
    String? runId,
    Map<String, Object?>? payload,
    int? expiresAt,
  }) = _PendingAction;

  factory PendingAction.fromJson(Map<String, Object?> json) =>
      _$PendingActionFromJson(json);
}
