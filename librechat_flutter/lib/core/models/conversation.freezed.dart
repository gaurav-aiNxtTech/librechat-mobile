// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

 String? get conversationId; String? get title; String? get endpoint; String? get endpointType; String? get model;@JsonKey(name: 'agent_id') String? get agentId; String? get spec; String? get iconURL; List<String>? get tags; bool get isArchived; bool? get pinned; String? get chatProjectId; bool? get isTemporary;// Model parameters.
 double? get temperature;@JsonKey(name: 'top_p') double? get topP; int? get topK;@JsonKey(name: 'frequency_penalty') double? get frequencyPenalty;@JsonKey(name: 'presence_penalty') double? get presencePenalty; int? get maxOutputTokens; int? get maxContextTokens; int? get maxTokens; String? get system; String? get promptPrefix; String? get modelLabel;@JsonKey(name: 'reasoning_effort') String? get reasoningEffort;@JsonKey(name: 'reasoning_mode') String? get reasoningMode;@JsonKey(name: 'reasoning_context') String? get reasoningContext; String? get effort; String? get thinkingLevel; String? get thinkingDisplay; List<String>? get stop;@JsonKey(name: 'web_search') bool? get webSearch;@JsonKey(name: 'url_context') bool? get urlContext; String? get promptCacheTtl;@UtcDateTimeConverter() DateTime? get createdAt;@UtcDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.endpointType, endpointType) || other.endpointType == endpointType)&&(identical(other.model, model) || other.model == model)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.spec, spec) || other.spec == spec)&&(identical(other.iconURL, iconURL) || other.iconURL == iconURL)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.chatProjectId, chatProjectId) || other.chatProjectId == chatProjectId)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.topP, topP) || other.topP == topP)&&(identical(other.topK, topK) || other.topK == topK)&&(identical(other.frequencyPenalty, frequencyPenalty) || other.frequencyPenalty == frequencyPenalty)&&(identical(other.presencePenalty, presencePenalty) || other.presencePenalty == presencePenalty)&&(identical(other.maxOutputTokens, maxOutputTokens) || other.maxOutputTokens == maxOutputTokens)&&(identical(other.maxContextTokens, maxContextTokens) || other.maxContextTokens == maxContextTokens)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.system, system) || other.system == system)&&(identical(other.promptPrefix, promptPrefix) || other.promptPrefix == promptPrefix)&&(identical(other.modelLabel, modelLabel) || other.modelLabel == modelLabel)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.reasoningMode, reasoningMode) || other.reasoningMode == reasoningMode)&&(identical(other.reasoningContext, reasoningContext) || other.reasoningContext == reasoningContext)&&(identical(other.effort, effort) || other.effort == effort)&&(identical(other.thinkingLevel, thinkingLevel) || other.thinkingLevel == thinkingLevel)&&(identical(other.thinkingDisplay, thinkingDisplay) || other.thinkingDisplay == thinkingDisplay)&&const DeepCollectionEquality().equals(other.stop, stop)&&(identical(other.webSearch, webSearch) || other.webSearch == webSearch)&&(identical(other.urlContext, urlContext) || other.urlContext == urlContext)&&(identical(other.promptCacheTtl, promptCacheTtl) || other.promptCacheTtl == promptCacheTtl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,conversationId,title,endpoint,endpointType,model,agentId,spec,iconURL,const DeepCollectionEquality().hash(tags),isArchived,pinned,chatProjectId,isTemporary,temperature,topP,topK,frequencyPenalty,presencePenalty,maxOutputTokens,maxContextTokens,maxTokens,system,promptPrefix,modelLabel,reasoningEffort,reasoningMode,reasoningContext,effort,thinkingLevel,thinkingDisplay,const DeepCollectionEquality().hash(stop),webSearch,urlContext,promptCacheTtl,createdAt,updatedAt]);

