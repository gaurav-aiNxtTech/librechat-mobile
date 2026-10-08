// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileConfig {

 Map<String, EndpointFileConfig> get endpoints; int? get serverFileSizeLimit;
/// Create a copy of FileConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileConfigCopyWith<FileConfig> get copyWith => _$FileConfigCopyWithImpl<FileConfig>(this as FileConfig, _$identity);

  /// Serializes this FileConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileConfig&&const DeepCollectionEquality().equals(other.endpoints, endpoints)&&(identical(other.serverFileSizeLimit, serverFileSizeLimit) || other.serverFileSizeLimit == serverFileSizeLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(endpoints),serverFileSizeLimit);

@override
String toString() {
  return 'FileConfig(endpoints: $endpoints, serverFileSizeLimit: $serverFileSizeLimit)';
}


}

/// @nodoc
abstract mixin class $FileConfigCopyWith<$Res>  {
  factory $FileConfigCopyWith(FileConfig value, $Res Function(FileConfig) _then) = _$FileConfigCopyWithImpl;
@useResult
$Res call({
 Map<String, EndpointFileConfig> endpoints, int? serverFileSizeLimit
});




}
/// @nodoc
class _$FileConfigCopyWithImpl<$Res>
    implements $FileConfigCopyWith<$Res> {
  _$FileConfigCopyWithImpl(this._self, this._then);

  final FileConfig _self;
  final $Res Function(FileConfig) _then;

/// Create a copy of FileConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? endpoints = null,Object? serverFileSizeLimit = freezed,}) {
  return _then(_self.copyWith(
endpoints: null == endpoints ? _self.endpoints : endpoints // ignore: cast_nullable_to_non_nullable
as Map<String, EndpointFileConfig>,serverFileSizeLimit: freezed == serverFileSizeLimit ? _self.serverFileSizeLimit : serverFileSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileConfig].
extension FileConfigPatterns on FileConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileConfig value)  $default,){
final _that = this;
switch (_that) {
case _FileConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileConfig value)?  $default,){
final _that = this;
switch (_that) {
case _FileConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, EndpointFileConfig> endpoints,  int? serverFileSizeLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileConfig() when $default != null:
return $default(_that.endpoints,_that.serverFileSizeLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, EndpointFileConfig> endpoints,  int? serverFileSizeLimit)  $default,) {final _that = this;
switch (_that) {
case _FileConfig():
return $default(_that.endpoints,_that.serverFileSizeLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, EndpointFileConfig> endpoints,  int? serverFileSizeLimit)?  $default,) {final _that = this;
switch (_that) {
case _FileConfig() when $default != null:
return $default(_that.endpoints,_that.serverFileSizeLimit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileConfig implements FileConfig {
  const _FileConfig({final  Map<String, EndpointFileConfig> endpoints = const <String, EndpointFileConfig>{}, this.serverFileSizeLimit}): _endpoints = endpoints;
  factory _FileConfig.fromJson(Map<String, dynamic> json) => _$FileConfigFromJson(json);

 final  Map<String, EndpointFileConfig> _endpoints;
@override@JsonKey() Map<String, EndpointFileConfig> get endpoints {
  if (_endpoints is EqualUnmodifiableMapView) return _endpoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_endpoints);
}

@override final  int? serverFileSizeLimit;

/// Create a copy of FileConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileConfigCopyWith<_FileConfig> get copyWith => __$FileConfigCopyWithImpl<_FileConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileConfig&&const DeepCollectionEquality().equals(other._endpoints, _endpoints)&&(identical(other.serverFileSizeLimit, serverFileSizeLimit) || other.serverFileSizeLimit == serverFileSizeLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_endpoints),serverFileSizeLimit);

@override
String toString() {
  return 'FileConfig(endpoints: $endpoints, serverFileSizeLimit: $serverFileSizeLimit)';
}


}

/// @nodoc
abstract mixin class _$FileConfigCopyWith<$Res> implements $FileConfigCopyWith<$Res> {
  factory _$FileConfigCopyWith(_FileConfig value, $Res Function(_FileConfig) _then) = __$FileConfigCopyWithImpl;
@override @useResult
$Res call({
 Map<String, EndpointFileConfig> endpoints, int? serverFileSizeLimit
});




}
/// @nodoc
class __$FileConfigCopyWithImpl<$Res>
    implements _$FileConfigCopyWith<$Res> {
  __$FileConfigCopyWithImpl(this._self, this._then);

  final _FileConfig _self;
  final $Res Function(_FileConfig) _then;

/// Create a copy of FileConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? endpoints = null,Object? serverFileSizeLimit = freezed,}) {
  return _then(_FileConfig(
endpoints: null == endpoints ? _self._endpoints : endpoints // ignore: cast_nullable_to_non_nullable
as Map<String, EndpointFileConfig>,serverFileSizeLimit: freezed == serverFileSizeLimit ? _self.serverFileSizeLimit : serverFileSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$EndpointFileConfig {

 int? get fileLimit; int? get fileSizeLimit; int? get totalSizeLimit; List<String> get supportedMimeTypes; bool? get disabled;
/// Create a copy of EndpointFileConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EndpointFileConfigCopyWith<EndpointFileConfig> get copyWith => _$EndpointFileConfigCopyWithImpl<EndpointFileConfig>(this as EndpointFileConfig, _$identity);

  /// Serializes this EndpointFileConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EndpointFileConfig&&(identical(other.fileLimit, fileLimit) || other.fileLimit == fileLimit)&&(identical(other.fileSizeLimit, fileSizeLimit) || other.fileSizeLimit == fileSizeLimit)&&(identical(other.totalSizeLimit, totalSizeLimit) || other.totalSizeLimit == totalSizeLimit)&&const DeepCollectionEquality().equals(other.supportedMimeTypes, supportedMimeTypes)&&(identical(other.disabled, disabled) || other.disabled == disabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileLimit,fileSizeLimit,totalSizeLimit,const DeepCollectionEquality().hash(supportedMimeTypes),disabled);

@override
String toString() {
  return 'EndpointFileConfig(fileLimit: $fileLimit, fileSizeLimit: $fileSizeLimit, totalSizeLimit: $totalSizeLimit, supportedMimeTypes: $supportedMimeTypes, disabled: $disabled)';
}


}

/// @nodoc
abstract mixin class $EndpointFileConfigCopyWith<$Res>  {
  factory $EndpointFileConfigCopyWith(EndpointFileConfig value, $Res Function(EndpointFileConfig) _then) = _$EndpointFileConfigCopyWithImpl;
@useResult
$Res call({
 int? fileLimit, int? fileSizeLimit, int? totalSizeLimit, List<String> supportedMimeTypes, bool? disabled
});




}
/// @nodoc
class _$EndpointFileConfigCopyWithImpl<$Res>
    implements $EndpointFileConfigCopyWith<$Res> {
  _$EndpointFileConfigCopyWithImpl(this._self, this._then);

  final EndpointFileConfig _self;
  final $Res Function(EndpointFileConfig) _then;

/// Create a copy of EndpointFileConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileLimit = freezed,Object? fileSizeLimit = freezed,Object? totalSizeLimit = freezed,Object? supportedMimeTypes = null,Object? disabled = freezed,}) {
  return _then(_self.copyWith(
fileLimit: freezed == fileLimit ? _self.fileLimit : fileLimit // ignore: cast_nullable_to_non_nullable
as int?,fileSizeLimit: freezed == fileSizeLimit ? _self.fileSizeLimit : fileSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,totalSizeLimit: freezed == totalSizeLimit ? _self.totalSizeLimit : totalSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,supportedMimeTypes: null == supportedMimeTypes ? _self.supportedMimeTypes : supportedMimeTypes // ignore: cast_nullable_to_non_nullable
as List<String>,disabled: freezed == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [EndpointFileConfig].
extension EndpointFileConfigPatterns on EndpointFileConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EndpointFileConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EndpointFileConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EndpointFileConfig value)  $default,){
final _that = this;
switch (_that) {
case _EndpointFileConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EndpointFileConfig value)?  $default,){
final _that = this;
switch (_that) {
case _EndpointFileConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? fileLimit,  int? fileSizeLimit,  int? totalSizeLimit,  List<String> supportedMimeTypes,  bool? disabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EndpointFileConfig() when $default != null:
return $default(_that.fileLimit,_that.fileSizeLimit,_that.totalSizeLimit,_that.supportedMimeTypes,_that.disabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? fileLimit,  int? fileSizeLimit,  int? totalSizeLimit,  List<String> supportedMimeTypes,  bool? disabled)  $default,) {final _that = this;
switch (_that) {
case _EndpointFileConfig():
return $default(_that.fileLimit,_that.fileSizeLimit,_that.totalSizeLimit,_that.supportedMimeTypes,_that.disabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? fileLimit,  int? fileSizeLimit,  int? totalSizeLimit,  List<String> supportedMimeTypes,  bool? disabled)?  $default,) {final _that = this;
switch (_that) {
case _EndpointFileConfig() when $default != null:
return $default(_that.fileLimit,_that.fileSizeLimit,_that.totalSizeLimit,_that.supportedMimeTypes,_that.disabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EndpointFileConfig implements EndpointFileConfig {
  const _EndpointFileConfig({this.fileLimit, this.fileSizeLimit, this.totalSizeLimit, final  List<String> supportedMimeTypes = const <String>[], this.disabled}): _supportedMimeTypes = supportedMimeTypes;
  factory _EndpointFileConfig.fromJson(Map<String, dynamic> json) => _$EndpointFileConfigFromJson(json);

@override final  int? fileLimit;
@override final  int? fileSizeLimit;
@override final  int? totalSizeLimit;
 final  List<String> _supportedMimeTypes;
@override@JsonKey() List<String> get supportedMimeTypes {
  if (_supportedMimeTypes is EqualUnmodifiableListView) return _supportedMimeTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedMimeTypes);
}

@override final  bool? disabled;

/// Create a copy of EndpointFileConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EndpointFileConfigCopyWith<_EndpointFileConfig> get copyWith => __$EndpointFileConfigCopyWithImpl<_EndpointFileConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EndpointFileConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EndpointFileConfig&&(identical(other.fileLimit, fileLimit) || other.fileLimit == fileLimit)&&(identical(other.fileSizeLimit, fileSizeLimit) || other.fileSizeLimit == fileSizeLimit)&&(identical(other.totalSizeLimit, totalSizeLimit) || other.totalSizeLimit == totalSizeLimit)&&const DeepCollectionEquality().equals(other._supportedMimeTypes, _supportedMimeTypes)&&(identical(other.disabled, disabled) || other.disabled == disabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileLimit,fileSizeLimit,totalSizeLimit,const DeepCollectionEquality().hash(_supportedMimeTypes),disabled);

@override
String toString() {
  return 'EndpointFileConfig(fileLimit: $fileLimit, fileSizeLimit: $fileSizeLimit, totalSizeLimit: $totalSizeLimit, supportedMimeTypes: $supportedMimeTypes, disabled: $disabled)';
}


}

/// @nodoc
abstract mixin class _$EndpointFileConfigCopyWith<$Res> implements $EndpointFileConfigCopyWith<$Res> {
  factory _$EndpointFileConfigCopyWith(_EndpointFileConfig value, $Res Function(_EndpointFileConfig) _then) = __$EndpointFileConfigCopyWithImpl;
@override @useResult
$Res call({
 int? fileLimit, int? fileSizeLimit, int? totalSizeLimit, List<String> supportedMimeTypes, bool? disabled
});




}
/// @nodoc
class __$EndpointFileConfigCopyWithImpl<$Res>
    implements _$EndpointFileConfigCopyWith<$Res> {
  __$EndpointFileConfigCopyWithImpl(this._self, this._then);

  final _EndpointFileConfig _self;
  final $Res Function(_EndpointFileConfig) _then;

/// Create a copy of EndpointFileConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileLimit = freezed,Object? fileSizeLimit = freezed,Object? totalSizeLimit = freezed,Object? supportedMimeTypes = null,Object? disabled = freezed,}) {
  return _then(_EndpointFileConfig(
fileLimit: freezed == fileLimit ? _self.fileLimit : fileLimit // ignore: cast_nullable_to_non_nullable
as int?,fileSizeLimit: freezed == fileSizeLimit ? _self.fileSizeLimit : fileSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,totalSizeLimit: freezed == totalSizeLimit ? _self.totalSizeLimit : totalSizeLimit // ignore: cast_nullable_to_non_nullable
as int?,supportedMimeTypes: null == supportedMimeTypes ? _self._supportedMimeTypes : supportedMimeTypes // ignore: cast_nullable_to_non_nullable
as List<String>,disabled: freezed == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
