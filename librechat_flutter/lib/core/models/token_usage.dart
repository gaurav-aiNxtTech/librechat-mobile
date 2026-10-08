import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_usage.freezed.dart';
part 'token_usage.g.dart';

/// One model call's token counts, from the `on_token_usage` stream event.
/// [usageType] is set for side calls such as `activity-label` and null for
/// the turn's own model call.
@freezed
abstract class TokenUsage with _$TokenUsage {
  const factory TokenUsage({
    @JsonKey(name: 'input_tokens') int? inputTokens,
    @JsonKey(name: 'output_tokens') int? outputTokens,
    @JsonKey(name: 'total_tokens') int? totalTokens,
    String? model,
    String? provider,
    @JsonKey(name: 'usage_type') String? usageType,
  }) = _TokenUsage;

  factory TokenUsage.fromJson(Map<String, Object?> json) =>
      _$TokenUsageFromJson(json);
}
