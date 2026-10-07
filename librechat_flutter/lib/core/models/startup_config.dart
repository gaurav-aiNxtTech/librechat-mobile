import 'package:freezed_annotation/freezed_annotation.dart';

import 'interface_config.dart';

part 'startup_config.freezed.dart';
part 'startup_config.g.dart';

/// `GET /api/config`, holding only the fields the App reads. Defaults follow the KMP model.
@freezed
abstract class StartupConfig with _$StartupConfig {
  const factory StartupConfig({
    @Default('LibreChat') String appTitle,
    @Default(true) bool emailLoginEnabled,
    @Default(false) bool registrationEnabled,
    @Default(false) bool passwordResetEnabled,
    List<String>? socialLogins,
    @Default(false) bool googleLoginEnabled,
    @Default(false) bool githubLoginEnabled,
    @Default(false) bool discordLoginEnabled,
    @Default(false) bool facebookLoginEnabled,
    @Default(false) bool appleLoginEnabled,
    @Default(false) bool openidLoginEnabled,
    String? openidLabel,
    String? openidImageUrl,
    @Default(false) bool openidAutoRedirect,
    @Default(false) bool samlLoginEnabled,
    String? samlLabel,
    String? samlImageUrl,
    LdapConfig? ldap,
    int? minPasswordLength,
    @Default(false) bool sharedLinksEnabled,
    String? helpAndFaqURL,
    @Default(true) bool allowAccountDeletion,
    BalanceConfig? balance,
    int? conversationImportMaxFileSize,
    Map<String, Object?>? modelSpecs,
    String? version,
    BuildInfo? buildInfo,
    // Null on servers that predate compaction, which is the gate, so it has no default.
    bool? compactionEnabled,
    @JsonKey(name: 'interface') @Default(InterfaceConfig()) InterfaceConfig interfaceConfig,
  }) = _StartupConfig;

  factory StartupConfig.fromJson(Map<String, Object?> json) => _$StartupConfigFromJson(json);
}

@freezed
abstract class LdapConfig with _$LdapConfig {
  const factory LdapConfig({
    @Default(false) bool enabled,
    @Default(false) bool username,
  }) = _LdapConfig;

  factory LdapConfig.fromJson(Map<String, Object?> json) => _$LdapConfigFromJson(json);
}

@freezed
abstract class BalanceConfig with _$BalanceConfig {
  const factory BalanceConfig({@Default(false) bool enabled}) = _BalanceConfig;

  factory BalanceConfig.fromJson(Map<String, Object?> json) => _$BalanceConfigFromJson(json);
}

@freezed
abstract class BuildInfo with _$BuildInfo {
  const factory BuildInfo({String? commit}) = _BuildInfo;

  factory BuildInfo.fromJson(Map<String, Object?> json) => _$BuildInfoFromJson(json);
}
