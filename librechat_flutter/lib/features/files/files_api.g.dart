// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'files_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileObject _$FileObjectFromJson(Map<String, dynamic> json) => _FileObject(
  fileId: json['file_id'] as String?,
  filename: json['filename'] as String?,
  filepath: json['filepath'] as String?,
  type: json['type'] as String?,
  bytes: (json['bytes'] as num?)?.toInt(),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  source: json['source'] as String?,
  user: json['user'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FileObjectToJson(_FileObject instance) =>
    <String, dynamic>{
      'file_id': ?instance.fileId,
      'filename': ?instance.filename,
      'filepath': ?instance.filepath,
      'type': ?instance.type,
      'bytes': ?instance.bytes,
      'width': ?instance.width,
      'height': ?instance.height,
      'source': ?instance.source,
      'user': ?instance.user,
      'createdAt': ?instance.createdAt?.toIso8601String(),
      'updatedAt': ?instance.updatedAt?.toIso8601String(),
    };
