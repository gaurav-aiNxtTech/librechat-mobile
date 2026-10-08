import 'package:freezed_annotation/freezed_annotation.dart';

part 'context_usage.freezed.dart';
part 'context_usage.g.dart';

/// How much of the context window a run uses, from the `on_context_usage`
/// stream event. [breakdown] stays raw.
@freezed
abstract class ContextUsage with _$ContextUsage {
  const factory ContextUsage({
    int? contextBudget,
    int? remainingContextTokens,
    int? prePruneContextTokens,
    Map<String, Object?>? breakdown,
    String? runId,
    String? agentId,
  }) = _ContextUsage;

  factory ContextUsage.fromJson(Map<String, Object?> json) =>
      _$ContextUsageFromJson(json);
}
