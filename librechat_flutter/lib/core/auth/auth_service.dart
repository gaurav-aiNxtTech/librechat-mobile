import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../log/diagnostic_log.dart';
import '../models/user.dart';
import '../storage/cache_db.dart';
import '../storage/secure_store.dart';

/// The app's [AuthService]. `main()` builds and loads it, then overrides this
/// provider. Widgets and the router listen to it for session changes.
final authServiceProvider = ChangeNotifierProvider<AuthService>(
  (ref) => throw UnimplementedError('authServiceProvider is not overridden'),
);

/// A signed-in session, kept in the Secure_Store as
/// `{accessToken, refreshToken, user}`.
@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Throws a `TypeError` when a field is missing or has the wrong type.
  factory Session.fromJson(Map<String, Object?> json) => Session(
    accessToken: json['accessToken']! as String,
    refreshToken: json['refreshToken']! as String,
    user: User.fromJson((json['user']! as Map).cast<String, Object?>()),
  );

  final String accessToken;
  final String refreshToken;
  final User user;

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };
}

/// Owns the Server_URL and the session (Req 1.2). Only this class writes
/// tokens, and other code reads them through [session] (Req 1.3).
///
/// Sign-in, refresh and sign-out join with Task 5.1, through `AuthApi`.
class AuthService extends ChangeNotifier {
  AuthService({required this._secure, required this._cache, this._log});

  final SecureStore _secure;
  final CacheDb _cache;
  final DiagnosticLog? _log;

  Session? _session;

  /// The stored Server_URL, or null before onboarding.
  String? get serverUrl => _secure.serverUrl;

  /// The current session, or null while signed out.
  Session? get session => _session;

  /// Takes the session that [SecureStore.load] read. A stored session that no
  /// longer decodes counts as signed out.
  Future<void> load() async {
    final raw = _secure.session;
    Session? session;
    if (raw != null) {
      try {
        session = Session.fromJson(raw);
      } catch (e, st) {
        _log?.error('auth', 'session_unreadable', e, st);
      }
    }
    _session = session;
    notifyListeners();
  }

  /// Stores the Server_URL with its Custom_Headers. A URL that differs from
  /// the stored one first clears the session and the Cache (Req 7.9).
  Future<void> saveServer(String url, Map<String, String> headers) async {
    if (url != serverUrl) await _clearSession();
    await _secure.writeServer(url, headers);
    notifyListeners();
  }

  /// Deletes the session and empties the Cache. The Server_URL and the
  /// Custom_Headers stay (Req 12.11).
  Future<void> _clearSession() async {
    await _secure.deleteSession();
    _session = null;
    await _cache.clearAll();
  }
}
