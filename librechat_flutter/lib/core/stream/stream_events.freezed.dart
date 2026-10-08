// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent()';
}


}

/// @nodoc
class $StreamEventCopyWith<$Res>  {
$StreamEventCopyWith(StreamEvent _, $Res Function(StreamEvent) __);
}


/// Adds pattern-matching-related methods to [StreamEvent].
extension StreamEventPatterns on StreamEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextDelta value)?  textDelta,TResult Function( ThinkDelta value)?  thinkDelta,TResult Function( ToolCallStarted value)?  toolCallStarted,TResult Function( ToolCallCompleted value)?  toolCallCompleted,TResult Function( ToolCallClosed value)?  toolCallClosed,TResult Function( SummaryEvent value)?  summary,TResult Function( SubagentUpdate value)?  subagentUpdate,TResult Function( AttachmentEvent value)?  attachment,TResult Function( TitleEvent value)?  title,TResult Function( TokenUsageEvent value)?  tokenUsage,TResult Function( ContextUsageEvent value)?  contextUsage,TResult Function( PendingActionEvent value)?  pendingAction,TResult Function( SteerApplied value)?  steerApplied,TResult Function( SyncSnapshot value)?  syncSnapshot,TResult Function( SteersSynced value)?  steersSynced,TResult Function( FinalEvent value)?  finalFrame,TResult Function( CreatedEvent value)?  created,TResult Function( StreamError value)?  streamError,TResult Function( StreamReconnecting value)?  reconnecting,TResult Function( StreamExpired value)?  expired,TResult Function( StreamRetryExhausted value)?  retryExhausted,TResult Function( StreamFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextDelta() when textDelta != null:
return textDelta(_that);case ThinkDelta() when thinkDelta != null:
return thinkDelta(_that);case ToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that);case ToolCallCompleted() when toolCallCompleted != null:
return toolCallCompleted(_that);case ToolCallClosed() when toolCallClosed != null:
return toolCallClosed(_that);case SummaryEvent() when summary != null:
return summary(_that);case SubagentUpdate() when subagentUpdate != null:
return subagentUpdate(_that);case AttachmentEvent() when attachment != null:
return attachment(_that);case TitleEvent() when title != null:
return title(_that);case TokenUsageEvent() when tokenUsage != null:
return tokenUsage(_that);case ContextUsageEvent() when contextUsage != null:
return contextUsage(_that);case PendingActionEvent() when pendingAction != null:
return pendingAction(_that);case SteerApplied() when steerApplied != null:
return steerApplied(_that);case SyncSnapshot() when syncSnapshot != null:
return syncSnapshot(_that);case SteersSynced() when steersSynced != null:
return steersSynced(_that);case FinalEvent() when finalFrame != null:
return finalFrame(_that);case CreatedEvent() when created != null:
return created(_that);case StreamError() when streamError != null:
return streamError(_that);case StreamReconnecting() when reconnecting != null:
return reconnecting(_that);case StreamExpired() when expired != null:
return expired(_that);case StreamRetryExhausted() when retryExhausted != null:
return retryExhausted(_that);case StreamFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextDelta value)  textDelta,required TResult Function( ThinkDelta value)  thinkDelta,required TResult Function( ToolCallStarted value)  toolCallStarted,required TResult Function( ToolCallCompleted value)  toolCallCompleted,required TResult Function( ToolCallClosed value)  toolCallClosed,required TResult Function( SummaryEvent value)  summary,required TResult Function( SubagentUpdate value)  subagentUpdate,required TResult Function( AttachmentEvent value)  attachment,required TResult Function( TitleEvent value)  title,required TResult Function( TokenUsageEvent value)  tokenUsage,required TResult Function( ContextUsageEvent value)  contextUsage,required TResult Function( PendingActionEvent value)  pendingAction,required TResult Function( SteerApplied value)  steerApplied,required TResult Function( SyncSnapshot value)  syncSnapshot,required TResult Function( SteersSynced value)  steersSynced,required TResult Function( FinalEvent value)  finalFrame,required TResult Function( CreatedEvent value)  created,required TResult Function( StreamError value)  streamError,required TResult Function( StreamReconnecting value)  reconnecting,required TResult Function( StreamExpired value)  expired,required TResult Function( StreamRetryExhausted value)  retryExhausted,required TResult Function( StreamFailed value)  failed,}){
final _that = this;
switch (_that) {
case TextDelta():
return textDelta(_that);case ThinkDelta():
return thinkDelta(_that);case ToolCallStarted():
return toolCallStarted(_that);case ToolCallCompleted():
return toolCallCompleted(_that);case ToolCallClosed():
return toolCallClosed(_that);case SummaryEvent():
return summary(_that);case SubagentUpdate():
return subagentUpdate(_that);case AttachmentEvent():
return attachment(_that);case TitleEvent():
return title(_that);case TokenUsageEvent():
return tokenUsage(_that);case ContextUsageEvent():
return contextUsage(_that);case PendingActionEvent():
return pendingAction(_that);case SteerApplied():
return steerApplied(_that);case SyncSnapshot():
return syncSnapshot(_that);case SteersSynced():
return steersSynced(_that);case FinalEvent():
return finalFrame(_that);case CreatedEvent():
return created(_that);case StreamError():
return streamError(_that);case StreamReconnecting():
return reconnecting(_that);case StreamExpired():
return expired(_that);case StreamRetryExhausted():
return retryExhausted(_that);case StreamFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextDelta value)?  textDelta,TResult? Function( ThinkDelta value)?  thinkDelta,TResult? Function( ToolCallStarted value)?  toolCallStarted,TResult? Function( ToolCallCompleted value)?  toolCallCompleted,TResult? Function( ToolCallClosed value)?  toolCallClosed,TResult? Function( SummaryEvent value)?  summary,TResult? Function( SubagentUpdate value)?  subagentUpdate,TResult? Function( AttachmentEvent value)?  attachment,TResult? Function( TitleEvent value)?  title,TResult? Function( TokenUsageEvent value)?  tokenUsage,TResult? Function( ContextUsageEvent value)?  contextUsage,TResult? Function( PendingActionEvent value)?  pendingAction,TResult? Function( SteerApplied value)?  steerApplied,TResult? Function( SyncSnapshot value)?  syncSnapshot,TResult? Function( SteersSynced value)?  steersSynced,TResult? Function( FinalEvent value)?  finalFrame,TResult? Function( CreatedEvent value)?  created,TResult? Function( StreamError value)?  streamError,TResult? Function( StreamReconnecting value)?  reconnecting,TResult? Function( StreamExpired value)?  expired,TResult? Function( StreamRetryExhausted value)?  retryExhausted,TResult? Function( StreamFailed value)?  failed,}){
final _that = this;
switch (_that) {
case TextDelta() when textDelta != null:
return textDelta(_that);case ThinkDelta() when thinkDelta != null:
return thinkDelta(_that);case ToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that);case ToolCallCompleted() when toolCallCompleted != null:
return toolCallCompleted(_that);case ToolCallClosed() when toolCallClosed != null:
return toolCallClosed(_that);case SummaryEvent() when summary != null:
return summary(_that);case SubagentUpdate() when subagentUpdate != null:
return subagentUpdate(_that);case AttachmentEvent() when attachment != null:
return attachment(_that);case TitleEvent() when title != null:
return title(_that);case TokenUsageEvent() when tokenUsage != null:
return tokenUsage(_that);case ContextUsageEvent() when contextUsage != null:
return contextUsage(_that);case PendingActionEvent() when pendingAction != null:
return pendingAction(_that);case SteerApplied() when steerApplied != null:
return steerApplied(_that);case SyncSnapshot() when syncSnapshot != null:
return syncSnapshot(_that);case SteersSynced() when steersSynced != null:
return steersSynced(_that);case FinalEvent() when finalFrame != null:
return finalFrame(_that);case CreatedEvent() when created != null:
return created(_that);case StreamError() when streamError != null:
return streamError(_that);case StreamReconnecting() when reconnecting != null:
return reconnecting(_that);case StreamExpired() when expired != null:
return expired(_that);case StreamRetryExhausted() when retryExhausted != null:
return retryExhausted(_that);case StreamFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text,  String? agentId)?  textDelta,TResult Function( String think,  String? agentId)?  thinkDelta,TResult Function( String id,  String? name,  Object? args,  String? agentId)?  toolCallStarted,TResult Function( String toolCallId,  String? output,  String? agentId)?  toolCallCompleted,TResult Function( String toolCallId,  String status,  String? agentId)?  toolCallClosed,TResult Function( String text,  String? agentId)?  summary,TResult Function( String phase,  String? parentToolCallId,  String? subagentRunId,  String? subagentType,  String? label)?  subagentUpdate,TResult Function( Attachment attachment,  String? text,  String? textFormat)?  attachment,TResult Function( String? conversationId,  String title)?  title,TResult Function( TokenUsage usage)?  tokenUsage,TResult Function( ContextUsage usage)?  contextUsage,TResult Function( PendingAction action)?  pendingAction,TResult Function( String steerId,  String? clientSteerId,  int? index,  ContentPart? part)?  steerApplied,TResult Function( List<ContentPart> parts)?  syncSnapshot,TResult Function( List<PendingSteer> steers)?  steersSynced,TResult Function( Conversation? conversation,  Message? requestMessage,  Message? responseMessage,  bool aborted,  bool earlyAbort,  List<PendingSteer> pendingSteers)?  finalFrame,TResult Function( String? conversationId,  String? messageId,  String? parentMessageId)?  created,TResult Function( String text)?  streamError,TResult Function( int attempt)?  reconnecting,TResult Function()?  expired,TResult Function()?  retryExhausted,TResult Function( AppException error)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextDelta() when textDelta != null:
return textDelta(_that.text,_that.agentId);case ThinkDelta() when thinkDelta != null:
return thinkDelta(_that.think,_that.agentId);case ToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that.id,_that.name,_that.args,_that.agentId);case ToolCallCompleted() when toolCallCompleted != null:
return toolCallCompleted(_that.toolCallId,_that.output,_that.agentId);case ToolCallClosed() when toolCallClosed != null:
return toolCallClosed(_that.toolCallId,_that.status,_that.agentId);case SummaryEvent() when summary != null:
return summary(_that.text,_that.agentId);case SubagentUpdate() when subagentUpdate != null:
return subagentUpdate(_that.phase,_that.parentToolCallId,_that.subagentRunId,_that.subagentType,_that.label);case AttachmentEvent() when attachment != null:
return attachment(_that.attachment,_that.text,_that.textFormat);case TitleEvent() when title != null:
return title(_that.conversationId,_that.title);case TokenUsageEvent() when tokenUsage != null:
return tokenUsage(_that.usage);case ContextUsageEvent() when contextUsage != null:
return contextUsage(_that.usage);case PendingActionEvent() when pendingAction != null:
return pendingAction(_that.action);case SteerApplied() when steerApplied != null:
return steerApplied(_that.steerId,_that.clientSteerId,_that.index,_that.part);case SyncSnapshot() when syncSnapshot != null:
return syncSnapshot(_that.parts);case SteersSynced() when steersSynced != null:
return steersSynced(_that.steers);case FinalEvent() when finalFrame != null:
return finalFrame(_that.conversation,_that.requestMessage,_that.responseMessage,_that.aborted,_that.earlyAbort,_that.pendingSteers);case CreatedEvent() when created != null:
return created(_that.conversationId,_that.messageId,_that.parentMessageId);case StreamError() when streamError != null:
return streamError(_that.text);case StreamReconnecting() when reconnecting != null:
return reconnecting(_that.attempt);case StreamExpired() when expired != null:
return expired();case StreamRetryExhausted() when retryExhausted != null:
return retryExhausted();case StreamFailed() when failed != null:
return failed(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text,  String? agentId)  textDelta,required TResult Function( String think,  String? agentId)  thinkDelta,required TResult Function( String id,  String? name,  Object? args,  String? agentId)  toolCallStarted,required TResult Function( String toolCallId,  String? output,  String? agentId)  toolCallCompleted,required TResult Function( String toolCallId,  String status,  String? agentId)  toolCallClosed,required TResult Function( String text,  String? agentId)  summary,required TResult Function( String phase,  String? parentToolCallId,  String? subagentRunId,  String? subagentType,  String? label)  subagentUpdate,required TResult Function( Attachment attachment,  String? text,  String? textFormat)  attachment,required TResult Function( String? conversationId,  String title)  title,required TResult Function( TokenUsage usage)  tokenUsage,required TResult Function( ContextUsage usage)  contextUsage,required TResult Function( PendingAction action)  pendingAction,required TResult Function( String steerId,  String? clientSteerId,  int? index,  ContentPart? part)  steerApplied,required TResult Function( List<ContentPart> parts)  syncSnapshot,required TResult Function( List<PendingSteer> steers)  steersSynced,required TResult Function( Conversation? conversation,  Message? requestMessage,  Message? responseMessage,  bool aborted,  bool earlyAbort,  List<PendingSteer> pendingSteers)  finalFrame,required TResult Function( String? conversationId,  String? messageId,  String? parentMessageId)  created,required TResult Function( String text)  streamError,required TResult Function( int attempt)  reconnecting,required TResult Function()  expired,required TResult Function()  retryExhausted,required TResult Function( AppException error)  failed,}) {final _that = this;
switch (_that) {
case TextDelta():
return textDelta(_that.text,_that.agentId);case ThinkDelta():
return thinkDelta(_that.think,_that.agentId);case ToolCallStarted():
return toolCallStarted(_that.id,_that.name,_that.args,_that.agentId);case ToolCallCompleted():
return toolCallCompleted(_that.toolCallId,_that.output,_that.agentId);case ToolCallClosed():
return toolCallClosed(_that.toolCallId,_that.status,_that.agentId);case SummaryEvent():
return summary(_that.text,_that.agentId);case SubagentUpdate():
return subagentUpdate(_that.phase,_that.parentToolCallId,_that.subagentRunId,_that.subagentType,_that.label);case AttachmentEvent():
return attachment(_that.attachment,_that.text,_that.textFormat);case TitleEvent():
return title(_that.conversationId,_that.title);case TokenUsageEvent():
return tokenUsage(_that.usage);case ContextUsageEvent():
return contextUsage(_that.usage);case PendingActionEvent():
return pendingAction(_that.action);case SteerApplied():
return steerApplied(_that.steerId,_that.clientSteerId,_that.index,_that.part);case SyncSnapshot():
return syncSnapshot(_that.parts);case SteersSynced():
return steersSynced(_that.steers);case FinalEvent():
return finalFrame(_that.conversation,_that.requestMessage,_that.responseMessage,_that.aborted,_that.earlyAbort,_that.pendingSteers);case CreatedEvent():
return created(_that.conversationId,_that.messageId,_that.parentMessageId);case StreamError():
return streamError(_that.text);case StreamReconnecting():
return reconnecting(_that.attempt);case StreamExpired():
return expired();case StreamRetryExhausted():
return retryExhausted();case StreamFailed():
return failed(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text,  String? agentId)?  textDelta,TResult? Function( String think,  String? agentId)?  thinkDelta,TResult? Function( String id,  String? name,  Object? args,  String? agentId)?  toolCallStarted,TResult? Function( String toolCallId,  String? output,  String? agentId)?  toolCallCompleted,TResult? Function( String toolCallId,  String status,  String? agentId)?  toolCallClosed,TResult? Function( String text,  String? agentId)?  summary,TResult? Function( String phase,  String? parentToolCallId,  String? subagentRunId,  String? subagentType,  String? label)?  subagentUpdate,TResult? Function( Attachment attachment,  String? text,  String? textFormat)?  attachment,TResult? Function( String? conversationId,  String title)?  title,TResult? Function( TokenUsage usage)?  tokenUsage,TResult? Function( ContextUsage usage)?  contextUsage,TResult? Function( PendingAction action)?  pendingAction,TResult? Function( String steerId,  String? clientSteerId,  int? index,  ContentPart? part)?  steerApplied,TResult? Function( List<ContentPart> parts)?  syncSnapshot,TResult? Function( List<PendingSteer> steers)?  steersSynced,TResult? Function( Conversation? conversation,  Message? requestMessage,  Message? responseMessage,  bool aborted,  bool earlyAbort,  List<PendingSteer> pendingSteers)?  finalFrame,TResult? Function( String? conversationId,  String? messageId,  String? parentMessageId)?  created,TResult? Function( String text)?  streamError,TResult? Function( int attempt)?  reconnecting,TResult? Function()?  expired,TResult? Function()?  retryExhausted,TResult? Function( AppException error)?  failed,}) {final _that = this;
switch (_that) {
case TextDelta() when textDelta != null:
return textDelta(_that.text,_that.agentId);case ThinkDelta() when thinkDelta != null:
return thinkDelta(_that.think,_that.agentId);case ToolCallStarted() when toolCallStarted != null:
return toolCallStarted(_that.id,_that.name,_that.args,_that.agentId);case ToolCallCompleted() when toolCallCompleted != null:
return toolCallCompleted(_that.toolCallId,_that.output,_that.agentId);case ToolCallClosed() when toolCallClosed != null:
return toolCallClosed(_that.toolCallId,_that.status,_that.agentId);case SummaryEvent() when summary != null:
return summary(_that.text,_that.agentId);case SubagentUpdate() when subagentUpdate != null:
return subagentUpdate(_that.phase,_that.parentToolCallId,_that.subagentRunId,_that.subagentType,_that.label);case AttachmentEvent() when attachment != null:
return attachment(_that.attachment,_that.text,_that.textFormat);case TitleEvent() when title != null:
return title(_that.conversationId,_that.title);case TokenUsageEvent() when tokenUsage != null:
return tokenUsage(_that.usage);case ContextUsageEvent() when contextUsage != null:
return contextUsage(_that.usage);case PendingActionEvent() when pendingAction != null:
return pendingAction(_that.action);case SteerApplied() when steerApplied != null:
return steerApplied(_that.steerId,_that.clientSteerId,_that.index,_that.part);case SyncSnapshot() when syncSnapshot != null:
return syncSnapshot(_that.parts);case SteersSynced() when steersSynced != null:
return steersSynced(_that.steers);case FinalEvent() when finalFrame != null:
return finalFrame(_that.conversation,_that.requestMessage,_that.responseMessage,_that.aborted,_that.earlyAbort,_that.pendingSteers);case CreatedEvent() when created != null:
return created(_that.conversationId,_that.messageId,_that.parentMessageId);case StreamError() when streamError != null:
return streamError(_that.text);case StreamReconnecting() when reconnecting != null:
return reconnecting(_that.attempt);case StreamExpired() when expired != null:
return expired();case StreamRetryExhausted() when retryExhausted != null:
return retryExhausted();case StreamFailed() when failed != null:
return failed(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class TextDelta implements StreamEvent {
  const TextDelta(this.text, {this.agentId});
  

 final  String text;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextDeltaCopyWith<TextDelta> get copyWith => _$TextDeltaCopyWithImpl<TextDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDelta&&(identical(other.text, text) || other.text == text)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,text,agentId);

@override
String toString() {
  return 'StreamEvent.textDelta(text: $text, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $TextDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $TextDeltaCopyWith(TextDelta value, $Res Function(TextDelta) _then) = _$TextDeltaCopyWithImpl;
@useResult
$Res call({
 String text, String? agentId
});




}
/// @nodoc
class _$TextDeltaCopyWithImpl<$Res>
    implements $TextDeltaCopyWith<$Res> {
  _$TextDeltaCopyWithImpl(this._self, this._then);

  final TextDelta _self;
  final $Res Function(TextDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,Object? agentId = freezed,}) {
  return _then(TextDelta(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ThinkDelta implements StreamEvent {
  const ThinkDelta(this.think, {this.agentId});
  

 final  String think;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThinkDeltaCopyWith<ThinkDelta> get copyWith => _$ThinkDeltaCopyWithImpl<ThinkDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThinkDelta&&(identical(other.think, think) || other.think == think)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,think,agentId);

@override
String toString() {
  return 'StreamEvent.thinkDelta(think: $think, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $ThinkDeltaCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ThinkDeltaCopyWith(ThinkDelta value, $Res Function(ThinkDelta) _then) = _$ThinkDeltaCopyWithImpl;
@useResult
$Res call({
 String think, String? agentId
});




}
/// @nodoc
class _$ThinkDeltaCopyWithImpl<$Res>
    implements $ThinkDeltaCopyWith<$Res> {
  _$ThinkDeltaCopyWithImpl(this._self, this._then);

  final ThinkDelta _self;
  final $Res Function(ThinkDelta) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? think = null,Object? agentId = freezed,}) {
  return _then(ThinkDelta(
null == think ? _self.think : think // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ToolCallStarted implements StreamEvent {
  const ToolCallStarted({required this.id, this.name, this.args, this.agentId});
  

 final  String id;
 final  String? name;
 final  Object? args;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallStartedCopyWith<ToolCallStarted> get copyWith => _$ToolCallStartedCopyWithImpl<ToolCallStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallStarted&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.args, args)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(args),agentId);

@override
String toString() {
  return 'StreamEvent.toolCallStarted(id: $id, name: $name, args: $args, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $ToolCallStartedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolCallStartedCopyWith(ToolCallStarted value, $Res Function(ToolCallStarted) _then) = _$ToolCallStartedCopyWithImpl;
@useResult
$Res call({
 String id, String? name, Object? args, String? agentId
});




}
/// @nodoc
class _$ToolCallStartedCopyWithImpl<$Res>
    implements $ToolCallStartedCopyWith<$Res> {
  _$ToolCallStartedCopyWithImpl(this._self, this._then);

  final ToolCallStarted _self;
  final $Res Function(ToolCallStarted) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? args = freezed,Object? agentId = freezed,}) {
  return _then(ToolCallStarted(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,args: freezed == args ? _self.args : args ,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ToolCallCompleted implements StreamEvent {
  const ToolCallCompleted({required this.toolCallId, this.output, this.agentId});
  

 final  String toolCallId;
 final  String? output;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallCompletedCopyWith<ToolCallCompleted> get copyWith => _$ToolCallCompletedCopyWithImpl<ToolCallCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallCompleted&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.output, output) || other.output == output)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,toolCallId,output,agentId);

@override
String toString() {
  return 'StreamEvent.toolCallCompleted(toolCallId: $toolCallId, output: $output, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $ToolCallCompletedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolCallCompletedCopyWith(ToolCallCompleted value, $Res Function(ToolCallCompleted) _then) = _$ToolCallCompletedCopyWithImpl;
@useResult
$Res call({
 String toolCallId, String? output, String? agentId
});




}
/// @nodoc
class _$ToolCallCompletedCopyWithImpl<$Res>
    implements $ToolCallCompletedCopyWith<$Res> {
  _$ToolCallCompletedCopyWithImpl(this._self, this._then);

  final ToolCallCompleted _self;
  final $Res Function(ToolCallCompleted) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolCallId = null,Object? output = freezed,Object? agentId = freezed,}) {
  return _then(ToolCallCompleted(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ToolCallClosed implements StreamEvent {
  const ToolCallClosed({required this.toolCallId, required this.status, this.agentId});
  

 final  String toolCallId;
 final  String status;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallClosedCopyWith<ToolCallClosed> get copyWith => _$ToolCallClosedCopyWithImpl<ToolCallClosed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallClosed&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.status, status) || other.status == status)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,toolCallId,status,agentId);

@override
String toString() {
  return 'StreamEvent.toolCallClosed(toolCallId: $toolCallId, status: $status, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $ToolCallClosedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ToolCallClosedCopyWith(ToolCallClosed value, $Res Function(ToolCallClosed) _then) = _$ToolCallClosedCopyWithImpl;
@useResult
$Res call({
 String toolCallId, String status, String? agentId
});




}
/// @nodoc
class _$ToolCallClosedCopyWithImpl<$Res>
    implements $ToolCallClosedCopyWith<$Res> {
  _$ToolCallClosedCopyWithImpl(this._self, this._then);

  final ToolCallClosed _self;
  final $Res Function(ToolCallClosed) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolCallId = null,Object? status = null,Object? agentId = freezed,}) {
  return _then(ToolCallClosed(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SummaryEvent implements StreamEvent {
  const SummaryEvent(this.text, {this.agentId});
  

 final  String text;
 final  String? agentId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryEventCopyWith<SummaryEvent> get copyWith => _$SummaryEventCopyWithImpl<SummaryEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SummaryEvent&&(identical(other.text, text) || other.text == text)&&(identical(other.agentId, agentId) || other.agentId == agentId));
}


@override
int get hashCode => Object.hash(runtimeType,text,agentId);

@override
String toString() {
  return 'StreamEvent.summary(text: $text, agentId: $agentId)';
}


}

/// @nodoc
abstract mixin class $SummaryEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $SummaryEventCopyWith(SummaryEvent value, $Res Function(SummaryEvent) _then) = _$SummaryEventCopyWithImpl;
@useResult
$Res call({
 String text, String? agentId
});




}
/// @nodoc
class _$SummaryEventCopyWithImpl<$Res>
    implements $SummaryEventCopyWith<$Res> {
  _$SummaryEventCopyWithImpl(this._self, this._then);

  final SummaryEvent _self;
  final $Res Function(SummaryEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,Object? agentId = freezed,}) {
  return _then(SummaryEvent(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SubagentUpdate implements StreamEvent {
  const SubagentUpdate({required this.phase, this.parentToolCallId, this.subagentRunId, this.subagentType, this.label});
  

 final  String phase;
 final  String? parentToolCallId;
 final  String? subagentRunId;
 final  String? subagentType;
 final  String? label;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubagentUpdateCopyWith<SubagentUpdate> get copyWith => _$SubagentUpdateCopyWithImpl<SubagentUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubagentUpdate&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.parentToolCallId, parentToolCallId) || other.parentToolCallId == parentToolCallId)&&(identical(other.subagentRunId, subagentRunId) || other.subagentRunId == subagentRunId)&&(identical(other.subagentType, subagentType) || other.subagentType == subagentType)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,phase,parentToolCallId,subagentRunId,subagentType,label);

@override
String toString() {
  return 'StreamEvent.subagentUpdate(phase: $phase, parentToolCallId: $parentToolCallId, subagentRunId: $subagentRunId, subagentType: $subagentType, label: $label)';
}


}

/// @nodoc
abstract mixin class $SubagentUpdateCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $SubagentUpdateCopyWith(SubagentUpdate value, $Res Function(SubagentUpdate) _then) = _$SubagentUpdateCopyWithImpl;
@useResult
$Res call({
 String phase, String? parentToolCallId, String? subagentRunId, String? subagentType, String? label
});




}
/// @nodoc
class _$SubagentUpdateCopyWithImpl<$Res>
    implements $SubagentUpdateCopyWith<$Res> {
  _$SubagentUpdateCopyWithImpl(this._self, this._then);

  final SubagentUpdate _self;
  final $Res Function(SubagentUpdate) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? parentToolCallId = freezed,Object? subagentRunId = freezed,Object? subagentType = freezed,Object? label = freezed,}) {
  return _then(SubagentUpdate(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,parentToolCallId: freezed == parentToolCallId ? _self.parentToolCallId : parentToolCallId // ignore: cast_nullable_to_non_nullable
as String?,subagentRunId: freezed == subagentRunId ? _self.subagentRunId : subagentRunId // ignore: cast_nullable_to_non_nullable
as String?,subagentType: freezed == subagentType ? _self.subagentType : subagentType // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AttachmentEvent implements StreamEvent {
  const AttachmentEvent(this.attachment, {this.text, this.textFormat});
  

 final  Attachment attachment;
 final  String? text;
 final  String? textFormat;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentEventCopyWith<AttachmentEvent> get copyWith => _$AttachmentEventCopyWithImpl<AttachmentEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentEvent&&(identical(other.attachment, attachment) || other.attachment == attachment)&&(identical(other.text, text) || other.text == text)&&(identical(other.textFormat, textFormat) || other.textFormat == textFormat));
}


@override
int get hashCode => Object.hash(runtimeType,attachment,text,textFormat);

@override
String toString() {
  return 'StreamEvent.attachment(attachment: $attachment, text: $text, textFormat: $textFormat)';
}


}

/// @nodoc
abstract mixin class $AttachmentEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $AttachmentEventCopyWith(AttachmentEvent value, $Res Function(AttachmentEvent) _then) = _$AttachmentEventCopyWithImpl;
@useResult
$Res call({
 Attachment attachment, String? text, String? textFormat
});


$AttachmentCopyWith<$Res> get attachment;

}
/// @nodoc
class _$AttachmentEventCopyWithImpl<$Res>
    implements $AttachmentEventCopyWith<$Res> {
  _$AttachmentEventCopyWithImpl(this._self, this._then);

  final AttachmentEvent _self;
  final $Res Function(AttachmentEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attachment = null,Object? text = freezed,Object? textFormat = freezed,}) {
  return _then(AttachmentEvent(
null == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as Attachment,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,textFormat: freezed == textFormat ? _self.textFormat : textFormat // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttachmentCopyWith<$Res> get attachment {
  
  return $AttachmentCopyWith<$Res>(_self.attachment, (value) {
    return _then(_self.copyWith(attachment: value));
  });
}
}

/// @nodoc


class TitleEvent implements StreamEvent {
  const TitleEvent({this.conversationId, required this.title});
  

 final  String? conversationId;
 final  String title;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleEventCopyWith<TitleEvent> get copyWith => _$TitleEventCopyWithImpl<TitleEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleEvent&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,title);

@override
String toString() {
  return 'StreamEvent.title(conversationId: $conversationId, title: $title)';
}


}

/// @nodoc
abstract mixin class $TitleEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $TitleEventCopyWith(TitleEvent value, $Res Function(TitleEvent) _then) = _$TitleEventCopyWithImpl;
@useResult
$Res call({
 String? conversationId, String title
});




}
/// @nodoc
class _$TitleEventCopyWithImpl<$Res>
    implements $TitleEventCopyWith<$Res> {
  _$TitleEventCopyWithImpl(this._self, this._then);

  final TitleEvent _self;
  final $Res Function(TitleEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversationId = freezed,Object? title = null,}) {
  return _then(TitleEvent(
conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TokenUsageEvent implements StreamEvent {
  const TokenUsageEvent(this.usage);
  

 final  TokenUsage usage;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenUsageEventCopyWith<TokenUsageEvent> get copyWith => _$TokenUsageEventCopyWithImpl<TokenUsageEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenUsageEvent&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,usage);

@override
String toString() {
  return 'StreamEvent.tokenUsage(usage: $usage)';
}


}

/// @nodoc
abstract mixin class $TokenUsageEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $TokenUsageEventCopyWith(TokenUsageEvent value, $Res Function(TokenUsageEvent) _then) = _$TokenUsageEventCopyWithImpl;
@useResult
$Res call({
 TokenUsage usage
});


$TokenUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$TokenUsageEventCopyWithImpl<$Res>
    implements $TokenUsageEventCopyWith<$Res> {
  _$TokenUsageEventCopyWithImpl(this._self, this._then);

  final TokenUsageEvent _self;
  final $Res Function(TokenUsageEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? usage = null,}) {
  return _then(TokenUsageEvent(
null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as TokenUsage,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TokenUsageCopyWith<$Res> get usage {
  
  return $TokenUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc


class ContextUsageEvent implements StreamEvent {
  const ContextUsageEvent(this.usage);
  

 final  ContextUsage usage;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextUsageEventCopyWith<ContextUsageEvent> get copyWith => _$ContextUsageEventCopyWithImpl<ContextUsageEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextUsageEvent&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,usage);

@override
String toString() {
  return 'StreamEvent.contextUsage(usage: $usage)';
}


}

/// @nodoc
abstract mixin class $ContextUsageEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $ContextUsageEventCopyWith(ContextUsageEvent value, $Res Function(ContextUsageEvent) _then) = _$ContextUsageEventCopyWithImpl;
@useResult
$Res call({
 ContextUsage usage
});


$ContextUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$ContextUsageEventCopyWithImpl<$Res>
    implements $ContextUsageEventCopyWith<$Res> {
  _$ContextUsageEventCopyWithImpl(this._self, this._then);

  final ContextUsageEvent _self;
  final $Res Function(ContextUsageEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? usage = null,}) {
  return _then(ContextUsageEvent(
null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as ContextUsage,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContextUsageCopyWith<$Res> get usage {
  
  return $ContextUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc


class PendingActionEvent implements StreamEvent {
  const PendingActionEvent(this.action);
  

 final  PendingAction action;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingActionEventCopyWith<PendingActionEvent> get copyWith => _$PendingActionEventCopyWithImpl<PendingActionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingActionEvent&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,action);

@override
String toString() {
  return 'StreamEvent.pendingAction(action: $action)';
}


}

/// @nodoc
abstract mixin class $PendingActionEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $PendingActionEventCopyWith(PendingActionEvent value, $Res Function(PendingActionEvent) _then) = _$PendingActionEventCopyWithImpl;
@useResult
$Res call({
 PendingAction action
});


$PendingActionCopyWith<$Res> get action;

}
/// @nodoc
class _$PendingActionEventCopyWithImpl<$Res>
    implements $PendingActionEventCopyWith<$Res> {
  _$PendingActionEventCopyWithImpl(this._self, this._then);

  final PendingActionEvent _self;
  final $Res Function(PendingActionEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(PendingActionEvent(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as PendingAction,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingActionCopyWith<$Res> get action {
  
  return $PendingActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class SteerApplied implements StreamEvent {
  const SteerApplied({required this.steerId, this.clientSteerId, this.index, this.part});
  

 final  String steerId;
 final  String? clientSteerId;
 final  int? index;
 final  ContentPart? part;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SteerAppliedCopyWith<SteerApplied> get copyWith => _$SteerAppliedCopyWithImpl<SteerApplied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SteerApplied&&(identical(other.steerId, steerId) || other.steerId == steerId)&&(identical(other.clientSteerId, clientSteerId) || other.clientSteerId == clientSteerId)&&(identical(other.index, index) || other.index == index)&&(identical(other.part, part) || other.part == part));
}


@override
int get hashCode => Object.hash(runtimeType,steerId,clientSteerId,index,part);

@override
String toString() {
  return 'StreamEvent.steerApplied(steerId: $steerId, clientSteerId: $clientSteerId, index: $index, part: $part)';
}


}

/// @nodoc
abstract mixin class $SteerAppliedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $SteerAppliedCopyWith(SteerApplied value, $Res Function(SteerApplied) _then) = _$SteerAppliedCopyWithImpl;
@useResult
$Res call({
 String steerId, String? clientSteerId, int? index, ContentPart? part
});


$ContentPartCopyWith<$Res>? get part;

}
/// @nodoc
class _$SteerAppliedCopyWithImpl<$Res>
    implements $SteerAppliedCopyWith<$Res> {
  _$SteerAppliedCopyWithImpl(this._self, this._then);

  final SteerApplied _self;
  final $Res Function(SteerApplied) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? steerId = null,Object? clientSteerId = freezed,Object? index = freezed,Object? part = freezed,}) {
  return _then(SteerApplied(
steerId: null == steerId ? _self.steerId : steerId // ignore: cast_nullable_to_non_nullable
as String,clientSteerId: freezed == clientSteerId ? _self.clientSteerId : clientSteerId // ignore: cast_nullable_to_non_nullable
as String?,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,part: freezed == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as ContentPart?,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentPartCopyWith<$Res>? get part {
    if (_self.part == null) {
    return null;
  }

  return $ContentPartCopyWith<$Res>(_self.part!, (value) {
    return _then(_self.copyWith(part: value));
  });
}
}

/// @nodoc


class SyncSnapshot implements StreamEvent {
  const SyncSnapshot(final  List<ContentPart> parts): _parts = parts;
  

 final  List<ContentPart> _parts;
 List<ContentPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncSnapshotCopyWith<SyncSnapshot> get copyWith => _$SyncSnapshotCopyWithImpl<SyncSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncSnapshot&&const DeepCollectionEquality().equals(other._parts, _parts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_parts));

@override
String toString() {
  return 'StreamEvent.syncSnapshot(parts: $parts)';
}


}

/// @nodoc
abstract mixin class $SyncSnapshotCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $SyncSnapshotCopyWith(SyncSnapshot value, $Res Function(SyncSnapshot) _then) = _$SyncSnapshotCopyWithImpl;
@useResult
$Res call({
 List<ContentPart> parts
});




}
/// @nodoc
class _$SyncSnapshotCopyWithImpl<$Res>
    implements $SyncSnapshotCopyWith<$Res> {
  _$SyncSnapshotCopyWithImpl(this._self, this._then);

  final SyncSnapshot _self;
  final $Res Function(SyncSnapshot) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? parts = null,}) {
  return _then(SyncSnapshot(
null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<ContentPart>,
  ));
}


}

/// @nodoc


class SteersSynced implements StreamEvent {
  const SteersSynced(final  List<PendingSteer> steers): _steers = steers;
  

 final  List<PendingSteer> _steers;
 List<PendingSteer> get steers {
  if (_steers is EqualUnmodifiableListView) return _steers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steers);
}


/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SteersSyncedCopyWith<SteersSynced> get copyWith => _$SteersSyncedCopyWithImpl<SteersSynced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SteersSynced&&const DeepCollectionEquality().equals(other._steers, _steers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_steers));

@override
String toString() {
  return 'StreamEvent.steersSynced(steers: $steers)';
}


}

/// @nodoc
abstract mixin class $SteersSyncedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $SteersSyncedCopyWith(SteersSynced value, $Res Function(SteersSynced) _then) = _$SteersSyncedCopyWithImpl;
@useResult
$Res call({
 List<PendingSteer> steers
});




}
/// @nodoc
class _$SteersSyncedCopyWithImpl<$Res>
    implements $SteersSyncedCopyWith<$Res> {
  _$SteersSyncedCopyWithImpl(this._self, this._then);

  final SteersSynced _self;
  final $Res Function(SteersSynced) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? steers = null,}) {
  return _then(SteersSynced(
null == steers ? _self._steers : steers // ignore: cast_nullable_to_non_nullable
as List<PendingSteer>,
  ));
}


}

/// @nodoc


class FinalEvent implements StreamEvent {
  const FinalEvent({this.conversation, this.requestMessage, this.responseMessage, this.aborted = false, this.earlyAbort = false, final  List<PendingSteer> pendingSteers = const <PendingSteer>[]}): _pendingSteers = pendingSteers;
  

 final  Conversation? conversation;
 final  Message? requestMessage;
 final  Message? responseMessage;
@JsonKey() final  bool aborted;
@JsonKey() final  bool earlyAbort;
 final  List<PendingSteer> _pendingSteers;
@JsonKey() List<PendingSteer> get pendingSteers {
  if (_pendingSteers is EqualUnmodifiableListView) return _pendingSteers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingSteers);
}


/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinalEventCopyWith<FinalEvent> get copyWith => _$FinalEventCopyWithImpl<FinalEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinalEvent&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.requestMessage, requestMessage) || other.requestMessage == requestMessage)&&(identical(other.responseMessage, responseMessage) || other.responseMessage == responseMessage)&&(identical(other.aborted, aborted) || other.aborted == aborted)&&(identical(other.earlyAbort, earlyAbort) || other.earlyAbort == earlyAbort)&&const DeepCollectionEquality().equals(other._pendingSteers, _pendingSteers));
}


