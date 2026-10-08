import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell/shell_menu_button.dart';
import '../../core/config/server_config.dart';

/// The landing greeting for the local time [now] (KMP LandingContent.kt
/// `getTimeBasedGreeting`).
String timeGreeting(DateTime now) {
  final hour = now.hour;
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  if (weekend) {
    if (hour < 5) return 'Happy late night';
    if (hour < 12) return 'Happy weekend morning';
    if (hour < 17) return 'Happy weekend afternoon';
    return 'Happy weekend evening';
  }
  if (hour < 5) return 'Happy late night';
  if (hour < 9) return 'Good early morning';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// The `/chat` new-chat screen. For now only its landing state: the app
/// icon, the time-based greeting and the Server's custom welcome (Req 17.8,
/// in part; the model icon and conversation starters come later).
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final welcome = ref
        .watch(
          serverConfigProvider.select(
            (s) => s.value?.config.interfaceConfig.customWelcome,
          ),
        )
        ?.trim();
    return Scaffold(
      appBar: AppBar(leading: ShellMenuButton.leading(context)),
      // Centered when it fits; scrolls when banners or a landscape phone
      // leave too little height.
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: _landing(theme, welcome)),
          ),
        ),
      ),
    );
  }

  Widget _landing(ThemeData theme, String? welcome) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: colors.primaryContainer,
              child: SizedBox.square(
                dimension: 56,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 32,
                  color: colors.onPrimaryContainer,
                  semanticLabel: 'Switchboard', // KMP feature/chat cd_librechat
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              timeGreeting(DateTime.now()),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            welcome == null || welcome.isEmpty
                ? 'How can I help you today?' // KMP feature/chat how_can_i_help
                : welcome,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
