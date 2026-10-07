import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/theme/accent_colors.dart';

part 'settings_store.freezed.dart';

enum ChatFontSize { small, medium, large }

enum MessageLayout { thread, twoSided }

enum DuringRunAction { queue, steer }

enum ArtifactViewer { sheet, fullscreen }

/// Artifact types rendered inline in the message instead of as a card.
enum InlineArtifact { html, react, svg, mermaid, markdown }

/// Speech engine choice. A null setting means the Server's default.
enum VoiceEngine { device, server }

enum ForkMode { directPath, includeBranches, targetLevel }

/// Every General and Chat setting kept on the device. Defaults follow the design's key table.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(0xFF3B82F6) int accentSeed,
    @Default(false) bool dynamicColor,
    @Default(ChatFontSize.medium) ChatFontSize chatFontSize,
    @Default(MessageLayout.thread) MessageLayout messageLayout,
    @Default(true) bool autoScroll,
    @Default(true) bool dismissKeyboardOnSend,
    @Default(DuringRunAction.queue) DuringRunAction duringRunAction,
    @Default(ArtifactViewer.sheet) ArtifactViewer artifactViewer,
    @Default(<InlineArtifact>{}) Set<InlineArtifact> inlineArtifacts,
    @Default(true) bool slashCommands,
    @Default(true) bool sttEnabled,
    VoiceEngine? sttEngine,
    VoiceEngine? ttsEngine,
    String? ttsVoice,
    @Default(false) bool autoReadAloud,
    @Default(ForkMode.targetLevel) ForkMode forkMode,
    @Default(false) bool forkSplitAtTarget,
    String? lastEndpoint,
    String? lastModel,
    String? lastSpec,
    @Default(<String>[]) List<String> dismissedBannerIds,
    String? dismissedVersionBanner,
    @Default(false) bool ssoWarningAcknowledged,
  }) = _AppSettings;
}

/// The Settings_Store. `main()` overrides this with `overrideWith(() => SettingsStore(prefs))`.
final settingsProvider = NotifierProvider<SettingsStore, AppSettings>(
  () =>
      throw UnimplementedError('settingsProvider must be overridden in main()'),
);

class SettingsStore extends Notifier<AppSettings> {
  SettingsStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _defaults = AppSettings();

  @override
  AppSettings build() => AppSettings(
    themeMode: _enum('theme_mode', ThemeMode.values) ?? _defaults.themeMode,
    accentSeed: _accentSeed(),
    dynamicColor: _bool('dynamic_color') ?? _defaults.dynamicColor,
    chatFontSize:
        _enum('chat_font_size', ChatFontSize.values) ?? _defaults.chatFontSize,
    messageLayout:
        _enum('message_layout', MessageLayout.values) ??
        _defaults.messageLayout,
    autoScroll: _bool('auto_scroll') ?? _defaults.autoScroll,
    dismissKeyboardOnSend:
        _bool('dismiss_keyboard_on_send') ?? _defaults.dismissKeyboardOnSend,
    duringRunAction:
        _enum('during_run_action', DuringRunAction.values) ??
        _defaults.duringRunAction,
    artifactViewer:
        _enum('artifact_viewer', ArtifactViewer.values) ??
        _defaults.artifactViewer,
    inlineArtifacts: _inlineArtifacts(),
    slashCommands: _bool('slash_commands') ?? _defaults.slashCommands,
    sttEnabled: _bool('stt_enabled') ?? _defaults.sttEnabled,
    sttEngine: _enum('stt_engine', VoiceEngine.values),
    ttsEngine: _enum('tts_engine', VoiceEngine.values),
    ttsVoice: _string('tts_voice'),
    autoReadAloud: _bool('auto_read_aloud') ?? _defaults.autoReadAloud,
    forkMode: _enum('fork_mode', ForkMode.values) ?? _defaults.forkMode,
    forkSplitAtTarget:
        _bool('fork_split_at_target') ?? _defaults.forkSplitAtTarget,
    lastEndpoint: _string('last_endpoint'),
    lastModel: _string('last_model'),
    lastSpec: _string('last_spec'),
    dismissedBannerIds:
        _stringList('dismissed_banners') ?? _defaults.dismissedBannerIds,
    dismissedVersionBanner: _string('dismissed_version_banner'),
    ssoWarningAcknowledged:
        _bool('sso_warning_ack') ?? _defaults.ssoWarningAcknowledged,
  );

