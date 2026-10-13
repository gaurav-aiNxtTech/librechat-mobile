import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/feature_gate.dart';
import '../../core/network/api_client.dart';

part 'agents_api.freezed.dart';
part 'agents_api.g.dart';

/// An agent as `GET /api/agents` lists it, with only the fields the App
/// reads so far. The Agent_Marketplace task adds the rest.
@freezed
abstract class Agent with _$Agent {
  const factory Agent({
    required String id,
    String? name,
    String? description,
    @AvatarPathConverter() @JsonKey(name: 'avatar') String? avatarPath,
    @JsonKey(name: 'conversation_starters')
    @Default(<String>[])
    List<String> conversationStarters,
    bool? isPublic,
  }) = _Agent;

  factory Agent.fromJson(Map<String, Object?> json) => _$AgentFromJson(json);
}

/// Reads an agent's `avatar`, which is an object with a `filepath` or a
/// plain path, as the path; a blank one reads as null.
class AvatarPathConverter implements JsonConverter<String?, Object?> {
  const AvatarPathConverter();

  @override
  String? fromJson(Object? json) {
    final path = json is Map ? json['filepath'] : json;
    return path is String && path.trim().isNotEmpty ? path : null;
  }

  @override
  Object? toJson(String? path) => path == null ? null : {'filepath': path};
}

/// The [AgentsApi] on the app's [ApiClient]. Tests override it.
final agentsApiProvider = Provider<AgentsApi>(
  (ref) => AgentsApi(ref.read(apiClientProvider)),
);

/// The agents the user can chat with, for the Model_Selector (Req 21.2).
/// Empty when the Feature_Gate hides agents. Reloads when the user changes.
final agentsProvider = FutureProvider<List<Agent>>((ref) async {
  ref.watch(authServiceProvider.select((a) => a.session?.user.id));
  final enabled = ref.watch(
    featureGatesProvider.select((g) => g.has(Feature.agents)),
  );
  if (!enabled) return const [];
  return ref.read(agentsApiProvider).list();
});

/// The agent routes.
class AgentsApi {
  AgentsApi(this._api);

  final ApiClient _api;

  /// `GET /api/agents`: the `data` list. Entries that are not objects or
  /// have no `id` are skipped.
  Future<List<Agent>> list() => _api.json(
    'GET',
    '/api/agents',
    (json) => [
      if (json case {'data': final List data})
        for (final entry in data)
          if (entry is Map && entry['id'] is String)
            Agent.fromJson(entry.cast<String, Object?>()),
    ],
    feature: Feature.agents,
  );
}
