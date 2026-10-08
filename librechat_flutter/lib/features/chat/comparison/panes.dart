/// Compare-models helpers (Req 30.4, 30.7), ported from the KMP
/// `feature/chat/.../util/ParallelContent.kt`.
///
/// A comparison turn is one assistant message whose parts each carry an
/// `agentId`. The added (secondary) model's ids end in `____N`, as in
/// `agent_abc____1` or the ephemeral `openAI__gpt-4o___GPT-4o____1`.
library;

import '../../../core/models/content_part.dart';

final _paneSuffix = RegExp(r'____\d+$');

const _agentsEndpoint = 'agents';

/// The endpoint, model, saved agent and sender a pane's agent id names.
typedef PaneSelection = ({
  String endpoint,
  String model,
  String? agentId,
  String? sender,
});

/// True when [agentId] ends in the `____N` suffix of the secondary pane.
bool isSecondaryAgentId(String? agentId) =>
    agentId != null && _paneSuffix.hasMatch(agentId);

/// [agentId] without a trailing `____N`.
String stripPaneSuffix(String agentId) => agentId.replaceFirst(_paneSuffix, '');

/// Splits [parts] into the primary and secondary panes, keeping the input
/// order in each (Req 30.4). A part is secondary exactly when its `agentId`
/// has the `____N` suffix; unattributed parts are primary.
(List<ContentPart>, List<ContentPart>) splitPanes(List<ContentPart> parts) {
  final primary = <ContentPart>[];
  final secondary = <ContentPart>[];
  for (final part in parts) {
    (isSecondaryAgentId(part.agentId) ? secondary : primary).add(part);
  }
  return (primary, secondary);
}

/// The first secondary `agentId` in [parts], or null when there is none.
String? secondaryAgentId(List<ContentPart> parts) {
  for (final part in parts) {
    if (isSecondaryAgentId(part.agentId)) return part.agentId;
  }
  return null;
}

/// Decodes a pane's agent id to restore its selection on reopen (Req 30.7),
/// as the KMP `resolveSecondarySelection` does.
///
/// A saved agent (`agent_…`) is the `agents` endpoint with the agent id as
/// the model. Otherwise the id is the ephemeral
/// `endpoint__model___sender____N`, where `__` escapes `:` in the model and
/// sender. An ephemeral id that does not parse falls back to `agents`.
PaneSelection parsePaneAgentId(String agentId) {
  final stripped = stripPaneSuffix(agentId);
  final PaneSelection fallback = (
    endpoint: _agentsEndpoint,
    model: stripped,
    agentId: stripped,
    sender: null,
  );
  if (stripped.startsWith('agent_')) return fallback;

  var main = stripped;
  String? sender;
  final senderAt = stripped.indexOf('___');
  if (senderAt >= 0) {
    main = stripped.substring(0, senderAt);
    sender = stripped.substring(senderAt + 3).replaceAll('__', ':');
  }
  final segments = main.split('__');
  if (segments.length < 2 || segments.first.isEmpty) return fallback;
  return (
    endpoint: segments.first,
    model: segments.skip(1).join(':'),
    agentId: null,
    sender: sender,
  );
}
