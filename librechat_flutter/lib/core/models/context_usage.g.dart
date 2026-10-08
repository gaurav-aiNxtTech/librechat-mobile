// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContextUsage _$ContextUsageFromJson(Map<String, dynamic> json) =>
    _ContextUsage(
      contextBudget: (json['contextBudget'] as num?)?.toInt(),
      remainingContextTokens: (json['remainingContextTokens'] as num?)?.toInt(),
      prePruneContextTokens: (json['prePruneContextTokens'] as num?)?.toInt(),
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      runId: json['runId'] as String?,
      agentId: json['agentId'] as String?,
    );

Map<String, dynamic> _$ContextUsageToJson(_ContextUsage instance) =>
    <String, dynamic>{
      'contextBudget': ?instance.contextBudget,
      'remainingContextTokens': ?instance.remainingContextTokens,
      'prePruneContextTokens': ?instance.prePruneContextTokens,
      'breakdown': ?instance.breakdown,
      'runId': ?instance.runId,
      'agentId': ?instance.agentId,
    };
