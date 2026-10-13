// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileConfig _$FileConfigFromJson(Map<String, dynamic> json) => _FileConfig(
  endpoints:
      (json['endpoints'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, EndpointFileConfig.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, EndpointFileConfig>{},
  serverFileSizeLimit: (json['serverFileSizeLimit'] as num?)?.toInt(),
  text: json['text'] == null
      ? null
      : MimeTypesConfig.fromJson(json['text'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FileConfigToJson(_FileConfig instance) =>
    <String, dynamic>{
      'endpoints': instance.endpoints.map((k, e) => MapEntry(k, e.toJson())),
      'serverFileSizeLimit': ?instance.serverFileSizeLimit,
      'text': ?instance.text?.toJson(),
    };

_MimeTypesConfig _$MimeTypesConfigFromJson(Map<String, dynamic> json) =>
    _MimeTypesConfig(
      supportedMimeTypes:
          (json['supportedMimeTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$MimeTypesConfigToJson(_MimeTypesConfig instance) =>
    <String, dynamic>{'supportedMimeTypes': instance.supportedMimeTypes};

_EndpointFileConfig _$EndpointFileConfigFromJson(Map<String, dynamic> json) =>
    _EndpointFileConfig(
      fileLimit: (json['fileLimit'] as num?)?.toInt(),
      fileSizeLimit: (json['fileSizeLimit'] as num?)?.toInt(),
      totalSizeLimit: (json['totalSizeLimit'] as num?)?.toInt(),
      supportedMimeTypes:
          (json['supportedMimeTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      disabled: json['disabled'] as bool?,
    );

Map<String, dynamic> _$EndpointFileConfigToJson(_EndpointFileConfig instance) =>
    <String, dynamic>{
      'fileLimit': ?instance.fileLimit,
      'fileSizeLimit': ?instance.fileSizeLimit,
      'totalSizeLimit': ?instance.totalSizeLimit,
      'supportedMimeTypes': instance.supportedMimeTypes,
      'disabled': ?instance.disabled,
    };
