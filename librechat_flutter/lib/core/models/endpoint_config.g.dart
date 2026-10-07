// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'endpoint_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EndpointConfig _$EndpointConfigFromJson(Map<String, dynamic> json) =>
    _EndpointConfig(
      type: json['type'] as String?,
      order: (json['order'] as num?)?.toInt(),
      iconURL: json['iconURL'] as String?,
      modelDisplayLabel: json['modelDisplayLabel'] as String?,
      userProvide: json['userProvide'] as bool?,
      userProvideURL: json['userProvideURL'] as bool?,
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$EndpointConfigToJson(_EndpointConfig instance) =>
    <String, dynamic>{
      'type': ?instance.type,
      'order': ?instance.order,
      'iconURL': ?instance.iconURL,
      'modelDisplayLabel': ?instance.modelDisplayLabel,
      'userProvide': ?instance.userProvide,
      'userProvideURL': ?instance.userProvideURL,
      'capabilities': ?instance.capabilities,
    };
