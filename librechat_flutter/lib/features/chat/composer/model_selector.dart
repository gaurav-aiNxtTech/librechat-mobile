import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_gate.dart';
import '../../../core/config/server_config.dart';
import '../../../core/images/app_image.dart';
import '../../../core/models/endpoint_config.dart';
import '../../agents/agents_api.dart';
import '../render/endpoint_icon.dart';
import '../send/chat_turn.dart';

/// The agents endpoint, whose choices are agents rather than models.
const agentsEndpoint = 'agents';

/// One Server_Config model spec (`modelSpecs.list[]`) with a usable preset.
@immutable
class ModelSpecEntry {
  const ModelSpecEntry({
    required this.name,
    required this.selection,
    this.label,
    this.description,
    this.iconUrl,
    this.isDefault = false,
  });

  final String name;
  final ChatSelection selection;
  final String? label;
  final String? description;
  final String? iconUrl;

  /// The spec's `default` flag: the Server's default for a new chat.
  final bool isDefault;
}

/// The model specs in StartupConfig [modelSpecs]. A spec without a name or
/// a preset endpoint is skipped. Its `iconURL` counts as an image only when
/// it is a URL or a Server path; otherwise it names an endpoint.
List<ModelSpecEntry> parseModelSpecs(
  Map<String, Object?>? modelSpecs,
  Map<String, EndpointConfig> endpoints,
) => [
  if (modelSpecs?['list'] case final List list)
    for (final entry in list)
      if (entry
          case {
                'name': final String name,
                'preset':
                    {'endpoint': final String endpoint} && final Map preset,
              } &&
              final Map spec)
        ModelSpecEntry(
          name: name,
          label: _string(spec['label']),
          description: _string(spec['description']),
          iconUrl: switch (_string(spec['iconURL'])) {
            final url? when url.startsWith('/') || url.contains('://') => url,
            _ => null,
          },
          isDefault: spec['default'] == true,
          selection: ChatSelection(
            endpoint: endpoint,
            endpointType: endpoints[endpoint]?.type,
            model: _string(preset['model']),
            agentId: _string(preset['agent_id']),
            spec: name,
            modelLabel: _string(preset['modelLabel']) ?? _string(spec['label']),
          ),
        ),
];

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// Everything the Model_Selector lists (Req 21.2): the Server's endpoints
/// and models, the Server_Config model specs and the user's agents.
///
/// [agentsLoaded] is false while the agent list is still loading.
/// [favorites] holds [favoriteKey]s, listed first (Req 21.3); Task 21.9
/// loads them. [showEndpoints] is off when Server_Config disables the
/// endpoints menu or model selection, which hides endpoint and model rows
/// (Req 21.4).
@immutable
class SelectorData {
  const SelectorData({
    this.endpoints = const {},
    this.models = const {},
    this.specs = const [],
    this.agents = const [],
    this.agentsLoaded = true,
    this.favorites = const {},
    this.showEndpoints = true,
  });

  final Map<String, EndpointConfig> endpoints;
  final Map<String, List<String>> models;
  final List<ModelSpecEntry> specs;
  final List<Agent> agents;
  final bool agentsLoaded;
  final Set<String> favorites;
  final bool showEndpoints;

  Agent? agent(String? id) =>
      id == null ? null : agents.where((a) => a.id == id).firstOrNull;

  ModelSpecEntry? spec(String? name) =>
      name == null ? null : specs.where((s) => s.name == name).firstOrNull;

  /// An endpoint's display label (KMP: `modelDisplayLabel`, else the name).
  String endpointLabel(String endpoint) =>
      endpoints[endpoint]?.modelDisplayLabel ?? endpoint;
}

/// The key a favorite is stored under: the spec, the agent, or the
/// endpoint and model.
String favoriteKey(ChatSelection s) => switch (s) {
  ChatSelection(:final spec?) => 'spec:$spec',
  ChatSelection(:final agentId?) => 'agent:$agentId',
  _ => '${s.endpoint}::${s.model}',
};

/// One choice in the Model_Selector.
@immutable
class SelectorItem {
  const SelectorItem({
    required this.selection,
    required this.label,
    this.iconUrl,
    this.isPublic = false,
  });

  final ChatSelection selection;
  final String label;
  final String? iconUrl;
  final bool isPublic;
}

/// One section of the Model_Selector: the model specs, the agents or one
/// endpoint's models.
@immutable
class SelectorGroup {
  const SelectorGroup({
    required this.key,
    required this.label,
    required this.items,
    this.endpoint,
    this.iconUrl,
  });

  final String key;
  final String label;
  final List<SelectorItem> items;
  final String? endpoint;
  final String? iconUrl;
}

