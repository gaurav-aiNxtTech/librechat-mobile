// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings implements DiagnosticableTreeMixin {

 ThemeMode get themeMode; int get accentSeed; bool get dynamicColor; ChatFontSize get chatFontSize; MessageLayout get messageLayout; bool get autoScroll; bool get dismissKeyboardOnSend; DuringRunAction get duringRunAction; ArtifactViewer get artifactViewer; Set<InlineArtifact> get inlineArtifacts; bool get slashCommands; bool get sttEnabled; VoiceEngine? get sttEngine; VoiceEngine? get ttsEngine; String? get ttsVoice; bool get autoReadAloud; ForkMode get forkMode; bool get forkSplitAtTarget; String? get lastEndpoint; String? get lastModel; String? get lastSpec; List<String> get dismissedBannerIds; String? get dismissedVersionBanner; bool get ssoWarningAcknowledged;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppSettings'))
    ..add(DiagnosticsProperty('themeMode', themeMode))..add(DiagnosticsProperty('accentSeed', accentSeed))..add(DiagnosticsProperty('dynamicColor', dynamicColor))..add(DiagnosticsProperty('chatFontSize', chatFontSize))..add(DiagnosticsProperty('messageLayout', messageLayout))..add(DiagnosticsProperty('autoScroll', autoScroll))..add(DiagnosticsProperty('dismissKeyboardOnSend', dismissKeyboardOnSend))..add(DiagnosticsProperty('duringRunAction', duringRunAction))..add(DiagnosticsProperty('artifactViewer', artifactViewer))..add(DiagnosticsProperty('inlineArtifacts', inlineArtifacts))..add(DiagnosticsProperty('slashCommands', slashCommands))..add(DiagnosticsProperty('sttEnabled', sttEnabled))..add(DiagnosticsProperty('sttEngine', sttEngine))..add(DiagnosticsProperty('ttsEngine', ttsEngine))..add(DiagnosticsProperty('ttsVoice', ttsVoice))..add(DiagnosticsProperty('autoReadAloud', autoReadAloud))..add(DiagnosticsProperty('forkMode', forkMode))..add(DiagnosticsProperty('forkSplitAtTarget', forkSplitAtTarget))..add(DiagnosticsProperty('lastEndpoint', lastEndpoint))..add(DiagnosticsProperty('lastModel', lastModel))..add(DiagnosticsProperty('lastSpec', lastSpec))..add(DiagnosticsProperty('dismissedBannerIds', dismissedBannerIds))..add(DiagnosticsProperty('dismissedVersionBanner', dismissedVersionBanner))..add(DiagnosticsProperty('ssoWarningAcknowledged', ssoWarningAcknowledged));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accentSeed, accentSeed) || other.accentSeed == accentSeed)&&(identical(other.dynamicColor, dynamicColor) || other.dynamicColor == dynamicColor)&&(identical(other.chatFontSize, chatFontSize) || other.chatFontSize == chatFontSize)&&(identical(other.messageLayout, messageLayout) || other.messageLayout == messageLayout)&&(identical(other.autoScroll, autoScroll) || other.autoScroll == autoScroll)&&(identical(other.dismissKeyboardOnSend, dismissKeyboardOnSend) || other.dismissKeyboardOnSend == dismissKeyboardOnSend)&&(identical(other.duringRunAction, duringRunAction) || other.duringRunAction == duringRunAction)&&(identical(other.artifactViewer, artifactViewer) || other.artifactViewer == artifactViewer)&&const DeepCollectionEquality().equals(other.inlineArtifacts, inlineArtifacts)&&(identical(other.slashCommands, slashCommands) || other.slashCommands == slashCommands)&&(identical(other.sttEnabled, sttEnabled) || other.sttEnabled == sttEnabled)&&(identical(other.sttEngine, sttEngine) || other.sttEngine == sttEngine)&&(identical(other.ttsEngine, ttsEngine) || other.ttsEngine == ttsEngine)&&(identical(other.ttsVoice, ttsVoice) || other.ttsVoice == ttsVoice)&&(identical(other.autoReadAloud, autoReadAloud) || other.autoReadAloud == autoReadAloud)&&(identical(other.forkMode, forkMode) || other.forkMode == forkMode)&&(identical(other.forkSplitAtTarget, forkSplitAtTarget) || other.forkSplitAtTarget == forkSplitAtTarget)&&(identical(other.lastEndpoint, lastEndpoint) || other.lastEndpoint == lastEndpoint)&&(identical(other.lastModel, lastModel) || other.lastModel == lastModel)&&(identical(other.lastSpec, lastSpec) || other.lastSpec == lastSpec)&&const DeepCollectionEquality().equals(other.dismissedBannerIds, dismissedBannerIds)&&(identical(other.dismissedVersionBanner, dismissedVersionBanner) || other.dismissedVersionBanner == dismissedVersionBanner)&&(identical(other.ssoWarningAcknowledged, ssoWarningAcknowledged) || other.ssoWarningAcknowledged == ssoWarningAcknowledged));
}


