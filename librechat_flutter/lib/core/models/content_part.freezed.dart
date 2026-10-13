// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_part.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContentPart {

 String get type;@FlexibleTextConverter() String? get text; String? get think;@JsonKey(name: 'tool_call_ids') List<String>? get toolCallIds;@JsonKey(name: 'tool_call') ToolCall? get toolCall;@JsonKey(name: 'image_url') Object? get imageUrl;@JsonKey(name: 'image_file') Map<String, Object?>? get imageFile;@JsonKey(name: 'video_url') Object? get videoUrl;@JsonKey(name: 'input_audio') Map<String, Object?>? get inputAudio; String? get error;@JsonKey(name: 'agent_update') Map<String, Object?>? get agentUpdate; Object? get steer;// The Server sends the steered text as a string.
@JsonKey(name: 'activity_label') String? get activityLabel;@JsonKey(name: 'activity_label_type') String? get activityLabelType;@JsonKey(name: 'activity_end_index') int? get activityEndIndex;// An activity label still being written: a reservation, or a phase that has not finalized.
 bool? get pending;// An activity label's `failed` or `partial` batch status, or a live
// tool call's terminal step status from `on_run_step_closed`.
 String? get status;// A summary's body: a string or a list of `{type, text}` blocks.
 Object? get content; String? get agentId; int? get groupId; int? get stepIndex;
/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentPartCopyWith<ContentPart> get copyWith => _$ContentPartCopyWithImpl<ContentPart>(this as ContentPart, _$identity);

  /// Serializes this ContentPart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentPart&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.think, think) || other.think == think)&&const DeepCollectionEquality().equals(other.toolCallIds, toolCallIds)&&(identical(other.toolCall, toolCall) || other.toolCall == toolCall)&&const DeepCollectionEquality().equals(other.imageUrl, imageUrl)&&const DeepCollectionEquality().equals(other.imageFile, imageFile)&&const DeepCollectionEquality().equals(other.videoUrl, videoUrl)&&const DeepCollectionEquality().equals(other.inputAudio, inputAudio)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.agentUpdate, agentUpdate)&&const DeepCollectionEquality().equals(other.steer, steer)&&(identical(other.activityLabel, activityLabel) || other.activityLabel == activityLabel)&&(identical(other.activityLabelType, activityLabelType) || other.activityLabelType == activityLabelType)&&(identical(other.activityEndIndex, activityEndIndex) || other.activityEndIndex == activityEndIndex)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,text,think,const DeepCollectionEquality().hash(toolCallIds),toolCall,const DeepCollectionEquality().hash(imageUrl),const DeepCollectionEquality().hash(imageFile),const DeepCollectionEquality().hash(videoUrl),const DeepCollectionEquality().hash(inputAudio),error,const DeepCollectionEquality().hash(agentUpdate),const DeepCollectionEquality().hash(steer),activityLabel,activityLabelType,activityEndIndex,pending,status,const DeepCollectionEquality().hash(content),agentId,groupId,stepIndex]);

@override
String toString() {
  return 'ContentPart(type: $type, text: $text, think: $think, toolCallIds: $toolCallIds, toolCall: $toolCall, imageUrl: $imageUrl, imageFile: $imageFile, videoUrl: $videoUrl, inputAudio: $inputAudio, error: $error, agentUpdate: $agentUpdate, steer: $steer, activityLabel: $activityLabel, activityLabelType: $activityLabelType, activityEndIndex: $activityEndIndex, pending: $pending, status: $status, content: $content, agentId: $agentId, groupId: $groupId, stepIndex: $stepIndex)';
}


}

