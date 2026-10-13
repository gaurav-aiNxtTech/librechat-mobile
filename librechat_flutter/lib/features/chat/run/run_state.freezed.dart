// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubagentProgress {

 SubagentStatus get status; String? get parentToolCallId; String? get label; String? get type;
/// Create a copy of SubagentProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubagentProgressCopyWith<SubagentProgress> get copyWith => _$SubagentProgressCopyWithImpl<SubagentProgress>(this as SubagentProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubagentProgress&&(identical(other.status, status) || other.status == status)&&(identical(other.parentToolCallId, parentToolCallId) || other.parentToolCallId == parentToolCallId)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,status,parentToolCallId,label,type);

@override
String toString() {
  return 'SubagentProgress(status: $status, parentToolCallId: $parentToolCallId, label: $label, type: $type)';
}


}

/// @nodoc
abstract mixin class $SubagentProgressCopyWith<$Res>  {
  factory $SubagentProgressCopyWith(SubagentProgress value, $Res Function(SubagentProgress) _then) = _$SubagentProgressCopyWithImpl;
@useResult
$Res call({
 SubagentStatus status, String? parentToolCallId, String? label, String? type
});




}
/// @nodoc
class _$SubagentProgressCopyWithImpl<$Res>
    implements $SubagentProgressCopyWith<$Res> {
  _$SubagentProgressCopyWithImpl(this._self, this._then);

  final SubagentProgress _self;
  final $Res Function(SubagentProgress) _then;

/// Create a copy of SubagentProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? parentToolCallId = freezed,Object? label = freezed,Object? type = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubagentStatus,parentToolCallId: freezed == parentToolCallId ? _self.parentToolCallId : parentToolCallId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubagentProgress].
extension SubagentProgressPatterns on SubagentProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubagentProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubagentProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubagentProgress value)  $default,){
final _that = this;
switch (_that) {
case _SubagentProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubagentProgress value)?  $default,){
final _that = this;
switch (_that) {
case _SubagentProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubagentStatus status,  String? parentToolCallId,  String? label,  String? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubagentProgress() when $default != null:
return $default(_that.status,_that.parentToolCallId,_that.label,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubagentStatus status,  String? parentToolCallId,  String? label,  String? type)  $default,) {final _that = this;
switch (_that) {
case _SubagentProgress():
return $default(_that.status,_that.parentToolCallId,_that.label,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubagentStatus status,  String? parentToolCallId,  String? label,  String? type)?  $default,) {final _that = this;
switch (_that) {
case _SubagentProgress() when $default != null:
return $default(_that.status,_that.parentToolCallId,_that.label,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _SubagentProgress implements SubagentProgress {
  const _SubagentProgress({required this.status, this.parentToolCallId, this.label, this.type});
  

@override final  SubagentStatus status;
@override final  String? parentToolCallId;
@override final  String? label;
@override final  String? type;

/// Create a copy of SubagentProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubagentProgressCopyWith<_SubagentProgress> get copyWith => __$SubagentProgressCopyWithImpl<_SubagentProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubagentProgress&&(identical(other.status, status) || other.status == status)&&(identical(other.parentToolCallId, parentToolCallId) || other.parentToolCallId == parentToolCallId)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,status,parentToolCallId,label,type);

@override
String toString() {
  return 'SubagentProgress(status: $status, parentToolCallId: $parentToolCallId, label: $label, type: $type)';
}


}

/// @nodoc
abstract mixin class _$SubagentProgressCopyWith<$Res> implements $SubagentProgressCopyWith<$Res> {
  factory _$SubagentProgressCopyWith(_SubagentProgress value, $Res Function(_SubagentProgress) _then) = __$SubagentProgressCopyWithImpl;
@override @useResult
$Res call({
 SubagentStatus status, String? parentToolCallId, String? label, String? type
});




}
/// @nodoc
class __$SubagentProgressCopyWithImpl<$Res>
    implements _$SubagentProgressCopyWith<$Res> {
  __$SubagentProgressCopyWithImpl(this._self, this._then);

  final _SubagentProgress _self;
  final $Res Function(_SubagentProgress) _then;

/// Create a copy of SubagentProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? parentToolCallId = freezed,Object? label = freezed,Object? type = freezed,}) {
  return _then(_SubagentProgress(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubagentStatus,parentToolCallId: freezed == parentToolCallId ? _self.parentToolCallId : parentToolCallId // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$RunState {

 String get key; TurnKind get kind; ChatSelection get selection; String? get conversationId; String? get streamId; String? get requestMessageId; int? get generationCreatedAt; bool get isTemporary; bool get isComparison; bool get firstRunOfNewChat; Message? get optimistic; String? get anchorId; RunPhase get phase; int get attempt; bool get resumedOnce; bool get stopping; List<ContentPart> get parts; List<Attachment> get attachments; PendingAction? get pendingAction; String? get actionError; Map<String, SubagentProgress> get subagents; String? get title; String? get error; int get epoch;
/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunStateCopyWith<RunState> get copyWith => _$RunStateCopyWithImpl<RunState>(this as RunState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunState&&(identical(other.key, key) || other.key == key)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.requestMessageId, requestMessageId) || other.requestMessageId == requestMessageId)&&(identical(other.generationCreatedAt, generationCreatedAt) || other.generationCreatedAt == generationCreatedAt)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.isComparison, isComparison) || other.isComparison == isComparison)&&(identical(other.firstRunOfNewChat, firstRunOfNewChat) || other.firstRunOfNewChat == firstRunOfNewChat)&&(identical(other.optimistic, optimistic) || other.optimistic == optimistic)&&(identical(other.anchorId, anchorId) || other.anchorId == anchorId)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.resumedOnce, resumedOnce) || other.resumedOnce == resumedOnce)&&(identical(other.stopping, stopping) || other.stopping == stopping)&&const DeepCollectionEquality().equals(other.parts, parts)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.pendingAction, pendingAction) || other.pendingAction == pendingAction)&&(identical(other.actionError, actionError) || other.actionError == actionError)&&const DeepCollectionEquality().equals(other.subagents, subagents)&&(identical(other.title, title) || other.title == title)&&(identical(other.error, error) || other.error == error)&&(identical(other.epoch, epoch) || other.epoch == epoch));
}


