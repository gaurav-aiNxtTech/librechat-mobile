// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Attachment _$AttachmentFromJson(Map<String, dynamic> json) => _Attachment(
  fileId: json['file_id'] as String?,
  filename: json['filename'] as String?,
  filepath: json['filepath'] as String?,
  type: json['type'] as String?,
  bytes: (json['bytes'] as num?)?.toInt(),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  messageId: json['messageId'] as String?,
  toolCallId: json['toolCallId'] as String?,
  status: json['status'] as String?,
  text: json['text'] as String?,
  textFormat: json['textFormat'] as String?,
  previewError: json['previewError'] as String?,
  webSearch: json['web_search'] as Map<String, dynamic>?,
  fileSearch: json['file_search'] as Map<String, dynamic>?,
  memory: json['memory'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AttachmentToJson(_Attachment instance) =>
    <String, dynamic>{
      'file_id': ?instance.fileId,
      'filename': ?instance.filename,
      'filepath': ?instance.filepath,
      'type': ?instance.type,
      'bytes': ?instance.bytes,
      'width': ?instance.width,
      'height': ?instance.height,
      'messageId': ?instance.messageId,
      'toolCallId': ?instance.toolCallId,
      'status': ?instance.status,
      'text': ?instance.text,
      'textFormat': ?instance.textFormat,
      'previewError': ?instance.previewError,
      'web_search': ?instance.webSearch,
      'file_search': ?instance.fileSearch,
      'memory': ?instance.memory,
    };
