// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Message {

 String get messageId; String get conversationId; String? get parentMessageId; String? get sender; String get text; bool get isCreatedByUser; String? get endpoint; String? get model; bool get error; bool get unfinished; List<ContentPart>? get content; List<Attachment>? get files; List<Attachment>? get attachments; MessageFeedback? get feedback; List<String>? get quotes;@UtcDateTimeConverter() DateTime? get createdAt;@UtcDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.text, text) || other.text == text)&&(identical(other.isCreatedByUser, isCreatedByUser) || other.isCreatedByUser == isCreatedByUser)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.model, model) || other.model == model)&&(identical(other.error, error) || other.error == error)&&(identical(other.unfinished, unfinished) || other.unfinished == unfinished)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.files, files)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&const DeepCollectionEquality().equals(other.quotes, quotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,parentMessageId,sender,text,isCreatedByUser,endpoint,model,error,unfinished,const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(files),const DeepCollectionEquality().hash(attachments),feedback,const DeepCollectionEquality().hash(quotes),createdAt,updatedAt);

@override
String toString() {
  return 'Message(messageId: $messageId, conversationId: $conversationId, parentMessageId: $parentMessageId, sender: $sender, text: $text, isCreatedByUser: $isCreatedByUser, endpoint: $endpoint, model: $model, error: $error, unfinished: $unfinished, content: $content, files: $files, attachments: $attachments, feedback: $feedback, quotes: $quotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String messageId, String conversationId, String? parentMessageId, String? sender, String text, bool isCreatedByUser, String? endpoint, String? model, bool error, bool unfinished, List<ContentPart>? content, List<Attachment>? files, List<Attachment>? attachments, MessageFeedback? feedback, List<String>? quotes,@UtcDateTimeConverter() DateTime? createdAt,@UtcDateTimeConverter() DateTime? updatedAt
});


$MessageFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? conversationId = null,Object? parentMessageId = freezed,Object? sender = freezed,Object? text = null,Object? isCreatedByUser = null,Object? endpoint = freezed,Object? model = freezed,Object? error = null,Object? unfinished = null,Object? content = freezed,Object? files = freezed,Object? attachments = freezed,Object? feedback = freezed,Object? quotes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isCreatedByUser: null == isCreatedByUser ? _self.isCreatedByUser : isCreatedByUser // ignore: cast_nullable_to_non_nullable
as bool,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as bool,unfinished: null == unfinished ? _self.unfinished : unfinished // ignore: cast_nullable_to_non_nullable
as bool,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<ContentPart>?,files: freezed == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>?,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MessageFeedback?,quotes: freezed == quotes ? _self.quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $MessageFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String? parentMessageId,  String? sender,  String text,  bool isCreatedByUser,  String? endpoint,  String? model,  bool error,  bool unfinished,  List<ContentPart>? content,  List<Attachment>? files,  List<Attachment>? attachments,  MessageFeedback? feedback,  List<String>? quotes, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.parentMessageId,_that.sender,_that.text,_that.isCreatedByUser,_that.endpoint,_that.model,_that.error,_that.unfinished,_that.content,_that.files,_that.attachments,_that.feedback,_that.quotes,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String? parentMessageId,  String? sender,  String text,  bool isCreatedByUser,  String? endpoint,  String? model,  bool error,  bool unfinished,  List<ContentPart>? content,  List<Attachment>? files,  List<Attachment>? attachments,  MessageFeedback? feedback,  List<String>? quotes, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.messageId,_that.conversationId,_that.parentMessageId,_that.sender,_that.text,_that.isCreatedByUser,_that.endpoint,_that.model,_that.error,_that.unfinished,_that.content,_that.files,_that.attachments,_that.feedback,_that.quotes,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String conversationId,  String? parentMessageId,  String? sender,  String text,  bool isCreatedByUser,  String? endpoint,  String? model,  bool error,  bool unfinished,  List<ContentPart>? content,  List<Attachment>? files,  List<Attachment>? attachments,  MessageFeedback? feedback,  List<String>? quotes, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.parentMessageId,_that.sender,_that.text,_that.isCreatedByUser,_that.endpoint,_that.model,_that.error,_that.unfinished,_that.content,_that.files,_that.attachments,_that.feedback,_that.quotes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({required this.messageId, required this.conversationId, this.parentMessageId, this.sender, this.text = '', this.isCreatedByUser = false, this.endpoint, this.model, this.error = false, this.unfinished = false, final  List<ContentPart>? content, final  List<Attachment>? files, final  List<Attachment>? attachments, this.feedback, final  List<String>? quotes, @UtcDateTimeConverter() this.createdAt, @UtcDateTimeConverter() this.updatedAt}): _content = content,_files = files,_attachments = attachments,_quotes = quotes;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String messageId;
@override final  String conversationId;
@override final  String? parentMessageId;
@override final  String? sender;
@override@JsonKey() final  String text;
@override@JsonKey() final  bool isCreatedByUser;
@override final  String? endpoint;
@override final  String? model;
@override@JsonKey() final  bool error;
@override@JsonKey() final  bool unfinished;
 final  List<ContentPart>? _content;