/// The Model_Selector's sections for [query] (Req 21.2-21.4): model specs,
/// then the agents ("My Agents", KMP), then each endpoint's models in the
/// Server's order.
///
/// A choice matches when its label, its model or its section's label
/// contains the trimmed [query], ignoring case; a blank query matches all.
/// Favorites come first within each section, otherwise the order is kept.
/// Empty sections are dropped. Endpoint and model rows are left out when
/// [SelectorData.showEndpoints] is off; the agents endpoint is listed only
/// as agents, and, as in the KMP_App, an endpoint missing from a non-empty
/// endpoint list is left out.
List<SelectorGroup> filterSelector(SelectorData data, String query) {
  final q = query.trim().toLowerCase();
  bool has(String? text) => text != null && text.toLowerCase().contains(q);

  SelectorGroup? group(
    String key,
    String label,
    List<SelectorItem> items, {
    String? endpoint,
    String? iconUrl,
  }) {
    final groupMatches = q.isEmpty || has(label);
    final kept = [
      for (final item in items)
        if (groupMatches || has(item.label) || has(item.selection.model)) item,
    ];
    if (kept.isEmpty) return null;
    bool favorite(SelectorItem i) =>
        data.favorites.contains(favoriteKey(i.selection));
    return SelectorGroup(
      key: key,
      label: label,
      endpoint: endpoint,
      iconUrl: iconUrl,
      items: [...kept.where(favorite), ...kept.where((i) => !favorite(i))],
    );
  }

  return [
    ?group('specs', 'Model specs', [
      for (final s in data.specs)
        SelectorItem(
          selection: s.selection,
          label: s.label ?? s.name,
          iconUrl: s.iconUrl,
        ),
    ]),
    ?group('agents', 'My Agents', endpoint: agentsEndpoint, [
      for (final a in data.agents)
        SelectorItem(
          selection: ChatSelection(
            endpoint: agentsEndpoint,
            agentId: a.id,
            modelLabel: a.name,
          ),
          label: a.name ?? a.id,
          iconUrl: a.avatarPath,
          isPublic: a.isPublic == true,
        ),
    ]),
    if (data.showEndpoints)
      for (final MapEntry(key: endpoint, value: models) in data.models.entries)
        if (endpoint != agentsEndpoint &&
            (data.endpoints.isEmpty || data.endpoints.containsKey(endpoint)))
          ?group(
            endpoint,
            data.endpointLabel(endpoint),
            endpoint: endpoint,
            iconUrl: data.endpoints[endpoint]?.iconURL,
            [
              for (final model in models)
                SelectorItem(
                  selection: ChatSelection(
                    endpoint: endpoint,
                    endpointType: data.endpoints[endpoint]?.type,
                    model: model,
                  ),
                  label: model,
                ),
            ],
          ),
  ];
}

/// A new chat's selection (Req 21.1): the last used spec, else the last
/// used endpoint and model (the agent id on the agents endpoint), else the
/// Server's default spec, else the first choice the Model_Selector lists.
///
/// A last used choice that the loaded lists no longer hold is skipped.
/// While its list is still loading (no models, or agents not loaded) it is
/// kept, so the landing shows it at once. Null when nothing is listed.
ChatSelection? defaultSelection(
  SelectorData data, {
  String? lastEndpoint,
  String? lastModel,
  String? lastSpec,
}) {
  final choices = [
    for (final g in filterSelector(data, ''))
      ...g.items.map((i) => i.selection),
  ];
  ChatSelection? find(bool Function(ChatSelection s) test) =>
      choices.where(test).firstOrNull;

  if (lastSpec != null) {
    if (find((s) => s.spec == lastSpec) case final hit?) return hit;
  }
  if (lastEndpoint != null && lastModel != null) {
    if (lastEndpoint == agentsEndpoint) {
      final hit = find((s) => s.spec == null && s.agentId == lastModel);
      if (hit != null) return hit;
      if (!data.agentsLoaded) {
        return ChatSelection(endpoint: agentsEndpoint, agentId: lastModel);
      }
    } else {
      final hit = find(
        (s) =>
            s.spec == null &&
            s.agentId == null &&
            s.endpoint == lastEndpoint &&
            s.model == lastModel,
      );
      if (hit != null) return hit;
      if (data.showEndpoints && data.models.isEmpty) {
        return ChatSelection(
          endpoint: lastEndpoint,
          endpointType: data.endpoints[lastEndpoint]?.type,
          model: lastModel,
        );
      }
    }
  }
  final serverDefault = data.specs.where((s) => s.isDefault).firstOrNull;
  return serverDefault?.selection ?? choices.firstOrNull;
}

/// The label shown for [s]: the spec's or agent's name, else the model
/// label or model, else the endpoint's label.
String selectionLabel(ChatSelection s, SelectorData data) {
  if (data.spec(s.spec) case final spec?) return spec.label ?? spec.name;
  if (s.agentId case final id?) {
    return data.agent(id)?.name ?? s.modelLabel ?? id;
  }
  return s.modelLabel ?? s.model ?? data.endpointLabel(s.endpoint);
}

/// The icon URL of [s]: the agent's avatar, the spec's icon or the
/// endpoint's `iconURL`.
String? selectionIconUrl(ChatSelection s, SelectorData data) {
  final url =
      data.agent(s.agentId)?.avatarPath ??
      data.spec(s.spec)?.iconUrl ??
      data.endpoints[s.endpoint]?.iconURL;
  return url == null || url.trim().isEmpty ? null : url.trim();
}

