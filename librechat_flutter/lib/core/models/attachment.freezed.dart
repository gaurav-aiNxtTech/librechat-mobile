// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Attachment {

@JsonKey(name: 'file_id') String? get fileId; String? get filename; String? get filepath; String? get type; int? get bytes; int? get width; int? get height; String? get messageId; String? get toolCallId;// An office preview's lifecycle (`pending`, `ready`, `failed`) and, once
// ready, its extracted body: `textFormat` is `html` or `text`.
 String? get status; String? get text; String? get textFormat; String? get previewError;@JsonKey(name: 'web_search') Map<String, Object?>? get webSearch;@JsonKey(name: 'file_search') Map<String, Object?>? get fileSearch; Map<String, Object?>? get memory;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);

  /// Serializes this Attachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.filepath, filepath) || other.filepath == filepath)&&(identical(other.type, type) || other.type == type)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.status, status) || other.status == status)&&(identical(other.text, text) || other.text == text)&&(identical(other.textFormat, textFormat) || other.textFormat == textFormat)&&(identical(other.previewError, previewError) || other.previewError == previewError)&&const DeepCollectionEquality().equals(other.webSearch, webSearch)&&const DeepCollectionEquality().equals(other.fileSearch, fileSearch)&&const DeepCollectionEquality().equals(other.memory, memory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,filename,filepath,type,bytes,width,height,messageId,toolCallId,status,text,textFormat,previewError,const DeepCollectionEquality().hash(webSearch),const DeepCollectionEquality().hash(fileSearch),const DeepCollectionEquality().hash(memory));