@override
int get hashCode => Object.hashAll([runtimeType,key,kind,selection,conversationId,streamId,requestMessageId,generationCreatedAt,isTemporary,isComparison,firstRunOfNewChat,optimistic,anchorId,phase,attempt,resumedOnce,stopping,const DeepCollectionEquality().hash(parts),const DeepCollectionEquality().hash(attachments),pendingAction,actionError,const DeepCollectionEquality().hash(subagents),title,error,epoch]);

@override
String toString() {
  return 'RunState(key: $key, kind: $kind, selection: $selection, conversationId: $conversationId, streamId: $streamId, requestMessageId: $requestMessageId, generationCreatedAt: $generationCreatedAt, isTemporary: $isTemporary, isComparison: $isComparison, firstRunOfNewChat: $firstRunOfNewChat, optimistic: $optimistic, anchorId: $anchorId, phase: $phase, attempt: $attempt, resumedOnce: $resumedOnce, stopping: $stopping, parts: $parts, attachments: $attachments, pendingAction: $pendingAction, actionError: $actionError, subagents: $subagents, title: $title, error: $error, epoch: $epoch)';
}


}

/// @nodoc
abstract mixin class $RunStateCopyWith<$Res>  {
  factory $RunStateCopyWith(RunState value, $Res Function(RunState) _then) = _$RunStateCopyWithImpl;
@useResult
$Res call({
 String key, TurnKind kind, ChatSelection selection, String? conversationId, String? streamId, String? requestMessageId, int? generationCreatedAt, bool isTemporary, bool isComparison, bool firstRunOfNewChat, Message? optimistic, String? anchorId, RunPhase phase, int attempt, bool resumedOnce, bool stopping, List<ContentPart> parts, List<Attachment> attachments, PendingAction? pendingAction, String? actionError, Map<String, SubagentProgress> subagents, String? title, String? error, int epoch
});


$ChatSelectionCopyWith<$Res> get selection;$MessageCopyWith<$Res>? get optimistic;$PendingActionCopyWith<$Res>? get pendingAction;

}
/// @nodoc
class _$RunStateCopyWithImpl<$Res>
    implements $RunStateCopyWith<$Res> {
  _$RunStateCopyWithImpl(this._self, this._then);

  final RunState _self;
  final $Res Function(RunState) _then;

/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? kind = null,Object? selection = null,Object? conversationId = freezed,Object? streamId = freezed,Object? requestMessageId = freezed,Object? generationCreatedAt = freezed,Object? isTemporary = null,Object? isComparison = null,Object? firstRunOfNewChat = null,Object? optimistic = freezed,Object? anchorId = freezed,Object? phase = null,Object? attempt = null,Object? resumedOnce = null,Object? stopping = null,Object? parts = null,Object? attachments = null,Object? pendingAction = freezed,Object? actionError = freezed,Object? subagents = null,Object? title = freezed,Object? error = freezed,Object? epoch = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as ChatSelection,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,requestMessageId: freezed == requestMessageId ? _self.requestMessageId : requestMessageId // ignore: cast_nullable_to_non_nullable
as String?,generationCreatedAt: freezed == generationCreatedAt ? _self.generationCreatedAt : generationCreatedAt // ignore: cast_nullable_to_non_nullable
as int?,isTemporary: null == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool,isComparison: null == isComparison ? _self.isComparison : isComparison // ignore: cast_nullable_to_non_nullable
as bool,firstRunOfNewChat: null == firstRunOfNewChat ? _self.firstRunOfNewChat : firstRunOfNewChat // ignore: cast_nullable_to_non_nullable
as bool,optimistic: freezed == optimistic ? _self.optimistic : optimistic // ignore: cast_nullable_to_non_nullable
as Message?,anchorId: freezed == anchorId ? _self.anchorId : anchorId // ignore: cast_nullable_to_non_nullable
as String?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as RunPhase,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,resumedOnce: null == resumedOnce ? _self.resumedOnce : resumedOnce // ignore: cast_nullable_to_non_nullable
as bool,stopping: null == stopping ? _self.stopping : stopping // ignore: cast_nullable_to_non_nullable
as bool,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<ContentPart>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,pendingAction: freezed == pendingAction ? _self.pendingAction : pendingAction // ignore: cast_nullable_to_non_nullable
as PendingAction?,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,subagents: null == subagents ? _self.subagents : subagents // ignore: cast_nullable_to_non_nullable
as Map<String, SubagentProgress>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,epoch: null == epoch ? _self.epoch : epoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res> get selection {
  
  return $ChatSelectionCopyWith<$Res>(_self.selection, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get optimistic {
    if (_self.optimistic == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.optimistic!, (value) {
    return _then(_self.copyWith(optimistic: value));
  });
}/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingActionCopyWith<$Res>? get pendingAction {
    if (_self.pendingAction == null) {
    return null;
  }

  return $PendingActionCopyWith<$Res>(_self.pendingAction!, (value) {
    return _then(_self.copyWith(pendingAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [RunState].
extension RunStatePatterns on RunState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RunState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RunState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RunState value)  $default,){
final _that = this;
switch (_that) {
case _RunState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RunState value)?  $default,){
final _that = this;
switch (_that) {
case _RunState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  TurnKind kind,  ChatSelection selection,  String? conversationId,  String? streamId,  String? requestMessageId,  int? generationCreatedAt,  bool isTemporary,  bool isComparison,  bool firstRunOfNewChat,  Message? optimistic,  String? anchorId,  RunPhase phase,  int attempt,  bool resumedOnce,  bool stopping,  List<ContentPart> parts,  List<Attachment> attachments,  PendingAction? pendingAction,  String? actionError,  Map<String, SubagentProgress> subagents,  String? title,  String? error,  int epoch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RunState() when $default != null:
return $default(_that.key,_that.kind,_that.selection,_that.conversationId,_that.streamId,_that.requestMessageId,_that.generationCreatedAt,_that.isTemporary,_that.isComparison,_that.firstRunOfNewChat,_that.optimistic,_that.anchorId,_that.phase,_that.attempt,_that.resumedOnce,_that.stopping,_that.parts,_that.attachments,_that.pendingAction,_that.actionError,_that.subagents,_that.title,_that.error,_that.epoch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  TurnKind kind,  ChatSelection selection,  String? conversationId,  String? streamId,  String? requestMessageId,  int? generationCreatedAt,  bool isTemporary,  bool isComparison,  bool firstRunOfNewChat,  Message? optimistic,  String? anchorId,  RunPhase phase,  int attempt,  bool resumedOnce,  bool stopping,  List<ContentPart> parts,  List<Attachment> attachments,  PendingAction? pendingAction,  String? actionError,  Map<String, SubagentProgress> subagents,  String? title,  String? error,  int epoch)  $default,) {final _that = this;
switch (_that) {
case _RunState():
return $default(_that.key,_that.kind,_that.selection,_that.conversationId,_that.streamId,_that.requestMessageId,_that.generationCreatedAt,_that.isTemporary,_that.isComparison,_that.firstRunOfNewChat,_that.optimistic,_that.anchorId,_that.phase,_that.attempt,_that.resumedOnce,_that.stopping,_that.parts,_that.attachments,_that.pendingAction,_that.actionError,_that.subagents,_that.title,_that.error,_that.epoch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  TurnKind kind,  ChatSelection selection,  String? conversationId,  String? streamId,  String? requestMessageId,  int? generationCreatedAt,  bool isTemporary,  bool isComparison,  bool firstRunOfNewChat,  Message? optimistic,  String? anchorId,  RunPhase phase,  int attempt,  bool resumedOnce,  bool stopping,  List<ContentPart> parts,  List<Attachment> attachments,  PendingAction? pendingAction,  String? actionError,  Map<String, SubagentProgress> subagents,  String? title,  String? error,  int epoch)?  $default,) {final _that = this;
switch (_that) {
case _RunState() when $default != null:
return $default(_that.key,_that.kind,_that.selection,_that.conversationId,_that.streamId,_that.requestMessageId,_that.generationCreatedAt,_that.isTemporary,_that.isComparison,_that.firstRunOfNewChat,_that.optimistic,_that.anchorId,_that.phase,_that.attempt,_that.resumedOnce,_that.stopping,_that.parts,_that.attachments,_that.pendingAction,_that.actionError,_that.subagents,_that.title,_that.error,_that.epoch);case _:
  return null;

}
}

}

/// @nodoc


class _RunState extends RunState {
  const _RunState({required this.key, required this.kind, required this.selection, this.conversationId, this.streamId, this.requestMessageId, this.generationCreatedAt, this.isTemporary = false, this.isComparison = false, this.firstRunOfNewChat = false, this.optimistic, this.anchorId, this.phase = RunPhase.starting, this.attempt = 0, this.resumedOnce = false, this.stopping = false, final  List<ContentPart> parts = const <ContentPart>[], final  List<Attachment> attachments = const <Attachment>[], this.pendingAction, this.actionError, final  Map<String, SubagentProgress> subagents = const <String, SubagentProgress>{}, this.title, this.error, this.epoch = 0}): _parts = parts,_attachments = attachments,_subagents = subagents,super._();
  

@override final  String key;
@override final  TurnKind kind;
@override final  ChatSelection selection;
@override final  String? conversationId;
@override final  String? streamId;
@override final  String? requestMessageId;
@override final  int? generationCreatedAt;
@override@JsonKey() final  bool isTemporary;
@override@JsonKey() final  bool isComparison;
@override@JsonKey() final  bool firstRunOfNewChat;
@override final  Message? optimistic;
@override final  String? anchorId;
@override@JsonKey() final  RunPhase phase;
@override@JsonKey() final  int attempt;
@override@JsonKey() final  bool resumedOnce;
@override@JsonKey() final  bool stopping;
 final  List<ContentPart> _parts;
@override@JsonKey() List<ContentPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

 final  List<Attachment> _attachments;
@override@JsonKey() List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override final  PendingAction? pendingAction;
@override final  String? actionError;
 final  Map<String, SubagentProgress> _subagents;
@override@JsonKey() Map<String, SubagentProgress> get subagents {
  if (_subagents is EqualUnmodifiableMapView) return _subagents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_subagents);
}

@override final  String? title;
@override final  String? error;
@override@JsonKey() final  int epoch;

/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunStateCopyWith<_RunState> get copyWith => __$RunStateCopyWithImpl<_RunState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RunState&&(identical(other.key, key) || other.key == key)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.requestMessageId, requestMessageId) || other.requestMessageId == requestMessageId)&&(identical(other.generationCreatedAt, generationCreatedAt) || other.generationCreatedAt == generationCreatedAt)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.isComparison, isComparison) || other.isComparison == isComparison)&&(identical(other.firstRunOfNewChat, firstRunOfNewChat) || other.firstRunOfNewChat == firstRunOfNewChat)&&(identical(other.optimistic, optimistic) || other.optimistic == optimistic)&&(identical(other.anchorId, anchorId) || other.anchorId == anchorId)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.resumedOnce, resumedOnce) || other.resumedOnce == resumedOnce)&&(identical(other.stopping, stopping) || other.stopping == stopping)&&const DeepCollectionEquality().equals(other._parts, _parts)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.pendingAction, pendingAction) || other.pendingAction == pendingAction)&&(identical(other.actionError, actionError) || other.actionError == actionError)&&const DeepCollectionEquality().equals(other._subagents, _subagents)&&(identical(other.title, title) || other.title == title)&&(identical(other.error, error) || other.error == error)&&(identical(other.epoch, epoch) || other.epoch == epoch));
}


