import 'package:freezed_annotation/freezed_annotation.dart';

part 'interface_config.freezed.dart';
part 'interface_config.g.dart';

/// `StartupConfig.interface`. An absent boolean flag is on, which is the Server's default. The
/// unions are `bool` or an object and are read by FeatureGates.
@freezed
abstract class InterfaceConfig with _$InterfaceConfig {
  const factory InterfaceConfig({
    String? customWelcome,
    TermsOfServiceConfig? termsOfService,
    @Default(true) bool endpointsMenu,
    @Default(true) bool modelSelect,
    @Default(true) bool parameters,
    @Default(true) bool presets,
    @Default(true) bool bookmarks,
    @Default(true) bool multiConvo,
    @Default(true) bool temporaryChat,
    @Default(true) bool runCode,
    @Default(true) bool webSearch,
    @Default(true) bool fileSearch,
    @Default(true) bool fileCitations,
    @Default(true) bool memories,
    @Default(true) bool contextUsage,
    @Default(true) bool feedback,
    Object? prompts,
    Object? agents,
    Object? remoteAgents,
    Object? skills,
    Object? sharedLinks,
    Object? schedules,
    Object? traceViewer,
    Object? mcpServers,
    Object? marketplace,
  }) = _InterfaceConfig;

  factory InterfaceConfig.fromJson(Map<String, Object?> json) =>
      _$InterfaceConfigFromJson(json);
}

/// `interface.termsOfService`. `modalContent` is a string or a list of strings.
@freezed
abstract class TermsOfServiceConfig with _$TermsOfServiceConfig {
  const factory TermsOfServiceConfig({
    bool? modalAcceptance,
    String? modalTitle,
    Object? modalContent,
  }) = _TermsOfServiceConfig;

  factory TermsOfServiceConfig.fromJson(Map<String, Object?> json) =>
      _$TermsOfServiceConfigFromJson(json);
}
