import 'package:flutter/material.dart';

/// Default accent seed (KMP `DEFAULT_ACCENT_SEED_ARGB`, core/model Constants.kt).
const Color defaultAccentSeed = Color(0xFF3B82F6);

/// Curated accent seeds offered in the picker (KMP core/ui theme/AccentColors.kt).
///
/// These are *source* colors: the full Material 3 scheme is generated from the chosen seed with the
/// tonal-spot variant, so no role resolves to the exact swatch hex. The default is listed first and
/// must not repeat further down, because the picker marks selection by comparing ARGB values.
const List<Color> accentColorPresets = [
  defaultAccentSeed, // Blue (default)
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Lavender (the original brand hue)
  Color(0xFF06B6D4), // Cyan
  Color(0xFF00D8BB), // Turquoise (matches the app icon's cable)
  Color(0xFF22C55E), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFFEC4899), // Pink
  Color(0xFF64748B), // Slate
];

/// Human-readable names for the presets, index-aligned with [accentColorPresets].
const List<String> accentColorPresetNames = [
  'Blue',
  'Indigo',
  'Lavender',
  'Cyan',
  'Turquoise',
  'Green',
  'Amber',
  'Orange',
  'Red',
  'Pink',
  'Slate',
];
