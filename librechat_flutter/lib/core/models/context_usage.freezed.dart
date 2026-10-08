// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'context_usage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContextUsage {

 int? get contextBudget; int? get remainingContextTokens; int? get prePruneContextTokens; Map<String, Object?>? get breakdown; String? get runId; String? get agentId;
/// Create a copy of ContextUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextUsageCopyWith<ContextUsage> get copyWith => _$ContextUsageCopyWithImpl<ContextUsage>(this as ContextUsage, _$identity);

  /// Serializes this ContextUsage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextUsage&&(identical(other.contextBudget, contextBudget) || other.contextBudget == contextBudget)&&(identical(other.remainingContextTokens, remainingContextTokens) || other.remainingContextTokens == remainingContextTokens)&&(identical(other.prePruneContextTokens, prePruneContextTokens) || other.prePruneContextTokens == prePruneContextTokens)&&const DeepCollectionEquality().equals(other.breakdown, breakdown)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contextBudget,remainingContextTokens,prePruneContextTokens,const DeepCollectionEquality().hash(breakdown),runId,agentId);

@override
String toString() {
  return 'ContextUsage(contextBudget: $contextBudget, remainingContextTokens: $remainingContextTokens, prePruneContextTokens: $prePruneContextTokens, breakdown: $breakdown, runId: $runId, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $ContextUsageCopyWith<$Res>  {
  factory $ContextUsageCopyWith(ContextUsage value, $Res Function(ContextUsage) _then) = _$ContextUsageCopyWithImpl;
@useResult
$Res call({
 int? contextBudget, int? remainingContextTokens, int? prePruneContextTokens, Map<String, Object?>? breakdown, String? runId, String? agentId
});




}
/// @nodoc
class _$ContextUsageCopyWithImpl<$Res>
    implements $ContextUsageCopyWith<$Res> {
  _$ContextUsageCopyWithImpl(this._self, this._then);

  final ContextUsage _self;
  final $Res Function(ContextUsage) _then;

/// Create a copy of ContextUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contextBudget = freezed,Object? remainingContextTokens = freezed,Object? prePruneContextTokens = freezed,Object? breakdown = freezed,Object? runId = freezed,Object? agentId = freezed,}) {
  return _then(_self.copyWith(
contextBudget: freezed == contextBudget ? _self.contextBudget : contextBudget // ignore: cast_nullable_to_non_nullable
as int?,remainingContextTokens: freezed == remainingContextTokens ? _self.remainingContextTokens : remainingContextTokens // ignore: cast_nullable_to_non_nullable
as int?,prePruneContextTokens: freezed == prePruneContextTokens ? _self.prePruneContextTokens : prePruneContextTokens // ignore: cast_nullable_to_non_nullable
as int?,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContextUsage].
extension ContextUsagePatterns on ContextUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextUsage value)  $default,){
final _that = this;
switch (_that) {
case _ContextUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextUsage value)?  $default,){
final _that = this;
switch (_that) {
case _ContextUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? contextBudget,  int? remainingContextTokens,  int? prePruneContextTokens,  Map<String, Object?>? breakdown,  String? runId,  String? agentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextUsage() when $default != null:
return $default(_that.contextBudget,_that.remainingContextTokens,_that.prePruneContextTokens,_that.breakdown,_that.runId,_that.agentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? contextBudget,  int? remainingContextTokens,  int? prePruneContextTokens,  Map<String, Object?>? breakdown,  String? runId,  String? agentId)  $default,) {final _that = this;
switch (_that) {
case _ContextUsage():
return $default(_that.contextBudget,_that.remainingContextTokens,_that.prePruneContextTokens,_that.breakdown,_that.runId,_that.agentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? contextBudget,  int? remainingContextTokens,  int? prePruneContextTokens,  Map<String, Object?>? breakdown,  String? runId,  String? agentId)?  $default,) {final _that = this;
switch (_that) {
case _ContextUsage() when $default != null:
return $default(_that.contextBudget,_that.remainingContextTokens,_that.prePruneContextTokens,_that.breakdown,_that.runId,_that.agentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextUsage implements ContextUsage {
  const _ContextUsage({this.contextBudget, this.remainingContextTokens, this.prePruneContextTokens, final  Map<String, Object?>? breakdown, this.runId, this.agentId}): _breakdown = breakdown;
  factory _ContextUsage.fromJson(Map<String, dynamic> json) => _$ContextUsageFromJson(json);

@override final  int? contextBudget;
@override final  int? remainingContextTokens;
@override final  int? prePruneContextTokens;
 final  Map<String, Object?>? _breakdown;
@override Map<String, Object?>? get breakdown {
  final value = _breakdown;
  if (value == null) return null;
  if (_breakdown is EqualUnmodifiableMapView) return _breakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? runId;
@override final  String? agentId;

/// Create a copy of ContextUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextUsageCopyWith<_ContextUsage> get copyWith => __$ContextUsageCopyWithImpl<_ContextUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextUsageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextUsage&&(identical(other.contextBudget, contextBudget) || other.contextBudget == contextBudget)&&(identical(other.remainingContextTokens, remainingContextTokens) || other.remainingContextTokens == remainingContextTokens)&&(identical(other.prePruneContextTokens, prePruneContextTokens) || other.prePruneContextTokens == prePruneContextTokens)&&const DeepCollectionEquality().equals(other._breakdown, _breakdown)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contextBudget,remainingContextTokens,prePruneContextTokens,const DeepCollectionEquality().hash(_breakdown),runId,agentId);

@override
String toString() {
  return 'ContextUsage(contextBudget: $contextBudget, remainingContextTokens: $remainingContextTokens, prePruneContextTokens: $prePruneContextTokens, breakdown: $breakdown, runId: $runId, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class _$ContextUsageCopyWith<$Res> implements $ContextUsageCopyWith<$Res> {
  factory _$ContextUsageCopyWith(_ContextUsage value, $Res Function(_ContextUsage) _then) = __$ContextUsageCopyWithImpl;
@override @useResult
$Res call({
 int? contextBudget, int? remainingContextTokens, int? prePruneContextTokens, Map<String, Object?>? breakdown, String? runId, String? agentId
});




}
/// @nodoc
class __$ContextUsageCopyWithImpl<$Res>
    implements _$ContextUsageCopyWith<$Res> {
  __$ContextUsageCopyWithImpl(this._self, this._then);

  final _ContextUsage _self;
  final $Res Function(_ContextUsage) _then;

/// Create a copy of ContextUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contextBudget = freezed,Object? remainingContextTokens = freezed,Object? prePruneContextTokens = freezed,Object? breakdown = freezed,Object? runId = freezed,Object? agentId = freezed,}) {
  return _then(_ContextUsage(
contextBudget: freezed == contextBudget ? _self.contextBudget : contextBudget // ignore: cast_nullable_to_non_nullable
as int?,remainingContextTokens: freezed == remainingContextTokens ? _self.remainingContextTokens : remainingContextTokens // ignore: cast_nullable_to_non_nullable
as int?,prePruneContextTokens: freezed == prePruneContextTokens ? _self.prePruneContextTokens : prePruneContextTokens // ignore: cast_nullable_to_non_nullable
as int?,breakdown: freezed == breakdown ? _self._breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
