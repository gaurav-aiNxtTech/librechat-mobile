// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingAction {

 String? get actionId; String? get streamId; String? get conversationId; String? get runId; Map<String, Object?>? get payload; int? get expiresAt;
/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingActionCopyWith<PendingAction> get copyWith => _$PendingActionCopyWithImpl<PendingAction>(this as PendingAction, _$identity);

  /// Serializes this PendingAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.runId, runId) || other.runId == runId)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,streamId,conversationId,runId,const DeepCollectionEquality().hash(payload),expiresAt);

@override
String toString() {
  return 'PendingAction(actionId: $actionId, streamId: $streamId, conversationId: $conversationId, runId: $runId, payload: $payload, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PendingActionCopyWith<$Res>  {
  factory $PendingActionCopyWith(PendingAction value, $Res Function(PendingAction) _then) = _$PendingActionCopyWithImpl;
@useResult
$Res call({
 String? actionId, String? streamId, String? conversationId, String? runId, Map<String, Object?>? payload, int? expiresAt
});




}
/// @nodoc
class _$PendingActionCopyWithImpl<$Res>
    implements $PendingActionCopyWith<$Res> {
  _$PendingActionCopyWithImpl(this._self, this._then);

  final PendingAction _self;
  final $Res Function(PendingAction) _then;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionId = freezed,Object? streamId = freezed,Object? conversationId = freezed,Object? runId = freezed,Object? payload = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
actionId: freezed == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String?,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingAction].
extension PendingActionPatterns on PendingAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingAction value)  $default,){
final _that = this;
switch (_that) {
case _PendingAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingAction value)?  $default,){
final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? actionId,  String? streamId,  String? conversationId,  String? runId,  Map<String, Object?>? payload,  int? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
return $default(_that.actionId,_that.streamId,_that.conversationId,_that.runId,_that.payload,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? actionId,  String? streamId,  String? conversationId,  String? runId,  Map<String, Object?>? payload,  int? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PendingAction():
return $default(_that.actionId,_that.streamId,_that.conversationId,_that.runId,_that.payload,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? actionId,  String? streamId,  String? conversationId,  String? runId,  Map<String, Object?>? payload,  int? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingAction() when $default != null:
return $default(_that.actionId,_that.streamId,_that.conversationId,_that.runId,_that.payload,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingAction implements PendingAction {
  const _PendingAction({this.actionId, this.streamId, this.conversationId, this.runId, final  Map<String, Object?>? payload, this.expiresAt}): _payload = payload;
  factory _PendingAction.fromJson(Map<String, dynamic> json) => _$PendingActionFromJson(json);

@override final  String? actionId;
@override final  String? streamId;
@override final  String? conversationId;
@override final  String? runId;
 final  Map<String, Object?>? _payload;
@override Map<String, Object?>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  int? expiresAt;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingActionCopyWith<_PendingAction> get copyWith => __$PendingActionCopyWithImpl<_PendingAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingAction&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.runId, runId) || other.runId == runId)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionId,streamId,conversationId,runId,const DeepCollectionEquality().hash(_payload),expiresAt);

@override
String toString() {
  return 'PendingAction(actionId: $actionId, streamId: $streamId, conversationId: $conversationId, runId: $runId, payload: $payload, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PendingActionCopyWith<$Res> implements $PendingActionCopyWith<$Res> {
  factory _$PendingActionCopyWith(_PendingAction value, $Res Function(_PendingAction) _then) = __$PendingActionCopyWithImpl;
@override @useResult
$Res call({
 String? actionId, String? streamId, String? conversationId, String? runId, Map<String, Object?>? payload, int? expiresAt
});




}
/// @nodoc
class __$PendingActionCopyWithImpl<$Res>
    implements _$PendingActionCopyWith<$Res> {
  __$PendingActionCopyWithImpl(this._self, this._then);

  final _PendingAction _self;
  final $Res Function(_PendingAction) _then;

/// Create a copy of PendingAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionId = freezed,Object? streamId = freezed,Object? conversationId = freezed,Object? runId = freezed,Object? payload = freezed,Object? expiresAt = freezed,}) {
  return _then(_PendingAction(
actionId: freezed == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String?,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
