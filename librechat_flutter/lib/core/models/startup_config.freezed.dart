// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'startup_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StartupConfig {

 String get appTitle; bool get emailLoginEnabled; bool get registrationEnabled; bool get passwordResetEnabled; List<String>? get socialLogins; bool get googleLoginEnabled; bool get githubLoginEnabled; bool get discordLoginEnabled; bool get facebookLoginEnabled; bool get appleLoginEnabled; bool get openidLoginEnabled; String? get openidLabel; String? get openidImageUrl; bool get openidAutoRedirect; bool get samlLoginEnabled; String? get samlLabel; String? get samlImageUrl; LdapConfig? get ldap; int? get minPasswordLength; bool get sharedLinksEnabled; String? get helpAndFaqURL; bool get allowAccountDeletion; BalanceConfig? get balance; int? get conversationImportMaxFileSize; Map<String, Object?>? get modelSpecs; String? get version; BuildInfo? get buildInfo;// Null on servers that predate compaction, which is the gate, so it has no default.
 bool? get compactionEnabled;@JsonKey(name: 'interface') InterfaceConfig get interfaceConfig;
/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartupConfigCopyWith<StartupConfig> get copyWith => _$StartupConfigCopyWithImpl<StartupConfig>(this as StartupConfig, _$identity);

  /// Serializes this StartupConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartupConfig&&(identical(other.appTitle, appTitle) || other.appTitle == appTitle)&&(identical(other.emailLoginEnabled, emailLoginEnabled) || other.emailLoginEnabled == emailLoginEnabled)&&(identical(other.registrationEnabled, registrationEnabled) || other.registrationEnabled == registrationEnabled)&&(identical(other.passwordResetEnabled, passwordResetEnabled) || other.passwordResetEnabled == passwordResetEnabled)&&const DeepCollectionEquality().equals(other.socialLogins, socialLogins)&&(identical(other.googleLoginEnabled, googleLoginEnabled) || other.googleLoginEnabled == googleLoginEnabled)&&(identical(other.githubLoginEnabled, githubLoginEnabled) || other.githubLoginEnabled == githubLoginEnabled)&&(identical(other.discordLoginEnabled, discordLoginEnabled) || other.discordLoginEnabled == discordLoginEnabled)&&(identical(other.facebookLoginEnabled, facebookLoginEnabled) || other.facebookLoginEnabled == facebookLoginEnabled)&&(identical(other.appleLoginEnabled, appleLoginEnabled) || other.appleLoginEnabled == appleLoginEnabled)&&(identical(other.openidLoginEnabled, openidLoginEnabled) || other.openidLoginEnabled == openidLoginEnabled)&&(identical(other.openidLabel, openidLabel) || other.openidLabel == openidLabel)&&(identical(other.openidImageUrl, openidImageUrl) || other.openidImageUrl == openidImageUrl)&&(identical(other.openidAutoRedirect, openidAutoRedirect) || other.openidAutoRedirect == openidAutoRedirect)&&(identical(other.samlLoginEnabled, samlLoginEnabled) || other.samlLoginEnabled == samlLoginEnabled)&&(identical(other.samlLabel, samlLabel) || other.samlLabel == samlLabel)&&(identical(other.samlImageUrl, samlImageUrl) || other.samlImageUrl == samlImageUrl)&&(identical(other.ldap, ldap) || other.ldap == ldap)&&(identical(other.minPasswordLength, minPasswordLength) || other.minPasswordLength == minPasswordLength)&&(identical(other.sharedLinksEnabled, sharedLinksEnabled) || other.sharedLinksEnabled == sharedLinksEnabled)&&(identical(other.helpAndFaqURL, helpAndFaqURL) || other.helpAndFaqURL == helpAndFaqURL)&&(identical(other.allowAccountDeletion, allowAccountDeletion) || other.allowAccountDeletion == allowAccountDeletion)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.conversationImportMaxFileSize, conversationImportMaxFileSize) || other.conversationImportMaxFileSize == conversationImportMaxFileSize)&&const DeepCollectionEquality().equals(other.modelSpecs, modelSpecs)&&(identical(other.version, version) || other.version == version)&&(identical(other.buildInfo, buildInfo) || other.buildInfo == buildInfo)&&(identical(other.compactionEnabled, compactionEnabled) || other.compactionEnabled == compactionEnabled)&&(identical(other.interfaceConfig, interfaceConfig) || other.interfaceConfig == interfaceConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appTitle,emailLoginEnabled,registrationEnabled,passwordResetEnabled,const DeepCollectionEquality().hash(socialLogins),googleLoginEnabled,githubLoginEnabled,discordLoginEnabled,facebookLoginEnabled,appleLoginEnabled,openidLoginEnabled,openidLabel,openidImageUrl,openidAutoRedirect,samlLoginEnabled,samlLabel,samlImageUrl,ldap,minPasswordLength,sharedLinksEnabled,helpAndFaqURL,allowAccountDeletion,balance,conversationImportMaxFileSize,const DeepCollectionEquality().hash(modelSpecs),version,buildInfo,compactionEnabled,interfaceConfig]);

