import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_steer.freezed.dart';
part 'pending_steer.g.dart';

/// A steer queued for a live run and not yet injected. Comes from the steer
/// response, the Sync_Frame's `resumeState.pendingSteers` and the Final_Frame's
/// `pendingSteers`. [createdAt] is epoch ms.
@freezed
abstract class PendingSteer with _$PendingSteer {
  const factory PendingSteer({
    String? steerId,
    String? clientSteerId,
    String? text,
    List<String>? quotes,
    int? createdAt,
  }) = _PendingSteer;

  factory PendingSteer.fromJson(Map<String, Object?> json) =>
      _$PendingSteerFromJson(json);
}
