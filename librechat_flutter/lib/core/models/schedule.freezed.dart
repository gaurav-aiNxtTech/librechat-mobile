// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleCadence {

 String get frequency; int? get hour; int? get minute; List<int>? get daysOfWeek; String? get expression;
/// Create a copy of ScheduleCadence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleCadenceCopyWith<ScheduleCadence> get copyWith => _$ScheduleCadenceCopyWithImpl<ScheduleCadence>(this as ScheduleCadence, _$identity);

  /// Serializes this ScheduleCadence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleCadence&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.minute, minute) || other.minute == minute)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.expression, expression) || other.expression == expression));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,hour,minute,const DeepCollectionEquality().hash(daysOfWeek),expression);

@override
String toString() {
  return 'ScheduleCadence(frequency: $frequency, hour: $hour, minute: $minute, daysOfWeek: $daysOfWeek, expression: $expression)';
}


}

/// @nodoc
abstract mixin class $ScheduleCadenceCopyWith<$Res>  {
  factory $ScheduleCadenceCopyWith(ScheduleCadence value, $Res Function(ScheduleCadence) _then) = _$ScheduleCadenceCopyWithImpl;
@useResult
$Res call({
 String frequency, int? hour, int? minute, List<int>? daysOfWeek, String? expression
});




}
/// @nodoc
class _$ScheduleCadenceCopyWithImpl<$Res>
    implements $ScheduleCadenceCopyWith<$Res> {
  _$ScheduleCadenceCopyWithImpl(this._self, this._then);

  final ScheduleCadence _self;
  final $Res Function(ScheduleCadence) _then;

/// Create a copy of ScheduleCadence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? hour = freezed,Object? minute = freezed,Object? daysOfWeek = freezed,Object? expression = freezed,}) {
  return _then(_self.copyWith(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,hour: freezed == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int?,minute: freezed == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int?,daysOfWeek: freezed == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>?,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleCadence].
extension ScheduleCadencePatterns on ScheduleCadence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleCadence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleCadence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleCadence value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleCadence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleCadence value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleCadence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String frequency,  int? hour,  int? minute,  List<int>? daysOfWeek,  String? expression)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleCadence() when $default != null:
return $default(_that.frequency,_that.hour,_that.minute,_that.daysOfWeek,_that.expression);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String frequency,  int? hour,  int? minute,  List<int>? daysOfWeek,  String? expression)  $default,) {final _that = this;
switch (_that) {
case _ScheduleCadence():
return $default(_that.frequency,_that.hour,_that.minute,_that.daysOfWeek,_that.expression);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String frequency,  int? hour,  int? minute,  List<int>? daysOfWeek,  String? expression)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleCadence() when $default != null:
return $default(_that.frequency,_that.hour,_that.minute,_that.daysOfWeek,_that.expression);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduleCadence implements ScheduleCadence {
  const _ScheduleCadence({required this.frequency, this.hour, this.minute, final  List<int>? daysOfWeek, this.expression}): _daysOfWeek = daysOfWeek;
  factory _ScheduleCadence.fromJson(Map<String, dynamic> json) => _$ScheduleCadenceFromJson(json);

@override final  String frequency;
@override final  int? hour;
@override final  int? minute;
 final  List<int>? _daysOfWeek;
@override List<int>? get daysOfWeek {
  final value = _daysOfWeek;
  if (value == null) return null;
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? expression;

/// Create a copy of ScheduleCadence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleCadenceCopyWith<_ScheduleCadence> get copyWith => __$ScheduleCadenceCopyWithImpl<_ScheduleCadence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleCadenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleCadence&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.minute, minute) || other.minute == minute)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.expression, expression) || other.expression == expression));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,hour,minute,const DeepCollectionEquality().hash(_daysOfWeek),expression);

@override
String toString() {
  return 'ScheduleCadence(frequency: $frequency, hour: $hour, minute: $minute, daysOfWeek: $daysOfWeek, expression: $expression)';
}


}

/// @nodoc
abstract mixin class _$ScheduleCadenceCopyWith<$Res> implements $ScheduleCadenceCopyWith<$Res> {
  factory _$ScheduleCadenceCopyWith(_ScheduleCadence value, $Res Function(_ScheduleCadence) _then) = __$ScheduleCadenceCopyWithImpl;
@override @useResult
$Res call({
 String frequency, int? hour, int? minute, List<int>? daysOfWeek, String? expression
});




}
/// @nodoc
class __$ScheduleCadenceCopyWithImpl<$Res>
    implements _$ScheduleCadenceCopyWith<$Res> {
  __$ScheduleCadenceCopyWithImpl(this._self, this._then);

  final _ScheduleCadence _self;
  final $Res Function(_ScheduleCadence) _then;

/// Create a copy of ScheduleCadence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? hour = freezed,Object? minute = freezed,Object? daysOfWeek = freezed,Object? expression = freezed,}) {
  return _then(_ScheduleCadence(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,hour: freezed == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int?,minute: freezed == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int?,daysOfWeek: freezed == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>?,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
