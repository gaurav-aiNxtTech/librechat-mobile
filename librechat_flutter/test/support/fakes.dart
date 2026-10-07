/// Hand-written fakes for widget and notifier tests.
///
/// Each fake `implements` the production class it stands in for and is
/// injected through a ProviderScope override. There is no mocking package.
/// A fake is added here by the task that first needs it, and only for a class
/// that exists:
///
/// ```dart
/// class FakeConversationsApi implements ConversationsApi {
///   final calls = <String>[];
///   ...
/// }
/// ```
library;

import 'dart:async';

import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';

/// Records [probe] and [save] calls. [probe] answers with [probeResult], or
/// throws [probeError], after [probeGate] completes when one is set. Other
/// members are not used by the Server_URL_Screen and throw.
class FakeConfigRepository implements ConfigRepository {
  final probes = <(String, Map<String, String>)>[];
  final savedConfigs = <StartupConfig>[];
  StartupConfig probeResult = const StartupConfig(appTitle: 'Probed');
  Object? probeError;
  Completer<void>? probeGate;

  @override
  Future<StartupConfig> probe(String url, Map<String, String> headers) async {
    probes.add((url, headers));
    await probeGate?.future;
    if (probeError case final error?) throw error;
    return probeResult;
  }

  @override
  Future<void> save({
    StartupConfig? config,
    Object? endpoints,
    Object? models,
    Object? role,
  }) async {
    if (config != null) savedConfigs.add(config);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
