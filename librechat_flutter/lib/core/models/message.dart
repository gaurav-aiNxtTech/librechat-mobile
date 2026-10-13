import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment.dart';
import 'content_part.dart';
import 'json_converters.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// `GET /api/messages/{conversationId}` items and the Final_Frame messages.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required String messageId,
    required String conversationId,
    String? parentMessageId,
    String? sender,
    @Default('') String text,
    @Default(false) bool isCreatedByUser,
    String? endpoint,
    String? model,
    @Default(false) bool error,
    @Default(false) bool unfinished,
    List<ContentPart>? content,
    List<Attachment>? files,
    List<Attachment>? attachments,
    MessageFeedback? feedback,
    List<String>? quotes,
    @UtcDateTimeConverter() DateTime? createdAt,
    @UtcDateTimeConverter() DateTime? updatedAt,
  }) = _Message;

  factory Message.fromJson(Map<String, Object?> json) =>
      _$MessageFromJson(json);
}

enum FeedbackRating { thumbsUp, thumbsDown, unknown }

/// `Message.feedback`. `tag` stays raw.
@freezed
abstract class MessageFeedback with _$MessageFeedback {
  const factory MessageFeedback({
    @JsonKey(unknownEnumValue: FeedbackRating.unknown) FeedbackRating? rating,
    Object? tag,
    String? text,
  }) = _MessageFeedback;

  factory MessageFeedback.fromJson(Map<String, Object?> json) =>
      _$MessageFeedbackFromJson(json);
}