@override
String toString() {
  return 'Conversation(conversationId: $conversationId, title: $title, endpoint: $endpoint, endpointType: $endpointType, model: $model, agentId: $agentId, spec: $spec, iconURL: $iconURL, tags: $tags, isArchived: $isArchived, pinned: $pinned, chatProjectId: $chatProjectId, isTemporary: $isTemporary, temperature: $temperature, topP: $topP, topK: $topK, frequencyPenalty: $frequencyPenalty, presencePenalty: $presencePenalty, maxOutputTokens: $maxOutputTokens, maxContextTokens: $maxContextTokens, maxTokens: $maxTokens, system: $system, promptPrefix: $promptPrefix, modelLabel: $modelLabel, reasoningEffort: $reasoningEffort, reasoningMode: $reasoningMode, reasoningContext: $reasoningContext, effort: $effort, thinkingLevel: $thinkingLevel, thinkingDisplay: $thinkingDisplay, stop: $stop, webSearch: $webSearch, urlContext: $urlContext, promptCacheTtl: $promptCacheTtl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String? conversationId, String? title, String? endpoint, String? endpointType, String? model,@JsonKey(name: 'agent_id') String? agentId, String? spec, String? iconURL, List<String>? tags, bool isArchived, bool? pinned, String? chatProjectId, bool? isTemporary, double? temperature,@JsonKey(name: 'top_p') double? topP, int? topK,@JsonKey(name: 'frequency_penalty') double? frequencyPenalty,@JsonKey(name: 'presence_penalty') double? presencePenalty, int? maxOutputTokens, int? maxContextTokens, int? maxTokens, String? system, String? promptPrefix, String? modelLabel,@JsonKey(name: 'reasoning_effort') String? reasoningEffort,@JsonKey(name: 'reasoning_mode') String? reasoningMode,@JsonKey(name: 'reasoning_context') String? reasoningContext, String? effort, String? thinkingLevel, String? thinkingDisplay, List<String>? stop,@JsonKey(name: 'web_search') bool? webSearch,@JsonKey(name: 'url_context') bool? urlContext, String? promptCacheTtl,@UtcDateTimeConverter() DateTime? createdAt,@UtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = freezed,Object? title = freezed,Object? endpoint = freezed,Object? endpointType = freezed,Object? model = freezed,Object? agentId = freezed,Object? spec = freezed,Object? iconURL = freezed,Object? tags = freezed,Object? isArchived = null,Object? pinned = freezed,Object? chatProjectId = freezed,Object? isTemporary = freezed,Object? temperature = freezed,Object? topP = freezed,Object? topK = freezed,Object? frequencyPenalty = freezed,Object? presencePenalty = freezed,Object? maxOutputTokens = freezed,Object? maxContextTokens = freezed,Object? maxTokens = freezed,Object? system = freezed,Object? promptPrefix = freezed,Object? modelLabel = freezed,Object? reasoningEffort = freezed,Object? reasoningMode = freezed,Object? reasoningContext = freezed,Object? effort = freezed,Object? thinkingLevel = freezed,Object? thinkingDisplay = freezed,Object? stop = freezed,Object? webSearch = freezed,Object? urlContext = freezed,Object? promptCacheTtl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,endpointType: freezed == endpointType ? _self.endpointType : endpointType // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,spec: freezed == spec ? _self.spec : spec // ignore: cast_nullable_to_non_nullable
as String?,iconURL: freezed == iconURL ? _self.iconURL : iconURL // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,pinned: freezed == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool?,chatProjectId: freezed == chatProjectId ? _self.chatProjectId : chatProjectId // ignore: cast_nullable_to_non_nullable
as String?,isTemporary: freezed == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,topP: freezed == topP ? _self.topP : topP // ignore: cast_nullable_to_non_nullable
as double?,topK: freezed == topK ? _self.topK : topK // ignore: cast_nullable_to_non_nullable
as int?,frequencyPenalty: freezed == frequencyPenalty ? _self.frequencyPenalty : frequencyPenalty // ignore: cast_nullable_to_non_nullable
as double?,presencePenalty: freezed == presencePenalty ? _self.presencePenalty : presencePenalty // ignore: cast_nullable_to_non_nullable
as double?,maxOutputTokens: freezed == maxOutputTokens ? _self.maxOutputTokens : maxOutputTokens // ignore: cast_nullable_to_non_nullable
as int?,maxContextTokens: freezed == maxContextTokens ? _self.maxContextTokens : maxContextTokens // ignore: cast_nullable_to_non_nullable
as int?,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,system: freezed == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String?,promptPrefix: freezed == promptPrefix ? _self.promptPrefix : promptPrefix // ignore: cast_nullable_to_non_nullable
as String?,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,reasoningMode: freezed == reasoningMode ? _self.reasoningMode : reasoningMode // ignore: cast_nullable_to_non_nullable
as String?,reasoningContext: freezed == reasoningContext ? _self.reasoningContext : reasoningContext // ignore: cast_nullable_to_non_nullable
as String?,effort: freezed == effort ? _self.effort : effort // ignore: cast_nullable_to_non_nullable
as String?,thinkingLevel: freezed == thinkingLevel ? _self.thinkingLevel : thinkingLevel // ignore: cast_nullable_to_non_nullable
as String?,thinkingDisplay: freezed == thinkingDisplay ? _self.thinkingDisplay : thinkingDisplay // ignore: cast_nullable_to_non_nullable
as String?,stop: freezed == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as List<String>?,webSearch: freezed == webSearch ? _self.webSearch : webSearch // ignore: cast_nullable_to_non_nullable
as bool?,urlContext: freezed == urlContext ? _self.urlContext : urlContext // ignore: cast_nullable_to_non_nullable
as bool?,promptCacheTtl: freezed == promptCacheTtl ? _self.promptCacheTtl : promptCacheTtl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? conversationId,  String? title,  String? endpoint,  String? endpointType,  String? model, @JsonKey(name: 'agent_id')  String? agentId,  String? spec,  String? iconURL,  List<String>? tags,  bool isArchived,  bool? pinned,  String? chatProjectId,  bool? isTemporary,  double? temperature, @JsonKey(name: 'top_p')  double? topP,  int? topK, @JsonKey(name: 'frequency_penalty')  double? frequencyPenalty, @JsonKey(name: 'presence_penalty')  double? presencePenalty,  int? maxOutputTokens,  int? maxContextTokens,  int? maxTokens,  String? system,  String? promptPrefix,  String? modelLabel, @JsonKey(name: 'reasoning_effort')  String? reasoningEffort, @JsonKey(name: 'reasoning_mode')  String? reasoningMode, @JsonKey(name: 'reasoning_context')  String? reasoningContext,  String? effort,  String? thinkingLevel,  String? thinkingDisplay,  List<String>? stop, @JsonKey(name: 'web_search')  bool? webSearch, @JsonKey(name: 'url_context')  bool? urlContext,  String? promptCacheTtl, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.conversationId,_that.title,_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.iconURL,_that.tags,_that.isArchived,_that.pinned,_that.chatProjectId,_that.isTemporary,_that.temperature,_that.topP,_that.topK,_that.frequencyPenalty,_that.presencePenalty,_that.maxOutputTokens,_that.maxContextTokens,_that.maxTokens,_that.system,_that.promptPrefix,_that.modelLabel,_that.reasoningEffort,_that.reasoningMode,_that.reasoningContext,_that.effort,_that.thinkingLevel,_that.thinkingDisplay,_that.stop,_that.webSearch,_that.urlContext,_that.promptCacheTtl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? conversationId,  String? title,  String? endpoint,  String? endpointType,  String? model, @JsonKey(name: 'agent_id')  String? agentId,  String? spec,  String? iconURL,  List<String>? tags,  bool isArchived,  bool? pinned,  String? chatProjectId,  bool? isTemporary,  double? temperature, @JsonKey(name: 'top_p')  double? topP,  int? topK, @JsonKey(name: 'frequency_penalty')  double? frequencyPenalty, @JsonKey(name: 'presence_penalty')  double? presencePenalty,  int? maxOutputTokens,  int? maxContextTokens,  int? maxTokens,  String? system,  String? promptPrefix,  String? modelLabel, @JsonKey(name: 'reasoning_effort')  String? reasoningEffort, @JsonKey(name: 'reasoning_mode')  String? reasoningMode, @JsonKey(name: 'reasoning_context')  String? reasoningContext,  String? effort,  String? thinkingLevel,  String? thinkingDisplay,  List<String>? stop, @JsonKey(name: 'web_search')  bool? webSearch, @JsonKey(name: 'url_context')  bool? urlContext,  String? promptCacheTtl, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.conversationId,_that.title,_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.iconURL,_that.tags,_that.isArchived,_that.pinned,_that.chatProjectId,_that.isTemporary,_that.temperature,_that.topP,_that.topK,_that.frequencyPenalty,_that.presencePenalty,_that.maxOutputTokens,_that.maxContextTokens,_that.maxTokens,_that.system,_that.promptPrefix,_that.modelLabel,_that.reasoningEffort,_that.reasoningMode,_that.reasoningContext,_that.effort,_that.thinkingLevel,_that.thinkingDisplay,_that.stop,_that.webSearch,_that.urlContext,_that.promptCacheTtl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? conversationId,  String? title,  String? endpoint,  String? endpointType,  String? model, @JsonKey(name: 'agent_id')  String? agentId,  String? spec,  String? iconURL,  List<String>? tags,  bool isArchived,  bool? pinned,  String? chatProjectId,  bool? isTemporary,  double? temperature, @JsonKey(name: 'top_p')  double? topP,  int? topK, @JsonKey(name: 'frequency_penalty')  double? frequencyPenalty, @JsonKey(name: 'presence_penalty')  double? presencePenalty,  int? maxOutputTokens,  int? maxContextTokens,  int? maxTokens,  String? system,  String? promptPrefix,  String? modelLabel, @JsonKey(name: 'reasoning_effort')  String? reasoningEffort, @JsonKey(name: 'reasoning_mode')  String? reasoningMode, @JsonKey(name: 'reasoning_context')  String? reasoningContext,  String? effort,  String? thinkingLevel,  String? thinkingDisplay,  List<String>? stop, @JsonKey(name: 'web_search')  bool? webSearch, @JsonKey(name: 'url_context')  bool? urlContext,  String? promptCacheTtl, @UtcDateTimeConverter()  DateTime? createdAt, @UtcDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.conversationId,_that.title,_that.endpoint,_that.endpointType,_that.model,_that.agentId,_that.spec,_that.iconURL,_that.tags,_that.isArchived,_that.pinned,_that.chatProjectId,_that.isTemporary,_that.temperature,_that.topP,_that.topK,_that.frequencyPenalty,_that.presencePenalty,_that.maxOutputTokens,_that.maxContextTokens,_that.maxTokens,_that.system,_that.promptPrefix,_that.modelLabel,_that.reasoningEffort,_that.reasoningMode,_that.reasoningContext,_that.effort,_that.thinkingLevel,_that.thinkingDisplay,_that.stop,_that.webSearch,_that.urlContext,_that.promptCacheTtl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({this.conversationId, this.title, this.endpoint, this.endpointType, this.model, @JsonKey(name: 'agent_id') this.agentId, this.spec, this.iconURL, final  List<String>? tags, this.isArchived = false, this.pinned, this.chatProjectId, this.isTemporary, this.temperature, @JsonKey(name: 'top_p') this.topP, this.topK, @JsonKey(name: 'frequency_penalty') this.frequencyPenalty, @JsonKey(name: 'presence_penalty') this.presencePenalty, this.maxOutputTokens, this.maxContextTokens, this.maxTokens, this.system, this.promptPrefix, this.modelLabel, @JsonKey(name: 'reasoning_effort') this.reasoningEffort, @JsonKey(name: 'reasoning_mode') this.reasoningMode, @JsonKey(name: 'reasoning_context') this.reasoningContext, this.effort, this.thinkingLevel, this.thinkingDisplay, final  List<String>? stop, @JsonKey(name: 'web_search') this.webSearch, @JsonKey(name: 'url_context') this.urlContext, this.promptCacheTtl, @UtcDateTimeConverter() this.createdAt, @UtcDateTimeConverter() this.updatedAt}): _tags = tags,_stop = stop;
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String? conversationId;
@override final  String? title;
@override final  String? endpoint;
@override final  String? endpointType;
@override final  String? model;
@override@JsonKey(name: 'agent_id') final  String? agentId;
@override final  String? spec;
@override final  String? iconURL;
 final  List<String>? _tags;
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool isArchived;
@override final  bool? pinned;
@override final  String? chatProjectId;
@override final  bool? isTemporary;
// Model parameters.
@override final  double? temperature;
@override@JsonKey(name: 'top_p') final  double? topP;
@override final  int? topK;
@override@JsonKey(name: 'frequency_penalty') final  double? frequencyPenalty;
@override@JsonKey(name: 'presence_penalty') final  double? presencePenalty;
@override final  int? maxOutputTokens;
@override final  int? maxContextTokens;
@override final  int? maxTokens;
@override final  String? system;
@override final  String? promptPrefix;
@override final  String? modelLabel;
@override@JsonKey(name: 'reasoning_effort') final  String? reasoningEffort;
@override@JsonKey(name: 'reasoning_mode') final  String? reasoningMode;
@override@JsonKey(name: 'reasoning_context') final  String? reasoningContext;
@override final  String? effort;
@override final  String? thinkingLevel;
@override final  String? thinkingDisplay;
 final  List<String>? _stop;
@override List<String>? get stop {
  final value = _stop;
  if (value == null) return null;
  if (_stop is EqualUnmodifiableListView) return _stop;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'web_search') final  bool? webSearch;
@override@JsonKey(name: 'url_context') final  bool? urlContext;
@override final  String? promptCacheTtl;
@override@UtcDateTimeConverter() final  DateTime? createdAt;
@override@UtcDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.endpointType, endpointType) || other.endpointType == endpointType)&&(identical(other.model, model) || other.model == model)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.spec, spec) || other.spec == spec)&&(identical(other.iconURL, iconURL) || other.iconURL == iconURL)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.chatProjectId, chatProjectId) || other.chatProjectId == chatProjectId)&&(identical(other.isTemporary, isTemporary) || other.isTemporary == isTemporary)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.topP, topP) || other.topP == topP)&&(identical(other.topK, topK) || other.topK == topK)&&(identical(other.frequencyPenalty, frequencyPenalty) || other.frequencyPenalty == frequencyPenalty)&&(identical(other.presencePenalty, presencePenalty) || other.presencePenalty == presencePenalty)&&(identical(other.maxOutputTokens, maxOutputTokens) || other.maxOutputTokens == maxOutputTokens)&&(identical(other.maxContextTokens, maxContextTokens) || other.maxContextTokens == maxContextTokens)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.system, system) || other.system == system)&&(identical(other.promptPrefix, promptPrefix) || other.promptPrefix == promptPrefix)&&(identical(other.modelLabel, modelLabel) || other.modelLabel == modelLabel)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort)&&(identical(other.reasoningMode, reasoningMode) || other.reasoningMode == reasoningMode)&&(identical(other.reasoningContext, reasoningContext) || other.reasoningContext == reasoningContext)&&(identical(other.effort, effort) || other.effort == effort)&&(identical(other.thinkingLevel, thinkingLevel) || other.thinkingLevel == thinkingLevel)&&(identical(other.thinkingDisplay, thinkingDisplay) || other.thinkingDisplay == thinkingDisplay)&&const DeepCollectionEquality().equals(other._stop, _stop)&&(identical(other.webSearch, webSearch) || other.webSearch == webSearch)&&(identical(other.urlContext, urlContext) || other.urlContext == urlContext)&&(identical(other.promptCacheTtl, promptCacheTtl) || other.promptCacheTtl == promptCacheTtl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,conversationId,title,endpoint,endpointType,model,agentId,spec,iconURL,const DeepCollectionEquality().hash(_tags),isArchived,pinned,chatProjectId,isTemporary,temperature,topP,topK,frequencyPenalty,presencePenalty,maxOutputTokens,maxContextTokens,maxTokens,system,promptPrefix,modelLabel,reasoningEffort,reasoningMode,reasoningContext,effort,thinkingLevel,thinkingDisplay,const DeepCollectionEquality().hash(_stop),webSearch,urlContext,promptCacheTtl,createdAt,updatedAt]);

