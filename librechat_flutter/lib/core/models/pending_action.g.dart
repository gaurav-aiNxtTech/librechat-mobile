// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingAction _$PendingActionFromJson(Map<String, dynamic> json) =>
    _PendingAction(
      actionId: json['actionId'] as String?,
      streamId: json['streamId'] as String?,
      conversationId: json['conversationId'] as String?,
      runId: json['runId'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      expiresAt: (json['expiresAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PendingActionToJson(_PendingAction instance) =>
    <String, dynamic>{
      'actionId': ?instance.actionId,
      'streamId': ?instance.streamId,
      'conversationId': ?instance.conversationId,
      'runId': ?instance.runId,
      'payload': ?instance.payload,
      'expiresAt': ?instance.expiresAt,
    };
