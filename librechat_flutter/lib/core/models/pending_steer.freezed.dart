// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_steer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingSteer {

 String? get steerId; String? get clientSteerId; String? get text; List<String>? get quotes; int? get createdAt;
/// Create a copy of PendingSteer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingSteerCopyWith<PendingSteer> get copyWith => _$PendingSteerCopyWithImpl<PendingSteer>(this as PendingSteer, _$identity);

  /// Serializes this PendingSteer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingSteer&&(identical(other.steerId, steerId) || other.steerId == steerId)&&(identical(other.clientSteerId, clientSteerId) || other.clientSteerId == clientSteerId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.quotes, quotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,steerId,clientSteerId,text,const DeepCollectionEquality().hash(quotes),createdAt);

@override
String toString() {
  return 'PendingSteer(steerId: $steerId, clientSteerId: $clientSteerId, text: $text, quotes: $quotes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PendingSteerCopyWith<$Res>  {
  factory $PendingSteerCopyWith(PendingSteer value, $Res Function(PendingSteer) _then) = _$PendingSteerCopyWithImpl;
@useResult
$Res call({
 String? steerId, String? clientSteerId, String? text, List<String>? quotes, int? createdAt
});




}
/// @nodoc
class _$PendingSteerCopyWithImpl<$Res>
    implements $PendingSteerCopyWith<$Res> {
  _$PendingSteerCopyWithImpl(this._self, this._then);

  final PendingSteer _self;
  final $Res Function(PendingSteer) _then;

/// Create a copy of PendingSteer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? steerId = freezed,Object? clientSteerId = freezed,Object? text = freezed,Object? quotes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
steerId: freezed == steerId ? _self.steerId : steerId // ignore: cast_nullable_to_non_nullable
as String?,clientSteerId: freezed == clientSteerId ? _self.clientSteerId : clientSteerId // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,quotes: freezed == quotes ? _self.quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingSteer].
extension PendingSteerPatterns on PendingSteer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingSteer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingSteer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingSteer value)  $default,){
final _that = this;
switch (_that) {
case _PendingSteer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingSteer value)?  $default,){
final _that = this;
switch (_that) {
case _PendingSteer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? steerId,  String? clientSteerId,  String? text,  List<String>? quotes,  int? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingSteer() when $default != null:
return $default(_that.steerId,_that.clientSteerId,_that.text,_that.quotes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? steerId,  String? clientSteerId,  String? text,  List<String>? quotes,  int? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PendingSteer():
return $default(_that.steerId,_that.clientSteerId,_that.text,_that.quotes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? steerId,  String? clientSteerId,  String? text,  List<String>? quotes,  int? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingSteer() when $default != null:
return $default(_that.steerId,_that.clientSteerId,_that.text,_that.quotes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingSteer implements PendingSteer {
  const _PendingSteer({this.steerId, this.clientSteerId, this.text, final  List<String>? quotes, this.createdAt}): _quotes = quotes;
  factory _PendingSteer.fromJson(Map<String, dynamic> json) => _$PendingSteerFromJson(json);

@override final  String? steerId;
@override final  String? clientSteerId;
@override final  String? text;
 final  List<String>? _quotes;
@override List<String>? get quotes {
  final value = _quotes;
  if (value == null) return null;
  if (_quotes is EqualUnmodifiableListView) return _quotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? createdAt;

/// Create a copy of PendingSteer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingSteerCopyWith<_PendingSteer> get copyWith => __$PendingSteerCopyWithImpl<_PendingSteer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingSteerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingSteer&&(identical(other.steerId, steerId) || other.steerId == steerId)&&(identical(other.clientSteerId, clientSteerId) || other.clientSteerId == clientSteerId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._quotes, _quotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,steerId,clientSteerId,text,const DeepCollectionEquality().hash(_quotes),createdAt);

@override
String toString() {
  return 'PendingSteer(steerId: $steerId, clientSteerId: $clientSteerId, text: $text, quotes: $quotes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PendingSteerCopyWith<$Res> implements $PendingSteerCopyWith<$Res> {
  factory _$PendingSteerCopyWith(_PendingSteer value, $Res Function(_PendingSteer) _then) = __$PendingSteerCopyWithImpl;
@override @useResult
$Res call({
 String? steerId, String? clientSteerId, String? text, List<String>? quotes, int? createdAt
});




}
/// @nodoc
class __$PendingSteerCopyWithImpl<$Res>
    implements _$PendingSteerCopyWith<$Res> {
  __$PendingSteerCopyWithImpl(this._self, this._then);

  final _PendingSteer _self;
  final $Res Function(_PendingSteer) _then;

/// Create a copy of PendingSteer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? steerId = freezed,Object? clientSteerId = freezed,Object? text = freezed,Object? quotes = freezed,Object? createdAt = freezed,}) {
  return _then(_PendingSteer(
steerId: freezed == steerId ? _self.steerId : steerId // ignore: cast_nullable_to_non_nullable
as String?,clientSteerId: freezed == clientSteerId ? _self.clientSteerId : clientSteerId // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,quotes: freezed == quotes ? _self._quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