@override
int get hashCode => Object.hashAll([runtimeType,key,kind,selection,conversationId,streamId,requestMessageId,generationCreatedAt,isTemporary,isComparison,firstRunOfNewChat,optimistic,anchorId,phase,attempt,resumedOnce,stopping,const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_attachments),pendingAction,actionError,const DeepCollectionEquality().hash(_subagents),title,error,epoch]);

@override
String toString() {
  return 'RunState(key: $key, kind: $kind, selection: $selection, conversationId: $conversationId, streamId: $streamId, requestMessageId: $requestMessageId, generationCreatedAt: $generationCreatedAt, isTemporary: $isTemporary, isComparison: $isComparison, firstRunOfNewChat: $firstRunOfNewChat, optimistic: $optimistic, anchorId: $anchorId, phase: $phase, attempt: $attempt, resumedOnce: $resumedOnce, stopping: $stopping, parts: $parts, attachments: $attachments, pendingAction: $pendingAction, actionError: $actionError, subagents: $subagents, title: $title, error: $error, epoch: $epoch)';
}


}

/// @nodoc
abstract mixin class _$RunStateCopyWith<$Res> implements $RunStateCopyWith<$Res> {
  factory _$RunStateCopyWith(_RunState value, $Res Function(_RunState) _then) = __$RunStateCopyWithImpl;
@override @useResult
$Res call({
 String key, TurnKind kind, ChatSelection selection, String? conversationId, String? streamId, String? requestMessageId, int? generationCreatedAt, bool isTemporary, bool isComparison, bool firstRunOfNewChat, Message? optimistic, String? anchorId, RunPhase phase, int attempt, bool resumedOnce, bool stopping, List<ContentPart> parts, List<Attachment> attachments, PendingAction? pendingAction, String? actionError, Map<String, SubagentProgress> subagents, String? title, String? error, int epoch
});


@override $ChatSelectionCopyWith<$Res> get selection;@override $MessageCopyWith<$Res>? get optimistic;@override $PendingActionCopyWith<$Res>? get pendingAction;

}
/// @nodoc
class __$RunStateCopyWithImpl<$Res>
    implements _$RunStateCopyWith<$Res> {
  __$RunStateCopyWithImpl(this._self, this._then);

  final _RunState _self;
  final $Res Function(_RunState) _then;

/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? kind = null,Object? selection = null,Object? conversationId = freezed,Object? streamId = freezed,Object? requestMessageId = freezed,Object? generationCreatedAt = freezed,Object? isTemporary = null,Object? isComparison = null,Object? firstRunOfNewChat = null,Object? optimistic = freezed,Object? anchorId = freezed,Object? phase = null,Object? attempt = null,Object? resumedOnce = null,Object? stopping = null,Object? parts = null,Object? attachments = null,Object? pendingAction = freezed,Object? actionError = freezed,Object? subagents = null,Object? title = freezed,Object? error = freezed,Object? epoch = null,}) {
  return _then(_RunState(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as ChatSelection,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,requestMessageId: freezed == requestMessageId ? _self.requestMessageId : requestMessageId // ignore: cast_nullable_to_non_nullable
as String?,generationCreatedAt: freezed == generationCreatedAt ? _self.generationCreatedAt : generationCreatedAt // ignore: cast_nullable_to_non_nullable
as int?,isTemporary: null == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool,isComparison: null == isComparison ? _self.isComparison : isComparison // ignore: cast_nullable_to_non_nullable
as bool,firstRunOfNewChat: null == firstRunOfNewChat ? _self.firstRunOfNewChat : firstRunOfNewChat // ignore: cast_nullable_to_non_nullable
as bool,optimistic: freezed == optimistic ? _self.optimistic : optimistic // ignore: cast_nullable_to_non_nullable
as Message?,anchorId: freezed == anchorId ? _self.anchorId : anchorId // ignore: cast_nullable_to_non_nullable
as String?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as RunPhase,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,resumedOnce: null == resumedOnce ? _self.resumedOnce : resumedOnce // ignore: cast_nullable_to_non_nullable
as bool,stopping: null == stopping ? _self.stopping : stopping // ignore: cast_nullable_to_non_nullable
as bool,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<ContentPart>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,pendingAction: freezed == pendingAction ? _self.pendingAction : pendingAction // ignore: cast_nullable_to_non_nullable
as PendingAction?,actionError: freezed == actionError ? _self.actionError : actionError // ignore: cast_nullable_to_non_nullable
as String?,subagents: null == subagents ? _self._subagents : subagents // ignore: cast_nullable_to_non_nullable
as Map<String, SubagentProgress>,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,epoch: null == epoch ? _self.epoch : epoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res> get selection {
  
  return $ChatSelectionCopyWith<$Res>(_self.selection, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get optimistic {
    if (_self.optimistic == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.optimistic!, (value) {
    return _then(_self.copyWith(optimistic: value));
  });
}/// Create a copy of RunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingActionCopyWith<$Res>? get pendingAction {
    if (_self.pendingAction == null) {
    return null;
  }

  return $PendingActionCopyWith<$Res>(_self.pendingAction!, (value) {
    return _then(_self.copyWith(pendingAction: value));
  });
}
}

/// @nodoc
mixin _$ConversationRuns {

 Map<String, RunState> get runs; Map<String, String> get movedTo; Map<String, String> get errors;
/// Create a copy of ConversationRuns
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationRunsCopyWith<ConversationRuns> get copyWith => _$ConversationRunsCopyWithImpl<ConversationRuns>(this as ConversationRuns, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationRuns&&const DeepCollectionEquality().equals(other.runs, runs)&&const DeepCollectionEquality().equals(other.movedTo, movedTo)&&const DeepCollectionEquality().equals(other.errors, errors));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(runs),const DeepCollectionEquality().hash(movedTo),const DeepCollectionEquality().hash(errors));

@override
String toString() {
  return 'ConversationRuns(runs: $runs, movedTo: $movedTo, errors: $errors)';
}


}

/// @nodoc
abstract mixin class $ConversationRunsCopyWith<$Res>  {
  factory $ConversationRunsCopyWith(ConversationRuns value, $Res Function(ConversationRuns) _then) = _$ConversationRunsCopyWithImpl;
@useResult
$Res call({
 Map<String, RunState> runs, Map<String, String> movedTo, Map<String, String> errors
});




}
/// @nodoc
class _$ConversationRunsCopyWithImpl<$Res>
    implements $ConversationRunsCopyWith<$Res> {
  _$ConversationRunsCopyWithImpl(this._self, this._then);

  final ConversationRuns _self;
  final $Res Function(ConversationRuns) _then;

/// Create a copy of ConversationRuns
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runs = null,Object? movedTo = null,Object? errors = null,}) {
  return _then(_self.copyWith(
runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, RunState>,movedTo: null == movedTo ? _self.movedTo : movedTo // ignore: cast_nullable_to_non_nullable
as Map<String, String>,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationRuns].
extension ConversationRunsPatterns on ConversationRuns {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationRuns value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationRuns() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationRuns value)  $default,){
final _that = this;
switch (_that) {
case _ConversationRuns():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationRuns value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationRuns() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, RunState> runs,  Map<String, String> movedTo,  Map<String, String> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationRuns() when $default != null:
return $default(_that.runs,_that.movedTo,_that.errors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, RunState> runs,  Map<String, String> movedTo,  Map<String, String> errors)  $default,) {final _that = this;
switch (_that) {
case _ConversationRuns():
return $default(_that.runs,_that.movedTo,_that.errors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, RunState> runs,  Map<String, String> movedTo,  Map<String, String> errors)?  $default,) {final _that = this;
switch (_that) {
case _ConversationRuns() when $default != null:
return $default(_that.runs,_that.movedTo,_that.errors);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationRuns implements ConversationRuns {
  const _ConversationRuns({final  Map<String, RunState> runs = const <String, RunState>{}, final  Map<String, String> movedTo = const <String, String>{}, final  Map<String, String> errors = const <String, String>{}}): _runs = runs,_movedTo = movedTo,_errors = errors;
  

 final  Map<String, RunState> _runs;
@override@JsonKey() Map<String, RunState> get runs {
  if (_runs is EqualUnmodifiableMapView) return _runs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_runs);
}

 final  Map<String, String> _movedTo;
@override@JsonKey() Map<String, String> get movedTo {
  if (_movedTo is EqualUnmodifiableMapView) return _movedTo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_movedTo);
}

 final  Map<String, String> _errors;
@override@JsonKey() Map<String, String> get errors {
  if (_errors is EqualUnmodifiableMapView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_errors);
}


/// Create a copy of ConversationRuns
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationRunsCopyWith<_ConversationRuns> get copyWith => __$ConversationRunsCopyWithImpl<_ConversationRuns>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationRuns&&const DeepCollectionEquality().equals(other._runs, _runs)&&const DeepCollectionEquality().equals(other._movedTo, _movedTo)&&const DeepCollectionEquality().equals(other._errors, _errors));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_runs),const DeepCollectionEquality().hash(_movedTo),const DeepCollectionEquality().hash(_errors));

@override
String toString() {
  return 'ConversationRuns(runs: $runs, movedTo: $movedTo, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$ConversationRunsCopyWith<$Res> implements $ConversationRunsCopyWith<$Res> {
  factory _$ConversationRunsCopyWith(_ConversationRuns value, $Res Function(_ConversationRuns) _then) = __$ConversationRunsCopyWithImpl;
@override @useResult
$Res call({
 Map<String, RunState> runs, Map<String, String> movedTo, Map<String, String> errors
});




}
/// @nodoc
class __$ConversationRunsCopyWithImpl<$Res>
    implements _$ConversationRunsCopyWith<$Res> {
  __$ConversationRunsCopyWithImpl(this._self, this._then);

  final _ConversationRuns _self;
  final $Res Function(_ConversationRuns) _then;

/// Create a copy of ConversationRuns
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runs = null,Object? movedTo = null,Object? errors = null,}) {
  return _then(_ConversationRuns(
runs: null == runs ? _self._runs : runs // ignore: cast_nullable_to_non_nullable
as Map<String, RunState>,movedTo: null == movedTo ? _self._movedTo : movedTo // ignore: cast_nullable_to_non_nullable
as Map<String, String>,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
