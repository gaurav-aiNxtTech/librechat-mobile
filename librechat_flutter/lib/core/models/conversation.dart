import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_converters.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// `GET /api/convos` items and `GET /api/convos/{id}`. The model parameter fields follow the KMP
/// `Conversation`, plus `promptPrefix` and `modelLabel`.
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    String? conversationId,
    String? title,
    String? endpoint,
    String? endpointType,
    String? model,
    @JsonKey(name: 'agent_id') String? agentId,
    String? spec,
    String? iconURL,
    List<String>? tags,
    @Default(false) bool isArchived,
    bool? pinned,
    String? chatProjectId,
    bool? isTemporary,
    // Model parameters.
    double? temperature,
    @JsonKey(name: 'top_p') double? topP,
    int? topK,
    @JsonKey(name: 'frequency_penalty') double? frequencyPenalty,
    @JsonKey(name: 'presence_penalty') double? presencePenalty,
    int? maxOutputTokens,
    int? maxContextTokens,
    int? maxTokens,
    String? system,
    String? promptPrefix,
    String? modelLabel,
    @JsonKey(name: 'reasoning_effort') String? reasoningEffort,
    @JsonKey(name: 'reasoning_mode') String? reasoningMode,
    @JsonKey(name: 'reasoning_context') String? reasoningContext,
    String? effort,
    String? thinkingLevel,
    String? thinkingDisplay,
    List<String>? stop,
    @JsonKey(name: 'web_search') bool? webSearch,
    @JsonKey(name: 'url_context') bool? urlContext,
    String? promptCacheTtl,
    @UtcDateTimeConverter() DateTime? createdAt,
    @UtcDateTimeConverter() DateTime? updatedAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, Object?> json) => _$ConversationFromJson(json);
}
