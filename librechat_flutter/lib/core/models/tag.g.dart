// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tag _$TagFromJson(Map<String, dynamic> json) => _Tag(
  tag: json['tag'] as String,
  description: json['description'] as String?,
  count: (json['count'] as num?)?.toInt() ?? 0,
  position: (json['position'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TagToJson(_Tag instance) => <String, dynamic>{
  'tag': instance.tag,
  'description': ?instance.description,
  'count': instance.count,
  'position': instance.position,
};
