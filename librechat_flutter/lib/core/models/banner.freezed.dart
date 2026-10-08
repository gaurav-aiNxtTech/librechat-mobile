// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerBanner {

 String? get bannerId; String? get message; String? get type; bool? get persistable;@UtcDateTimeConverter() DateTime? get displayFrom;@UtcDateTimeConverter() DateTime? get displayTo;
/// Create a copy of ServerBanner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerBannerCopyWith<ServerBanner> get copyWith => _$ServerBannerCopyWithImpl<ServerBanner>(this as ServerBanner, _$identity);

  /// Serializes this ServerBanner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerBanner&&(identical(other.bannerId, bannerId) || other.bannerId == bannerId)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.persistable, persistable) || other.persistable == persistable)&&(identical(other.displayFrom, displayFrom) || other.displayFrom == displayFrom)&&(identical(other.displayTo, displayTo) || other.displayTo == displayTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannerId,message,type,persistable,displayFrom,displayTo);

@override
String toString() {
  return 'ServerBanner(bannerId: $bannerId, message: $message, type: $type, persistable: $persistable, displayFrom: $displayFrom, displayTo: $displayTo)';
}


}

/// @nodoc
abstract mixin class $ServerBannerCopyWith<$Res>  {
  factory $ServerBannerCopyWith(ServerBanner value, $Res Function(ServerBanner) _then) = _$ServerBannerCopyWithImpl;
@useResult
$Res call({
 String? bannerId, String? message, String? type, bool? persistable,@UtcDateTimeConverter() DateTime? displayFrom,@UtcDateTimeConverter() DateTime? displayTo
});




}
/// @nodoc
class _$ServerBannerCopyWithImpl<$Res>
    implements $ServerBannerCopyWith<$Res> {
  _$ServerBannerCopyWithImpl(this._self, this._then);

  final ServerBanner _self;
  final $Res Function(ServerBanner) _then;

/// Create a copy of ServerBanner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bannerId = freezed,Object? message = freezed,Object? type = freezed,Object? persistable = freezed,Object? displayFrom = freezed,Object? displayTo = freezed,}) {
  return _then(_self.copyWith(
bannerId: freezed == bannerId ? _self.bannerId : bannerId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,persistable: freezed == persistable ? _self.persistable : persistable // ignore: cast_nullable_to_non_nullable
as bool?,displayFrom: freezed == displayFrom ? _self.displayFrom : displayFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,displayTo: freezed == displayTo ? _self.displayTo : displayTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerBanner].
extension ServerBannerPatterns on ServerBanner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerBanner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerBanner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerBanner value)  $default,){
final _that = this;
switch (_that) {
case _ServerBanner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerBanner value)?  $default,){
final _that = this;
switch (_that) {
case _ServerBanner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? bannerId,  String? message,  String? type,  bool? persistable, @UtcDateTimeConverter()  DateTime? displayFrom, @UtcDateTimeConverter()  DateTime? displayTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerBanner() when $default != null:
return $default(_that.bannerId,_that.message,_that.type,_that.persistable,_that.displayFrom,_that.displayTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? bannerId,  String? message,  String? type,  bool? persistable, @UtcDateTimeConverter()  DateTime? displayFrom, @UtcDateTimeConverter()  DateTime? displayTo)  $default,) {final _that = this;
switch (_that) {
case _ServerBanner():
return $default(_that.bannerId,_that.message,_that.type,_that.persistable,_that.displayFrom,_that.displayTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? bannerId,  String? message,  String? type,  bool? persistable, @UtcDateTimeConverter()  DateTime? displayFrom, @UtcDateTimeConverter()  DateTime? displayTo)?  $default,) {final _that = this;
switch (_that) {
case _ServerBanner() when $default != null:
return $default(_that.bannerId,_that.message,_that.type,_that.persistable,_that.displayFrom,_that.displayTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerBanner implements ServerBanner {
  const _ServerBanner({this.bannerId, this.message, this.type, this.persistable, @UtcDateTimeConverter() this.displayFrom, @UtcDateTimeConverter() this.displayTo});
  factory _ServerBanner.fromJson(Map<String, dynamic> json) => _$ServerBannerFromJson(json);

@override final  String? bannerId;
@override final  String? message;
@override final  String? type;
@override final  bool? persistable;
@override@UtcDateTimeConverter() final  DateTime? displayFrom;
@override@UtcDateTimeConverter() final  DateTime? displayTo;

/// Create a copy of ServerBanner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerBannerCopyWith<_ServerBanner> get copyWith => __$ServerBannerCopyWithImpl<_ServerBanner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerBannerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerBanner&&(identical(other.bannerId, bannerId) || other.bannerId == bannerId)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.persistable, persistable) || other.persistable == persistable)&&(identical(other.displayFrom, displayFrom) || other.displayFrom == displayFrom)&&(identical(other.displayTo, displayTo) || other.displayTo == displayTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannerId,message,type,persistable,displayFrom,displayTo);

@override
String toString() {
  return 'ServerBanner(bannerId: $bannerId, message: $message, type: $type, persistable: $persistable, displayFrom: $displayFrom, displayTo: $displayTo)';
}


}

/// @nodoc
abstract mixin class _$ServerBannerCopyWith<$Res> implements $ServerBannerCopyWith<$Res> {
  factory _$ServerBannerCopyWith(_ServerBanner value, $Res Function(_ServerBanner) _then) = __$ServerBannerCopyWithImpl;
@override @useResult
$Res call({
 String? bannerId, String? message, String? type, bool? persistable,@UtcDateTimeConverter() DateTime? displayFrom,@UtcDateTimeConverter() DateTime? displayTo
});




}
/// @nodoc
class __$ServerBannerCopyWithImpl<$Res>
    implements _$ServerBannerCopyWith<$Res> {
  __$ServerBannerCopyWithImpl(this._self, this._then);

  final _ServerBanner _self;
  final $Res Function(_ServerBanner) _then;

/// Create a copy of ServerBanner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bannerId = freezed,Object? message = freezed,Object? type = freezed,Object? persistable = freezed,Object? displayFrom = freezed,Object? displayTo = freezed,}) {
  return _then(_ServerBanner(
bannerId: freezed == bannerId ? _self.bannerId : bannerId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,persistable: freezed == persistable ? _self.persistable : persistable // ignore: cast_nullable_to_non_nullable
as bool?,displayFrom: freezed == displayFrom ? _self.displayFrom : displayFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,displayTo: freezed == displayTo ? _self.displayTo : displayTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
