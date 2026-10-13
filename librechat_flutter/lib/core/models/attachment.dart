import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

/// A file on a message: `Message.files`, `Message.attachments` and `attachment` stream events.
/// The tool result payloads stay raw.
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    @JsonKey(name: 'file_id') String? fileId,
    String? filename,
    String? filepath,
    String? type,
    int? bytes,
    int? width,
    int? height,
    String? messageId,
    String? toolCallId,
    // An office preview's lifecycle (`pending`, `ready`, `failed`) and, once
    // ready, its extracted body: `textFormat` is `html` or `text`.
    String? status,
    String? text,
    String? textFormat,
    String? previewError,
    @JsonKey(name: 'web_search') Map<String, Object?>? webSearch,
    @JsonKey(name: 'file_search') Map<String, Object?>? fileSearch,
    Map<String, Object?>? memory,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, Object?> json) =>
      _$AttachmentFromJson(json);
}
