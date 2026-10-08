// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleCadence _$ScheduleCadenceFromJson(Map<String, dynamic> json) =>
    _ScheduleCadence(
      frequency: json['frequency'] as String,
      hour: (json['hour'] as num?)?.toInt(),
      minute: (json['minute'] as num?)?.toInt(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      expression: json['expression'] as String?,
    );

Map<String, dynamic> _$ScheduleCadenceToJson(_ScheduleCadence instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'hour': ?instance.hour,
      'minute': ?instance.minute,
      'daysOfWeek': ?instance.daysOfWeek,
      'expression': ?instance.expression,
    };