/// @nodoc
abstract mixin class $ContentPartCopyWith<$Res>  {
  factory $ContentPartCopyWith(ContentPart value, $Res Function(ContentPart) _then) = _$ContentPartCopyWithImpl;
@useResult
$Res call({
 String type,@FlexibleTextConverter() String? text, String? think,@JsonKey(name: 'tool_call_ids') List<String>? toolCallIds,@JsonKey(name: 'tool_call') ToolCall? toolCall,@JsonKey(name: 'image_url') Object? imageUrl,@JsonKey(name: 'image_file') Map<String, Object?>? imageFile,@JsonKey(name: 'video_url') Object? videoUrl,@JsonKey(name: 'input_audio') Map<String, Object?>? inputAudio, String? error,@JsonKey(name: 'agent_update') Map<String, Object?>? agentUpdate, Object? steer,@JsonKey(name: 'activity_label') String? activityLabel,@JsonKey(name: 'activity_label_type') String? activityLabelType,@JsonKey(name: 'activity_end_index') int? activityEndIndex, bool? pending, String? status, Object? content, String? agentId, int? groupId, int? stepIndex
});


$ToolCallCopyWith<$Res>? get toolCall;

}
/// @nodoc
class _$ContentPartCopyWithImpl<$Res>
    implements $ContentPartCopyWith<$Res> {
  _$ContentPartCopyWithImpl(this._self, this._then);

  final ContentPart _self;
  final $Res Function(ContentPart) _then;

/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = freezed,Object? think = freezed,Object? toolCallIds = freezed,Object? toolCall = freezed,Object? imageUrl = freezed,Object? imageFile = freezed,Object? videoUrl = freezed,Object? inputAudio = freezed,Object? error = freezed,Object? agentUpdate = freezed,Object? steer = freezed,Object? activityLabel = freezed,Object? activityLabelType = freezed,Object? activityEndIndex = freezed,Object? pending = freezed,Object? status = freezed,Object? content = freezed,Object? agentId = freezed,Object? groupId = freezed,Object? stepIndex = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,think: freezed == think ? _self.think : think // ignore: cast_nullable_to_non_nullable
as String?,toolCallIds: freezed == toolCallIds ? _self.toolCallIds : toolCallIds // ignore: cast_nullable_to_non_nullable
as List<String>?,toolCall: freezed == toolCall ? _self.toolCall : toolCall // ignore: cast_nullable_to_non_nullable
as ToolCall?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl ,imageFile: freezed == imageFile ? _self.imageFile : imageFile // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl ,inputAudio: freezed == inputAudio ? _self.inputAudio : inputAudio // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,agentUpdate: freezed == agentUpdate ? _self.agentUpdate : agentUpdate // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,steer: freezed == steer ? _self.steer : steer ,activityLabel: freezed == activityLabel ? _self.activityLabel : activityLabel // ignore: cast_nullable_to_non_nullable
as String?,activityLabelType: freezed == activityLabelType ? _self.activityLabelType : activityLabelType // ignore: cast_nullable_to_non_nullable
as String?,activityEndIndex: freezed == activityEndIndex ? _self.activityEndIndex : activityEndIndex // ignore: cast_nullable_to_non_nullable
as int?,pending: freezed == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content ,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,stepIndex: freezed == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallCopyWith<$Res>? get toolCall {
    if (_self.toolCall == null) {
    return null;
  }

  return $ToolCallCopyWith<$Res>(_self.toolCall!, (value) {
    return _then(_self.copyWith(toolCall: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContentPart].
extension ContentPartPatterns on ContentPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentPart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentPart value)  $default,){
final _that = this;
switch (_that) {
case _ContentPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentPart value)?  $default,){
final _that = this;
switch (_that) {
case _ContentPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type, @FlexibleTextConverter()  String? text,  String? think, @JsonKey(name: 'tool_call_ids')  List<String>? toolCallIds, @JsonKey(name: 'tool_call')  ToolCall? toolCall, @JsonKey(name: 'image_url')  Object? imageUrl, @JsonKey(name: 'image_file')  Map<String, Object?>? imageFile, @JsonKey(name: 'video_url')  Object? videoUrl, @JsonKey(name: 'input_audio')  Map<String, Object?>? inputAudio,  String? error, @JsonKey(name: 'agent_update')  Map<String, Object?>? agentUpdate,  Object? steer, @JsonKey(name: 'activity_label')  String? activityLabel, @JsonKey(name: 'activity_label_type')  String? activityLabelType, @JsonKey(name: 'activity_end_index')  int? activityEndIndex,  bool? pending,  String? status,  Object? content,  String? agentId,  int? groupId,  int? stepIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentPart() when $default != null:
return $default(_that.type,_that.text,_that.think,_that.toolCallIds,_that.toolCall,_that.imageUrl,_that.imageFile,_that.videoUrl,_that.inputAudio,_that.error,_that.agentUpdate,_that.steer,_that.activityLabel,_that.activityLabelType,_that.activityEndIndex,_that.pending,_that.status,_that.content,_that.agentId,_that.groupId,_that.stepIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type, @FlexibleTextConverter()  String? text,  String? think, @JsonKey(name: 'tool_call_ids')  List<String>? toolCallIds, @JsonKey(name: 'tool_call')  ToolCall? toolCall, @JsonKey(name: 'image_url')  Object? imageUrl, @JsonKey(name: 'image_file')  Map<String, Object?>? imageFile, @JsonKey(name: 'video_url')  Object? videoUrl, @JsonKey(name: 'input_audio')  Map<String, Object?>? inputAudio,  String? error, @JsonKey(name: 'agent_update')  Map<String, Object?>? agentUpdate,  Object? steer, @JsonKey(name: 'activity_label')  String? activityLabel, @JsonKey(name: 'activity_label_type')  String? activityLabelType, @JsonKey(name: 'activity_end_index')  int? activityEndIndex,  bool? pending,  String? status,  Object? content,  String? agentId,  int? groupId,  int? stepIndex)  $default,) {final _that = this;
switch (_that) {
case _ContentPart():
return $default(_that.type,_that.text,_that.think,_that.toolCallIds,_that.toolCall,_that.imageUrl,_that.imageFile,_that.videoUrl,_that.inputAudio,_that.error,_that.agentUpdate,_that.steer,_that.activityLabel,_that.activityLabelType,_that.activityEndIndex,_that.pending,_that.status,_that.content,_that.agentId,_that.groupId,_that.stepIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type, @FlexibleTextConverter()  String? text,  String? think, @JsonKey(name: 'tool_call_ids')  List<String>? toolCallIds, @JsonKey(name: 'tool_call')  ToolCall? toolCall, @JsonKey(name: 'image_url')  Object? imageUrl, @JsonKey(name: 'image_file')  Map<String, Object?>? imageFile, @JsonKey(name: 'video_url')  Object? videoUrl, @JsonKey(name: 'input_audio')  Map<String, Object?>? inputAudio,  String? error, @JsonKey(name: 'agent_update')  Map<String, Object?>? agentUpdate,  Object? steer, @JsonKey(name: 'activity_label')  String? activityLabel, @JsonKey(name: 'activity_label_type')  String? activityLabelType, @JsonKey(name: 'activity_end_index')  int? activityEndIndex,  bool? pending,  String? status,  Object? content,  String? agentId,  int? groupId,  int? stepIndex)?  $default,) {final _that = this;
switch (_that) {
case _ContentPart() when $default != null:
return $default(_that.type,_that.text,_that.think,_that.toolCallIds,_that.toolCall,_that.imageUrl,_that.imageFile,_that.videoUrl,_that.inputAudio,_that.error,_that.agentUpdate,_that.steer,_that.activityLabel,_that.activityLabelType,_that.activityEndIndex,_that.pending,_that.status,_that.content,_that.agentId,_that.groupId,_that.stepIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContentPart implements ContentPart {
  const _ContentPart({required this.type, @FlexibleTextConverter() this.text, this.think, @JsonKey(name: 'tool_call_ids') final  List<String>? toolCallIds, @JsonKey(name: 'tool_call') this.toolCall, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'image_file') final  Map<String, Object?>? imageFile, @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'input_audio') final  Map<String, Object?>? inputAudio, this.error, @JsonKey(name: 'agent_update') final  Map<String, Object?>? agentUpdate, this.steer, @JsonKey(name: 'activity_label') this.activityLabel, @JsonKey(name: 'activity_label_type') this.activityLabelType, @JsonKey(name: 'activity_end_index') this.activityEndIndex, this.pending, this.status, this.content, this.agentId, this.groupId, this.stepIndex}): _toolCallIds = toolCallIds,_imageFile = imageFile,_inputAudio = inputAudio,_agentUpdate = agentUpdate;
  factory _ContentPart.fromJson(Map<String, dynamic> json) => _$ContentPartFromJson(json);

@override final  String type;
@override@FlexibleTextConverter() final  String? text;
@override final  String? think;
 final  List<String>? _toolCallIds;
@override@JsonKey(name: 'tool_call_ids') List<String>? get toolCallIds {
  final value = _toolCallIds;
  if (value == null) return null;
  if (_toolCallIds is EqualUnmodifiableListView) return _toolCallIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'tool_call') final  ToolCall? toolCall;
@override@JsonKey(name: 'image_url') final  Object? imageUrl;
 final  Map<String, Object?>? _imageFile;
@override@JsonKey(name: 'image_file') Map<String, Object?>? get imageFile {
  final value = _imageFile;
  if (value == null) return null;
  if (_imageFile is EqualUnmodifiableMapView) return _imageFile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'video_url') final  Object? videoUrl;
 final  Map<String, Object?>? _inputAudio;
@override@JsonKey(name: 'input_audio') Map<String, Object?>? get inputAudio {
  final value = _inputAudio;
  if (value == null) return null;
  if (_inputAudio is EqualUnmodifiableMapView) return _inputAudio;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? error;
 final  Map<String, Object?>? _agentUpdate;
@override@JsonKey(name: 'agent_update') Map<String, Object?>? get agentUpdate {
  final value = _agentUpdate;
  if (value == null) return null;
  if (_agentUpdate is EqualUnmodifiableMapView) return _agentUpdate;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  Object? steer;
// The Server sends the steered text as a string.
@override@JsonKey(name: 'activity_label') final  String? activityLabel;
@override@JsonKey(name: 'activity_label_type') final  String? activityLabelType;
@override@JsonKey(name: 'activity_end_index') final  int? activityEndIndex;
// An activity label still being written: a reservation, or a phase that has not finalized.
@override final  bool? pending;
// An activity label's `failed` or `partial` batch status, or a live
// tool call's terminal step status from `on_run_step_closed`.
@override final  String? status;
// A summary's body: a string or a list of `{type, text}` blocks.
@override final  Object? content;
@override final  String? agentId;
@override final  int? groupId;
@override final  int? stepIndex;

/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentPartCopyWith<_ContentPart> get copyWith => __$ContentPartCopyWithImpl<_ContentPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentPartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentPart&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.think, think) || other.think == think)&&const DeepCollectionEquality().equals(other._toolCallIds, _toolCallIds)&&(identical(other.toolCall, toolCall) || other.toolCall == toolCall)&&const DeepCollectionEquality().equals(other.imageUrl, imageUrl)&&const DeepCollectionEquality().equals(other._imageFile, _imageFile)&&const DeepCollectionEquality().equals(other.videoUrl, videoUrl)&&const DeepCollectionEquality().equals(other._inputAudio, _inputAudio)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._agentUpdate, _agentUpdate)&&const DeepCollectionEquality().equals(other.steer, steer)&&(identical(other.activityLabel, activityLabel) || other.activityLabel == activityLabel)&&(identical(other.activityLabelType, activityLabelType) || other.activityLabelType == activityLabelType)&&(identical(other.activityEndIndex, activityEndIndex) || other.activityEndIndex == activityEndIndex)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,text,think,const DeepCollectionEquality().hash(_toolCallIds),toolCall,const DeepCollectionEquality().hash(imageUrl),const DeepCollectionEquality().hash(_imageFile),const DeepCollectionEquality().hash(videoUrl),const DeepCollectionEquality().hash(_inputAudio),error,const DeepCollectionEquality().hash(_agentUpdate),const DeepCollectionEquality().hash(steer),activityLabel,activityLabelType,activityEndIndex,pending,status,const DeepCollectionEquality().hash(content),agentId,groupId,stepIndex]);

@override
String toString() {
  return 'ContentPart(type: $type, text: $text, think: $think, toolCallIds: $toolCallIds, toolCall: $toolCall, imageUrl: $imageUrl, imageFile: $imageFile, videoUrl: $videoUrl, inputAudio: $inputAudio, error: $error, agentUpdate: $agentUpdate, steer: $steer, activityLabel: $activityLabel, activityLabelType: $activityLabelType, activityEndIndex: $activityEndIndex, pending: $pending, status: $status, content: $content, agentId: $agentId, groupId: $groupId, stepIndex: $stepIndex)';
}


}

/// @nodoc
abstract mixin class _$ContentPartCopyWith<$Res> implements $ContentPartCopyWith<$Res> {
  factory _$ContentPartCopyWith(_ContentPart value, $Res Function(_ContentPart) _then) = __$ContentPartCopyWithImpl;
@override @useResult
$Res call({
 String type,@FlexibleTextConverter() String? text, String? think,@JsonKey(name: 'tool_call_ids') List<String>? toolCallIds,@JsonKey(name: 'tool_call') ToolCall? toolCall,@JsonKey(name: 'image_url') Object? imageUrl,@JsonKey(name: 'image_file') Map<String, Object?>? imageFile,@JsonKey(name: 'video_url') Object? videoUrl,@JsonKey(name: 'input_audio') Map<String, Object?>? inputAudio, String? error,@JsonKey(name: 'agent_update') Map<String, Object?>? agentUpdate, Object? steer,@JsonKey(name: 'activity_label') String? activityLabel,@JsonKey(name: 'activity_label_type') String? activityLabelType,@JsonKey(name: 'activity_end_index') int? activityEndIndex, bool? pending, String? status, Object? content, String? agentId, int? groupId, int? stepIndex
});


@override $ToolCallCopyWith<$Res>? get toolCall;

}
/// @nodoc
class __$ContentPartCopyWithImpl<$Res>
    implements _$ContentPartCopyWith<$Res> {
  __$ContentPartCopyWithImpl(this._self, this._then);

  final _ContentPart _self;
  final $Res Function(_ContentPart) _then;

/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = freezed,Object? think = freezed,Object? toolCallIds = freezed,Object? toolCall = freezed,Object? imageUrl = freezed,Object? imageFile = freezed,Object? videoUrl = freezed,Object? inputAudio = freezed,Object? error = freezed,Object? agentUpdate = freezed,Object? steer = freezed,Object? activityLabel = freezed,Object? activityLabelType = freezed,Object? activityEndIndex = freezed,Object? pending = freezed,Object? status = freezed,Object? content = freezed,Object? agentId = freezed,Object? groupId = freezed,Object? stepIndex = freezed,}) {
  return _then(_ContentPart(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,think: freezed == think ? _self.think : think // ignore: cast_nullable_to_non_nullable
as String?,toolCallIds: freezed == toolCallIds ? _self._toolCallIds : toolCallIds // ignore: cast_nullable_to_non_nullable
as List<String>?,toolCall: freezed == toolCall ? _self.toolCall : toolCall // ignore: cast_nullable_to_non_nullable
as ToolCall?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl ,imageFile: freezed == imageFile ? _self._imageFile : imageFile // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl ,inputAudio: freezed == inputAudio ? _self._inputAudio : inputAudio // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,agentUpdate: freezed == agentUpdate ? _self._agentUpdate : agentUpdate // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,steer: freezed == steer ? _self.steer : steer ,activityLabel: freezed == activityLabel ? _self.activityLabel : activityLabel // ignore: cast_nullable_to_non_nullable
as String?,activityLabelType: freezed == activityLabelType ? _self.activityLabelType : activityLabelType // ignore: cast_nullable_to_non_nullable
as String?,activityEndIndex: freezed == activityEndIndex ? _self.activityEndIndex : activityEndIndex // ignore: cast_nullable_to_non_nullable
as int?,pending: freezed == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content ,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,stepIndex: freezed == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ContentPart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallCopyWith<$Res>? get toolCall {
    if (_self.toolCall == null) {
    return null;
  }

  return $ToolCallCopyWith<$Res>(_self.toolCall!, (value) {
    return _then(_self.copyWith(toolCall: value));
  });
}
}


/// @nodoc
mixin _$ToolCall {

 String? get id; String? get name; String? get type; Object? get args; String? get output; double? get progress;
/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallCopyWith<ToolCall> get copyWith => _$ToolCallCopyWithImpl<ToolCall>(this as ToolCall, _$identity);

  /// Serializes this ToolCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.args, args)&&(identical(other.output, output) || other.output == output)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(args),output,progress);

@override
String toString() {
  return 'ToolCall(id: $id, name: $name, type: $type, args: $args, output: $output, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $ToolCallCopyWith<$Res>  {
  factory $ToolCallCopyWith(ToolCall value, $Res Function(ToolCall) _then) = _$ToolCallCopyWithImpl;
@useResult
$Res call({
 String? id, String? name, String? type, Object? args, String? output, double? progress
});




}
/// @nodoc
class _$ToolCallCopyWithImpl<$Res>
    implements $ToolCallCopyWith<$Res> {
  _$ToolCallCopyWithImpl(this._self, this._then);

  final ToolCall _self;
  final $Res Function(ToolCall) _then;

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? type = freezed,Object? args = freezed,Object? output = freezed,Object? progress = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,args: freezed == args ? _self.args : args ,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolCall].
extension ToolCallPatterns on ToolCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolCall value)  $default,){
final _that = this;
switch (_that) {
case _ToolCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolCall value)?  $default,){
final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? name,  String? type,  Object? args,  String? output,  double? progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.args,_that.output,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? name,  String? type,  Object? args,  String? output,  double? progress)  $default,) {final _that = this;
switch (_that) {
case _ToolCall():
return $default(_that.id,_that.name,_that.type,_that.args,_that.output,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? name,  String? type,  Object? args,  String? output,  double? progress)?  $default,) {final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.args,_that.output,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToolCall implements ToolCall {
  const _ToolCall({this.id, this.name, this.type, this.args, this.output, this.progress});
  factory _ToolCall.fromJson(Map<String, dynamic> json) => _$ToolCallFromJson(json);

@override final  String? id;
@override final  String? name;
@override final  String? type;
@override final  Object? args;
@override final  String? output;
@override final  double? progress;

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolCallCopyWith<_ToolCall> get copyWith => __$ToolCallCopyWithImpl<_ToolCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToolCallToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolCall&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.args, args)&&(identical(other.output, output) || other.output == output)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,const DeepCollectionEquality().hash(args),output,progress);

@override
String toString() {
  return 'ToolCall(id: $id, name: $name, type: $type, args: $args, output: $output, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$ToolCallCopyWith<$Res> implements $ToolCallCopyWith<$Res> {
  factory _$ToolCallCopyWith(_ToolCall value, $Res Function(_ToolCall) _then) = __$ToolCallCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? name, String? type, Object? args, String? output, double? progress
});




}
/// @nodoc
class __$ToolCallCopyWithImpl<$Res>
    implements _$ToolCallCopyWith<$Res> {
  __$ToolCallCopyWithImpl(this._self, this._then);

  final _ToolCall _self;
  final $Res Function(_ToolCall) _then;

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? type = freezed,Object? args = freezed,Object? output = freezed,Object? progress = freezed,}) {
  return _then(_ToolCall(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,args: freezed == args ? _self.args : args ,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