@override
int get hashCode => Object.hash(runtimeType,conversation,requestMessage,responseMessage,aborted,earlyAbort,const DeepCollectionEquality().hash(_pendingSteers));

@override
String toString() {
  return 'StreamEvent.finalFrame(conversation: $conversation, requestMessage: $requestMessage, responseMessage: $responseMessage, aborted: $aborted, earlyAbort: $earlyAbort, pendingSteers: $pendingSteers)';
}


}

/// @nodoc
abstract mixin class $FinalEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $FinalEventCopyWith(FinalEvent value, $Res Function(FinalEvent) _then) = _$FinalEventCopyWithImpl;
@useResult
$Res call({
 Conversation? conversation, Message? requestMessage, Message? responseMessage, bool aborted, bool earlyAbort, List<PendingSteer> pendingSteers
});


$ConversationCopyWith<$Res>? get conversation;$MessageCopyWith<$Res>? get requestMessage;$MessageCopyWith<$Res>? get responseMessage;

}
/// @nodoc
class _$FinalEventCopyWithImpl<$Res>
    implements $FinalEventCopyWith<$Res> {
  _$FinalEventCopyWithImpl(this._self, this._then);

  final FinalEvent _self;
  final $Res Function(FinalEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversation = freezed,Object? requestMessage = freezed,Object? responseMessage = freezed,Object? aborted = null,Object? earlyAbort = null,Object? pendingSteers = null,}) {
  return _then(FinalEvent(
conversation: freezed == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as Conversation?,requestMessage: freezed == requestMessage ? _self.requestMessage : requestMessage // ignore: cast_nullable_to_non_nullable
as Message?,responseMessage: freezed == responseMessage ? _self.responseMessage : responseMessage // ignore: cast_nullable_to_non_nullable
as Message?,aborted: null == aborted ? _self.aborted : aborted // ignore: cast_nullable_to_non_nullable
as bool,earlyAbort: null == earlyAbort ? _self.earlyAbort : earlyAbort // ignore: cast_nullable_to_non_nullable
as bool,pendingSteers: null == pendingSteers ? _self._pendingSteers : pendingSteers // ignore: cast_nullable_to_non_nullable
as List<PendingSteer>,
  ));
}

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConversationCopyWith<$Res>? get conversation {
    if (_self.conversation == null) {
    return null;
  }

  return $ConversationCopyWith<$Res>(_self.conversation!, (value) {
    return _then(_self.copyWith(conversation: value));
  });
}/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get requestMessage {
    if (_self.requestMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.requestMessage!, (value) {
    return _then(_self.copyWith(requestMessage: value));
  });
}/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get responseMessage {
    if (_self.responseMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.responseMessage!, (value) {
    return _then(_self.copyWith(responseMessage: value));
  });
}
}

