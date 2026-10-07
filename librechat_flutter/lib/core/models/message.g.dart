// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  messageId: json['messageId'] as String,
  conversationId: json['conversationId'] as String,
  parentMessageId: json['parentMessageId'] as String?,
  sender: json['sender'] as String?,
  text: json['text'] as String? ?? '',
  isCreatedByUser: json['isCreatedByUser'] as bool? ?? false,
  endpoint: json['endpoint'] as String?,
  model: json['model'] as String?,
  error: json['error'] as bool? ?? false,
  unfinished: json['unfinished'] as bool? ?? false,
  content: (json['content'] as List<dynamic>?)
      ?.map((e) => ContentPart.fromJson(e as Map<String, dynamic>))
      .toList(),
  files: (json['files'] as List<dynamic>?)
      ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
      .toList(),
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
      .toList(),
  feedback: json['feedback'] == null
      ? null
      : MessageFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
  quotes: (json['quotes'] as List<dynamic>?)?.map((e) => e as String).toList(),
  createdAt: const UtcDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const UtcDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'messageId': instance.messageId,
  'conversationId': instance.conversationId,
  'parentMessageId': ?instance.parentMessageId,
  'sender': ?instance.sender,
  'text': instance.text,
  'isCreatedByUser': instance.isCreatedByUser,
  'endpoint': ?instance.endpoint,
  'model': ?instance.model,
  'error': instance.error,
  'unfinished': instance.unfinished,
  'content': ?instance.content?.map((e) => e.toJson()).toList(),
  'files': ?instance.files?.map((e) => e.toJson()).toList(),
  'attachments': ?instance.attachments?.map((e) => e.toJson()).toList(),
  'feedback': ?instance.feedback?.toJson(),
  'quotes': ?instance.quotes,
  'createdAt': ?const UtcDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': ?const UtcDateTimeConverter().toJson(instance.updatedAt),
};

_MessageFeedback _$MessageFeedbackFromJson(Map<String, dynamic> json) =>
    _MessageFeedback(
      rating: $enumDecodeNullable(
        _$FeedbackRatingEnumMap,
        json['rating'],
        unknownValue: FeedbackRating.unknown,
      ),
      tag: json['tag'],
      text: json['text'] as String?,
    );

Map<String, dynamic> _$MessageFeedbackToJson(_MessageFeedback instance) =>
    <String, dynamic>{
      'rating': ?_$FeedbackRatingEnumMap[instance.rating],
      'tag': ?instance.tag,
      'text': ?instance.text,
    };

const _$FeedbackRatingEnumMap = {
  FeedbackRating.thumbsUp: 'thumbsUp',
  FeedbackRating.thumbsDown: 'thumbsDown',
  FeedbackRating.unknown: 'unknown',
};
