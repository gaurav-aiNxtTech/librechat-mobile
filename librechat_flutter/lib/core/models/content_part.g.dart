// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContentPart _$ContentPartFromJson(Map<String, dynamic> json) => _ContentPart(
  type: json['type'] as String,
  text: const FlexibleTextConverter().fromJson(json['text']),
  think: json['think'] as String?,
  toolCallIds: (json['tool_call_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  toolCall: json['tool_call'] == null
      ? null
      : ToolCall.fromJson(json['tool_call'] as Map<String, dynamic>),
  imageUrl: json['image_url'],
  imageFile: json['image_file'] as Map<String, dynamic>?,
  videoUrl: json['video_url'],
  inputAudio: json['input_audio'] as Map<String, dynamic>?,
  error: json['error'] as String?,
  agentUpdate: json['agent_update'] as Map<String, dynamic>?,
  steer: json['steer'],
  activityLabel: json['activity_label'] as String?,
  activityLabelType: json['activity_label_type'] as String?,
  activityEndIndex: (json['activity_end_index'] as num?)?.toInt(),
  pending: json['pending'] as bool?,
  status: json['status'] as String?,
  content: json['content'],
  agentId: json['agentId'] as String?,
  groupId: (json['groupId'] as num?)?.toInt(),
  stepIndex: (json['stepIndex'] as num?)?.toInt(),
);

Map<String, dynamic> _$ContentPartToJson(_ContentPart instance) =>
    <String, dynamic>{
      'type': instance.type,
      'text': ?const FlexibleTextConverter().toJson(instance.text),
      'think': ?instance.think,
      'tool_call_ids': ?instance.toolCallIds,
      'tool_call': ?instance.toolCall?.toJson(),
      'image_url': ?instance.imageUrl,
      'image_file': ?instance.imageFile,
      'video_url': ?instance.videoUrl,
      'input_audio': ?instance.inputAudio,
      'error': ?instance.error,
      'agent_update': ?instance.agentUpdate,
      'steer': ?instance.steer,
      'activity_label': ?instance.activityLabel,
      'activity_label_type': ?instance.activityLabelType,
      'activity_end_index': ?instance.activityEndIndex,
      'pending': ?instance.pending,
      'status': ?instance.status,
      'content': ?instance.content,
      'agentId': ?instance.agentId,
      'groupId': ?instance.groupId,
      'stepIndex': ?instance.stepIndex,
    };

_ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => _ToolCall(
  id: json['id'] as String?,
  name: json['name'] as String?,
  type: json['type'] as String?,
  args: json['args'],
  output: json['output'] as String?,
  progress: (json['progress'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ToolCallToJson(_ToolCall instance) => <String, dynamic>{
  'id': ?instance.id,
  'name': ?instance.name,
  'type': ?instance.type,
  'args': ?instance.args,
  'output': ?instance.output,
  'progress': ?instance.progress,
};