@override
String toString() {
  return 'StartupConfig(appTitle: $appTitle, emailLoginEnabled: $emailLoginEnabled, registrationEnabled: $registrationEnabled, passwordResetEnabled: $passwordResetEnabled, socialLogins: $socialLogins, googleLoginEnabled: $googleLoginEnabled, githubLoginEnabled: $githubLoginEnabled, discordLoginEnabled: $discordLoginEnabled, facebookLoginEnabled: $facebookLoginEnabled, appleLoginEnabled: $appleLoginEnabled, openidLoginEnabled: $openidLoginEnabled, openidLabel: $openidLabel, openidImageUrl: $openidImageUrl, openidAutoRedirect: $openidAutoRedirect, samlLoginEnabled: $samlLoginEnabled, samlLabel: $samlLabel, samlImageUrl: $samlImageUrl, ldap: $ldap, minPasswordLength: $minPasswordLength, sharedLinksEnabled: $sharedLinksEnabled, helpAndFaqURL: $helpAndFaqURL, allowAccountDeletion: $allowAccountDeletion, balance: $balance, conversationImportMaxFileSize: $conversationImportMaxFileSize, modelSpecs: $modelSpecs, version: $version, buildInfo: $buildInfo, compactionEnabled: $compactionEnabled, interfaceConfig: $interfaceConfig)';
}


}