@override
int get hashCode => Object.hashAll([runtimeType,themeMode,accentSeed,dynamicColor,chatFontSize,messageLayout,autoScroll,dismissKeyboardOnSend,duringRunAction,artifactViewer,const DeepCollectionEquality().hash(inlineArtifacts),slashCommands,sttEnabled,sttEngine,ttsEngine,ttsVoice,autoReadAloud,forkMode,forkSplitAtTarget,lastEndpoint,lastModel,lastSpec,const DeepCollectionEquality().hash(dismissedBannerIds),dismissedVersionBanner,ssoWarningAcknowledged]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppSettings(themeMode: $themeMode, accentSeed: $accentSeed, dynamicColor: $dynamicColor, chatFontSize: $chatFontSize, messageLayout: $messageLayout, autoScroll: $autoScroll, dismissKeyboardOnSend: $dismissKeyboardOnSend, duringRunAction: $duringRunAction, artifactViewer: $artifactViewer, inlineArtifacts: $inlineArtifacts, slashCommands: $slashCommands, sttEnabled: $sttEnabled, sttEngine: $sttEngine, ttsEngine: $ttsEngine, ttsVoice: $ttsVoice, autoReadAloud: $autoReadAloud, forkMode: $forkMode, forkSplitAtTarget: $forkSplitAtTarget, lastEndpoint: $lastEndpoint, lastModel: $lastModel, lastSpec: $lastSpec, dismissedBannerIds: $dismissedBannerIds, dismissedVersionBanner: $dismissedVersionBanner, ssoWarningAcknowledged: $ssoWarningAcknowledged)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode, int accentSeed, bool dynamicColor, ChatFontSize chatFontSize, MessageLayout messageLayout, bool autoScroll, bool dismissKeyboardOnSend, DuringRunAction duringRunAction, ArtifactViewer artifactViewer, Set<InlineArtifact> inlineArtifacts, bool slashCommands, bool sttEnabled, VoiceEngine? sttEngine, VoiceEngine? ttsEngine, String? ttsVoice, bool autoReadAloud, ForkMode forkMode, bool forkSplitAtTarget, String? lastEndpoint, String? lastModel, String? lastSpec, List<String> dismissedBannerIds, String? dismissedVersionBanner, bool ssoWarningAcknowledged
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? accentSeed = null,Object? dynamicColor = null,Object? chatFontSize = null,Object? messageLayout = null,Object? autoScroll = null,Object? dismissKeyboardOnSend = null,Object? duringRunAction = null,Object? artifactViewer = null,Object? inlineArtifacts = null,Object? slashCommands = null,Object? sttEnabled = null,Object? sttEngine = freezed,Object? ttsEngine = freezed,Object? ttsVoice = freezed,Object? autoReadAloud = null,Object? forkMode = null,Object? forkSplitAtTarget = null,Object? lastEndpoint = freezed,Object? lastModel = freezed,Object? lastSpec = freezed,Object? dismissedBannerIds = null,Object? dismissedVersionBanner = freezed,Object? ssoWarningAcknowledged = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,accentSeed: null == accentSeed ? _self.accentSeed : accentSeed // ignore: cast_nullable_to_non_nullable
as int,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,chatFontSize: null == chatFontSize ? _self.chatFontSize : chatFontSize // ignore: cast_nullable_to_non_nullable
as ChatFontSize,messageLayout: null == messageLayout ? _self.messageLayout : messageLayout // ignore: cast_nullable_to_non_nullable
as MessageLayout,autoScroll: null == autoScroll ? _self.autoScroll : autoScroll // ignore: cast_nullable_to_non_nullable
as bool,dismissKeyboardOnSend: null == dismissKeyboardOnSend ? _self.dismissKeyboardOnSend : dismissKeyboardOnSend // ignore: cast_nullable_to_non_nullable
as bool,duringRunAction: null == duringRunAction ? _self.duringRunAction : duringRunAction // ignore: cast_nullable_to_non_nullable
as DuringRunAction,artifactViewer: null == artifactViewer ? _self.artifactViewer : artifactViewer // ignore: cast_nullable_to_non_nullable
as ArtifactViewer,inlineArtifacts: null == inlineArtifacts ? _self.inlineArtifacts : inlineArtifacts // ignore: cast_nullable_to_non_nullable
as Set<InlineArtifact>,slashCommands: null == slashCommands ? _self.slashCommands : slashCommands // ignore: cast_nullable_to_non_nullable
as bool,sttEnabled: null == sttEnabled ? _self.sttEnabled : sttEnabled // ignore: cast_nullable_to_non_nullable
as bool,sttEngine: freezed == sttEngine ? _self.sttEngine : sttEngine // ignore: cast_nullable_to_non_nullable
as VoiceEngine?,ttsEngine: freezed == ttsEngine ? _self.ttsEngine : ttsEngine // ignore: cast_nullable_to_non_nullable
as VoiceEngine?,ttsVoice: freezed == ttsVoice ? _self.ttsVoice : ttsVoice // ignore: cast_nullable_to_non_nullable
as String?,autoReadAloud: null == autoReadAloud ? _self.autoReadAloud : autoReadAloud // ignore: cast_nullable_to_non_nullable
as bool,forkMode: null == forkMode ? _self.forkMode : forkMode // ignore: cast_nullable_to_non_nullable
as ForkMode,forkSplitAtTarget: null == forkSplitAtTarget ? _self.forkSplitAtTarget : forkSplitAtTarget // ignore: cast_nullable_to_non_nullable
as bool,lastEndpoint: freezed == lastEndpoint ? _self.lastEndpoint : lastEndpoint // ignore: cast_nullable_to_non_nullable
as String?,lastModel: freezed == lastModel ? _self.lastModel : lastModel // ignore: cast_nullable_to_non_nullable
as String?,lastSpec: freezed == lastSpec ? _self.lastSpec : lastSpec // ignore: cast_nullable_to_non_nullable
as String?,dismissedBannerIds: null == dismissedBannerIds ? _self.dismissedBannerIds : dismissedBannerIds // ignore: cast_nullable_to_non_nullable
as List<String>,dismissedVersionBanner: freezed == dismissedVersionBanner ? _self.dismissedVersionBanner : dismissedVersionBanner // ignore: cast_nullable_to_non_nullable
as String?,ssoWarningAcknowledged: null == ssoWarningAcknowledged ? _self.ssoWarningAcknowledged : ssoWarningAcknowledged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode themeMode,  int accentSeed,  bool dynamicColor,  ChatFontSize chatFontSize,  MessageLayout messageLayout,  bool autoScroll,  bool dismissKeyboardOnSend,  DuringRunAction duringRunAction,  ArtifactViewer artifactViewer,  Set<InlineArtifact> inlineArtifacts,  bool slashCommands,  bool sttEnabled,  VoiceEngine? sttEngine,  VoiceEngine? ttsEngine,  String? ttsVoice,  bool autoReadAloud,  ForkMode forkMode,  bool forkSplitAtTarget,  String? lastEndpoint,  String? lastModel,  String? lastSpec,  List<String> dismissedBannerIds,  String? dismissedVersionBanner,  bool ssoWarningAcknowledged)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.accentSeed,_that.dynamicColor,_that.chatFontSize,_that.messageLayout,_that.autoScroll,_that.dismissKeyboardOnSend,_that.duringRunAction,_that.artifactViewer,_that.inlineArtifacts,_that.slashCommands,_that.sttEnabled,_that.sttEngine,_that.ttsEngine,_that.ttsVoice,_that.autoReadAloud,_that.forkMode,_that.forkSplitAtTarget,_that.lastEndpoint,_that.lastModel,_that.lastSpec,_that.dismissedBannerIds,_that.dismissedVersionBanner,_that.ssoWarningAcknowledged);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode themeMode,  int accentSeed,  bool dynamicColor,  ChatFontSize chatFontSize,  MessageLayout messageLayout,  bool autoScroll,  bool dismissKeyboardOnSend,  DuringRunAction duringRunAction,  ArtifactViewer artifactViewer,  Set<InlineArtifact> inlineArtifacts,  bool slashCommands,  bool sttEnabled,  VoiceEngine? sttEngine,  VoiceEngine? ttsEngine,  String? ttsVoice,  bool autoReadAloud,  ForkMode forkMode,  bool forkSplitAtTarget,  String? lastEndpoint,  String? lastModel,  String? lastSpec,  List<String> dismissedBannerIds,  String? dismissedVersionBanner,  bool ssoWarningAcknowledged)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.accentSeed,_that.dynamicColor,_that.chatFontSize,_that.messageLayout,_that.autoScroll,_that.dismissKeyboardOnSend,_that.duringRunAction,_that.artifactViewer,_that.inlineArtifacts,_that.slashCommands,_that.sttEnabled,_that.sttEngine,_that.ttsEngine,_that.ttsVoice,_that.autoReadAloud,_that.forkMode,_that.forkSplitAtTarget,_that.lastEndpoint,_that.lastModel,_that.lastSpec,_that.dismissedBannerIds,_that.dismissedVersionBanner,_that.ssoWarningAcknowledged);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode themeMode,  int accentSeed,  bool dynamicColor,  ChatFontSize chatFontSize,  MessageLayout messageLayout,  bool autoScroll,  bool dismissKeyboardOnSend,  DuringRunAction duringRunAction,  ArtifactViewer artifactViewer,  Set<InlineArtifact> inlineArtifacts,  bool slashCommands,  bool sttEnabled,  VoiceEngine? sttEngine,  VoiceEngine? ttsEngine,  String? ttsVoice,  bool autoReadAloud,  ForkMode forkMode,  bool forkSplitAtTarget,  String? lastEndpoint,  String? lastModel,  String? lastSpec,  List<String> dismissedBannerIds,  String? dismissedVersionBanner,  bool ssoWarningAcknowledged)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.accentSeed,_that.dynamicColor,_that.chatFontSize,_that.messageLayout,_that.autoScroll,_that.dismissKeyboardOnSend,_that.duringRunAction,_that.artifactViewer,_that.inlineArtifacts,_that.slashCommands,_that.sttEnabled,_that.sttEngine,_that.ttsEngine,_that.ttsVoice,_that.autoReadAloud,_that.forkMode,_that.forkSplitAtTarget,_that.lastEndpoint,_that.lastModel,_that.lastSpec,_that.dismissedBannerIds,_that.dismissedVersionBanner,_that.ssoWarningAcknowledged);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings with DiagnosticableTreeMixin implements AppSettings {
  const _AppSettings({this.themeMode = ThemeMode.system, this.accentSeed = 0xFF3B82F6, this.dynamicColor = false, this.chatFontSize = ChatFontSize.medium, this.messageLayout = MessageLayout.thread, this.autoScroll = true, this.dismissKeyboardOnSend = true, this.duringRunAction = DuringRunAction.queue, this.artifactViewer = ArtifactViewer.sheet, final  Set<InlineArtifact> inlineArtifacts = const <InlineArtifact>{}, this.slashCommands = true, this.sttEnabled = true, this.sttEngine, this.ttsEngine, this.ttsVoice, this.autoReadAloud = false, this.forkMode = ForkMode.targetLevel, this.forkSplitAtTarget = false, this.lastEndpoint, this.lastModel, this.lastSpec, final  List<String> dismissedBannerIds = const <String>[], this.dismissedVersionBanner, this.ssoWarningAcknowledged = false}): _inlineArtifacts = inlineArtifacts,_dismissedBannerIds = dismissedBannerIds;
  

@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey() final  int accentSeed;
@override@JsonKey() final  bool dynamicColor;
@override@JsonKey() final  ChatFontSize chatFontSize;
@override@JsonKey() final  MessageLayout messageLayout;
@override@JsonKey() final  bool autoScroll;
@override@JsonKey() final  bool dismissKeyboardOnSend;
@override@JsonKey() final  DuringRunAction duringRunAction;
@override@JsonKey() final  ArtifactViewer artifactViewer;
 final  Set<InlineArtifact> _inlineArtifacts;
@override@JsonKey() Set<InlineArtifact> get inlineArtifacts {
  if (_inlineArtifacts is EqualUnmodifiableSetView) return _inlineArtifacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_inlineArtifacts);
}