@override List<ContentPart>? get content {
  final value = _content;
  if (value == null) return null;
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Attachment>? _files;
@override List<Attachment>? get files {
  final value = _files;
  if (value == null) return null;
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Attachment>? _attachments;
@override List<Attachment>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  MessageFeedback? feedback;
 final  List<String>? _quotes;
@override List<String>? get quotes {
  final value = _quotes;
  if (value == null) return null;
  if (_quotes is EqualUnmodifiableListView) return _quotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@UtcDateTimeConverter() final  DateTime? createdAt;
@override@UtcDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.text, text) || other.text == text)&&(identical(other.isCreatedByUser, isCreatedByUser) || other.isCreatedByUser == isCreatedByUser)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.model, model) || other.model == model)&&(identical(other.error, error) || other.error == error)&&(identical(other.unfinished, unfinished) || other.unfinished == unfinished)&&const DeepCollectionEquality().equals(other._content, _content)&&const DeepCollectionEquality().equals(other._files, _files)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&const DeepCollectionEquality().equals(other._quotes, _quotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,parentMessageId,sender,text,isCreatedByUser,endpoint,model,error,unfinished,const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_files),const DeepCollectionEquality().hash(_attachments),feedback,const DeepCollectionEquality().hash(_quotes),createdAt,updatedAt);

@override
String toString() {
  return 'Message(messageId: $messageId, conversationId: $conversationId, parentMessageId: $parentMessageId, sender: $sender, text: $text, isCreatedByUser: $isCreatedByUser, endpoint: $endpoint, model: $model, error: $error, unfinished: $unfinished, content: $content, files: $files, attachments: $attachments, feedback: $feedback, quotes: $quotes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String conversationId, String? parentMessageId, String? sender, String text, bool isCreatedByUser, String? endpoint, String? model, bool error, bool unfinished, List<ContentPart>? content, List<Attachment>? files, List<Attachment>? attachments, MessageFeedback? feedback, List<String>? quotes,@UtcDateTimeConverter() DateTime? createdAt,@UtcDateTimeConverter() DateTime? updatedAt
});


