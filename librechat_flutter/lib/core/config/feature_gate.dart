import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/startup_config.dart';
import '../network/api_client.dart';
import 'server_config.dart';
import 'server_version.dart';

/// A Server feature the Feature_Gate can hide (design Feature_Gate table).
///
/// API calls behind a feature pass it to `ApiClient.send(feature:)`, so a
/// route the Server lacks marks it missing (Req 6.7).
enum Feature {
  // Server_Config `interface.<feature>` plus the Role_Permissions USE bit.
  prompts,
  bookmarks,
  memories,
  mcpServers,
  skills,
  temporaryChat,

  /// Comparison (Compare models).
  multiConvo,
  webSearch,
  runCode,
  fileSearch,
  agents,
  marketplace,
  schedules,
  sharedLinks,
  apiKeys,

  // Server_Config only.
  presets,
  parameters,
  endpointsMenu,
  modelSelect,
  feedback,
  contextUsage,
  traceViewer,
  balance,

  // Minimum Server_Version only.
  projects,
  pin,
  quotes,
  steering,
  toolFavorites,
  serverQueue,
  archiveAll,
  memoryById,
}

/// The features whose routes answered 404 this session,
/// `ApiClient.missingFeatures` (Req 6.7).
final missingFeaturesProvider = Provider<ValueListenable<Set<Feature>>>(
  (ref) => ref.watch(apiClientProvider).missingFeatures,
);

/// The [FeatureGates] for the current [ServerInfo] and missing features.
/// Rebuilds when the config loads or changes and when a feature goes missing,
/// so screens hide it at once (Req 6.3, 6.5-6.7).
final featureGatesProvider = Provider<FeatureGates>((ref) {
  final info = ref.watch(serverConfigProvider.select((s) => s.value));
  final missing = ref.watch(missingFeaturesProvider);
  void changed() => ref.invalidateSelf();
  missing.addListener(changed);
  ref.onDispose(() => missing.removeListener(changed));
  return FeatureGates(
    info ?? const ServerInfo(config: StartupConfig()),
    missing: missing.value,
  );
});

/// Which [Feature]s the App shows, from the Server_Config, the endpoint list,
/// the Role_Permissions and the Server_Version (Req 6.3).
///
/// A feature in [missing] is off whatever the config says (Req 6.7). A
/// feature with a minimum Server_Version is off on older Servers, and an
/// unknown Server_Version counts as the [targetVersion] (Req 6.5, 6.6).
@immutable
class FeatureGates {
  const FeatureGates(this.info, {this.missing = const {}});

  final ServerInfo info;
  final Set<Feature> missing;

  static const _v0_8_7rc1 = Version(0, 8, 7, 'rc1');
  static const _v0_8_7 = Version(0, 8, 7);
  static const _v0_8_8rc1 = Version(0, 8, 8, 'rc1');
  static const _v0_8_8rc2 = Version(0, 8, 8, 'rc2');

  bool has(Feature feature) {
    if (missing.contains(feature)) return false;
    final ui = info.config.interfaceConfig;
    return switch (feature) {
      Feature.prompts => _flag(ui.prompts) && _use('PROMPTS'),
      Feature.bookmarks => ui.bookmarks && _use('BOOKMARKS'),
      Feature.memories => ui.memories && _use('MEMORIES'),
      Feature.mcpServers => _flag(ui.mcpServers) && _use('MCP_SERVERS'),
      Feature.skills => _flag(ui.skills) && _use('SKILLS'),
      Feature.temporaryChat => ui.temporaryChat && _use('TEMPORARY_CHAT'),
      Feature.multiConvo => ui.multiConvo && _use('MULTI_CONVO'),
      Feature.webSearch => ui.webSearch && _use('WEB_SEARCH'),
      Feature.runCode => ui.runCode && _use('RUN_CODE'),
      Feature.fileSearch => ui.fileSearch && _use('FILE_SEARCH'),
      Feature.agents =>
        _flag(ui.agents) &&
            _use('AGENTS') &&
            info.endpoints.containsKey('agents'),
      Feature.marketplace =>
        _flag(ui.marketplace) && _use('MARKETPLACE') && has(Feature.agents),
      Feature.schedules =>
        _flag(ui.schedules, absent: false) && _use('SCHEDULES'),
      Feature.sharedLinks =>
        info.config.sharedLinksEnabled && _use('SHARED_LINKS'),
      Feature.apiKeys => _flag(ui.remoteAgents) && _use('REMOTE_AGENTS'),
      Feature.presets => ui.presets,
      Feature.parameters => ui.parameters,
      Feature.endpointsMenu => ui.endpointsMenu,
      Feature.modelSelect => ui.modelSelect,
      Feature.feedback => ui.feedback,
      Feature.contextUsage => ui.contextUsage,
      Feature.traceViewer => switch (ui.traceViewer) {
        Map map => map['enabled'] == true,
        _ => false,
      },
      Feature.balance => info.config.balance?.enabled == true,
      Feature.projects => _atLeast(_v0_8_7rc1),
      Feature.pin || Feature.quotes => _atLeast(_v0_8_7),
      Feature.steering || Feature.toolFavorites => _atLeast(_v0_8_8rc1),
      Feature.serverQueue || Feature.archiveAll => _atLeast(_v0_8_8rc2),
      Feature.memoryById => _atLeast(_v0_8_8rc2) && has(Feature.memories),
    };
  }

  /// An `interface` union flag: [absent] when null, a `bool` as is, an
  /// object on unless its `use` is false, anything else on.
  static bool _flag(Object? value, {bool absent = true}) => switch (value) {
    null => absent,
    bool on => on,
    Map map => map['use'] != false,
    _ => true,
  };

  /// The Role_Permissions USE bit of [type]: granted until the role loads
  /// and when the type or its bit is absent, denied only by an explicit
  /// false (KMP UserRolePermissions.hasAccess).
  bool _use(String type) {
    final role = info.role;
    return role == null || role.permissions?[type]?['USE'] != false;
  }

  bool _atLeast(Version minimum) => (info.version ?? targetVersion) >= minimum;
}