@override@JsonKey() final  bool slashCommands;
@override@JsonKey() final  bool sttEnabled;
@override final  VoiceEngine? sttEngine;
@override final  VoiceEngine? ttsEngine;
@override final  String? ttsVoice;
@override@JsonKey() final  bool autoReadAloud;
@override@JsonKey() final  ForkMode forkMode;
@override@JsonKey() final  bool forkSplitAtTarget;
@override final  String? lastEndpoint;
@override final  String? lastModel;
@override final  String? lastSpec;
 final  List<String> _dismissedBannerIds;
@override@JsonKey() List<String> get dismissedBannerIds {
  if (_dismissedBannerIds is EqualUnmodifiableListView) return _dismissedBannerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dismissedBannerIds);
}

@override final  String? dismissedVersionBanner;
@override@JsonKey() final  bool ssoWarningAcknowledged;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppSettings'))
    ..add(DiagnosticsProperty('themeMode', themeMode))..add(DiagnosticsProperty('accentSeed', accentSeed))..add(DiagnosticsProperty('dynamicColor', dynamicColor))..add(DiagnosticsProperty('chatFontSize', chatFontSize))..add(DiagnosticsProperty('messageLayout', messageLayout))..add(DiagnosticsProperty('autoScroll', autoScroll))..add(DiagnosticsProperty('dismissKeyboardOnSend', dismissKeyboardOnSend))..add(DiagnosticsProperty('duringRunAction', duringRunAction))..add(DiagnosticsProperty('artifactViewer', artifactViewer))..add(DiagnosticsProperty('inlineArtifacts', inlineArtifacts))..add(DiagnosticsProperty('slashCommands', slashCommands))..add(DiagnosticsProperty('sttEnabled', sttEnabled))..add(DiagnosticsProperty('sttEngine', sttEngine))..add(DiagnosticsProperty('ttsEngine', ttsEngine))..add(DiagnosticsProperty('ttsVoice', ttsVoice))..add(DiagnosticsProperty('autoReadAloud', autoReadAloud))..add(DiagnosticsProperty('forkMode', forkMode))..add(DiagnosticsProperty('forkSplitAtTarget', forkSplitAtTarget))..add(DiagnosticsProperty('lastEndpoint', lastEndpoint))..add(DiagnosticsProperty('lastModel', lastModel))..add(DiagnosticsProperty('lastSpec', lastSpec))..add(DiagnosticsProperty('dismissedBannerIds', dismissedBannerIds))..add(DiagnosticsProperty('dismissedVersionBanner', dismissedVersionBanner))..add(DiagnosticsProperty('ssoWarningAcknowledged', ssoWarningAcknowledged));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accentSeed, accentSeed) || other.accentSeed == accentSeed)&&(identical(other.dynamicColor, dynamicColor) || other.dynamicColor == dynamicColor)&&(identical(other.chatFontSize, chatFontSize) || other.chatFontSize == chatFontSize)&&(identical(other.messageLayout, messageLayout) || other.messageLayout == messageLayout)&&(identical(other.autoScroll, autoScroll) || other.autoScroll == autoScroll)&&(identical(other.dismissKeyboardOnSend, dismissKeyboardOnSend) || other.dismissKeyboardOnSend == dismissKeyboardOnSend)&&(identical(other.duringRunAction, duringRunAction) || other.duringRunAction == duringRunAction)&&(identical(other.artifactViewer, artifactViewer) || other.artifactViewer == artifactViewer)&&const DeepCollectionEquality().equals(other._inlineArtifacts, _inlineArtifacts)&&(identical(other.slashCommands, slashCommands) || other.slashCommands == slashCommands)&&(identical(other.sttEnabled, sttEnabled) || other.sttEnabled == sttEnabled)&&(identical(other.sttEngine, sttEngine) || other.sttEngine == sttEngine)&&(identical(other.ttsEngine, ttsEngine) || other.ttsEngine == ttsEngine)&&(identical(other.ttsVoice, ttsVoice) || other.ttsVoice == ttsVoice)&&(identical(other.autoReadAloud, autoReadAloud) || other.autoReadAloud == autoReadAloud)&&(identical(other.forkMode, forkMode) || other.forkMode == forkMode)&&(identical(other.forkSplitAtTarget, forkSplitAtTarget) || other.forkSplitAtTarget == forkSplitAtTarget)&&(identical(other.lastEndpoint, lastEndpoint) || other.lastEndpoint == lastEndpoint)&&(identical(other.lastModel, lastModel) || other.lastModel == lastModel)&&(identical(other.lastSpec, lastSpec) || other.lastSpec == lastSpec)&&const DeepCollectionEquality().equals(other._dismissedBannerIds, _dismissedBannerIds)&&(identical(other.dismissedVersionBanner, dismissedVersionBanner) || other.dismissedVersionBanner == dismissedVersionBanner)&&(identical(other.ssoWarningAcknowledged, ssoWarningAcknowledged) || other.ssoWarningAcknowledged == ssoWarningAcknowledged));
}