/// The [SelectorData] for the current Server_Config, endpoints, models,
/// agents and Feature_Gate.
final selectorDataProvider = Provider.autoDispose<SelectorData>((ref) {
  final info = ref.watch(serverConfigProvider.select((s) => s.value));
  final gates = ref.watch(featureGatesProvider);
  final agents = gates.has(Feature.agents)
      ? ref.watch(agentsProvider)
      : const AsyncData(<Agent>[]);
  final endpoints = info?.endpoints ?? const {};
  return SelectorData(
    endpoints: endpoints,
    models: info?.models ?? const {},
    specs: parseModelSpecs(info?.config.modelSpecs, endpoints),
    agents: agents.value ?? const [],
    agentsLoaded: agents.hasValue || agents.hasError,
    showEndpoints:
        gates.has(Feature.endpointsMenu) && gates.has(Feature.modelSelect),
  );
});

/// Opens the Model_Selector sheet and returns the chosen selection, or
/// null when it is dismissed.
Future<ChatSelection?> showModelSelector(
  BuildContext context, {
  ChatSelection? selected,
}) => showModalBottomSheet<ChatSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => ModelSelectorSheet(selected: selected),
);

/// The Model_Selector: a search field over [filterSelector]'s sections
/// (KMP ModelSelectorSheet.kt). Sections start collapsed, except the one
/// holding [selected], and expand while searching. Tapping a choice pops
/// it.
class ModelSelectorSheet extends ConsumerStatefulWidget {
  const ModelSelectorSheet({super.key, this.selected});

  final ChatSelection? selected;

  @override
  ConsumerState<ModelSelectorSheet> createState() => _ModelSelectorSheetState();
}

class _ModelSelectorSheetState extends ConsumerState<ModelSelectorSheet> {
  final _search = TextEditingController();
  late final Set<String> _expanded = {
    if (widget.selected case final s?)
      s.spec != null
          ? 'specs'
          : s.agentId != null
          ? 'agents'
          : s.endpoint,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(selectorDataProvider);
    final query = _search.text;
    final searching = query.trim().isNotEmpty;
    final groups = filterSelector(data, query);
    final selected = widget.selected;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Semantics(
                header: true,
                child: Text(
                  'Select a model', // KMP select_a_model
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search models...', // KMP ModelSelectorSheet
                  border: const OutlineInputBorder(),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search', // KMP cd_clear_search
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final g in groups) ...[
                    _GroupHeader(
                      group: g,
                      expanded: searching || _expanded.contains(g.key),
                      onToggle: searching
                          ? null
                          : () => setState(() => _toggle(g.key)),
                    ),
                    if (searching || _expanded.contains(g.key))
                      for (final item in g.items)
                        _ItemRow(
                          item: item,
                          group: g,
                          selected: _same(item.selection, selected),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String key) {
    if (!_expanded.remove(key)) _expanded.add(key);
  }

  static bool _same(ChatSelection a, ChatSelection? b) =>
      b != null &&
      a.endpoint == b.endpoint &&
      a.spec == b.spec &&
      a.agentId == b.agentId &&
      (a.agentId != null || a.spec != null || a.model == b.model);
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.expanded,
    required this.onToggle,
  });

  final SelectorGroup group;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            EndpointIcon(
              endpoint: group.endpoint,
              url: group.iconUrl,
              fallback: Icons.tune,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${group.label} (${group.items.length})',
                style: theme.textTheme.labelMedium,
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              semanticLabel: expanded
                  ? 'Collapse ${group.label}' // KMP cd_collapse_section
                  : 'Expand ${group.label}', // KMP cd_expand_section
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.group,
    required this.selected,
  });

  final SelectorItem item;
  final SelectorGroup group;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAgent = item.selection.agentId != null && group.key == 'agents';
    final avatar = item.iconUrl;
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: isAgent
          ? avatar == null
                ? Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  )
                : ClipOval(
                    child: AppImage(
                      avatar,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  )
          : null,
      title: Text(item.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isPublic)
            const Icon(
              Icons.public,
              size: 16,
              color: Color(0xFF4CAF50),
              semanticLabel: 'Public agent', // KMP cd_public_agent
            ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check,
              color: colors.primary,
              semanticLabel: 'Selected', // KMP cd_selected
            ),
          ],
        ],
      ),
      onTap: () => Navigator.of(context).pop(item.selection),
    );
  }
}

/// The Composer's model chip: the selection's label, or "Select model",
/// opening the Model_Selector (KMP ModelSelectorButton.kt).
class ModelSelectorButton extends StatelessWidget {
  const ModelSelectorButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label ?? 'Select model', // KMP select_model
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_drop_down,
            size: 20,
            semanticLabel: 'Select model', // KMP cd_select_model
          ),
        ],
      ),
    );
  }
}