@override
String toString() {
  return 'Conversation(conversationId: $conversationId, title: $title, endpoint: $endpoint, endpointType: $endpointType, model: $model, agentId: $agentId, spec: $spec, iconURL: $iconURL, tags: $tags, isArchived: $isArchived, pinned: $pinned, chatProjectId: $chatProjectId, isTemporary: $isTemporary, temperature: $temperature, topP: $topP, topK: $topK, frequencyPenalty: $frequencyPenalty, presencePenalty: $presencePenalty, maxOutputTokens: $maxOutputTokens, maxContextTokens: $maxContextTokens, maxTokens: $maxTokens, system: $system, promptPrefix: $promptPrefix, modelLabel: $modelLabel, reasoningEffort: $reasoningEffort, reasoningMode: $reasoningMode, reasoningContext: $reasoningContext, effort: $effort, thinkingLevel: $thinkingLevel, thinkingDisplay: $thinkingDisplay, stop: $stop, webSearch: $webSearch, urlContext: $urlContext, promptCacheTtl: $promptCacheTtl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String? conversationId, String? title, String? endpoint, String? endpointType, String? model,@JsonKey(name: 'agent_id') String? agentId, String? spec, String? iconURL, List<String>? tags, bool isArchived, bool? pinned, String? chatProjectId, bool? isTemporary, double? temperature,@JsonKey(name: 'top_p') double? topP, int? topK,@JsonKey(name: 'frequency_penalty') double? frequencyPenalty,@JsonKey(name: 'presence_penalty') double? presencePenalty, int? maxOutputTokens, int? maxContextTokens, int? maxTokens, String? system, String? promptPrefix, String? modelLabel,@JsonKey(name: 'reasoning_effort') String? reasoningEffort,@JsonKey(name: 'reasoning_mode') String? reasoningMode,@JsonKey(name: 'reasoning_context') String? reasoningContext, String? effort, String? thinkingLevel, String? thinkingDisplay, List<String>? stop,@JsonKey(name: 'web_search') bool? webSearch,@JsonKey(name: 'url_context') bool? urlContext, String? promptCacheTtl,@UtcDateTimeConverter() DateTime? createdAt,@UtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = freezed,Object? title = freezed,Object? endpoint = freezed,Object? endpointType = freezed,Object? model = freezed,Object? agentId = freezed,Object? spec = freezed,Object? iconURL = freezed,Object? tags = freezed,Object? isArchived = null,Object? pinned = freezed,Object? chatProjectId = freezed,Object? isTemporary = freezed,Object? temperature = freezed,Object? topP = freezed,Object? topK = freezed,Object? frequencyPenalty = freezed,Object? presencePenalty = freezed,Object? maxOutputTokens = freezed,Object? maxContextTokens = freezed,Object? maxTokens = freezed,Object? system = freezed,Object? promptPrefix = freezed,Object? modelLabel = freezed,Object? reasoningEffort = freezed,Object? reasoningMode = freezed,Object? reasoningContext = freezed,Object? effort = freezed,Object? thinkingLevel = freezed,Object? thinkingDisplay = freezed,Object? stop = freezed,Object? webSearch = freezed,Object? urlContext = freezed,Object? promptCacheTtl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Conversation(
conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,endpointType: freezed == endpointType ? _self.endpointType : endpointType // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,spec: freezed == spec ? _self.spec : spec // ignore: cast_nullable_to_non_nullable
as String?,iconURL: freezed == iconURL ? _self.iconURL : iconURL // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,pinned: freezed == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool?,chatProjectId: freezed == chatProjectId ? _self.chatProjectId : chatProjectId // ignore: cast_nullable_to_non_nullable
as String?,isTemporary: freezed == isTemporary ? _self.isTemporary : isTemporary // ignore: cast_nullable_to_non_nullable
as bool?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,topP: freezed == topP ? _self.topP : topP // ignore: cast_nullable_to_non_nullable
as double?,topK: freezed == topK ? _self.topK : topK // ignore: cast_nullable_to_non_nullable
as int?,frequencyPenalty: freezed == frequencyPenalty ? _self.frequencyPenalty : frequencyPenalty // ignore: cast_nullable_to_non_nullable
as double?,presencePenalty: freezed == presencePenalty ? _self.presencePenalty : presencePenalty // ignore: cast_nullable_to_non_nullable
as double?,maxOutputTokens: freezed == maxOutputTokens ? _self.maxOutputTokens : maxOutputTokens // ignore: cast_nullable_to_non_nullable
as int?,maxContextTokens: freezed == maxContextTokens ? _self.maxContextTokens : maxContextTokens // ignore: cast_nullable_to_non_nullable
as int?,maxTokens: freezed == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int?,system: freezed == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String?,promptPrefix: freezed == promptPrefix ? _self.promptPrefix : promptPrefix // ignore: cast_nullable_to_non_nullable
as String?,modelLabel: freezed == modelLabel ? _self.modelLabel : modelLabel // ignore: cast_nullable_to_non_nullable
as String?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,reasoningMode: freezed == reasoningMode ? _self.reasoningMode : reasoningMode // ignore: cast_nullable_to_non_nullable
as String?,reasoningContext: freezed == reasoningContext ? _self.reasoningContext : reasoningContext // ignore: cast_nullable_to_non_nullable
as String?,effort: freezed == effort ? _self.effort : effort // ignore: cast_nullable_to_non_nullable
as String?,thinkingLevel: freezed == thinkingLevel ? _self.thinkingLevel : thinkingLevel // ignore: cast_nullable_to_non_nullable
as String?,thinkingDisplay: freezed == thinkingDisplay ? _self.thinkingDisplay : thinkingDisplay // ignore: cast_nullable_to_non_nullable
as String?,stop: freezed == stop ? _self._stop : stop // ignore: cast_nullable_to_non_nullable
as List<String>?,webSearch: freezed == webSearch ? _self.webSearch : webSearch // ignore: cast_nullable_to_non_nullable
as bool?,urlContext: freezed == urlContext ? _self.urlContext : urlContext // ignore: cast_nullable_to_non_nullable
as bool?,promptCacheTtl: freezed == promptCacheTtl ? _self.promptCacheTtl : promptCacheTtl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
