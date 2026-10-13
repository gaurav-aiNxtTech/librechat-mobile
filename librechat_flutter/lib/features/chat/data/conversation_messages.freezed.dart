// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationMessages {

 List<Message> get messages; Map<String, String> get selection; Set<String> get localIds; String? get justSettledId; bool get refreshing; Object? get refreshError;
/// Create a copy of ConversationMessages
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationMessagesCopyWith<ConversationMessages> get copyWith => _$ConversationMessagesCopyWithImpl<ConversationMessages>(this as ConversationMessages, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationMessages&&const DeepCollectionEquality().equals(other.messages, messages)&&const DeepCollectionEquality().equals(other.selection, selection)&&const DeepCollectionEquality().equals(other.localIds, localIds)&&(identical(other.justSettledId, justSettledId) || other.justSettledId == justSettledId)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&const DeepCollectionEquality().equals(other.refreshError, refreshError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),const DeepCollectionEquality().hash(selection),const DeepCollectionEquality().hash(localIds),justSettledId,refreshing,const DeepCollectionEquality().hash(refreshError));

@override
String toString() {
  return 'ConversationMessages(messages: $messages, selection: $selection, localIds: $localIds, justSettledId: $justSettledId, refreshing: $refreshing, refreshError: $refreshError)';
}


}

/// @nodoc
abstract mixin class $ConversationMessagesCopyWith<$Res>  {
  factory $ConversationMessagesCopyWith(ConversationMessages value, $Res Function(ConversationMessages) _then) = _$ConversationMessagesCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, Map<String, String> selection, Set<String> localIds, String? justSettledId, bool refreshing, Object? refreshError
});




}
/// @nodoc
class _$ConversationMessagesCopyWithImpl<$Res>
    implements $ConversationMessagesCopyWith<$Res> {
  _$ConversationMessagesCopyWithImpl(this._self, this._then);

  final ConversationMessages _self;
  final $Res Function(ConversationMessages) _then;

/// Create a copy of ConversationMessages
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? selection = null,Object? localIds = null,Object? justSettledId = freezed,Object? refreshing = null,Object? refreshError = freezed,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as Map<String, String>,localIds: null == localIds ? _self.localIds : localIds // ignore: cast_nullable_to_non_nullable
as Set<String>,justSettledId: freezed == justSettledId ? _self.justSettledId : justSettledId // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshError: freezed == refreshError ? _self.refreshError : refreshError ,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationMessages].
extension ConversationMessagesPatterns on ConversationMessages {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationMessages value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationMessages() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationMessages value)  $default,){
final _that = this;
switch (_that) {
case _ConversationMessages():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationMessages value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationMessages() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  Map<String, String> selection,  Set<String> localIds,  String? justSettledId,  bool refreshing,  Object? refreshError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationMessages() when $default != null:
return $default(_that.messages,_that.selection,_that.localIds,_that.justSettledId,_that.refreshing,_that.refreshError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  Map<String, String> selection,  Set<String> localIds,  String? justSettledId,  bool refreshing,  Object? refreshError)  $default,) {final _that = this;
switch (_that) {
case _ConversationMessages():
return $default(_that.messages,_that.selection,_that.localIds,_that.justSettledId,_that.refreshing,_that.refreshError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  Map<String, String> selection,  Set<String> localIds,  String? justSettledId,  bool refreshing,  Object? refreshError)?  $default,) {final _that = this;
switch (_that) {
case _ConversationMessages() when $default != null:
return $default(_that.messages,_that.selection,_that.localIds,_that.justSettledId,_that.refreshing,_that.refreshError);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationMessages extends ConversationMessages {
  const _ConversationMessages({final  List<Message> messages = const <Message>[], final  Map<String, String> selection = const <String, String>{}, final  Set<String> localIds = const <String>{}, this.justSettledId, this.refreshing = false, this.refreshError}): _messages = messages,_selection = selection,_localIds = localIds,super._();
  

 final  List<Message> _messages;
@override@JsonKey() List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

 final  Map<String, String> _selection;
@override@JsonKey() Map<String, String> get selection {
  if (_selection is EqualUnmodifiableMapView) return _selection;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selection);
}

 final  Set<String> _localIds;
@override@JsonKey() Set<String> get localIds {
  if (_localIds is EqualUnmodifiableSetView) return _localIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_localIds);
}

@override final  String? justSettledId;
@override@JsonKey() final  bool refreshing;
@override final  Object? refreshError;

/// Create a copy of ConversationMessages
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationMessagesCopyWith<_ConversationMessages> get copyWith => __$ConversationMessagesCopyWithImpl<_ConversationMessages>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationMessages&&const DeepCollectionEquality().equals(other._messages, _messages)&&const DeepCollectionEquality().equals(other._selection, _selection)&&const DeepCollectionEquality().equals(other._localIds, _localIds)&&(identical(other.justSettledId, justSettledId) || other.justSettledId == justSettledId)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&const DeepCollectionEquality().equals(other.refreshError, refreshError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),const DeepCollectionEquality().hash(_selection),const DeepCollectionEquality().hash(_localIds),justSettledId,refreshing,const DeepCollectionEquality().hash(refreshError));

@override
String toString() {
  return 'ConversationMessages(messages: $messages, selection: $selection, localIds: $localIds, justSettledId: $justSettledId, refreshing: $refreshing, refreshError: $refreshError)';
}


}

/// @nodoc
abstract mixin class _$ConversationMessagesCopyWith<$Res> implements $ConversationMessagesCopyWith<$Res> {
  factory _$ConversationMessagesCopyWith(_ConversationMessages value, $Res Function(_ConversationMessages) _then) = __$ConversationMessagesCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, Map<String, String> selection, Set<String> localIds, String? justSettledId, bool refreshing, Object? refreshError
});




}
/// @nodoc
class __$ConversationMessagesCopyWithImpl<$Res>
    implements _$ConversationMessagesCopyWith<$Res> {
  __$ConversationMessagesCopyWithImpl(this._self, this._then);

  final _ConversationMessages _self;
  final $Res Function(_ConversationMessages) _then;

/// Create a copy of ConversationMessages
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? selection = null,Object? localIds = null,Object? justSettledId = freezed,Object? refreshing = null,Object? refreshError = freezed,}) {
  return _then(_ConversationMessages(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,selection: null == selection ? _self._selection : selection // ignore: cast_nullable_to_non_nullable
as Map<String, String>,localIds: null == localIds ? _self._localIds : localIds // ignore: cast_nullable_to_non_nullable
as Set<String>,justSettledId: freezed == justSettledId ? _self.justSettledId : justSettledId // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshError: freezed == refreshError ? _self.refreshError : refreshError ,
  ));
}


}

// dart format on
