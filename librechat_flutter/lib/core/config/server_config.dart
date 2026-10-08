import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../auth/auth_service.dart';
import '../models/endpoint_config.dart';
import '../models/role_permissions.dart';
import '../models/startup_config.dart';
import '../network/api_client.dart';
import '../network/app_exception.dart';
import '../storage/cache_db.dart';
import 'server_version.dart';

/// What the App knows about the Server: the Server_Config, the endpoint
/// list, the models per endpoint and the user's Role_Permissions.
///
/// While signed out only [config] is loaded, so [endpoints] and [models] are
/// empty and [role] is null. [refreshError] is the last fetch's failure while
/// cached data stays on screen (Req 6.2, 45.3), or null after a clean fetch.
/// [version] is the Server_Version read from [config].
@immutable
class ServerInfo {
  const ServerInfo({
    required this.config,
    this.endpoints = const {},
    this.models = const {},
    this.role,
    this.refreshError,
  });

  final StartupConfig config;
  final Map<String, EndpointConfig> endpoints;
  final Map<String, List<String>> models;

  /// Null until `GET /api/roles/{role}` loads once; USE then counts as
  /// granted.
  final RolePermissions? role;
  final AppException? refreshError;

  /// The Server_Version, or null while it is unknown (Req 6.6).
  Version? get version => serverVersionOf(config);
}

/// Fetches the Server's configuration and keeps the last copy in the
/// `config`, `endpoints`, `models` and `role` cache entries.
class ConfigRepository {
  ConfigRepository(this._api, this._db);

  static const configKey = 'config';
  static const endpointsKey = 'endpoints';
  static const modelsKey = 'models';
  static const roleKey = 'role';

  final ApiClient _api;
  final CacheDb _db;

  /// `GET /api/config` on the typed [url] with the typed [headers] and no
  /// session, for the Server_URL_Screen (Req 5.7, 7.3). Writes nothing.
  Future<StartupConfig> probe(String url, Map<String, String> headers) =>
      _api.json(
        'GET',
        '/api/config',
        _decodeConfig,
        serverUrl: url,
        customHeaders: headers,
      );

  /// `GET /api/config`.
  Future<StartupConfig> fetchConfig() =>
      _api.json('GET', '/api/config', _decodeConfig);

  /// `GET /api/endpoints`: endpoint name → its config.
  Future<Map<String, EndpointConfig>> fetchEndpoints() =>
      _api.json('GET', '/api/endpoints', _decodeEndpoints);

  /// `GET /api/models`: endpoint name → its model names.
  Future<Map<String, List<String>>> fetchModels() =>
      _api.json('GET', '/api/models', _decodeModels);

  /// `GET /api/roles/{role}`.
  Future<RolePermissions> fetchRole(String role) =>
      _api.json('GET', '/api/roles/${Uri.encodeComponent(role)}', _decodeRole);

  /// The cached entries, or null when no Server_Config is cached. Signed out,
  /// only the config is read. An entry that no longer decodes counts as
  /// absent.
  Future<ServerInfo?> readCache({required bool signedIn}) async {
    final keys = signedIn
        ? const [configKey, endpointsKey, modelsKey, roleKey]
        : const [configKey];
    final rows = await (_db.select(
      _db.cacheEntries,
    )..where((t) => t.key.isIn(keys))).get();
    final text = {for (final row in rows) row.key: row.json};
    final config = _fromCache(text[configKey], _decodeConfig);
    if (config == null) return null;
    return ServerInfo(
      config: config,
      endpoints: _fromCache(text[endpointsKey], _decodeEndpoints) ?? const {},
      models: _fromCache(text[modelsKey], _decodeModels) ?? const {},
      role: _fromCache(text[roleKey], _decodeRole),
    );
  }

