import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accent_colors.dart';

/// The light and dark color schemes generated from the device's wallpaper (Android 12+).
typedef WallpaperSchemes = ({ColorScheme light, ColorScheme dark});

/// The wallpaper schemes `main()` loads before the first frame, or null when the device provides
/// no palette (below Android 12), which hides "Use wallpaper colors" (Req 3.4).
///
/// `main()` overrides this with `overrideWithValue`; tests override it with a scheme pair or null.
final wallpaperSchemesProvider = Provider<WallpaperSchemes?>(
  (ref) =>
      throw UnimplementedError('wallpaperSchemesProvider is not overridden'),
);

/// Reads the wallpaper palette once through `DynamicColorPlugin.getCorePalette()`.
///
/// Loading it before `runApp` replaces `DynamicColorBuilder`, which has no palette on its first
/// build and would paint the first frame in accent colors (Req 3.9).
Future<WallpaperSchemes?> loadWallpaperSchemes() async {
  try {
    final palette = await DynamicColorPlugin.getCorePalette();
    if (palette == null) return null;
    return (
      light: palette.toColorScheme(),
      dark: palette.toColorScheme(brightness: Brightness.dark),
    );
  } on PlatformException {
    return null;
  }
}

/// Port of the KMP `LibreChatTheme` (core/ui theme/Theme.kt, Type.kt, Shape.kt).
///
/// Color precedence: wallpaper-based dynamic color when the user enabled it and the platform
/// provides it (Android 12+), otherwise a scheme generated from the accent seed with the
/// tonal-spot variant, which also tints the neutral surfaces with the seed hue.
abstract final class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    Color accentSeed = defaultAccentSeed,
    ColorScheme? dynamicScheme,
  }) {
    final scheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: accentSeed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );
    final textTheme = _textTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      // Shapes (KMP libreChatShapes): small 8, medium 16, large 24, extraLarge 28.
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle? style(
      TextStyle? s,
      double size,
      double lineHeight,
      FontWeight weight,
    ) => s?.copyWith(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
    );
    return base.copyWith(
      bodyLarge: style(base.bodyLarge, 16, 24, FontWeight.w400),
      bodyMedium: style(base.bodyMedium, 14, 20, FontWeight.w400),
      headlineLarge: style(base.headlineLarge, 30, 36, FontWeight.w700),
      headlineMedium: style(base.headlineMedium, 24, 32, FontWeight.w500),
      titleMedium: style(base.titleMedium, 16, 24, FontWeight.w600),
      titleSmall: style(base.titleSmall, 14, 20, FontWeight.w400),
      labelSmall: style(base.labelSmall, 12, 16, FontWeight.w400),
    );
  }
}

/// KMP `isSurfaceDark()`: the single source of truth for "is the current surface dark?", used to
/// pick light/dark variants for WebView-rendered content so inline and fullscreen views agree.
extension SurfaceLuminance on ThemeData {
  bool get isSurfaceDark => colorScheme.surface.computeLuminance() < 0.5;
}
