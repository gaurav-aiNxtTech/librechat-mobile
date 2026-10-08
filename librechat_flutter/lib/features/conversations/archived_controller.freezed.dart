// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'archived_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArchivedState {

 List<Conversation> get items; String? get nextCursor; bool get loading; bool get loadingMore; Object? get error; Object? get pageError;
/// Create a copy of ArchivedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchivedStateCopyWith<ArchivedState> get copyWith => _$ArchivedStateCopyWithImpl<ArchivedState>(this as ArchivedState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchivedState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&const DeepCollectionEquality().equals(other.pageError, pageError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor,loading,loadingMore,const DeepCollectionEquality().hash(error),const DeepCollectionEquality().hash(pageError));

@override
String toString() {
  return 'ArchivedState(items: $items, nextCursor: $nextCursor, loading: $loading, loadingMore: $loadingMore, error: $error, pageError: $pageError)';
}


}

/// @nodoc
abstract mixin class $ArchivedStateCopyWith<$Res>  {
  factory $ArchivedStateCopyWith(ArchivedState value, $Res Function(ArchivedState) _then) = _$ArchivedStateCopyWithImpl;
@useResult
$Res call({
 List<Conversation> items, String? nextCursor, bool loading, bool loadingMore, Object? error, Object? pageError
});




}
/// @nodoc
class _$ArchivedStateCopyWithImpl<$Res>
    implements $ArchivedStateCopyWith<$Res> {
  _$ArchivedStateCopyWithImpl(this._self, this._then);

  final ArchivedState _self;
  final $Res Function(ArchivedState) _then;

/// Create a copy of ArchivedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? loading = null,Object? loadingMore = null,Object? error = freezed,Object? pageError = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Conversation>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,pageError: freezed == pageError ? _self.pageError : pageError ,
  ));
}

}


/// Adds pattern-matching-related methods to [ArchivedState].
extension ArchivedStatePatterns on ArchivedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArchivedState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArchivedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArchivedState value)  $default,){
final _that = this;
switch (_that) {
case _ArchivedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArchivedState value)?  $default,){
final _that = this;
switch (_that) {
case _ArchivedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Conversation> items,  String? nextCursor,  bool loading,  bool loadingMore,  Object? error,  Object? pageError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArchivedState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.loading,_that.loadingMore,_that.error,_that.pageError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Conversation> items,  String? nextCursor,  bool loading,  bool loadingMore,  Object? error,  Object? pageError)  $default,) {final _that = this;
switch (_that) {
case _ArchivedState():
return $default(_that.items,_that.nextCursor,_that.loading,_that.loadingMore,_that.error,_that.pageError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Conversation> items,  String? nextCursor,  bool loading,  bool loadingMore,  Object? error,  Object? pageError)?  $default,) {final _that = this;
switch (_that) {
case _ArchivedState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.loading,_that.loadingMore,_that.error,_that.pageError);case _:
  return null;

}
}

}

/// @nodoc


class _ArchivedState implements ArchivedState {
  const _ArchivedState({final  List<Conversation> items = const <Conversation>[], this.nextCursor, this.loading = true, this.loadingMore = false, this.error, this.pageError}): _items = items;
  

 final  List<Conversation> _items;
@override@JsonKey() List<Conversation> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
@override final  Object? error;
@override final  Object? pageError;

/// Create a copy of ArchivedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArchivedStateCopyWith<_ArchivedState> get copyWith => __$ArchivedStateCopyWithImpl<_ArchivedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArchivedState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&const DeepCollectionEquality().equals(other.pageError, pageError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,loading,loadingMore,const DeepCollectionEquality().hash(error),const DeepCollectionEquality().hash(pageError));

@override
String toString() {
  return 'ArchivedState(items: $items, nextCursor: $nextCursor, loading: $loading, loadingMore: $loadingMore, error: $error, pageError: $pageError)';
}


}

/// @nodoc
abstract mixin class _$ArchivedStateCopyWith<$Res> implements $ArchivedStateCopyWith<$Res> {
  factory _$ArchivedStateCopyWith(_ArchivedState value, $Res Function(_ArchivedState) _then) = __$ArchivedStateCopyWithImpl;
@override @useResult
$Res call({
 List<Conversation> items, String? nextCursor, bool loading, bool loadingMore, Object? error, Object? pageError
});




}
/// @nodoc
class __$ArchivedStateCopyWithImpl<$Res>
    implements _$ArchivedStateCopyWith<$Res> {
  __$ArchivedStateCopyWithImpl(this._self, this._then);

  final _ArchivedState _self;
  final $Res Function(_ArchivedState) _then;

/// Create a copy of ArchivedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? loading = null,Object? loadingMore = null,Object? error = freezed,Object? pageError = freezed,}) {
  return _then(_ArchivedState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Conversation>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,pageError: freezed == pageError ? _self.pageError : pageError ,
  ));
}


}

// dart format on
