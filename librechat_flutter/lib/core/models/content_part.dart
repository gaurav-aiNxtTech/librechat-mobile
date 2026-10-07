import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_converters.dart';

part 'content_part.freezed.dart';
part 'content_part.g.dart';

/// The Server's content part `type` values. The type stays a String, so an unknown one decodes.
abstract final class ContentPartType {
  static const text = 'text';
  static const textDelta = 'text_delta';
  static const think = 'think';
  static const toolCall = 'tool_call';
  static const imageUrl = 'image_url';
  static const imageFile = 'image_file';
  static const videoUrl = 'video_url';
  static const inputAudio = 'input_audio';
  static const error = 'error';
  static const agentUpdate = 'agent_update';
  static const summary = 'summary';
  static const steer = 'steer';
  static const activityLabel = 'activity_label';
}

/// One flat part of `Message.content` and stream deltas. Media payloads stay raw:
/// `image_url` and `video_url` are a URL string or `{url, …}`, the others are objects.
@freezed
abstract class ContentPart with _$ContentPart {
  const factory ContentPart({
    required String type,
    @FlexibleTextConverter() String? text,
    String? think,
    @JsonKey(name: 'tool_call_ids') List<String>? toolCallIds,
    @JsonKey(name: 'tool_call') ToolCall? toolCall,
    @JsonKey(name: 'image_url') Object? imageUrl,
    @JsonKey(name: 'image_file') Map<String, Object?>? imageFile,
    @JsonKey(name: 'video_url') Object? videoUrl,
    @JsonKey(name: 'input_audio') Map<String, Object?>? inputAudio,
    String? error,
    @JsonKey(name: 'agent_update') Map<String, Object?>? agentUpdate,
    Map<String, Object?>? steer,
    @JsonKey(name: 'activity_label') String? activityLabel,
    @JsonKey(name: 'activity_label_type') String? activityLabelType,
    @JsonKey(name: 'activity_end_index') int? activityEndIndex,
    // An activity label's `failed` or `partial` batch status.
    String? status,
    // A summary's body: a string or a list of `{type, text}` blocks.
    Object? content,
    String? agentId,
    int? groupId,
    int? stepIndex,
  }) = _ContentPart;

  factory ContentPart.fromJson(Map<String, Object?> json) => _$ContentPartFromJson(json);
}

/// `ContentPart.tool_call`. `args` is a map mid-stream and a JSON string once saved.
@freezed
abstract class ToolCall with _$ToolCall {
  const factory ToolCall({
    String? id,
    String? name,
    String? type,
    Object? args,
    String? output,
    double? progress,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, Object?> json) => _$ToolCallFromJson(json);
}
