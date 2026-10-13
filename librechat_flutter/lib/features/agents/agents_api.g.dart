// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Agent _$AgentFromJson(Map<String, dynamic> json) => _Agent(
  id: json['id'] as String,
  name: json['name'] as String?,
  description: json['description'] as String?,
  avatarPath: const AvatarPathConverter().fromJson(json['avatar']),
  conversationStarters:
      (json['conversation_starters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  isPublic: json['isPublic'] as bool?,
);

Map<String, dynamic> _$AgentToJson(_Agent instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'description': ?instance.description,
  'avatar': ?const AvatarPathConverter().toJson(instance.avatarPath),
  'conversation_starters': instance.conversationStarters,
  'isPublic': ?instance.isPublic,
};
