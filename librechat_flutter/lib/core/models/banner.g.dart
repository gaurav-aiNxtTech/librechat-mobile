// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerBanner _$ServerBannerFromJson(Map<String, dynamic> json) =>
    _ServerBanner(
      bannerId: json['bannerId'] as String?,
      message: json['message'] as String?,
      type: json['type'] as String?,
      persistable: json['persistable'] as bool?,
      displayFrom: const UtcDateTimeConverter().fromJson(json['displayFrom']),
      displayTo: const UtcDateTimeConverter().fromJson(json['displayTo']),
    );

Map<String, dynamic> _$ServerBannerToJson(_ServerBanner instance) =>
    <String, dynamic>{
      'bannerId': ?instance.bannerId,
      'message': ?instance.message,
      'type': ?instance.type,
      'persistable': ?instance.persistable,
      'displayFrom': ?const UtcDateTimeConverter().toJson(instance.displayFrom),
      'displayTo': ?const UtcDateTimeConverter().toJson(instance.displayTo),
    };