/// @nodoc
abstract mixin class $StartupConfigCopyWith<$Res>  {
  factory $StartupConfigCopyWith(StartupConfig value, $Res Function(StartupConfig) _then) = _$StartupConfigCopyWithImpl;
@useResult
$Res call({
 String appTitle, bool emailLoginEnabled, bool registrationEnabled, bool passwordResetEnabled, List<String>? socialLogins, bool googleLoginEnabled, bool githubLoginEnabled, bool discordLoginEnabled, bool facebookLoginEnabled, bool appleLoginEnabled, bool openidLoginEnabled, String? openidLabel, String? openidImageUrl, bool openidAutoRedirect, bool samlLoginEnabled, String? samlLabel, String? samlImageUrl, LdapConfig? ldap, int? minPasswordLength, bool sharedLinksEnabled, String? helpAndFaqURL, bool allowAccountDeletion, BalanceConfig? balance, int? conversationImportMaxFileSize, Map<String, Object?>? modelSpecs, String? version, BuildInfo? buildInfo, bool? compactionEnabled,@JsonKey(name: 'interface') InterfaceConfig interfaceConfig
});


$LdapConfigCopyWith<$Res>? get ldap;$BalanceConfigCopyWith<$Res>? get balance;$BuildInfoCopyWith<$Res>? get buildInfo;$InterfaceConfigCopyWith<$Res> get interfaceConfig;

}
/// @nodoc
class _$StartupConfigCopyWithImpl<$Res>
    implements $StartupConfigCopyWith<$Res> {
  _$StartupConfigCopyWithImpl(this._self, this._then);

  final StartupConfig _self;
  final $Res Function(StartupConfig) _then;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appTitle = null,Object? emailLoginEnabled = null,Object? registrationEnabled = null,Object? passwordResetEnabled = null,Object? socialLogins = freezed,Object? googleLoginEnabled = null,Object? githubLoginEnabled = null,Object? discordLoginEnabled = null,Object? facebookLoginEnabled = null,Object? appleLoginEnabled = null,Object? openidLoginEnabled = null,Object? openidLabel = freezed,Object? openidImageUrl = freezed,Object? openidAutoRedirect = null,Object? samlLoginEnabled = null,Object? samlLabel = freezed,Object? samlImageUrl = freezed,Object? ldap = freezed,Object? minPasswordLength = freezed,Object? sharedLinksEnabled = null,Object? helpAndFaqURL = freezed,Object? allowAccountDeletion = null,Object? balance = freezed,Object? conversationImportMaxFileSize = freezed,Object? modelSpecs = freezed,Object? version = freezed,Object? buildInfo = freezed,Object? compactionEnabled = freezed,Object? interfaceConfig = null,}) {
  return _then(_self.copyWith(
appTitle: null == appTitle ? _self.appTitle : appTitle // ignore: cast_nullable_to_non_nullable
as String,emailLoginEnabled: null == emailLoginEnabled ? _self.emailLoginEnabled : emailLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,registrationEnabled: null == registrationEnabled ? _self.registrationEnabled : registrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,passwordResetEnabled: null == passwordResetEnabled ? _self.passwordResetEnabled : passwordResetEnabled // ignore: cast_nullable_to_non_nullable
as bool,socialLogins: freezed == socialLogins ? _self.socialLogins : socialLogins // ignore: cast_nullable_to_non_nullable
as List<String>?,googleLoginEnabled: null == googleLoginEnabled ? _self.googleLoginEnabled : googleLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,githubLoginEnabled: null == githubLoginEnabled ? _self.githubLoginEnabled : githubLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,discordLoginEnabled: null == discordLoginEnabled ? _self.discordLoginEnabled : discordLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,facebookLoginEnabled: null == facebookLoginEnabled ? _self.facebookLoginEnabled : facebookLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,appleLoginEnabled: null == appleLoginEnabled ? _self.appleLoginEnabled : appleLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,openidLoginEnabled: null == openidLoginEnabled ? _self.openidLoginEnabled : openidLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,openidLabel: freezed == openidLabel ? _self.openidLabel : openidLabel // ignore: cast_nullable_to_non_nullable
as String?,openidImageUrl: freezed == openidImageUrl ? _self.openidImageUrl : openidImageUrl // ignore: cast_nullable_to_non_nullable
as String?,openidAutoRedirect: null == openidAutoRedirect ? _self.openidAutoRedirect : openidAutoRedirect // ignore: cast_nullable_to_non_nullable
as bool,samlLoginEnabled: null == samlLoginEnabled ? _self.samlLoginEnabled : samlLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,samlLabel: freezed == samlLabel ? _self.samlLabel : samlLabel // ignore: cast_nullable_to_non_nullable
as String?,samlImageUrl: freezed == samlImageUrl ? _self.samlImageUrl : samlImageUrl // ignore: cast_nullable_to_non_nullable
as String?,ldap: freezed == ldap ? _self.ldap : ldap // ignore: cast_nullable_to_non_nullable
as LdapConfig?,minPasswordLength: freezed == minPasswordLength ? _self.minPasswordLength : minPasswordLength // ignore: cast_nullable_to_non_nullable
as int?,sharedLinksEnabled: null == sharedLinksEnabled ? _self.sharedLinksEnabled : sharedLinksEnabled // ignore: cast_nullable_to_non_nullable
as bool,helpAndFaqURL: freezed == helpAndFaqURL ? _self.helpAndFaqURL : helpAndFaqURL // ignore: cast_nullable_to_non_nullable
as String?,allowAccountDeletion: null == allowAccountDeletion ? _self.allowAccountDeletion : allowAccountDeletion // ignore: cast_nullable_to_non_nullable
as bool,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as BalanceConfig?,conversationImportMaxFileSize: freezed == conversationImportMaxFileSize ? _self.conversationImportMaxFileSize : conversationImportMaxFileSize // ignore: cast_nullable_to_non_nullable
as int?,modelSpecs: freezed == modelSpecs ? _self.modelSpecs : modelSpecs // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,buildInfo: freezed == buildInfo ? _self.buildInfo : buildInfo // ignore: cast_nullable_to_non_nullable
as BuildInfo?,compactionEnabled: freezed == compactionEnabled ? _self.compactionEnabled : compactionEnabled // ignore: cast_nullable_to_non_nullable
as bool?,interfaceConfig: null == interfaceConfig ? _self.interfaceConfig : interfaceConfig // ignore: cast_nullable_to_non_nullable
as InterfaceConfig,
  ));
}
/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LdapConfigCopyWith<$Res>? get ldap {
    if (_self.ldap == null) {
    return null;
  }

  return $LdapConfigCopyWith<$Res>(_self.ldap!, (value) {
    return _then(_self.copyWith(ldap: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceConfigCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $BalanceConfigCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildInfoCopyWith<$Res>? get buildInfo {
    if (_self.buildInfo == null) {
    return null;
  }

  return $BuildInfoCopyWith<$Res>(_self.buildInfo!, (value) {
    return _then(_self.copyWith(buildInfo: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InterfaceConfigCopyWith<$Res> get interfaceConfig {
  
  return $InterfaceConfigCopyWith<$Res>(_self.interfaceConfig, (value) {
    return _then(_self.copyWith(interfaceConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [StartupConfig].
extension StartupConfigPatterns on StartupConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartupConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartupConfig value)  $default,){
final _that = this;
switch (_that) {
case _StartupConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartupConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appTitle,  bool emailLoginEnabled,  bool registrationEnabled,  bool passwordResetEnabled,  List<String>? socialLogins,  bool googleLoginEnabled,  bool githubLoginEnabled,  bool discordLoginEnabled,  bool facebookLoginEnabled,  bool appleLoginEnabled,  bool openidLoginEnabled,  String? openidLabel,  String? openidImageUrl,  bool openidAutoRedirect,  bool samlLoginEnabled,  String? samlLabel,  String? samlImageUrl,  LdapConfig? ldap,  int? minPasswordLength,  bool sharedLinksEnabled,  String? helpAndFaqURL,  bool allowAccountDeletion,  BalanceConfig? balance,  int? conversationImportMaxFileSize,  Map<String, Object?>? modelSpecs,  String? version,  BuildInfo? buildInfo,  bool? compactionEnabled, @JsonKey(name: 'interface')  InterfaceConfig interfaceConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
return $default(_that.appTitle,_that.emailLoginEnabled,_that.registrationEnabled,_that.passwordResetEnabled,_that.socialLogins,_that.googleLoginEnabled,_that.githubLoginEnabled,_that.discordLoginEnabled,_that.facebookLoginEnabled,_that.appleLoginEnabled,_that.openidLoginEnabled,_that.openidLabel,_that.openidImageUrl,_that.openidAutoRedirect,_that.samlLoginEnabled,_that.samlLabel,_that.samlImageUrl,_that.ldap,_that.minPasswordLength,_that.sharedLinksEnabled,_that.helpAndFaqURL,_that.allowAccountDeletion,_that.balance,_that.conversationImportMaxFileSize,_that.modelSpecs,_that.version,_that.buildInfo,_that.compactionEnabled,_that.interfaceConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appTitle,  bool emailLoginEnabled,  bool registrationEnabled,  bool passwordResetEnabled,  List<String>? socialLogins,  bool googleLoginEnabled,  bool githubLoginEnabled,  bool discordLoginEnabled,  bool facebookLoginEnabled,  bool appleLoginEnabled,  bool openidLoginEnabled,  String? openidLabel,  String? openidImageUrl,  bool openidAutoRedirect,  bool samlLoginEnabled,  String? samlLabel,  String? samlImageUrl,  LdapConfig? ldap,  int? minPasswordLength,  bool sharedLinksEnabled,  String? helpAndFaqURL,  bool allowAccountDeletion,  BalanceConfig? balance,  int? conversationImportMaxFileSize,  Map<String, Object?>? modelSpecs,  String? version,  BuildInfo? buildInfo,  bool? compactionEnabled, @JsonKey(name: 'interface')  InterfaceConfig interfaceConfig)  $default,) {final _that = this;
switch (_that) {
case _StartupConfig():
return $default(_that.appTitle,_that.emailLoginEnabled,_that.registrationEnabled,_that.passwordResetEnabled,_that.socialLogins,_that.googleLoginEnabled,_that.githubLoginEnabled,_that.discordLoginEnabled,_that.facebookLoginEnabled,_that.appleLoginEnabled,_that.openidLoginEnabled,_that.openidLabel,_that.openidImageUrl,_that.openidAutoRedirect,_that.samlLoginEnabled,_that.samlLabel,_that.samlImageUrl,_that.ldap,_that.minPasswordLength,_that.sharedLinksEnabled,_that.helpAndFaqURL,_that.allowAccountDeletion,_that.balance,_that.conversationImportMaxFileSize,_that.modelSpecs,_that.version,_that.buildInfo,_that.compactionEnabled,_that.interfaceConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appTitle,  bool emailLoginEnabled,  bool registrationEnabled,  bool passwordResetEnabled,  List<String>? socialLogins,  bool googleLoginEnabled,  bool githubLoginEnabled,  bool discordLoginEnabled,  bool facebookLoginEnabled,  bool appleLoginEnabled,  bool openidLoginEnabled,  String? openidLabel,  String? openidImageUrl,  bool openidAutoRedirect,  bool samlLoginEnabled,  String? samlLabel,  String? samlImageUrl,  LdapConfig? ldap,  int? minPasswordLength,  bool sharedLinksEnabled,  String? helpAndFaqURL,  bool allowAccountDeletion,  BalanceConfig? balance,  int? conversationImportMaxFileSize,  Map<String, Object?>? modelSpecs,  String? version,  BuildInfo? buildInfo,  bool? compactionEnabled, @JsonKey(name: 'interface')  InterfaceConfig interfaceConfig)?  $default,) {final _that = this;
switch (_that) {
case _StartupConfig() when $default != null:
return $default(_that.appTitle,_that.emailLoginEnabled,_that.registrationEnabled,_that.passwordResetEnabled,_that.socialLogins,_that.googleLoginEnabled,_that.githubLoginEnabled,_that.discordLoginEnabled,_that.facebookLoginEnabled,_that.appleLoginEnabled,_that.openidLoginEnabled,_that.openidLabel,_that.openidImageUrl,_that.openidAutoRedirect,_that.samlLoginEnabled,_that.samlLabel,_that.samlImageUrl,_that.ldap,_that.minPasswordLength,_that.sharedLinksEnabled,_that.helpAndFaqURL,_that.allowAccountDeletion,_that.balance,_that.conversationImportMaxFileSize,_that.modelSpecs,_that.version,_that.buildInfo,_that.compactionEnabled,_that.interfaceConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StartupConfig implements StartupConfig {
  const _StartupConfig({this.appTitle = 'LibreChat', this.emailLoginEnabled = true, this.registrationEnabled = false, this.passwordResetEnabled = false, final  List<String>? socialLogins, this.googleLoginEnabled = false, this.githubLoginEnabled = false, this.discordLoginEnabled = false, this.facebookLoginEnabled = false, this.appleLoginEnabled = false, this.openidLoginEnabled = false, this.openidLabel, this.openidImageUrl, this.openidAutoRedirect = false, this.samlLoginEnabled = false, this.samlLabel, this.samlImageUrl, this.ldap, this.minPasswordLength, this.sharedLinksEnabled = false, this.helpAndFaqURL, this.allowAccountDeletion = true, this.balance, this.conversationImportMaxFileSize, final  Map<String, Object?>? modelSpecs, this.version, this.buildInfo, this.compactionEnabled, @JsonKey(name: 'interface') this.interfaceConfig = const InterfaceConfig()}): _socialLogins = socialLogins,_modelSpecs = modelSpecs;
  factory _StartupConfig.fromJson(Map<String, dynamic> json) => _$StartupConfigFromJson(json);

@override@JsonKey() final  String appTitle;
@override@JsonKey() final  bool emailLoginEnabled;
@override@JsonKey() final  bool registrationEnabled;
@override@JsonKey() final  bool passwordResetEnabled;
 final  List<String>? _socialLogins;
@override List<String>? get socialLogins {
  final value = _socialLogins;
  if (value == null) return null;
  if (_socialLogins is EqualUnmodifiableListView) return _socialLogins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool googleLoginEnabled;
@override@JsonKey() final  bool githubLoginEnabled;
@override@JsonKey() final  bool discordLoginEnabled;
@override@JsonKey() final  bool facebookLoginEnabled;
@override@JsonKey() final  bool appleLoginEnabled;
@override@JsonKey() final  bool openidLoginEnabled;
@override final  String? openidLabel;
@override final  String? openidImageUrl;
@override@JsonKey() final  bool openidAutoRedirect;
@override@JsonKey() final  bool samlLoginEnabled;
@override final  String? samlLabel;
@override final  String? samlImageUrl;
@override final  LdapConfig? ldap;
@override final  int? minPasswordLength;
@override@JsonKey() final  bool sharedLinksEnabled;
@override final  String? helpAndFaqURL;
@override@JsonKey() final  bool allowAccountDeletion;
@override final  BalanceConfig? balance;
@override final  int? conversationImportMaxFileSize;
 final  Map<String, Object?>? _modelSpecs;
@override Map<String, Object?>? get modelSpecs {
  final value = _modelSpecs;
  if (value == null) return null;
  if (_modelSpecs is EqualUnmodifiableMapView) return _modelSpecs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? version;
@override final  BuildInfo? buildInfo;
// Null on servers that predate compaction, which is the gate, so it has no default.
@override final  bool? compactionEnabled;
@override@JsonKey(name: 'interface') final  InterfaceConfig interfaceConfig;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartupConfigCopyWith<_StartupConfig> get copyWith => __$StartupConfigCopyWithImpl<_StartupConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartupConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartupConfig&&(identical(other.appTitle, appTitle) || other.appTitle == appTitle)&&(identical(other.emailLoginEnabled, emailLoginEnabled) || other.emailLoginEnabled == emailLoginEnabled)&&(identical(other.registrationEnabled, registrationEnabled) || other.registrationEnabled == registrationEnabled)&&(identical(other.passwordResetEnabled, passwordResetEnabled) || other.passwordResetEnabled == passwordResetEnabled)&&const DeepCollectionEquality().equals(other._socialLogins, _socialLogins)&&(identical(other.googleLoginEnabled, googleLoginEnabled) || other.googleLoginEnabled == googleLoginEnabled)&&(identical(other.githubLoginEnabled, githubLoginEnabled) || other.githubLoginEnabled == githubLoginEnabled)&&(identical(other.discordLoginEnabled, discordLoginEnabled) || other.discordLoginEnabled == discordLoginEnabled)&&(identical(other.facebookLoginEnabled, facebookLoginEnabled) || other.facebookLoginEnabled == facebookLoginEnabled)&&(identical(other.appleLoginEnabled, appleLoginEnabled) || other.appleLoginEnabled == appleLoginEnabled)&&(identical(other.openidLoginEnabled, openidLoginEnabled) || other.openidLoginEnabled == openidLoginEnabled)&&(identical(other.openidLabel, openidLabel) || other.openidLabel == openidLabel)&&(identical(other.openidImageUrl, openidImageUrl) || other.openidImageUrl == openidImageUrl)&&(identical(other.openidAutoRedirect, openidAutoRedirect) || other.openidAutoRedirect == openidAutoRedirect)&&(identical(other.samlLoginEnabled, samlLoginEnabled) || other.samlLoginEnabled == samlLoginEnabled)&&(identical(other.samlLabel, samlLabel) || other.samlLabel == samlLabel)&&(identical(other.samlImageUrl, samlImageUrl) || other.samlImageUrl == samlImageUrl)&&(identical(other.ldap, ldap) || other.ldap == ldap)&&(identical(other.minPasswordLength, minPasswordLength) || other.minPasswordLength == minPasswordLength)&&(identical(other.sharedLinksEnabled, sharedLinksEnabled) || other.sharedLinksEnabled == sharedLinksEnabled)&&(identical(other.helpAndFaqURL, helpAndFaqURL) || other.helpAndFaqURL == helpAndFaqURL)&&(identical(other.allowAccountDeletion, allowAccountDeletion) || other.allowAccountDeletion == allowAccountDeletion)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.conversationImportMaxFileSize, conversationImportMaxFileSize) || other.conversationImportMaxFileSize == conversationImportMaxFileSize)&&const DeepCollectionEquality().equals(other._modelSpecs, _modelSpecs)&&(identical(other.version, version) || other.version == version)&&(identical(other.buildInfo, buildInfo) || other.buildInfo == buildInfo)&&(identical(other.compactionEnabled, compactionEnabled) || other.compactionEnabled == compactionEnabled)&&(identical(other.interfaceConfig, interfaceConfig) || other.interfaceConfig == interfaceConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appTitle,emailLoginEnabled,registrationEnabled,passwordResetEnabled,const DeepCollectionEquality().hash(_socialLogins),googleLoginEnabled,githubLoginEnabled,discordLoginEnabled,facebookLoginEnabled,appleLoginEnabled,openidLoginEnabled,openidLabel,openidImageUrl,openidAutoRedirect,samlLoginEnabled,samlLabel,samlImageUrl,ldap,minPasswordLength,sharedLinksEnabled,helpAndFaqURL,allowAccountDeletion,balance,conversationImportMaxFileSize,const DeepCollectionEquality().hash(_modelSpecs),version,buildInfo,compactionEnabled,interfaceConfig]);

@override
String toString() {
  return 'StartupConfig(appTitle: $appTitle, emailLoginEnabled: $emailLoginEnabled, registrationEnabled: $registrationEnabled, passwordResetEnabled: $passwordResetEnabled, socialLogins: $socialLogins, googleLoginEnabled: $googleLoginEnabled, githubLoginEnabled: $githubLoginEnabled, discordLoginEnabled: $discordLoginEnabled, facebookLoginEnabled: $facebookLoginEnabled, appleLoginEnabled: $appleLoginEnabled, openidLoginEnabled: $openidLoginEnabled, openidLabel: $openidLabel, openidImageUrl: $openidImageUrl, openidAutoRedirect: $openidAutoRedirect, samlLoginEnabled: $samlLoginEnabled, samlLabel: $samlLabel, samlImageUrl: $samlImageUrl, ldap: $ldap, minPasswordLength: $minPasswordLength, sharedLinksEnabled: $sharedLinksEnabled, helpAndFaqURL: $helpAndFaqURL, allowAccountDeletion: $allowAccountDeletion, balance: $balance, conversationImportMaxFileSize: $conversationImportMaxFileSize, modelSpecs: $modelSpecs, version: $version, buildInfo: $buildInfo, compactionEnabled: $compactionEnabled, interfaceConfig: $interfaceConfig)';
}


}

/// @nodoc
abstract mixin class _$StartupConfigCopyWith<$Res> implements $StartupConfigCopyWith<$Res> {
  factory _$StartupConfigCopyWith(_StartupConfig value, $Res Function(_StartupConfig) _then) = __$StartupConfigCopyWithImpl;
@override @useResult
$Res call({
 String appTitle, bool emailLoginEnabled, bool registrationEnabled, bool passwordResetEnabled, List<String>? socialLogins, bool googleLoginEnabled, bool githubLoginEnabled, bool discordLoginEnabled, bool facebookLoginEnabled, bool appleLoginEnabled, bool openidLoginEnabled, String? openidLabel, String? openidImageUrl, bool openidAutoRedirect, bool samlLoginEnabled, String? samlLabel, String? samlImageUrl, LdapConfig? ldap, int? minPasswordLength, bool sharedLinksEnabled, String? helpAndFaqURL, bool allowAccountDeletion, BalanceConfig? balance, int? conversationImportMaxFileSize, Map<String, Object?>? modelSpecs, String? version, BuildInfo? buildInfo, bool? compactionEnabled,@JsonKey(name: 'interface') InterfaceConfig interfaceConfig
});


@override $LdapConfigCopyWith<$Res>? get ldap;@override $BalanceConfigCopyWith<$Res>? get balance;@override $BuildInfoCopyWith<$Res>? get buildInfo;@override $InterfaceConfigCopyWith<$Res> get interfaceConfig;

}
/// @nodoc
class __$StartupConfigCopyWithImpl<$Res>
    implements _$StartupConfigCopyWith<$Res> {
  __$StartupConfigCopyWithImpl(this._self, this._then);

  final _StartupConfig _self;
  final $Res Function(_StartupConfig) _then;

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appTitle = null,Object? emailLoginEnabled = null,Object? registrationEnabled = null,Object? passwordResetEnabled = null,Object? socialLogins = freezed,Object? googleLoginEnabled = null,Object? githubLoginEnabled = null,Object? discordLoginEnabled = null,Object? facebookLoginEnabled = null,Object? appleLoginEnabled = null,Object? openidLoginEnabled = null,Object? openidLabel = freezed,Object? openidImageUrl = freezed,Object? openidAutoRedirect = null,Object? samlLoginEnabled = null,Object? samlLabel = freezed,Object? samlImageUrl = freezed,Object? ldap = freezed,Object? minPasswordLength = freezed,Object? sharedLinksEnabled = null,Object? helpAndFaqURL = freezed,Object? allowAccountDeletion = null,Object? balance = freezed,Object? conversationImportMaxFileSize = freezed,Object? modelSpecs = freezed,Object? version = freezed,Object? buildInfo = freezed,Object? compactionEnabled = freezed,Object? interfaceConfig = null,}) {
  return _then(_StartupConfig(
appTitle: null == appTitle ? _self.appTitle : appTitle // ignore: cast_nullable_to_non_nullable
as String,emailLoginEnabled: null == emailLoginEnabled ? _self.emailLoginEnabled : emailLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,registrationEnabled: null == registrationEnabled ? _self.registrationEnabled : registrationEnabled // ignore: cast_nullable_to_non_nullable
as bool,passwordResetEnabled: null == passwordResetEnabled ? _self.passwordResetEnabled : passwordResetEnabled // ignore: cast_nullable_to_non_nullable
as bool,socialLogins: freezed == socialLogins ? _self._socialLogins : socialLogins // ignore: cast_nullable_to_non_nullable
as List<String>?,googleLoginEnabled: null == googleLoginEnabled ? _self.googleLoginEnabled : googleLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,githubLoginEnabled: null == githubLoginEnabled ? _self.githubLoginEnabled : githubLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,discordLoginEnabled: null == discordLoginEnabled ? _self.discordLoginEnabled : discordLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,facebookLoginEnabled: null == facebookLoginEnabled ? _self.facebookLoginEnabled : facebookLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,appleLoginEnabled: null == appleLoginEnabled ? _self.appleLoginEnabled : appleLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,openidLoginEnabled: null == openidLoginEnabled ? _self.openidLoginEnabled : openidLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,openidLabel: freezed == openidLabel ? _self.openidLabel : openidLabel // ignore: cast_nullable_to_non_nullable
as String?,openidImageUrl: freezed == openidImageUrl ? _self.openidImageUrl : openidImageUrl // ignore: cast_nullable_to_non_nullable
as String?,openidAutoRedirect: null == openidAutoRedirect ? _self.openidAutoRedirect : openidAutoRedirect // ignore: cast_nullable_to_non_nullable
as bool,samlLoginEnabled: null == samlLoginEnabled ? _self.samlLoginEnabled : samlLoginEnabled // ignore: cast_nullable_to_non_nullable
as bool,samlLabel: freezed == samlLabel ? _self.samlLabel : samlLabel // ignore: cast_nullable_to_non_nullable
as String?,samlImageUrl: freezed == samlImageUrl ? _self.samlImageUrl : samlImageUrl // ignore: cast_nullable_to_non_nullable
as String?,ldap: freezed == ldap ? _self.ldap : ldap // ignore: cast_nullable_to_non_nullable
as LdapConfig?,minPasswordLength: freezed == minPasswordLength ? _self.minPasswordLength : minPasswordLength // ignore: cast_nullable_to_non_nullable
as int?,sharedLinksEnabled: null == sharedLinksEnabled ? _self.sharedLinksEnabled : sharedLinksEnabled // ignore: cast_nullable_to_non_nullable
as bool,helpAndFaqURL: freezed == helpAndFaqURL ? _self.helpAndFaqURL : helpAndFaqURL // ignore: cast_nullable_to_non_nullable
as String?,allowAccountDeletion: null == allowAccountDeletion ? _self.allowAccountDeletion : allowAccountDeletion // ignore: cast_nullable_to_non_nullable
as bool,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as BalanceConfig?,conversationImportMaxFileSize: freezed == conversationImportMaxFileSize ? _self.conversationImportMaxFileSize : conversationImportMaxFileSize // ignore: cast_nullable_to_non_nullable
as int?,modelSpecs: freezed == modelSpecs ? _self._modelSpecs : modelSpecs // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,buildInfo: freezed == buildInfo ? _self.buildInfo : buildInfo // ignore: cast_nullable_to_non_nullable
as BuildInfo?,compactionEnabled: freezed == compactionEnabled ? _self.compactionEnabled : compactionEnabled // ignore: cast_nullable_to_non_nullable
as bool?,interfaceConfig: null == interfaceConfig ? _self.interfaceConfig : interfaceConfig // ignore: cast_nullable_to_non_nullable
as InterfaceConfig,
  ));
}

/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LdapConfigCopyWith<$Res>? get ldap {
    if (_self.ldap == null) {
    return null;
  }

  return $LdapConfigCopyWith<$Res>(_self.ldap!, (value) {
    return _then(_self.copyWith(ldap: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceConfigCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $BalanceConfigCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildInfoCopyWith<$Res>? get buildInfo {
    if (_self.buildInfo == null) {
    return null;
  }

  return $BuildInfoCopyWith<$Res>(_self.buildInfo!, (value) {
    return _then(_self.copyWith(buildInfo: value));
  });
}/// Create a copy of StartupConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InterfaceConfigCopyWith<$Res> get interfaceConfig {
  
  return $InterfaceConfigCopyWith<$Res>(_self.interfaceConfig, (value) {
    return _then(_self.copyWith(interfaceConfig: value));
  });
}
}


/// @nodoc
mixin _$LdapConfig {

 bool get enabled; bool get username;
/// Create a copy of LdapConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LdapConfigCopyWith<LdapConfig> get copyWith => _$LdapConfigCopyWithImpl<LdapConfig>(this as LdapConfig, _$identity);

  /// Serializes this LdapConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LdapConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,username);

@override
String toString() {
  return 'LdapConfig(enabled: $enabled, username: $username)';
}


}

/// @nodoc
abstract mixin class $LdapConfigCopyWith<$Res>  {
  factory $LdapConfigCopyWith(LdapConfig value, $Res Function(LdapConfig) _then) = _$LdapConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool username
});




}
/// @nodoc
class _$LdapConfigCopyWithImpl<$Res>
    implements $LdapConfigCopyWith<$Res> {
  _$LdapConfigCopyWithImpl(this._self, this._then);

  final LdapConfig _self;
  final $Res Function(LdapConfig) _then;

/// Create a copy of LdapConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? username = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LdapConfig].
extension LdapConfigPatterns on LdapConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LdapConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LdapConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LdapConfig value)  $default,){
final _that = this;
switch (_that) {
case _LdapConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LdapConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LdapConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  bool username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LdapConfig() when $default != null:
return $default(_that.enabled,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  bool username)  $default,) {final _that = this;
switch (_that) {
case _LdapConfig():
return $default(_that.enabled,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  bool username)?  $default,) {final _that = this;
switch (_that) {
case _LdapConfig() when $default != null:
return $default(_that.enabled,_that.username);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LdapConfig implements LdapConfig {
  const _LdapConfig({this.enabled = false, this.username = false});
  factory _LdapConfig.fromJson(Map<String, dynamic> json) => _$LdapConfigFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool username;

/// Create a copy of LdapConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LdapConfigCopyWith<_LdapConfig> get copyWith => __$LdapConfigCopyWithImpl<_LdapConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LdapConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LdapConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,username);

@override
String toString() {
  return 'LdapConfig(enabled: $enabled, username: $username)';
}


}

/// @nodoc
abstract mixin class _$LdapConfigCopyWith<$Res> implements $LdapConfigCopyWith<$Res> {
  factory _$LdapConfigCopyWith(_LdapConfig value, $Res Function(_LdapConfig) _then) = __$LdapConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, bool username
});




}
/// @nodoc
class __$LdapConfigCopyWithImpl<$Res>
    implements _$LdapConfigCopyWith<$Res> {
  __$LdapConfigCopyWithImpl(this._self, this._then);

  final _LdapConfig _self;
  final $Res Function(_LdapConfig) _then;

/// Create a copy of LdapConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? username = null,}) {
  return _then(_LdapConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BalanceConfig {

 bool get enabled;
/// Create a copy of BalanceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceConfigCopyWith<BalanceConfig> get copyWith => _$BalanceConfigCopyWithImpl<BalanceConfig>(this as BalanceConfig, _$identity);

  /// Serializes this BalanceConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceConfig&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'BalanceConfig(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $BalanceConfigCopyWith<$Res>  {
  factory $BalanceConfigCopyWith(BalanceConfig value, $Res Function(BalanceConfig) _then) = _$BalanceConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class _$BalanceConfigCopyWithImpl<$Res>
    implements $BalanceConfigCopyWith<$Res> {
  _$BalanceConfigCopyWithImpl(this._self, this._then);

  final BalanceConfig _self;
  final $Res Function(BalanceConfig) _then;

/// Create a copy of BalanceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceConfig].
extension BalanceConfigPatterns on BalanceConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceConfig value)  $default,){
final _that = this;
switch (_that) {
case _BalanceConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceConfig() when $default != null:
return $default(_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled)  $default,) {final _that = this;
switch (_that) {
case _BalanceConfig():
return $default(_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _BalanceConfig() when $default != null:
return $default(_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceConfig implements BalanceConfig {
  const _BalanceConfig({this.enabled = false});
  factory _BalanceConfig.fromJson(Map<String, dynamic> json) => _$BalanceConfigFromJson(json);

@override@JsonKey() final  bool enabled;

/// Create a copy of BalanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceConfigCopyWith<_BalanceConfig> get copyWith => __$BalanceConfigCopyWithImpl<_BalanceConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceConfig&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'BalanceConfig(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$BalanceConfigCopyWith<$Res> implements $BalanceConfigCopyWith<$Res> {
  factory _$BalanceConfigCopyWith(_BalanceConfig value, $Res Function(_BalanceConfig) _then) = __$BalanceConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class __$BalanceConfigCopyWithImpl<$Res>
    implements _$BalanceConfigCopyWith<$Res> {
  __$BalanceConfigCopyWithImpl(this._self, this._then);

  final _BalanceConfig _self;
  final $Res Function(_BalanceConfig) _then;

/// Create a copy of BalanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(_BalanceConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BuildInfo {

 String? get commit;
/// Create a copy of BuildInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildInfoCopyWith<BuildInfo> get copyWith => _$BuildInfoCopyWithImpl<BuildInfo>(this as BuildInfo, _$identity);

  /// Serializes this BuildInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildInfo&&(identical(other.commit, commit) || other.commit == commit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commit);

@override
String toString() {
  return 'BuildInfo(commit: $commit)';
}


}

/// @nodoc
abstract mixin class $BuildInfoCopyWith<$Res>  {
  factory $BuildInfoCopyWith(BuildInfo value, $Res Function(BuildInfo) _then) = _$BuildInfoCopyWithImpl;
@useResult
$Res call({
 String? commit
});




}
/// @nodoc
class _$BuildInfoCopyWithImpl<$Res>
    implements $BuildInfoCopyWith<$Res> {
  _$BuildInfoCopyWithImpl(this._self, this._then);

  final BuildInfo _self;
  final $Res Function(BuildInfo) _then;

/// Create a copy of BuildInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commit = freezed,}) {
  return _then(_self.copyWith(
commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildInfo].
extension BuildInfoPatterns on BuildInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildInfo value)  $default,){
final _that = this;
switch (_that) {
case _BuildInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BuildInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? commit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildInfo() when $default != null:
return $default(_that.commit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? commit)  $default,) {final _that = this;
switch (_that) {
case _BuildInfo():
return $default(_that.commit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? commit)?  $default,) {final _that = this;
switch (_that) {
case _BuildInfo() when $default != null:
return $default(_that.commit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildInfo implements BuildInfo {
  const _BuildInfo({this.commit});
  factory _BuildInfo.fromJson(Map<String, dynamic> json) => _$BuildInfoFromJson(json);

@override final  String? commit;

/// Create a copy of BuildInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildInfoCopyWith<_BuildInfo> get copyWith => __$BuildInfoCopyWithImpl<_BuildInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildInfo&&(identical(other.commit, commit) || other.commit == commit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commit);

@override
String toString() {
  return 'BuildInfo(commit: $commit)';
}


}

/// @nodoc
abstract mixin class _$BuildInfoCopyWith<$Res> implements $BuildInfoCopyWith<$Res> {
  factory _$BuildInfoCopyWith(_BuildInfo value, $Res Function(_BuildInfo) _then) = __$BuildInfoCopyWithImpl;
@override @useResult
$Res call({
 String? commit
});




}
/// @nodoc
class __$BuildInfoCopyWithImpl<$Res>
    implements _$BuildInfoCopyWith<$Res> {
  __$BuildInfoCopyWithImpl(this._self, this._then);

  final _BuildInfo _self;
  final $Res Function(_BuildInfo) _then;

/// Create a copy of BuildInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commit = freezed,}) {
  return _then(_BuildInfo(
commit: freezed == commit ? _self.commit : commit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
