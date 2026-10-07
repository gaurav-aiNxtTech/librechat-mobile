import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/settings_store.dart';
import '../../core/ui/theme/accent_colors.dart';
import '../../core/ui/theme/app_theme.dart';

/// Dim factor for the accent presets while wallpaper colors override them (KMP `DISABLED_ALPHA`).
const double _disabledAlpha = 0.4;

/// General settings: theme mode, accent presets and "Use wallpaper colors" (Req 3.2, 3.4–3.6,
/// 40.2). Copy follows the KMP feature/settings `strings.xml`.
class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final hasWallpaper = ref.watch(wallpaperSchemesProvider) != null;
    // Presets lock only while wallpaper colors are actually in effect, so a stored
    // `dynamicColor` on a device without a palette never strands the accent choice.
    final wallpaperInEffect = settings.dynamicColor && hasWallpaper;

    void save(AppSettings next) =>
        // A failed write surfaces as an uncaught error, which the Diagnostic_Log records.
        unawaited(ref.read(settingsProvider.notifier).save(next));

    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          _ThemeSelector(
            selected: settings.themeMode,
            onSelect: (mode) => save(settings.copyWith(themeMode: mode)),
          ),
          const Divider(),
          _AccentPresets(
            selectedSeed: settings.accentSeed,
            enabled: !wallpaperInEffect,
            onSelect: (seed) => save(settings.copyWith(accentSeed: seed)),
          ),
          if (hasWallpaper) ...[
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.wallpaper),
              title: const Text('Use wallpaper colors'),
              subtitle: const Text(
                'Match the app accent to your system wallpaper (Material You)',
              ),
              value: settings.dynamicColor,
              onChanged: (on) => save(settings.copyWith(dynamicColor: on)),
            ),
          ],
          const Divider(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selected, required this.onSelect});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelect;

  static const _labels = {
    ThemeMode.system: 'System default',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ThemeMode>(
      groupValue: selected,
      onChanged: (mode) {
        if (mode != null) onSelect(mode);
      },
      child: Column(
        children: [
          for (final MapEntry(key: mode, value: label) in _labels.entries)
            RadioListTile<ThemeMode>(value: mode, title: Text(label)),
        ],
      ),
    );
  }
}

/// The 11 KMP presets as swatches. While [enabled] is false the row is dimmed and ignores taps
/// (Req 3.5).
class _AccentPresets extends StatelessWidget {
  const _AccentPresets({
    required this.selectedSeed,
    required this.enabled,
    required this.onSelect,
  });

  final int selectedSeed;
  final bool enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : _disabledAlpha,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Accent color'),
            subtitle: Text(_hex(selectedSeed)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              children: [
                for (final (i, preset) in accentColorPresets.indexed)
                  _Swatch(
                    color: preset,
                    label: accentColorPresetNames[i],
                    selected: preset.toARGB32() == selectedSeed,
                    outline: theme.colorScheme.outline,
                    selectedOutline: theme.colorScheme.onSurface,
                    onTap: enabled ? () => onSelect(preset.toARGB32()) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// KMP `Color.toHexString()`: `#RRGGBB`, upper case.
  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.outline,
    required this.selectedOutline,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final Color outline;
  final Color selectedOutline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The 48 dp box is the tap target (Req 47.2); the 36 dp circle is the KMP swatch.
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  width: selected ? 3 : 1,
                  color: selected ? selectedOutline : outline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
