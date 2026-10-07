import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/settings_store.dart';
import '../core/ui/theme/app_theme.dart';
import 'router.dart';

/// The app root. Both themes come from the Settings_Store and the preloaded wallpaper schemes,
/// so the first frame already uses the stored theme (Req 3.9), and a settings change recolors
/// every open screen in place through MaterialApp's theme animation (Req 3.8).
class SwitchboardApp extends ConsumerWidget {
  const SwitchboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final (themeMode, accentSeed, dynamicColor) = ref.watch(
      settingsProvider.select(
        (s) => (s.themeMode, s.accentSeed, s.dynamicColor),
      ),
    );
    final wallpaper = ref.watch(wallpaperSchemesProvider);
    // Wallpaper colors apply only when the device provides them (Req 3.3); otherwise the
    // tonal-spot scheme from the accent seed (Req 3.1).
    final schemes = dynamicColor ? wallpaper : null;
    final seed = Color(accentSeed);

    return MaterialApp.router(
      title: 'Switchboard',
      debugShowCheckedModeBanner: false,
      // System follows the device's dark theme setting (Req 3.7).
      themeMode: themeMode,
      theme: AppTheme.build(
        brightness: Brightness.light,
        accentSeed: seed,
        dynamicScheme: schemes?.light,
      ),
      darkTheme: AppTheme.build(
        brightness: Brightness.dark,
        accentSeed: seed,
        dynamicScheme: schemes?.dark,
      ),
      routerConfig: router,
    );
  }
}