  /// Writes each non-null value to its cache entry. The Server_URL_Screen
  /// caches the probed config through this too.
  Future<void> save({
    StartupConfig? config,
    Map<String, EndpointConfig>? endpoints,
    Map<String, List<String>>? models,
    RolePermissions? role,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    CacheEntriesCompanion entry(String key, Object json) =>
        CacheEntriesCompanion(
          key: Value(key),
          json: Value(jsonEncode(json)),
          updatedAt: Value(now),
        );
    return _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.cacheEntries, [
        if (config != null) entry(configKey, config.toJson()),
        if (endpoints != null)
          entry(endpointsKey, {
            for (final MapEntry(:key, :value) in endpoints.entries)
              key: value.toJson(),
          }),
        if (models != null) entry(modelsKey, models),
        if (role != null) entry(roleKey, role.toJson()),
      ]),
    );
  }

  static T? _fromCache<T>(String? text, T Function(Object? json) decode) {
    if (text == null) return null;
    try {
      return decode(jsonDecode(text));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on CheckedFromJsonException {
      return null;
    }
  }

  static StartupConfig _decodeConfig(Object? json) =>
      StartupConfig.fromJson((json! as Map).cast<String, Object?>());

  /// Entries whose value is not an object are skipped.
  static Map<String, EndpointConfig> _decodeEndpoints(Object? json) => {
    for (final MapEntry(:key, :value) in (json! as Map).entries)
      if (value is Map)
        key as String: EndpointConfig.fromJson(value.cast<String, Object?>()),
  };

  /// Entries whose value is not a list, and names that are not strings, are
  /// skipped.
  static Map<String, List<String>> _decodeModels(Object? json) => {
    for (final MapEntry(:key, :value) in (json! as Map).entries)
      if (value is List) key as String: [...value.whereType<String>()],
  };

  static RolePermissions _decodeRole(Object? json) =>
      RolePermissions.fromJson((json! as Map).cast<String, Object?>());
}

/// The Server's configuration for the current user and Server_URL, kept
/// alive. See [ServerConfigNotifier].
final serverConfigProvider =
    AsyncNotifierProvider<ServerConfigNotifier, ServerInfo>(
      ServerConfigNotifier.new,
    );

/// Shows the cached [ServerInfo] first, then fetches the Server's copy and
/// caches it (Req 45.2). Rebuilds on sign-in, sign-out and Server change, so
/// the config and Role_Permissions load after each sign-in (Req 6.1).
///
/// Signed out it fetches only `/api/config`, for the Login_Screen. Signed in
/// it also fetches `/api/endpoints`, `/api/models` and `/api/roles/{role}`.
/// A failed fetch keeps the cached data and sets [ServerInfo.refreshError];
/// the state is an error only when no Server_Config is cached (Req 6.2,
/// 45.3).
class ServerConfigNotifier extends AsyncNotifier<ServerInfo> {
  @override
  Future<ServerInfo> build() async {
    final userId = ref.watch(
      authServiceProvider.select((a) => a.session?.user.id),
    );
    ref.watch(authServiceProvider.select((a) => a.serverUrl));

    final cached = await _repository().readCache(signedIn: userId != null);
    if (cached == null) return _fetch(null);
    // A rebuild during the read supersedes this build and fetches itself.
    if (ref.mounted) {
      unawaited(
        _fetch(cached).then((info) {
          if (ref.mounted) state = AsyncData(info);
        }),
      );
    }
    return cached;
  }

  /// Fetches again, keeping the current data on screen. Without data the
  /// state shows loading, then the result or the error.
  Future<void> refresh() async {
    final current = state.value;
    if (current == null) state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _fetch(current));
    if (ref.mounted) state = next;
  }

  ConfigRepository _repository() =>
      ConfigRepository(ref.read(apiClientProvider), ref.read(cacheDbProvider));

  /// Fetches every part for the current user in parallel, caches what
  /// arrived and merges it over [cached]. Throws only when neither the
  /// fetch nor [cached] has a Server_Config.
  ///
  /// Everything is read from [ref] before the first await, because a
  /// rebuild unmounts this [ref].
  Future<ServerInfo> _fetch(ServerInfo? cached) async {
    final repository = _repository();
    final session = ref.read(authServiceProvider).session;
    final role = session?.user.role;

    AppException? error;
    Future<T?> attempt<T>(Future<T> Function() load) async {
      try {
        return await load();
      } on AppException catch (e) {
        error ??= e;
      } catch (_) {
        error ??= AppException(FailureKind.unknown, signedIn: session != null);
      }
      return null;
    }

    final configFuture = attempt(repository.fetchConfig);
    final endpointsFuture = session != null
        ? attempt(repository.fetchEndpoints)
        : Future.value(null);
    final modelsFuture = session != null
        ? attempt(repository.fetchModels)
        : Future.value(null);
    final roleFuture = role != null
        ? attempt(() => repository.fetchRole(role))
        : Future.value(null);
    final config = await configFuture;
    final endpoints = await endpointsFuture;
    final models = await modelsFuture;
    final permissions = await roleFuture;

    final shown = config ?? cached?.config;
    if (shown == null) throw error!;
    // A sign-out or Server change during the fetch already cleared the
    // Cache; this user's data must not land in it again.
    if (ref.mounted) {
      await attempt(
        () => repository.save(
          config: config,
          endpoints: endpoints,
          models: models,
          role: permissions,
        ),
      );
    }
    return ServerInfo(
      config: shown,
      endpoints: endpoints ?? cached?.endpoints ?? const {},
      models: models ?? cached?.models ?? const {},
      role: permissions ?? cached?.role,
      refreshError: error,
    );
  }
}
