// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'endpoint_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EndpointConfig {

 String? get type; int? get order; String? get iconURL; String? get modelDisplayLabel; bool? get userProvide; bool? get userProvideURL; List<String>? get capabilities;
/// Create a copy of EndpointConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EndpointConfigCopyWith<EndpointConfig> get copyWith => _$EndpointConfigCopyWithImpl<EndpointConfig>(this as EndpointConfig, _$identity);

  /// Serializes this EndpointConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EndpointConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.order, order) || other.order == order)&&(identical(other.iconURL, iconURL) || other.iconURL == iconURL)&&(identical(other.modelDisplayLabel, modelDisplayLabel) || other.modelDisplayLabel == modelDisplayLabel)&&(identical(other.userProvide, userProvide) || other.userProvide == userProvide)&&(identical(other.userProvideURL, userProvideURL) || other.userProvideURL == userProvideURL)&&const DeepCollectionEquality().equals(other.capabilities, capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,order,iconURL,modelDisplayLabel,userProvide,userProvideURL,const DeepCollectionEquality().hash(capabilities));

@override
String toString() {
  return 'EndpointConfig(type: $type, order: $order, iconURL: $iconURL, modelDisplayLabel: $modelDisplayLabel, userProvide: $userProvide, userProvideURL: $userProvideURL, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class $EndpointConfigCopyWith<$Res>  {
  factory $EndpointConfigCopyWith(EndpointConfig value, $Res Function(EndpointConfig) _then) = _$EndpointConfigCopyWithImpl;
@useResult
$Res call({
 String? type, int? order, String? iconURL, String? modelDisplayLabel, bool? userProvide, bool? userProvideURL, List<String>? capabilities
});




}
/// @nodoc
class _$EndpointConfigCopyWithImpl<$Res>
    implements $EndpointConfigCopyWith<$Res> {
  _$EndpointConfigCopyWithImpl(this._self, this._then);

  final EndpointConfig _self;
  final $Res Function(EndpointConfig) _then;

/// Create a copy of EndpointConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = freezed,Object? order = freezed,Object? iconURL = freezed,Object? modelDisplayLabel = freezed,Object? userProvide = freezed,Object? userProvideURL = freezed,Object? capabilities = freezed,}) {
  return _then(_self.copyWith(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,iconURL: freezed == iconURL ? _self.iconURL : iconURL // ignore: cast_nullable_to_non_nullable
as String?,modelDisplayLabel: freezed == modelDisplayLabel ? _self.modelDisplayLabel : modelDisplayLabel // ignore: cast_nullable_to_non_nullable
as String?,userProvide: freezed == userProvide ? _self.userProvide : userProvide // ignore: cast_nullable_to_non_nullable
as bool?,userProvideURL: freezed == userProvideURL ? _self.userProvideURL : userProvideURL // ignore: cast_nullable_to_non_nullable
as bool?,capabilities: freezed == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [EndpointConfig].
extension EndpointConfigPatterns on EndpointConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EndpointConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EndpointConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EndpointConfig value)  $default,){
final _that = this;
switch (_that) {
case _EndpointConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EndpointConfig value)?  $default,){
final _that = this;
switch (_that) {
case _EndpointConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? type,  int? order,  String? iconURL,  String? modelDisplayLabel,  bool? userProvide,  bool? userProvideURL,  List<String>? capabilities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EndpointConfig() when $default != null:
return $default(_that.type,_that.order,_that.iconURL,_that.modelDisplayLabel,_that.userProvide,_that.userProvideURL,_that.capabilities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? type,  int? order,  String? iconURL,  String? modelDisplayLabel,  bool? userProvide,  bool? userProvideURL,  List<String>? capabilities)  $default,) {final _that = this;
switch (_that) {
case _EndpointConfig():
return $default(_that.type,_that.order,_that.iconURL,_that.modelDisplayLabel,_that.userProvide,_that.userProvideURL,_that.capabilities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? type,  int? order,  String? iconURL,  String? modelDisplayLabel,  bool? userProvide,  bool? userProvideURL,  List<String>? capabilities)?  $default,) {final _that = this;
switch (_that) {
case _EndpointConfig() when $default != null:
return $default(_that.type,_that.order,_that.iconURL,_that.modelDisplayLabel,_that.userProvide,_that.userProvideURL,_that.capabilities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EndpointConfig implements EndpointConfig {
  const _EndpointConfig({this.type, this.order, this.iconURL, this.modelDisplayLabel, this.userProvide, this.userProvideURL, final  List<String>? capabilities}): _capabilities = capabilities;
  factory _EndpointConfig.fromJson(Map<String, dynamic> json) => _$EndpointConfigFromJson(json);

@override final  String? type;
@override final  int? order;
@override final  String? iconURL;
@override final  String? modelDisplayLabel;
@override final  bool? userProvide;
@override final  bool? userProvideURL;
 final  List<String>? _capabilities;
@override List<String>? get capabilities {
  final value = _capabilities;
  if (value == null) return null;
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of EndpointConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EndpointConfigCopyWith<_EndpointConfig> get copyWith => __$EndpointConfigCopyWithImpl<_EndpointConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EndpointConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EndpointConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.order, order) || other.order == order)&&(identical(other.iconURL, iconURL) || other.iconURL == iconURL)&&(identical(other.modelDisplayLabel, modelDisplayLabel) || other.modelDisplayLabel == modelDisplayLabel)&&(identical(other.userProvide, userProvide) || other.userProvide == userProvide)&&(identical(other.userProvideURL, userProvideURL) || other.userProvideURL == userProvideURL)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,order,iconURL,modelDisplayLabel,userProvide,userProvideURL,const DeepCollectionEquality().hash(_capabilities));

@override
String toString() {
  return 'EndpointConfig(type: $type, order: $order, iconURL: $iconURL, modelDisplayLabel: $modelDisplayLabel, userProvide: $userProvide, userProvideURL: $userProvideURL, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class _$EndpointConfigCopyWith<$Res> implements $EndpointConfigCopyWith<$Res> {
  factory _$EndpointConfigCopyWith(_EndpointConfig value, $Res Function(_EndpointConfig) _then) = __$EndpointConfigCopyWithImpl;
@override @useResult
$Res call({
 String? type, int? order, String? iconURL, String? modelDisplayLabel, bool? userProvide, bool? userProvideURL, List<String>? capabilities
});




}
/// @nodoc
class __$EndpointConfigCopyWithImpl<$Res>
    implements _$EndpointConfigCopyWith<$Res> {
  __$EndpointConfigCopyWithImpl(this._self, this._then);

  final _EndpointConfig _self;
  final $Res Function(_EndpointConfig) _then;

/// Create a copy of EndpointConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = freezed,Object? order = freezed,Object? iconURL = freezed,Object? modelDisplayLabel = freezed,Object? userProvide = freezed,Object? userProvideURL = freezed,Object? capabilities = freezed,}) {
  return _then(_EndpointConfig(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,iconURL: freezed == iconURL ? _self.iconURL : iconURL // ignore: cast_nullable_to_non_nullable
as String?,modelDisplayLabel: freezed == modelDisplayLabel ? _self.modelDisplayLabel : modelDisplayLabel // ignore: cast_nullable_to_non_nullable
as String?,userProvide: freezed == userProvide ? _self.userProvide : userProvide // ignore: cast_nullable_to_non_nullable
as bool?,userProvideURL: freezed == userProvideURL ? _self.userProvideURL : userProvideURL // ignore: cast_nullable_to_non_nullable
as bool?,capabilities: freezed == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