@override
int get hashCode => Object.hashAll([runtimeType,themeMode,accentSeed,dynamicColor,chatFontSize,messageLayout,autoScroll,dismissKeyboardOnSend,duringRunAction,artifactViewer,const DeepCollectionEquality().hash(_inlineArtifacts),slashCommands,sttEnabled,sttEngine,ttsEngine,ttsVoice,autoReadAloud,forkMode,forkSplitAtTarget,lastEndpoint,lastModel,lastSpec,const DeepCollectionEquality().hash(_dismissedBannerIds),dismissedVersionBanner,ssoWarningAcknowledged]);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppSettings(themeMode: $themeMode, accentSeed: $accentSeed, dynamicColor: $dynamicColor, chatFontSize: $chatFontSize, messageLayout: $messageLayout, autoScroll: $autoScroll, dismissKeyboardOnSend: $dismissKeyboardOnSend, duringRunAction: $duringRunAction, artifactViewer: $artifactViewer, inlineArtifacts: $inlineArtifacts, slashCommands: $slashCommands, sttEnabled: $sttEnabled, sttEngine: $sttEngine, ttsEngine: $ttsEngine, ttsVoice: $ttsVoice, autoReadAloud: $autoReadAloud, forkMode: $forkMode, forkSplitAtTarget: $forkSplitAtTarget, lastEndpoint: $lastEndpoint, lastModel: $lastModel, lastSpec: $lastSpec, dismissedBannerIds: $dismissedBannerIds, dismissedVersionBanner: $dismissedVersionBanner, ssoWarningAcknowledged: $ssoWarningAcknowledged)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode themeMode, int accentSeed, bool dynamicColor, ChatFontSize chatFontSize, MessageLayout messageLayout, bool autoScroll, bool dismissKeyboardOnSend, DuringRunAction duringRunAction, ArtifactViewer artifactViewer, Set<InlineArtifact> inlineArtifacts, bool slashCommands, bool sttEnabled, VoiceEngine? sttEngine, VoiceEngine? ttsEngine, String? ttsVoice, bool autoReadAloud, ForkMode forkMode, bool forkSplitAtTarget, String? lastEndpoint, String? lastModel, String? lastSpec, List<String> dismissedBannerIds, String? dismissedVersionBanner, bool ssoWarningAcknowledged
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? accentSeed = null,Object? dynamicColor = null,Object? chatFontSize = null,Object? messageLayout = null,Object? autoScroll = null,Object? dismissKeyboardOnSend = null,Object? duringRunAction = null,Object? artifactViewer = null,Object? inlineArtifacts = null,Object? slashCommands = null,Object? sttEnabled = null,Object? sttEngine = freezed,Object? ttsEngine = freezed,Object? ttsVoice = freezed,Object? autoReadAloud = null,Object? forkMode = null,Object? forkSplitAtTarget = null,Object? lastEndpoint = freezed,Object? lastModel = freezed,Object? lastSpec = freezed,Object? dismissedBannerIds = null,Object? dismissedVersionBanner = freezed,Object? ssoWarningAcknowledged = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,accentSeed: null == accentSeed ? _self.accentSeed : accentSeed // ignore: cast_nullable_to_non_nullable
as int,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,chatFontSize: null == chatFontSize ? _self.chatFontSize : chatFontSize // ignore: cast_nullable_to_non_nullable
as ChatFontSize,messageLayout: null == messageLayout ? _self.messageLayout : messageLayout // ignore: cast_nullable_to_non_nullable
as MessageLayout,autoScroll: null == autoScroll ? _self.autoScroll : autoScroll // ignore: cast_nullable_to_non_nullable
as bool,dismissKeyboardOnSend: null == dismissKeyboardOnSend ? _self.dismissKeyboardOnSend : dismissKeyboardOnSend // ignore: cast_nullable_to_non_nullable
as bool,duringRunAction: null == duringRunAction ? _self.duringRunAction : duringRunAction // ignore: cast_nullable_to_non_nullable
as DuringRunAction,artifactViewer: null == artifactViewer ? _self.artifactViewer : artifactViewer // ignore: cast_nullable_to_non_nullable
as ArtifactViewer,inlineArtifacts: null == inlineArtifacts ? _self._inlineArtifacts : inlineArtifacts // ignore: cast_nullable_to_non_nullable
as Set<InlineArtifact>,slashCommands: null == slashCommands ? _self.slashCommands : slashCommands // ignore: cast_nullable_to_non_nullable
as bool,sttEnabled: null == sttEnabled ? _self.sttEnabled : sttEnabled // ignore: cast_nullable_to_non_nullable
as bool,sttEngine: freezed == sttEngine ? _self.sttEngine : sttEngine // ignore: cast_nullable_to_non_nullable
as VoiceEngine?,ttsEngine: freezed == ttsEngine ? _self.ttsEngine : ttsEngine // ignore: cast_nullable_to_non_nullable
as VoiceEngine?,ttsVoice: freezed == ttsVoice ? _self.ttsVoice : ttsVoice // ignore: cast_nullable_to_non_nullable
as String?,autoReadAloud: null == autoReadAloud ? _self.autoReadAloud : autoReadAloud // ignore: cast_nullable_to_non_nullable
as bool,forkMode: null == forkMode ? _self.forkMode : forkMode // ignore: cast_nullable_to_non_nullable
as ForkMode,forkSplitAtTarget: null == forkSplitAtTarget ? _self.forkSplitAtTarget : forkSplitAtTarget // ignore: cast_nullable_to_non_nullable
as bool,lastEndpoint: freezed == lastEndpoint ? _self.lastEndpoint : lastEndpoint // ignore: cast_nullable_to_non_nullable
as String?,lastModel: freezed == lastModel ? _self.lastModel : lastModel // ignore: cast_nullable_to_non_nullable
as String?,lastSpec: freezed == lastSpec ? _self.lastSpec : lastSpec // ignore: cast_nullable_to_non_nullable
as String?,dismissedBannerIds: null == dismissedBannerIds ? _self._dismissedBannerIds : dismissedBannerIds // ignore: cast_nullable_to_non_nullable
as List<String>,dismissedVersionBanner: freezed == dismissedVersionBanner ? _self.dismissedVersionBanner : dismissedVersionBanner // ignore: cast_nullable_to_non_nullable
as String?,ssoWarningAcknowledged: null == ssoWarningAcknowledged ? _self.ssoWarningAcknowledged : ssoWarningAcknowledged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
