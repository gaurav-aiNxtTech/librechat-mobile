// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_turn.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSelection {

 String get endpoint; String? get endpointType; String? get model; String? get agentId; String? get spec; String? get modelLabel;
/// Create a copy of ChatSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<ChatSelection> get copyWith => _$ChatSelectionCopyWithImpl<ChatSelection>(this as ChatSelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSelection&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.endpointType, endpointType) || other.endpointType == endpointType)&&(identical(other.model, model) || other.model == model)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.spec, spec) || other.spec == spec)&&(identical(other.modelLabel, modelLabel) || other.modelLabel == modelLabel));
}


@override
int get hashCode => Object.hash(runtimeType,endpoint,endpointType,model,agentId,spec,modelLabel);

@override
String toString() {
  return 'ChatSelection(endpoint: $endpoint, endpointType: $endpointType, model: $model, agentId: $agentId, spec: $spec, modelLabel: $modelLabel)';
}


}

/// @nodoc
abstract mixin class $ChatSelectionCopyWith<$Res>  {
  factory $ChatSelectionCopyWith(ChatSelection value, $Res Function(ChatSelection) _then) = _$ChatSelectionCopyWithImpl;
@useResult
$Res call({
 String endpoint, String? endpointType, String? model, String? agentId, String? spec, String? modelLabel
});




}
/// @nodoc
class _$ChatSelectionCopyWithImpl<$Res>
    implements $ChatSelectionCopyWith<$Res> {
  _$ChatSelectionCopyWithImpl(this._self, this._then);

  final ChatSelection _self;
  final $Res Function(ChatSelection) _then;

/// Create a copy of ChatSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? endpoint = null,Object? endpointType = freezed,Object? model = freezed,Object? agentId = freezed,Object? spec = freezed,Object? modelLabel = freezed,}) {
  return _then(_self.copyWith(
endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,endpointType: freezed == endpointType ? _self.endpointType : endpointType // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,spec: freezed == spec ? _self.spec : spec // ignore: cast_nullable_to_non_nullable
as String?,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSelection].
extension ChatSelectionPatterns on ChatSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSelection value)  $default,){
final _that = this;
switch (_that) {
case _ChatSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSelection value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String endpoint,  String? endpointType,  String? model,  String? agentId,  String? spec,  String? modelLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSelection() when $default != null:
return $default(_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.modelLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String endpoint,  String? endpointType,  String? model,  String? agentId,  String? spec,  String? modelLabel)  $default,) {final _that = this;
switch (_that) {
case _ChatSelection():
return $default(_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.modelLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String endpoint,  String? endpointType,  String? model,  String? agentId,  String? spec,  String? modelLabel)?  $default,) {final _that = this;
switch (_that) {
case _ChatSelection() when $default != null:
return $default(_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.modelLabel);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSelection extends ChatSelection {
  const _ChatSelection({required this.endpoint, this.endpointType, this.model, this.agentId, this.spec, this.modelLabel}): super._();
  

@override final  String endpoint;
@override final  String? endpointType;
@override final  String? model;
@override final  String? agentId;
@override final  String? spec;
@override final  String? modelLabel;

/// Create a copy of ChatSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSelectionCopyWith<_ChatSelection> get copyWith => __$ChatSelectionCopyWithImpl<_ChatSelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSelection&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.endpointType, endpointType) || other.endpointType == endpointType)&&(identical(other.model, model) || other.model == model)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.spec, spec) || other.spec == spec)&&(identical(other.modelLabel, modelLabel) || other.modelLabel == modelLabel));
}


@override
int get hashCode => Object.hash(runtimeType,endpoint,endpointType,model,agentId,spec,modelLabel);

@override
String toString() {
  return 'ChatSelection(endpoint: $endpoint, endpointType: $endpointType, model: $model, agentId: $agentId, spec: $spec, modelLabel: $modelLabel)';
}


}

/// @nodoc
abstract mixin class _$ChatSelectionCopyWith<$Res> implements $ChatSelectionCopyWith<$Res> {
  factory _$ChatSelectionCopyWith(_ChatSelection value, $Res Function(_ChatSelection) _then) = __$ChatSelectionCopyWithImpl;
@override @useResult
$Res call({
 String endpoint, String? endpointType, String? model, String? agentId, String? spec, String? modelLabel
});




}
/// @nodoc
class __$ChatSelectionCopyWithImpl<$Res>
    implements _$ChatSelectionCopyWith<$Res> {
  __$ChatSelectionCopyWithImpl(this._self, this._then);

  final _ChatSelection _self;
  final $Res Function(_ChatSelection) _then;

/// Create a copy of ChatSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? endpoint = null,Object? endpointType = freezed,Object? model = freezed,Object? agentId = freezed,Object? spec = freezed,Object? modelLabel = freezed,}) {
  return _then(_ChatSelection(
endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,endpointType: freezed == endpointType ? _self.endpointType : endpointType // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,spec: freezed == spec ? _self.spec : spec // ignore: cast_nullable_to_non_nullable
as String?,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ChatTurn {

 TurnKind get kind; ChatSelection get selection; String get text; List<Attachment> get files; List<String> get quotes; ChatSelection? get addedSelection; Set<ChatTool> get tools; List<String> get mcpServers; Map<String, Object?> get params; bool get isTemporary; String? get parentMessageId; Message? get userMessage; String? get responseMessageId;
/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnCopyWith<ChatTurn> get copyWith => _$ChatTurnCopyWithImpl<ChatTurn>(this as ChatTurn, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurn&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.files, files)&&const DeepCollectionEquality().equals(other.quotes, quotes)&&(identical(other.addedSelection, addedSelection) || other.addedSelection == addedSelection)&&const DeepCollectionEquality().equals(other.tools, tools)&&const DeepCollectionEquality().equals(other.mcpServers, mcpServers)&&const DeepCollectionEquality().equals(other.params, params)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&(identical(other.responseMessageId, responseMessageId) || other.responseMessageId == responseMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,kind,selection,text,const DeepCollectionEquality().hash(files),const DeepCollectionEquality().hash(quotes),addedSelection,const DeepCollectionEquality().hash(tools),const DeepCollectionEquality().hash(mcpServers),const DeepCollectionEquality().hash(params),isTemporary,parentMessageId,userMessage,responseMessageId);

@override
String toString() {
  return 'ChatTurn(kind: $kind, selection: $selection, text: $text, files: $files, quotes: $quotes, addedSelection: $addedSelection, tools: $tools, mcpServers: $mcpServers, params: $params, isTemporary: $isTemporary, parentMessageId: $parentMessageId, userMessage: $userMessage, responseMessageId: $responseMessageId)';
}


}

/// @nodoc
abstract mixin class $ChatTurnCopyWith<$Res>  {
  factory $ChatTurnCopyWith(ChatTurn value, $Res Function(ChatTurn) _then) = _$ChatTurnCopyWithImpl;
@useResult
$Res call({
 TurnKind kind, ChatSelection selection, String text, List<Attachment> files, List<String> quotes, ChatSelection? addedSelection, Set<ChatTool> tools, List<String> mcpServers, Map<String, Object?> params, bool isTemporary, String? parentMessageId, Message? userMessage, String? responseMessageId
});


$ChatSelectionCopyWith<$Res> get selection;$ChatSelectionCopyWith<$Res>? get addedSelection;$MessageCopyWith<$Res>? get userMessage;

}
/// @nodoc
class _$ChatTurnCopyWithImpl<$Res>
    implements $ChatTurnCopyWith<$Res> {
  _$ChatTurnCopyWithImpl(this._self, this._then);

  final ChatTurn _self;
  final $Res Function(ChatTurn) _then;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? selection = null,Object? text = null,Object? files = null,Object? quotes = null,Object? addedSelection = freezed,Object? tools = null,Object? mcpServers = null,Object? params = null,Object? isTemporary = null,Object? parentMessageId = freezed,Object? userMessage = freezed,Object? responseMessageId = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as ChatSelection,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,quotes: null == quotes ? _self.quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>,addedSelection: freezed == addedSelection ? _self.addedSelection : addedSelection // ignore: cast_nullable_to_non_nullable
as ChatSelection?,tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as Set<ChatTool>,mcpServers: null == mcpServers ? _self.mcpServers : mcpServers // ignore: cast_nullable_to_non_nullable
as List<String>,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,isTemporary: null == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as Message?,responseMessageId: freezed == responseMessageId ? _self.responseMessageId : responseMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res> get selection {
  
  return $ChatSelectionCopyWith<$Res>(_self.selection, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res>? get addedSelection {
    if (_self.addedSelection == null) {
    return null;
  }

  return $ChatSelectionCopyWith<$Res>(_self.addedSelection!, (value) {
    return _then(_self.copyWith(addedSelection: value));
  });
}/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get userMessage {
    if (_self.userMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.userMessage!, (value) {
    return _then(_self.copyWith(userMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatTurn].
extension ChatTurnPatterns on ChatTurn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTurn value)  $default,){
final _that = this;
switch (_that) {
case _ChatTurn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTurn value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TurnKind kind,  ChatSelection selection,  String text,  List<Attachment> files,  List<String> quotes,  ChatSelection? addedSelection,  Set<ChatTool> tools,  List<String> mcpServers,  Map<String, Object?> params,  bool isTemporary,  String? parentMessageId,  Message? userMessage,  String? responseMessageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
return $default(_that.kind,_that.selection,_that.text,_that.files,_that.quotes,_that.addedSelection,_that.tools,_that.mcpServers,_that.params,_that.isTemporary,_that.parentMessageId,_that.userMessage,_that.responseMessageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TurnKind kind,  ChatSelection selection,  String text,  List<Attachment> files,  List<String> quotes,  ChatSelection? addedSelection,  Set<ChatTool> tools,  List<String> mcpServers,  Map<String, Object?> params,  bool isTemporary,  String? parentMessageId,  Message? userMessage,  String? responseMessageId)  $default,) {final _that = this;
switch (_that) {
case _ChatTurn():
return $default(_that.kind,_that.selection,_that.text,_that.files,_that.quotes,_that.addedSelection,_that.tools,_that.mcpServers,_that.params,_that.isTemporary,_that.parentMessageId,_that.userMessage,_that.responseMessageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TurnKind kind,  ChatSelection selection,  String text,  List<Attachment> files,  List<String> quotes,  ChatSelection? addedSelection,  Set<ChatTool> tools,  List<String> mcpServers,  Map<String, Object?> params,  bool isTemporary,  String? parentMessageId,  Message? userMessage,  String? responseMessageId)?  $default,) {final _that = this;
switch (_that) {
case _ChatTurn() when $default != null:
return $default(_that.kind,_that.selection,_that.text,_that.files,_that.quotes,_that.addedSelection,_that.tools,_that.mcpServers,_that.params,_that.isTemporary,_that.parentMessageId,_that.userMessage,_that.responseMessageId);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTurn implements ChatTurn {
  const _ChatTurn({required this.kind, required this.selection, this.text = '', final  List<Attachment> files = const <Attachment>[], final  List<String> quotes = const <String>[], this.addedSelection, final  Set<ChatTool> tools = const <ChatTool>{}, final  List<String> mcpServers = const <String>[], final  Map<String, Object?> params = const <String, Object?>{}, this.isTemporary = false, this.parentMessageId, this.userMessage, this.responseMessageId}): _files = files,_quotes = quotes,_tools = tools,_mcpServers = mcpServers,_params = params;
  

@override final  TurnKind kind;
@override final  ChatSelection selection;
@override@JsonKey() final  String text;
 final  List<Attachment> _files;
@override@JsonKey() List<Attachment> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

 final  List<String> _quotes;
@override@JsonKey() List<String> get quotes {
  if (_quotes is EqualUnmodifiableListView) return _quotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quotes);
}

@override final  ChatSelection? addedSelection;
 final  Set<ChatTool> _tools;
@override@JsonKey() Set<ChatTool> get tools {
  if (_tools is EqualUnmodifiableSetView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tools);
}

 final  List<String> _mcpServers;
@override@JsonKey() List<String> get mcpServers {
  if (_mcpServers is EqualUnmodifiableListView) return _mcpServers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mcpServers);
}

 final  Map<String, Object?> _params;
@override@JsonKey() Map<String, Object?> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}

@override@JsonKey() final  bool isTemporary;
@override final  String? parentMessageId;
@override final  Message? userMessage;
@override final  String? responseMessageId;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTurnCopyWith<_ChatTurn> get copyWith => __$ChatTurnCopyWithImpl<_ChatTurn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTurn&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.selection, selection) || other.selection == selection)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._files, _files)&&const DeepCollectionEquality().equals(other._quotes, _quotes)&&(identical(other.addedSelection, addedSelection) || other.addedSelection == addedSelection)&&const DeepCollectionEquality().equals(other._tools, _tools)&&const DeepCollectionEquality().equals(other._mcpServers, _mcpServers)&&const DeepCollectionEquality().equals(other._params, _params)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&(identical(other.responseMessageId, responseMessageId) || other.responseMessageId == responseMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,kind,selection,text,const DeepCollectionEquality().hash(_files),const DeepCollectionEquality().hash(_quotes),addedSelection,const DeepCollectionEquality().hash(_tools),const DeepCollectionEquality().hash(_mcpServers),const DeepCollectionEquality().hash(_params),isTemporary,parentMessageId,userMessage,responseMessageId);

@override
String toString() {
  return 'ChatTurn(kind: $kind, selection: $selection, text: $text, files: $files, quotes: $quotes, addedSelection: $addedSelection, tools: $tools, mcpServers: $mcpServers, params: $params, isTemporary: $isTemporary, parentMessageId: $parentMessageId, userMessage: $userMessage, responseMessageId: $responseMessageId)';
}


}

/// @nodoc
abstract mixin class _$ChatTurnCopyWith<$Res> implements $ChatTurnCopyWith<$Res> {
  factory _$ChatTurnCopyWith(_ChatTurn value, $Res Function(_ChatTurn) _then) = __$ChatTurnCopyWithImpl;
@override @useResult
$Res call({
 TurnKind kind, ChatSelection selection, String text, List<Attachment> files, List<String> quotes, ChatSelection? addedSelection, Set<ChatTool> tools, List<String> mcpServers, Map<String, Object?> params, bool isTemporary, String? parentMessageId, Message? userMessage, String? responseMessageId
});


@override $ChatSelectionCopyWith<$Res> get selection;@override $ChatSelectionCopyWith<$Res>? get addedSelection;@override $MessageCopyWith<$Res>? get userMessage;

}
/// @nodoc
class __$ChatTurnCopyWithImpl<$Res>
    implements _$ChatTurnCopyWith<$Res> {
  __$ChatTurnCopyWithImpl(this._self, this._then);

  final _ChatTurn _self;
  final $Res Function(_ChatTurn) _then;

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? selection = null,Object? text = null,Object? files = null,Object? quotes = null,Object? addedSelection = freezed,Object? tools = null,Object? mcpServers = null,Object? params = null,Object? isTemporary = null,Object? parentMessageId = freezed,Object? userMessage = freezed,Object? responseMessageId = freezed,}) {
  return _then(_ChatTurn(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TurnKind,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as ChatSelection,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,quotes: null == quotes ? _self._quotes : quotes // ignore: cast_nullable_to_non_nullable
as List<String>,addedSelection: freezed == addedSelection ? _self.addedSelection : addedSelection // ignore: cast_nullable_to_non_nullable
as ChatSelection?,tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as Set<ChatTool>,mcpServers: null == mcpServers ? _self._mcpServers : mcpServers // ignore: cast_nullable_to_non_nullable
as List<String>,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,isTemporary: null == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool,parentMessageId: freezed == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as Message?,responseMessageId: freezed == responseMessageId ? _self.responseMessageId : responseMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res> get selection {
  
  return $ChatSelectionCopyWith<$Res>(_self.selection, (value) {
    return _then(_self.copyWith(selection: value));
  });
}/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatSelectionCopyWith<$Res>? get addedSelection {
    if (_self.addedSelection == null) {
    return null;
  }

  return $ChatSelectionCopyWith<$Res>(_self.addedSelection!, (value) {
    return _then(_self.copyWith(addedSelection: value));
  });
}/// Create a copy of ChatTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get userMessage {
    if (_self.userMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.userMessage!, (value) {
    return _then(_self.copyWith(userMessage: value));
  });
}
}

// dart format on
