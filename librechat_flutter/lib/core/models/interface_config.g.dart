// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interface_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InterfaceConfig _$InterfaceConfigFromJson(Map<String, dynamic> json) =>
    _InterfaceConfig(
      customWelcome: json['customWelcome'] as String?,
      termsOfService: json['termsOfService'] == null
          ? null
          : TermsOfServiceConfig.fromJson(
              json['termsOfService'] as Map<String, dynamic>,
            ),
      endpointsMenu: json['endpointsMenu'] as bool? ?? true,
      modelSelect: json['modelSelect'] as bool? ?? true,
      parameters: json['parameters'] as bool? ?? true,
      presets: json['presets'] as bool? ?? true,
      bookmarks: json['bookmarks'] as bool? ?? true,
      multiConvo: json['multiConvo'] as bool? ?? true,
      temporaryChat: json['temporaryChat'] as bool? ?? true,
      runCode: json['runCode'] as bool? ?? true,
      webSearch: json['webSearch'] as bool? ?? true,
      fileSearch: json['fileSearch'] as bool? ?? true,
      fileCitations: json['fileCitations'] as bool? ?? true,
      memories: json['memories'] as bool? ?? true,
      contextUsage: json['contextUsage'] as bool? ?? true,
      feedback: json['feedback'] as bool? ?? true,
      prompts: json['prompts'],
      agents: json['agents'],
      remoteAgents: json['remoteAgents'],
      skills: json['skills'],
      sharedLinks: json['sharedLinks'],
      schedules: json['schedules'],
      traceViewer: json['traceViewer'],
      mcpServers: json['mcpServers'],
      marketplace: json['marketplace'],
    );

Map<String, dynamic> _$InterfaceConfigToJson(_InterfaceConfig instance) =>
    <String, dynamic>{
      'customWelcome': ?instance.customWelcome,
      'termsOfService': ?instance.termsOfService?.toJson(),
      'endpointsMenu': instance.endpointsMenu,
      'modelSelect': instance.modelSelect,
      'parameters': instance.parameters,
      'presets': instance.presets,
      'bookmarks': instance.bookmarks,
      'multiConvo': instance.multiConvo,
      'temporaryChat': instance.temporaryChat,
      'runCode': instance.runCode,
      'webSearch': instance.webSearch,
      'fileSearch': instance.fileSearch,
      'fileCitations': instance.fileCitations,
      'memories': instance.memories,
      'contextUsage': instance.contextUsage,
      'feedback': instance.feedback,
      'prompts': ?instance.prompts,
      'agents': ?instance.agents,
      'remoteAgents': ?instance.remoteAgents,
      'skills': ?instance.skills,
      'sharedLinks': ?instance.sharedLinks,
      'schedules': ?instance.schedules,
      'traceViewer': ?instance.traceViewer,
      'mcpServers': ?instance.mcpServers,
      'marketplace': ?instance.marketplace,
    };

_TermsOfServiceConfig _$TermsOfServiceConfigFromJson(
  Map<String, dynamic> json,
) => _TermsOfServiceConfig(
  modalAcceptance: json['modalAcceptance'] as bool?,
  modalTitle: json['modalTitle'] as String?,
  modalContent: json['modalContent'],
);

Map<String, dynamic> _$TermsOfServiceConfigToJson(
  _TermsOfServiceConfig instance,
) => <String, dynamic>{
  'modalAcceptance': ?instance.modalAcceptance,
  'modalTitle': ?instance.modalTitle,
  'modalContent': ?instance.modalContent,
};
