import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/role_permissions.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';

import '../../support/fakes.dart';

FeatureGates gates({
  InterfaceConfig ui = const InterfaceConfig(),
  String? version,
  bool sharedLinksEnabled = false,
  BalanceConfig? balance,
  Map<String, EndpointConfig> endpoints = const {},
  RolePermissions? role,
  Set<Feature> missing = const {},
}) => FeatureGates(
  ServerInfo(
    config: StartupConfig(
      interfaceConfig: ui,
      version: version,
      sharedLinksEnabled: sharedLinksEnabled,
      balance: balance,
    ),
    endpoints: endpoints,
    role: role,
  ),
  missing: missing,
);

RolePermissions role(Map<String, Map<String, bool>> permissions) =>
    RolePermissions(name: 'USER', permissions: permissions);

const agentsEndpoint = {'agents': EndpointConfig()};

void main() {
  group('interface flags', () {
    test('absent flags are on', () {
      final g = gates();
      for (final f in [
        Feature.prompts,
        Feature.bookmarks,
        Feature.memories,
        Feature.mcpServers,
        Feature.skills,
        Feature.temporaryChat,
        Feature.multiConvo,
        Feature.webSearch,
        Feature.runCode,
        Feature.fileSearch,
        Feature.apiKeys,
        Feature.presets,
        Feature.parameters,
        Feature.endpointsMenu,
        Feature.modelSelect,
        Feature.feedback,
        Feature.contextUsage,
      ]) {
        expect(g.has(f), isTrue, reason: f.name);
      }
    });

    test('schedules and traceViewer are off when absent', () {
      expect(gates().has(Feature.schedules), isFalse);
      expect(gates().has(Feature.traceViewer), isFalse);
    });

    test('object and bool union flags', () {
      bool prompts(Object? value) =>
          gates(ui: InterfaceConfig(prompts: value)).has(Feature.prompts);
      expect(prompts({'use': false}), isFalse);
      expect(prompts(false), isFalse);
      expect(prompts({'use': true}), isTrue);
      expect(prompts(<String, Object?>{}), isTrue);
      expect(prompts(true), isTrue);
      expect(
        gates(
          ui: const InterfaceConfig(schedules: true),
        ).has(Feature.schedules),
        isTrue,
      );
      expect(
        gates(
          ui: const InterfaceConfig(schedules: {'use': false}),
        ).has(Feature.schedules),
        isFalse,
      );
    });

    test('plain bool flags turn features off', () {
      expect(
        gates(
          ui: const InterfaceConfig(bookmarks: false),
        ).has(Feature.bookmarks),
        isFalse,
      );
      expect(
        gates(ui: const InterfaceConfig(presets: false)).has(Feature.presets),
        isFalse,
      );
    });

    test('traceViewer needs enabled: true', () {
      expect(
        gates(
          ui: const InterfaceConfig(traceViewer: {'enabled': true}),
        ).has(Feature.traceViewer),
        isTrue,
      );
      expect(
        gates(
          ui: const InterfaceConfig(traceViewer: <String, Object?>{}),
        ).has(Feature.traceViewer),
        isFalse,
      );
      expect(
        gates(
          ui: const InterfaceConfig(traceViewer: true),
        ).has(Feature.traceViewer),
        isFalse,
      );
    });
  });

  group('Role_Permissions USE', () {
    test('granted before the role loads', () {
      expect(gates().has(Feature.prompts), isTrue);
    });

    test('an explicit USE false hides the feature', () {
      final g = gates(
        role: role({
          'PROMPTS': {'USE': false},
        }),
      );
      expect(g.has(Feature.prompts), isFalse);
      expect(g.has(Feature.bookmarks), isTrue);
    });

    test('an absent type or bit keeps the feature on', () {
      final g = gates(
        role: role({
          'PROMPTS': {'CREATE': false},
        }),
      );
      expect(g.has(Feature.prompts), isTrue);
      expect(g.has(Feature.memories), isTrue);
      expect(
        gates(role: const RolePermissions(name: 'USER')).has(Feature.prompts),
        isTrue,
      );
    });
  });

  group('agents and marketplace', () {
    test('agents needs the agents endpoint', () {
      expect(gates().has(Feature.agents), isFalse);
      expect(gates(endpoints: agentsEndpoint).has(Feature.agents), isTrue);
      expect(
        gates(
          endpoints: agentsEndpoint,
          role: role({
            'AGENTS': {'USE': false},
          }),
        ).has(Feature.agents),
        isFalse,
      );
    });

    test('marketplace is off when agents is off', () {
      expect(gates().has(Feature.marketplace), isFalse);
      expect(gates(endpoints: agentsEndpoint).has(Feature.marketplace), isTrue);
      expect(
        gates(
          endpoints: agentsEndpoint,
          ui: const InterfaceConfig(agents: false),
        ).has(Feature.marketplace),
        isFalse,
      );
      expect(
        gates(
          endpoints: agentsEndpoint,
          ui: const InterfaceConfig(marketplace: {'use': false}),
        ).has(Feature.marketplace),
        isFalse,
      );
    });
  });

  test('sharedLinks follows sharedLinksEnabled', () {
    expect(gates().has(Feature.sharedLinks), isFalse);
    expect(gates(sharedLinksEnabled: true).has(Feature.sharedLinks), isTrue);
    expect(
      gates(
        sharedLinksEnabled: true,
        role: role({
          'SHARED_LINKS': {'USE': false},
        }),
      ).has(Feature.sharedLinks),
      isFalse,
    );
  });

  test('apiKeys follows remoteAgents', () {
    expect(
      gates(
        ui: const InterfaceConfig(remoteAgents: false),
      ).has(Feature.apiKeys),
      isFalse,
    );
    expect(
      gates(
        role: role({
          'REMOTE_AGENTS': {'USE': false},
        }),
      ).has(Feature.apiKeys),
      isFalse,
    );
  });

  test('balance follows balance.enabled', () {
    expect(gates().has(Feature.balance), isFalse);
    expect(gates(balance: const BalanceConfig()).has(Feature.balance), isFalse);
    expect(
      gates(balance: const BalanceConfig(enabled: true)).has(Feature.balance),
      isTrue,
    );
  });

  group('minimum Server_Version (Req 6.5, 6.6)', () {
    const thresholds = {
      Feature.projects: ('0.8.6', '0.8.7-rc1'),
      Feature.pin: ('0.8.7-rc1', '0.8.7'),
      Feature.quotes: ('0.8.7-rc1', '0.8.7'),
      Feature.steering: ('0.8.7', '0.8.8-rc1'),
      Feature.toolFavorites: ('0.8.7', '0.8.8-rc1'),
      Feature.serverQueue: ('0.8.8-rc1', '0.8.8-rc2'),
      Feature.archiveAll: ('0.8.8-rc1', '0.8.8-rc2'),
      Feature.memoryById: ('0.8.8-rc1', '0.8.8-rc2'),
    };

    for (final MapEntry(key: feature, value: (below, at))
        in thresholds.entries) {
      test('${feature.name}: off on $below, on from $at', () {
        expect(gates(version: below).has(feature), isFalse);
        expect(gates(version: at).has(feature), isTrue);
      });
    }

    test('0.8.8-rc1 shows steering but hides serverQueue', () {
      final g = gates(version: '0.8.8-rc1');
      expect(g.has(Feature.steering), isTrue);
      expect(g.has(Feature.serverQueue), isFalse);
    });

    test('an unknown version behaves as the target 0.8.8-rc4', () {
      final g = gates();
      for (final f in thresholds.keys) {
        expect(g.has(f), isTrue, reason: f.name);
      }
      expect(gates(version: 'latest').has(Feature.serverQueue), isTrue);
    });

    test('memoryById also needs memories', () {
      expect(
        gates(
          ui: const InterfaceConfig(memories: false),
        ).has(Feature.memoryById),
        isFalse,
      );
      expect(
        gates(
          role: role({
            'MEMORIES': {'USE': false},
          }),
        ).has(Feature.memoryById),
        isFalse,
      );
    });
  });

  test('a missing feature is off whatever the config says (Req 6.7)', () {
    final g = gates(missing: {Feature.prompts});
    expect(g.has(Feature.prompts), isFalse);
    expect(g.has(Feature.bookmarks), isTrue);
  });

  test('featureGatesProvider hides a feature once its route 404s', () async {
    final missing = ValueNotifier<Set<Feature>>(const {});
    addTearDown(missing.dispose);
    final container = ProviderContainer(
      overrides: [
        serverConfigProvider.overrideWith(
          () => FakeServerConfig(
            const ServerInfo(
              config: StartupConfig(
                interfaceConfig: InterfaceConfig(schedules: true),
              ),
            ),
          ),
        ),
        missingFeaturesProvider.overrideWithValue(missing),
      ],
    );
    addTearDown(container.dispose);
    container.listen(featureGatesProvider, (_, _) {});
    await container.read(serverConfigProvider.future);

    final before = container.read(featureGatesProvider);
    expect(before.has(Feature.schedules), isTrue);

    missing.value = {Feature.schedules};
    final after = container.read(featureGatesProvider);
    expect(after.has(Feature.schedules), isFalse);
    for (final f in Feature.values.where((f) => f != Feature.schedules)) {
      expect(after.has(f), before.has(f), reason: f.name);
    }
  });
}
