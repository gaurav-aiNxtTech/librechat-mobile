// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_steer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingSteer _$PendingSteerFromJson(Map<String, dynamic> json) =>
    _PendingSteer(
      steerId: json['steerId'] as String?,
      clientSteerId: json['clientSteerId'] as String?,
      text: json['text'] as String?,
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: (json['createdAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PendingSteerToJson(_PendingSteer instance) =>
    <String, dynamic>{
      'steerId': ?instance.steerId,
      'clientSteerId': ?instance.clientSteerId,
      'text': ?instance.text,
      'quotes': ?instance.quotes,
      'createdAt': ?instance.createdAt,
    };
