// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StartupConfig _$StartupConfigFromJson(Map<String, dynamic> json) =>
    _StartupConfig(
      appTitle: json['appTitle'] as String? ?? 'LibreChat',
      emailLoginEnabled: json['emailLoginEnabled'] as bool? ?? true,
      registrationEnabled: json['registrationEnabled'] as bool? ?? false,
      passwordResetEnabled: json['passwordResetEnabled'] as bool? ?? false,
      socialLogins: (json['socialLogins'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      googleLoginEnabled: json['googleLoginEnabled'] as bool? ?? false,
      githubLoginEnabled: json['githubLoginEnabled'] as bool? ?? false,
      discordLoginEnabled: json['discordLoginEnabled'] as bool? ?? false,
      facebookLoginEnabled: json['facebookLoginEnabled'] as bool? ?? false,
      appleLoginEnabled: json['appleLoginEnabled'] as bool? ?? false,
      openidLoginEnabled: json['openidLoginEnabled'] as bool? ?? false,
      openidLabel: json['openidLabel'] as String?,
      openidImageUrl: json['openidImageUrl'] as String?,
      openidAutoRedirect: json['openidAutoRedirect'] as bool? ?? false,
      samlLoginEnabled: json['samlLoginEnabled'] as bool? ?? false,
      samlLabel: json['samlLabel'] as String?,
      samlImageUrl: json['samlImageUrl'] as String?,
      ldap: json['ldap'] == null
          ? null
          : LdapConfig.fromJson(json['ldap'] as Map<String, dynamic>),
      minPasswordLength: (json['minPasswordLength'] as num?)?.toInt(),
      sharedLinksEnabled: json['sharedLinksEnabled'] as bool? ?? false,
      helpAndFaqURL: json['helpAndFaqURL'] as String?,
      allowAccountDeletion: json['allowAccountDeletion'] as bool? ?? true,
      balance: json['balance'] == null
          ? null
          : BalanceConfig.fromJson(json['balance'] as Map<String, dynamic>),
      conversationImportMaxFileSize:
          (json['conversationImportMaxFileSize'] as num?)?.toInt(),
      modelSpecs: json['modelSpecs'] as Map<String, dynamic>?,
      version: json['version'] as String?,
      buildInfo: json['buildInfo'] == null
          ? null
          : BuildInfo.fromJson(json['buildInfo'] as Map<String, dynamic>),
      compactionEnabled: json['compactionEnabled'] as bool?,
      interfaceConfig: json['interface'] == null
          ? const InterfaceConfig()
          : InterfaceConfig.fromJson(json['interface'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StartupConfigToJson(_StartupConfig instance) =>
    <String, dynamic>{
      'appTitle': instance.appTitle,
      'emailLoginEnabled': instance.emailLoginEnabled,
      'registrationEnabled': instance.registrationEnabled,
      'passwordResetEnabled': instance.passwordResetEnabled,
      'socialLogins': ?instance.socialLogins,
      'googleLoginEnabled': instance.googleLoginEnabled,
      'githubLoginEnabled': instance.githubLoginEnabled,
      'discordLoginEnabled': instance.discordLoginEnabled,
      'facebookLoginEnabled': instance.facebookLoginEnabled,
      'appleLoginEnabled': instance.appleLoginEnabled,
      'openidLoginEnabled': instance.openidLoginEnabled,
      'openidLabel': ?instance.openidLabel,
      'openidImageUrl': ?instance.openidImageUrl,
      'openidAutoRedirect': instance.openidAutoRedirect,
      'samlLoginEnabled': instance.samlLoginEnabled,
      'samlLabel': ?instance.samlLabel,
      'samlImageUrl': ?instance.samlImageUrl,
      'ldap': ?instance.ldap?.toJson(),
      'minPasswordLength': ?instance.minPasswordLength,
      'sharedLinksEnabled': instance.sharedLinksEnabled,
      'helpAndFaqURL': ?instance.helpAndFaqURL,
      'allowAccountDeletion': instance.allowAccountDeletion,
      'balance': ?instance.balance?.toJson(),
      'conversationImportMaxFileSize': ?instance.conversationImportMaxFileSize,
      'modelSpecs': ?instance.modelSpecs,
      'version': ?instance.version,
      'buildInfo': ?instance.buildInfo?.toJson(),
      'compactionEnabled': ?instance.compactionEnabled,
      'interface': instance.interfaceConfig.toJson(),
    };

_LdapConfig _$LdapConfigFromJson(Map<String, dynamic> json) => _LdapConfig(
  enabled: json['enabled'] as bool? ?? false,
  username: json['username'] as bool? ?? false,
);

Map<String, dynamic> _$LdapConfigToJson(_LdapConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'username': instance.username,
    };

_BalanceConfig _$BalanceConfigFromJson(Map<String, dynamic> json) =>
    _BalanceConfig(enabled: json['enabled'] as bool? ?? false);

Map<String, dynamic> _$BalanceConfigToJson(_BalanceConfig instance) =>
    <String, dynamic>{'enabled': instance.enabled};

_BuildInfo _$BuildInfoFromJson(Map<String, dynamic> json) =>
    _BuildInfo(commit: json['commit'] as String?);

Map<String, dynamic> _$BuildInfoToJson(_BuildInfo instance) =>
    <String, dynamic>{'commit': ?instance.commit};