@override $MessageFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? conversationId = null,Object? parentMessageId = freezed,Object? sender = freezed,Object? text = null,Object? isCreatedByUser = null,Object? endpoint = freezed,Object? model = freezed,Object? error = null,Object? unfinished = null,Object? content = freezed,Object? files = freezed,Object? attachments = freezed,Object? feedback = freezed,Object? quotes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Message(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,isCreatedByUser: null == isCreatedByUser ? _self.isCreatedByUser : isCreatedByUser // ignore: cast_nullable_to_non_nullable
as bool,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as bool,unfinished: null == unfinished ? _self.unfinished : unfinished // ignore: cast_nullable_to_non_nullable
as bool,content: freezed == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<ContentPart>?,files: freezed == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>?,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as MessageFeedback?,quotes: freezed == quotes ? _self._quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $MessageFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// @nodoc
mixin _$MessageFeedback {

@JsonKey(unknownEnumValue: FeedbackRating.unknown) FeedbackRating? get rating; Object? get tag; String? get text;
/// Create a copy of MessageFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageFeedbackCopyWith<MessageFeedback> get copyWith => _$MessageFeedbackCopyWithImpl<MessageFeedback>(this as MessageFeedback, _$identity);

  /// Serializes this MessageFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageFeedback&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.tag, tag)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rating,const DeepCollectionEquality().hash(tag),text);

@override
String toString() {
  return 'MessageFeedback(rating: $rating, tag: $tag, text: $text)';
}


}

/// @nodoc
abstract mixin class $MessageFeedbackCopyWith<$Res>  {
  factory $MessageFeedbackCopyWith(MessageFeedback value, $Res Function(MessageFeedback) _then) = _$MessageFeedbackCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: FeedbackRating.unknown) FeedbackRating? rating, Object? tag, String? text
});




}
/// @nodoc
class _$MessageFeedbackCopyWithImpl<$Res>
    implements $MessageFeedbackCopyWith<$Res> {
  _$MessageFeedbackCopyWithImpl(this._self, this._then);

  final MessageFeedback _self;
  final $Res Function(MessageFeedback) _then;

/// Create a copy of MessageFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rating = freezed,Object? tag = freezed,Object? text = freezed,}) {
  return _then(_self.copyWith(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as FeedbackRating?,tag: freezed == tag ? _self.tag : tag ,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageFeedback].
extension MessageFeedbackPatterns on MessageFeedback {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageFeedback() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageFeedback value)  $default,){
final _that = this;
switch (_that) {
case _MessageFeedback():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _MessageFeedback() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: FeedbackRating.unknown)  FeedbackRating? rating,  Object? tag,  String? text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageFeedback() when $default != null:
return $default(_that.rating,_that.tag,_that.text);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: FeedbackRating.unknown)  FeedbackRating? rating,  Object? tag,  String? text)  $default,) {final _that = this;
switch (_that) {
case _MessageFeedback():
return $default(_that.rating,_that.tag,_that.text);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: FeedbackRating.unknown)  FeedbackRating? rating,  Object? tag,  String? text)?  $default,) {final _that = this;
switch (_that) {
case _MessageFeedback() when $default != null:
return $default(_that.rating,_that.tag,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageFeedback implements MessageFeedback {
  const _MessageFeedback({@JsonKey(unknownEnumValue: FeedbackRating.unknown) this.rating, this.tag, this.text});
  factory _MessageFeedback.fromJson(Map<String, dynamic> json) => _$MessageFeedbackFromJson(json);

@override@JsonKey(unknownEnumValue: FeedbackRating.unknown) final  FeedbackRating? rating;
@override final  Object? tag;
@override final  String? text;

/// Create a copy of MessageFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageFeedbackCopyWith<_MessageFeedback> get copyWith => __$MessageFeedbackCopyWithImpl<_MessageFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageFeedback&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.tag, tag)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rating,const DeepCollectionEquality().hash(tag),text);

@override
String toString() {
  return 'MessageFeedback(rating: $rating, tag: $tag, text: $text)';
}


}

/// @nodoc
abstract mixin class _$MessageFeedbackCopyWith<$Res> implements $MessageFeedbackCopyWith<$Res> {
  factory _$MessageFeedbackCopyWith(_MessageFeedback value, $Res Function(_MessageFeedback) _then) = __$MessageFeedbackCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: FeedbackRating.unknown) FeedbackRating? rating, Object? tag, String? text
});




}
/// @nodoc
class __$MessageFeedbackCopyWithImpl<$Res>
    implements _$MessageFeedbackCopyWith<$Res> {
  __$MessageFeedbackCopyWithImpl(this._self, this._then);

  final _MessageFeedback _self;
  final $Res Function(_MessageFeedback) _then;

/// Create a copy of MessageFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rating = freezed,Object? tag = freezed,Object? text = freezed,}) {
  return _then(_MessageFeedback(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as FeedbackRating?,tag: freezed == tag ? _self.tag : tag ,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
