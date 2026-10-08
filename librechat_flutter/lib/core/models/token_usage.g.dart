// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenUsage _$TokenUsageFromJson(Map<String, dynamic> json) => _TokenUsage(
  inputTokens: (json['input_tokens'] as num?)?.toInt(),
  outputTokens: (json['output_tokens'] as num?)?.toInt(),
  totalTokens: (json['total_tokens'] as num?)?.toInt(),
  model: json['model'] as String?,
  provider: json['provider'] as String?,
  usageType: json['usage_type'] as String?,
);

Map<String, dynamic> _$TokenUsageToJson(_TokenUsage instance) =>
    <String, dynamic>{
      'input_tokens': ?instance.inputTokens,
      'output_tokens': ?instance.outputTokens,
      'total_tokens': ?instance.totalTokens,
      'model': ?instance.model,
      'provider': ?instance.provider,
      'usage_type': ?instance.usageType,
    };
