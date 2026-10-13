// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'files_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileObject {

@JsonKey(name: 'file_id') String? get fileId; String? get filename; String? get filepath; String? get type; int? get bytes; int? get width; int? get height; String? get source; String? get user; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileObjectCopyWith<FileObject> get copyWith => _$FileObjectCopyWithImpl<FileObject>(this as FileObject, _$identity);

  /// Serializes this FileObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileObject&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.filepath, filepath) || other.filepath == filepath)&&(identical(other.type, type) || other.type == type)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.source, source) || other.source == source)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,filename,filepath,type,bytes,width,height,source,user,createdAt,updatedAt);

@override
String toString() {
  return 'FileObject(fileId: $fileId, filename: $filename, filepath: $filepath, type: $type, bytes: $bytes, width: $width, height: $height, source: $source, user: $user, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FileObjectCopyWith<$Res>  {
  factory $FileObjectCopyWith(FileObject value, $Res Function(FileObject) _then) = _$FileObjectCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'file_id') String? fileId, String? filename, String? filepath, String? type, int? bytes, int? width, int? height, String? source, String? user, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$FileObjectCopyWithImpl<$Res>
    implements $FileObjectCopyWith<$Res> {
  _$FileObjectCopyWithImpl(this._self, this._then);

  final FileObject _self;
  final $Res Function(FileObject) _then;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = freezed,Object? filename = freezed,Object? filepath = freezed,Object? type = freezed,Object? bytes = freezed,Object? width = freezed,Object? height = freezed,Object? source = freezed,Object? user = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
fileId: freezed == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,filepath: freezed == filepath ? _self.filepath : filepath // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileObject].
extension FileObjectPatterns on FileObject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileObject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileObject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileObject value)  $default,){
final _that = this;
switch (_that) {
case _FileObject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileObject value)?  $default,){
final _that = this;
switch (_that) {
case _FileObject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? source,  String? user,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.source,_that.user,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? source,  String? user,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FileObject():
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.source,_that.user,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'file_id')  String? fileId,  String? filename,  String? filepath,  String? type,  int? bytes,  int? width,  int? height,  String? source,  String? user,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that.fileId,_that.filename,_that.filepath,_that.type,_that.bytes,_that.width,_that.height,_that.source,_that.user,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileObject implements FileObject {
  const _FileObject({@JsonKey(name: 'file_id') this.fileId, this.filename, this.filepath, this.type, this.bytes, this.width, this.height, this.source, this.user, this.createdAt, this.updatedAt});
  factory _FileObject.fromJson(Map<String, dynamic> json) => _$FileObjectFromJson(json);

@override@JsonKey(name: 'file_id') final  String? fileId;
@override final  String? filename;
@override final  String? filepath;
@override final  String? type;
@override final  int? bytes;
@override final  int? width;
@override final  int? height;
@override final  String? source;
@override final  String? user;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileObjectCopyWith<_FileObject> get copyWith => __$FileObjectCopyWithImpl<_FileObject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileObjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileObject&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.filepath, filepath) || other.filepath == filepath)&&(identical(other.type, type) || other.type == type)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.source, source) || other.source == source)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,filename,filepath,type,bytes,width,height,source,user,createdAt,updatedAt);

@override
String toString() {
  return 'FileObject(fileId: $fileId, filename: $filename, filepath: $filepath, type: $type, bytes: $bytes, width: $width, height: $height, source: $source, user: $user, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FileObjectCopyWith<$Res> implements $FileObjectCopyWith<$Res> {
  factory _$FileObjectCopyWith(_FileObject value, $Res Function(_FileObject) _then) = __$FileObjectCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'file_id') String? fileId, String? filename, String? filepath, String? type, int? bytes, int? width, int? height, String? source, String? user, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$FileObjectCopyWithImpl<$Res>
    implements _$FileObjectCopyWith<$Res> {
  __$FileObjectCopyWithImpl(this._self, this._then);

  final _FileObject _self;
  final $Res Function(_FileObject) _then;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = freezed,Object? filename = freezed,Object? filepath = freezed,Object? type = freezed,Object? bytes = freezed,Object? width = freezed,Object? height = freezed,Object? source = freezed,Object? user = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_FileObject(
fileId: freezed == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,filepath: freezed == filepath ? _self.filepath : filepath // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