@override
String toString() {
  return 'Attachment(fileId: $fileId, filename: $filename, filepath: $filepath, type: $type, bytes: $bytes, width: $width, height: $height, messageId: $messageId, toolCallId: $toolCallId, status: $status, text: $text, textFormat: $textFormat, previewError: $previewError, webSearch: $webSearch, fileSearch: $fileSearch, memory: $memory)';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'file_id') String? fileId, String? filename, String? filepath, String? type, int? bytes, int? width, int? height, String? messageId, String? toolCallId, String? status, String? text, String? textFormat, String? previewError,@JsonKey(name: 'web_search') Map<String, Object?>? webSearch,@JsonKey(name: 'file_search') Map<String, Object?>? fileSearch, Map<String, Object?>? memory
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = freezed,Object? filename = freezed,Object? filepath = freezed,Object? type = freezed,Object? bytes = freezed,Object? width = freezed,Object? height = freezed,Object? messageId = freezed,Object? toolCallId = freezed,Object? status = freezed,Object? text = freezed,Object? textFormat = freezed,Object? previewError = freezed,Object? webSearch = freezed,Object? fileSearch = freezed,Object? memory = freezed,}) {
  return _then(_self.copyWith(
fileId: freezed == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,filepath: freezed == filepath ? _self.filepath : filepath // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,textFormat: freezed == textFormat ? _self.textFormat : textFormat // ignore: cast_nullable_to_non_nullable
as String?,previewError: freezed == previewError ? _self.previewError : previewError // ignore: cast_nullable_to_non_nullable
as String?,webSearch: freezed == webSearch ? _self.webSearch : webSearch // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,fileSearch: freezed == fileSearch ? _self.fileSearch : fileSearch // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,memory: freezed == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? messageId,  String? toolCallId,  String? status,  String? text,  String? textFormat,  String? previewError, @JsonKey(name: 'web_search')  Map<String, Object?>? webSearch, @JsonKey(name: 'file_search')  Map<String, Object?>? fileSearch,  Map<String, Object?>? memory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.messageId,_that.toolCallId,_that.status,_that.text,_that.textFormat,_that.previewError,_that.webSearch,_that.fileSearch,_that.memory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? messageId,  String? toolCallId,  String? status,  String? text,  String? textFormat,  String? previewError, @JsonKey(name: 'web_search')  Map<String, Object?>? webSearch, @JsonKey(name: 'file_search')  Map<String, Object?>? fileSearch,  Map<String, Object?>? memory)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.messageId,_that.toolCallId,_that.status,_that.text,_that.textFormat,_that.previewError,_that.webSearch,_that.fileSearch,_that.memory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? messageId,  String? toolCallId,  String? status,  String? text,  String? textFormat,  String? previewError, @JsonKey(name: 'web_search')  Map<String, Object?>? webSearch, @JsonKey(name: 'file_search')  Map<String, Object?>? fileSearch,  Map<String, Object?>? memory)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.messageId,_that.toolCallId,_that.status,_that.text,_that.textFormat,_that.previewError,_that.webSearch,_that.fileSearch,_that.memory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Attachment implements Attachment {
  const _Attachment({@JsonKey(name: 'file_id') this.fileId, this.filename, this.filepath, this.type, this.bytes, this.width, this.height, this.messageId, this.toolCallId, this.status, this.text, this.textFormat, this.previewError, @JsonKey(name: 'web_search') final  Map<String, Object?>? webSearch, @JsonKey(name: 'file_search') final  Map<String, Object?>? fileSearch, final  Map<String, Object?>? memory}): _webSearch = webSearch,_fileSearch = fileSearch,_memory = memory;
  factory _Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);

@override@JsonKey(name: 'file_id') final  String? fileId;
@override final  String? filename;
@override final  String? filepath;
@override final  String? type;
@override final  int? bytes;
@override final  int? width;
@override final  int? height;
@override final  String? messageId;
@override final  String? toolCallId;
// An office preview's lifecycle (`pending`, `ready`, `failed`) and, once
// ready, its extracted body: `textFormat` is `html` or `text`.
@override final  String? status;
@override final  String? text;
@override final  String? textFormat;
@override final  String? previewError;
 final  Map<String, Object?>? _webSearch;
@override@JsonKey(name: 'web_search') Map<String, Object?>? get webSearch {
  final value = _webSearch;
  if (value == null) return null;
  if (_webSearch is EqualUnmodifiableMapView) return _webSearch;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, Object?>? _fileSearch;
@override@JsonKey(name: 'file_search') Map<String, Object?>? get fileSearch {
  final value = _fileSearch;
  if (value == null) return null;
  if (_fileSearch is EqualUnmodifiableMapView) return _fileSearch;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, Object?>? _memory;
@override Map<String, Object?>? get memory {
  final value = _memory;
  if (value == null) return null;
  if (_memory is EqualUnmodifiableMapView) return _memory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.filepath, filepath) || other.filepath == filepath)&&(identical(other.type, type) || other.type == type)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.status, status) || other.status == status)&&(identical(other.text, text) || other.text == text)&&(identical(other.textFormat, textFormat) || other.textFormat == textFormat)&&(identical(other.previewError, previewError) || other.previewError == previewError)&&const DeepCollectionEquality().equals(other._webSearch, _webSearch)&&const DeepCollectionEquality().equals(other._fileSearch, _fileSearch)&&const DeepCollectionEquality().equals(other._memory, _memory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,filename,filepath,type,bytes,width,height,messageId,toolCallId,status,text,textFormat,previewError,const DeepCollectionEquality().hash(_webSearch),const DeepCollectionEquality().hash(_fileSearch),const DeepCollectionEquality().hash(_memory));

@override
String toString() {
  return 'Attachment(fileId: $fileId, filename: $filename, filepath: $filepath, type: $type, bytes: $bytes, width: $width, height: $height, messageId: $messageId, toolCallId: $toolCallId, status: $status, text: $text, textFormat: $textFormat, previewError: $previewError, webSearch: $webSearch, fileSearch: $fileSearch, memory: $memory)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'file_id') String? fileId, String? filename, String? filepath, String? type, int? bytes, int? width, int? height, String? messageId, String? toolCallId, String? status, String? text, String? textFormat, String? previewError,@JsonKey(name: 'web_search') Map<String, Object?>? webSearch,@JsonKey(name: 'file_search') Map<String, Object?>? fileSearch, Map<String, Object?>? memory
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = freezed,Object? filename = freezed,Object? filepath = freezed,Object? type = freezed,Object? bytes = freezed,Object? width = freezed,Object? height = freezed,Object? messageId = freezed,Object? toolCallId = freezed,Object? status = freezed,Object? text = freezed,Object? textFormat = freezed,Object? previewError = freezed,Object? webSearch = freezed,Object? fileSearch = freezed,Object? memory = freezed,}) {
  return _then(_Attachment(
fileId: freezed == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,filepath: freezed == filepath ? _self.filepath : filepath // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,toolCallId: freezed == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,textFormat: freezed == textFormat ? _self.textFormat : textFormat // ignore: cast_nullable_to_non_nullable
as String?,previewError: freezed == previewError ? _self.previewError : previewError // ignore: cast_nullable_to_non_nullable
as String?,webSearch: freezed == webSearch ? _self._webSearch : webSearch // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,fileSearch: freezed == fileSearch ? _self._fileSearch : fileSearch // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,memory: freezed == memory ? _self._memory : memory // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

// dart format on
