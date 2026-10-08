// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_usage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TokenUsage {

@JsonKey(name: 'input_tokens') int? get inputTokens;@JsonKey(name: 'output_tokens') int? get outputTokens;@JsonKey(name: 'total_tokens') int? get totalTokens; String? get model; String? get provider;@JsonKey(name: 'usage_type') String? get usageType;
/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<TokenUsage> get copyWith => _$TokenUsageCopyWithImpl<TokenUsage>(this as TokenUsage, _$identity);

  /// Serializes this TokenUsage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenUsage&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.model, model) || other.model == model)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.usageType, usageType) || other.usageType == usageType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputTokens,outputTokens,totalTokens,model,provider,usageType);

@override
String toString() {
  return 'TokenUsage(inputTokens: $inputTokens, outputTokens: $outputTokens, totalTokens: $totalTokens, model: $model, provider: $provider, usageType: $usageType)';
}


}

/// @nodoc
abstract mixin class $TokenUsageCopyWith<$Res>  {
  factory $TokenUsageCopyWith(TokenUsage value, $Res Function(TokenUsage) _then) = _$TokenUsageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'input_tokens') int? inputTokens,@JsonKey(name: 'output_tokens') int? outputTokens,@JsonKey(name: 'total_tokens') int? totalTokens, String? model, String? provider,@JsonKey(name: 'usage_type') String? usageType
});




}
/// @nodoc
class _$TokenUsageCopyWithImpl<$Res>
    implements $TokenUsageCopyWith<$Res> {
  _$TokenUsageCopyWithImpl(this._self, this._then);

  final TokenUsage _self;
  final $Res Function(TokenUsage) _then;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputTokens = freezed,Object? outputTokens = freezed,Object? totalTokens = freezed,Object? model = freezed,Object? provider = freezed,Object? usageType = freezed,}) {
  return _then(_self.copyWith(
inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,usageType: freezed == usageType ? _self.usageType : usageType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenUsage].
extension TokenUsagePatterns on TokenUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenUsage value)  $default,){
final _that = this;
switch (_that) {
case _TokenUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenUsage value)?  $default,){
final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'input_tokens')  int? inputTokens, @JsonKey(name: 'output_tokens')  int? outputTokens, @JsonKey(name: 'total_tokens')  int? totalTokens,  String? model,  String? provider, @JsonKey(name: 'usage_type')  String? usageType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.totalTokens,_that.model,_that.provider,_that.usageType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'input_tokens')  int? inputTokens, @JsonKey(name: 'output_tokens')  int? outputTokens, @JsonKey(name: 'total_tokens')  int? totalTokens,  String? model,  String? provider, @JsonKey(name: 'usage_type')  String? usageType)  $default,) {final _that = this;
switch (_that) {
case _TokenUsage():
return $default(_that.inputTokens,_that.outputTokens,_that.totalTokens,_that.model,_that.provider,_that.usageType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'input_tokens')  int? inputTokens, @JsonKey(name: 'output_tokens')  int? outputTokens, @JsonKey(name: 'total_tokens')  int? totalTokens,  String? model,  String? provider, @JsonKey(name: 'usage_type')  String? usageType)?  $default,) {final _that = this;
switch (_that) {
case _TokenUsage() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.totalTokens,_that.model,_that.provider,_that.usageType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenUsage implements TokenUsage {
  const _TokenUsage({@JsonKey(name: 'input_tokens') this.inputTokens, @JsonKey(name: 'output_tokens') this.outputTokens, @JsonKey(name: 'total_tokens') this.totalTokens, this.model, this.provider, @JsonKey(name: 'usage_type') this.usageType});
  factory _TokenUsage.fromJson(Map<String, dynamic> json) => _$TokenUsageFromJson(json);

@override@JsonKey(name: 'input_tokens') final  int? inputTokens;
@override@JsonKey(name: 'output_tokens') final  int? outputTokens;
@override@JsonKey(name: 'total_tokens') final  int? totalTokens;
@override final  String? model;
@override final  String? provider;
@override@JsonKey(name: 'usage_type') final  String? usageType;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenUsageCopyWith<_TokenUsage> get copyWith => __$TokenUsageCopyWithImpl<_TokenUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenUsageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenUsage&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens)&&(identical(other.model, model) || other.model == model)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.usageType, usageType) || other.usageType == usageType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputTokens,outputTokens,totalTokens,model,provider,usageType);

@override
String toString() {
  return 'TokenUsage(inputTokens: $inputTokens, outputTokens: $outputTokens, totalTokens: $totalTokens, model: $model, provider: $provider, usageType: $usageType)';
}


}

/// @nodoc
abstract mixin class _$TokenUsageCopyWith<$Res> implements $TokenUsageCopyWith<$Res> {
  factory _$TokenUsageCopyWith(_TokenUsage value, $Res Function(_TokenUsage) _then) = __$TokenUsageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'input_tokens') int? inputTokens,@JsonKey(name: 'output_tokens') int? outputTokens,@JsonKey(name: 'total_tokens') int? totalTokens, String? model, String? provider,@JsonKey(name: 'usage_type') String? usageType
});




}
/// @nodoc
class __$TokenUsageCopyWithImpl<$Res>
    implements _$TokenUsageCopyWith<$Res> {
  __$TokenUsageCopyWithImpl(this._self, this._then);

  final _TokenUsage _self;
  final $Res Function(_TokenUsage) _then;

/// Create a copy of TokenUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputTokens = freezed,Object? outputTokens = freezed,Object? totalTokens = freezed,Object? model = freezed,Object? provider = freezed,Object? usageType = freezed,}) {
  return _then(_TokenUsage(
inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,totalTokens: freezed == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,usageType: freezed == usageType ? _self.usageType : usageType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