  /// Writes the keys that differ from the current state, then publishes [next].
  ///
  /// `SharedPreferencesWithCache` updates its cache synchronously, so the new state is published
  /// before the platform write finishes and a later [save] diffs against it.
  Future<void> save(AppSettings next) async {
    final before = _encode(state);
    final after = _encode(next);
    final writes = <Future<void>>[
      for (final MapEntry(:key, :value) in after.entries)
        if (!_same(before[key], value)) _write(key, value),
    ];
    state = next;
    await Future.wait(writes);
  }

  static Map<String, Object?> _encode(AppSettings s) => {
    'theme_mode': s.themeMode.name,
    'accent_seed': s.accentSeed,
    'dynamic_color': s.dynamicColor,
    'chat_font_size': s.chatFontSize.name,
    'message_layout': s.messageLayout.name,
    'auto_scroll': s.autoScroll,
    'dismiss_keyboard_on_send': s.dismissKeyboardOnSend,
    'during_run_action': s.duringRunAction.name,
    'artifact_viewer': s.artifactViewer.name,
    // Enum order keeps the stored list stable regardless of set insertion order.
    'inline_artifacts': [
      for (final a in InlineArtifact.values)
        if (s.inlineArtifacts.contains(a)) a.name,
    ],
    'slash_commands': s.slashCommands,
    'stt_enabled': s.sttEnabled,
    'stt_engine': s.sttEngine?.name,
    'tts_engine': s.ttsEngine?.name,
    'tts_voice': s.ttsVoice,
    'auto_read_aloud': s.autoReadAloud,
    'fork_mode': s.forkMode.name,
    'fork_split_at_target': s.forkSplitAtTarget,
    'last_endpoint': s.lastEndpoint,
    'last_model': s.lastModel,
    'last_spec': s.lastSpec,
    'dismissed_banners': s.dismissedBannerIds,
    'dismissed_version_banner': s.dismissedVersionBanner,
    'sso_warning_ack': s.ssoWarningAcknowledged,
  };

  static bool _same(Object? a, Object? b) =>
      a is List<String> && b is List<String> ? listEquals(a, b) : a == b;

  Future<void> _write(String key, Object? value) => switch (value) {
    null => _prefs.remove(key),
    final bool v => _prefs.setBool(key, v),
    final int v => _prefs.setInt(key, v),
    final String v => _prefs.setString(key, v),
    final List<String> v => _prefs.setStringList(key, v),
    _ => throw ArgumentError.value(value, key, 'unsupported settings value'),
  };

  // Readers go through `get` and check the type, so a value of the wrong type or an unknown enum
  // name falls back to the default instead of throwing.

  bool? _bool(String key) => switch (_prefs.get(key)) {
    final bool v => v,
    _ => null,
  };

  String? _string(String key) => switch (_prefs.get(key)) {
    final String v => v,
    _ => null,
  };

  List<String>? _stringList(String key) => switch (_prefs.get(key)) {
    final List<Object?> v when v.every((e) => e is String) =>
      v.cast<String>().toList(),
    _ => null,
  };

  T? _enum<T extends Enum>(String key, List<T> values) {
    final name = _string(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  int _accentSeed() => switch (_prefs.get('accent_seed')) {
    final int v when accentColorPresets.any((c) => c.toARGB32() == v) => v,
    _ => _defaults.accentSeed,
  };

  /// Unknown names are dropped; the rest of the stored subset is kept.
  Set<InlineArtifact> _inlineArtifacts() {
    final names = _stringList('inline_artifacts');
    if (names == null) return _defaults.inlineArtifacts;
    return {
      for (final a in InlineArtifact.values)
        if (names.contains(a.name)) a,
    };
  }
}