/// @nodoc


class CreatedEvent implements StreamEvent {
  const CreatedEvent({this.conversationId, this.messageId, this.parentMessageId});
  

 final  String? conversationId;
 final  String? messageId;
 final  String? parentMessageId;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedEventCopyWith<CreatedEvent> get copyWith => _$CreatedEventCopyWithImpl<CreatedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedEvent&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,messageId,parentMessageId);

@override
String toString() {
  return 'StreamEvent.created(conversationId: $conversationId, messageId: $messageId, parentMessageId: $parentMessageId)';
}


}

/// @nodoc
abstract mixin class $CreatedEventCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $CreatedEventCopyWith(CreatedEvent value, $Res Function(CreatedEvent) _then) = _$CreatedEventCopyWithImpl;
@useResult
$Res call({
 String? conversationId, String? messageId, String? parentMessageId
});




}
/// @nodoc
class _$CreatedEventCopyWithImpl<$Res>
    implements $CreatedEventCopyWith<$Res> {
  _$CreatedEventCopyWithImpl(this._self, this._then);

  final CreatedEvent _self;
  final $Res Function(CreatedEvent) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversationId = freezed,Object? messageId = freezed,Object? parentMessageId = freezed,}) {
  return _then(CreatedEvent(
conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class StreamError implements StreamEvent {
  const StreamError(this.text);
  

 final  String text;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamErrorCopyWith<StreamError> get copyWith => _$StreamErrorCopyWithImpl<StreamError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamError&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'StreamEvent.streamError(text: $text)';
}


}

/// @nodoc
abstract mixin class $StreamErrorCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamErrorCopyWith(StreamError value, $Res Function(StreamError) _then) = _$StreamErrorCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$StreamErrorCopyWithImpl<$Res>
    implements $StreamErrorCopyWith<$Res> {
  _$StreamErrorCopyWithImpl(this._self, this._then);

  final StreamError _self;
  final $Res Function(StreamError) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(StreamError(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StreamReconnecting implements StreamEvent {
  const StreamReconnecting(this.attempt);
  

 final  int attempt;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamReconnectingCopyWith<StreamReconnecting> get copyWith => _$StreamReconnectingCopyWithImpl<StreamReconnecting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamReconnecting&&(identical(other.attempt, attempt) || other.attempt == attempt));
}


@override
int get hashCode => Object.hash(runtimeType,attempt);

@override
String toString() {
  return 'StreamEvent.reconnecting(attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class $StreamReconnectingCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamReconnectingCopyWith(StreamReconnecting value, $Res Function(StreamReconnecting) _then) = _$StreamReconnectingCopyWithImpl;
@useResult
$Res call({
 int attempt
});




}
/// @nodoc
class _$StreamReconnectingCopyWithImpl<$Res>
    implements $StreamReconnectingCopyWith<$Res> {
  _$StreamReconnectingCopyWithImpl(this._self, this._then);

  final StreamReconnecting _self;
  final $Res Function(StreamReconnecting) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempt = null,}) {
  return _then(StreamReconnecting(
null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class StreamExpired implements StreamEvent {
  const StreamExpired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamExpired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent.expired()';
}


}




/// @nodoc


class StreamRetryExhausted implements StreamEvent {
  const StreamRetryExhausted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamRetryExhausted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent.retryExhausted()';
}


}




/// @nodoc


class StreamFailed implements StreamEvent {
  const StreamFailed(this.error);
  

 final  AppException error;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamFailedCopyWith<StreamFailed> get copyWith => _$StreamFailedCopyWithImpl<StreamFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamFailed&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'StreamEvent.failed(error: $error)';
}


}

/// @nodoc
abstract mixin class $StreamFailedCopyWith<$Res> implements $StreamEventCopyWith<$Res> {
  factory $StreamFailedCopyWith(StreamFailed value, $Res Function(StreamFailed) _then) = _$StreamFailedCopyWithImpl;
@useResult
$Res call({
 AppException error
});




}
/// @nodoc
class _$StreamFailedCopyWithImpl<$Res>
    implements $StreamFailedCopyWith<$Res> {
  _$StreamFailedCopyWithImpl(this._self, this._then);

  final StreamFailed _self;
  final $Res Function(StreamFailed) _then;

/// Create a copy of StreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(StreamFailed(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppException,
  ));
}


}

// dart format on
