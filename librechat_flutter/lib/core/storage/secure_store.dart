import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../log/diagnostic_log.dart';

/// The loaded Secure_Store. `main()` overrides this with `overrideWithValue`.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw UnimplementedError('secureStoreProvider is not overridden'),
);

/// The Secure_Store: the only place the Server_URL, the Custom_Headers and the
/// Session live on the device (Req 46.1).
///
/// [load] reads everything with one `readAll()`; the getters are synchronous
/// after that. Every writer goes to storage first and changes the in-memory
/// copy only when the write succeeds, so a failed write keeps the old values in
/// effect (Req 5.6) and a successful one applies to the next request (Req 5.10).
///
/// Only AuthService reads or writes the session (Req 1.3). The session is kept
/// as its decoded JSON object (`accessToken`, `refreshToken`, `user`); the
/// `Session` model converts to and from that map.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage, this._log})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String serverUrlKey = 'server_url';
  static const String customHeadersKey = 'custom_headers';
  static const String sessionKey = 'session';

  static const String _tag = 'secure_store';

  final FlutterSecureStorage _storage;
  final DiagnosticLog? _log;

  String? _serverUrl;
  Map<String, String> _customHeaders = const {};
  Map<String, Object?>? _session;

  String? get serverUrl => _serverUrl;

  /// The stored Custom_Headers, in their stored order. Empty when none are stored.
  Map<String, String> get customHeaders => _customHeaders;

  /// The stored session JSON object, or null when signed out.
  Map<String, Object?>? get session => _session;

  /// Reads all keys with one `readAll()`. Unreadable storage starts empty and
  /// logs `secure_store_unreadable`; a single unreadable value is dropped.
  Future<void> load() async {
    final Map<String, String> all;
    try {
      all = await _storage.readAll();
    } catch (e, st) {
      _log?.error(_tag, 'secure_store_unreadable', e, st);
      _serverUrl = null;
      _customHeaders = const {};
      _session = null;
      return;
    }
    final url = all[serverUrlKey];
    _serverUrl = url == null || url.isEmpty ? null : url;
    _customHeaders = _decodeHeaders(all[customHeadersKey]) ?? const {};
    _session = _decodeSession(all[sessionKey]);
  }

  /// Stores the Server_URL and its Custom_Headers together.
  Future<void> writeServer(String url, Map<String, String> headers) async {
    final stored = Map<String, String>.unmodifiable(headers);
    await _writeAll({
      serverUrlKey: (url, _serverUrl),
      customHeadersKey: (
        _encodeHeaders(stored),
        _encodeHeaders(_customHeaders),
      ),
    });
    _serverUrl = url;
    _customHeaders = stored;
  }

  /// Stores [headers] as the Custom_Headers. An empty map removes them.
  Future<void> writeCustomHeaders(Map<String, String> headers) async {
    final stored = Map<String, String>.unmodifiable(headers);
    await _write(customHeadersKey, _encodeHeaders(stored));
    _customHeaders = stored;
  }

  /// Stores [session], the Session's JSON object.
  Future<void> writeSession(Map<String, Object?> session) async {
    final encoded = jsonEncode(session);
    // Keep a decoded copy so later changes to the caller's map don't leak in.
    final stored = _decodeSession(encoded)!;
    await _write(sessionKey, encoded);
    _session = stored;
  }

  /// Removes the session; the Server_URL and Custom_Headers stay.
  Future<void> deleteSession() async {
    await _write(sessionKey, null);
    _session = null;
  }

  /// Writes [value], or deletes the key when it is null.
  Future<void> _write(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);

  /// Writes each `(next, previous)` pair in order. If one fails, the keys
  /// already written are put back to their previous values, best effort, so
  /// storage and memory stay in step, and the error is rethrown.
  Future<void> _writeAll(Map<String, (String?, String?)> values) async {
    final written = <String>[];
    try {
      for (final MapEntry(:key, value: (next, _)) in values.entries) {
        await _write(key, next);
        written.add(key);
      }
    } catch (_) {
      for (final key in written.reversed) {
        try {
          await _write(key, values[key]!.$2);
        } catch (_) {
          // The original error matters more; storage will be reread at startup.
        }
      }
      rethrow;
    }
  }

  static String? _encodeHeaders(Map<String, String> headers) =>
      headers.isEmpty ? null : jsonEncode(headers);

  Map<String, String>? _decodeHeaders(String? raw) {
    if (raw == null) return null;
    final value = _decode(customHeadersKey, raw);
    if (value is Map<String, Object?> &&
        value.values.every((v) => v is String)) {
      return Map.unmodifiable(value.cast<String, String>());
    }
    if (value != null) _unreadableValue(customHeadersKey);
    return null;
  }

  Map<String, Object?>? _decodeSession(String? raw) {
    if (raw == null) return null;
    final value = _decode(sessionKey, raw);
    if (value is Map<String, Object?>) return Map.unmodifiable(value);
    if (value != null) _unreadableValue(sessionKey);
    return null;
  }

  Object? _decode(String key, String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      _unreadableValue(key);
      return null;
    }
  }

  void _unreadableValue(String key) =>
      _log?.info(_tag, 'secure_store_value_unreadable', {'key': key});
}
