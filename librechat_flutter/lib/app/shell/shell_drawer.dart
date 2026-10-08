import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_gate.dart';
import '../routes.dart';
import 'shell_menu_button.dart';

/// A drawer row. A row with a [feature] shows only while FeatureGates has it;
/// a null [feature] always shows.
class _Entry {
  const _Entry(this.label, this.icon, this.route, {required this.feature});

  final String label;
  final IconData icon;
  final String route;
  final Feature? feature;
}

/// Footer rows. Each feature screen adds its row (with its [Feature]) when it
/// lands.
const _footer = [
  // Task 31 retargets this to Routes.settings when the settings list lands.
  _Entry(
    'Settings', // KMP feature/conversations settings
    Icons.settings,
    Routes.settingsGeneral,
    feature: null,
  ),
];

/// The AppShell's navigation: the modal drawer's content below 600 dp and
/// the persistent sidebar from 600 dp (Req 14.1–14.3). A tap in the [modal]
/// drawer closes it and then navigates.
class ShellDrawer extends ConsumerWidget {
  const ShellDrawer({super.key, required this.modal});

  final bool modal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gates = ref.watch(featureGatesProvider);
    final path = GoRouterState.of(context).uri.path;
    final entries = [
      for (final entry in _footer)
        if (entry.feature == null || gates.has(entry.feature!)) entry,
    ];

    void open(String route) {
      if (modal) {
        ShellScope.maybeOf(context)?.scaffoldKey.currentState?.closeDrawer();
      }
      context.go(route);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.add),
              label: const Text(
                'New Chat',
              ), // KMP feature/conversations new_chat
              onPressed: () => open(Routes.newChat),
            ),
          ),
          // The Conversation_List lands here with Task 9.
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries)
                  ListTile(
                    leading: Icon(entry.icon),
                    title: Text(entry.label),
                    minTileHeight: 56,
                    shape: const StadiumBorder(),
                    selected:
                        path == entry.route ||
                        path.startsWith('${entry.route}/'),
                    onTap: () => open(entry.route),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
