import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_api.dart';

import '../log/diagnostic_log.dart';
import '../models/user.dart';
import '../network/app_exception.dart';
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

/// What a login came to, short of an error.
sealed class LoginResult {
  const LoginResult();
}

/// The session is stored (Req 9.4).
final class SignedIn extends LoginResult {
  const SignedIn();
}

/// The Server wants a two-factor code for [tempToken] (Req 9.6).
final class NeedsTwoFactor extends LoginResult {
  const NeedsTwoFactor(this.tempToken);

  final String tempToken;
}

/// The Server answered `Email not verified.` (Req 9.7).
final class NeedsVerification extends LoginResult {
  const NeedsVerification();
}

/// The login message that opens the Verify_Email_Screen (Req 9.7).
const emailNotVerifiedMessage = 'Email not verified.';

/// Owns the Server_URL and the session (Req 1.2). Only this class writes
/// tokens, and other code reads them through [session] (Req 1.3). All of its
/// HTTP goes through [api].
class AuthService extends ChangeNotifier {
  AuthService({required this._secure, required this._cache, this._log});

  final SecureStore _secure;
  final CacheDb _cache;
  final DiagnosticLog? _log;

  /// Set once in `main()`, after the ApiClient that AuthApi needs exists.
  late AuthApi api;

  /// Whether the Login_Screen already started OpenID once this process
  /// (Req 9.10).
  bool openIdAutoRedirected = false;

  Session? _session;
  bool _expired = false;
  Future<void>? _refreshing;

  /// The stored Server_URL, or null before onboarding.
  String? get serverUrl => _secure.serverUrl;

  /// The current session, or null while signed out.
  Session? get session => _session;

  /// True after a LibreChat_Refresh_Rejection ended the session, until
  /// [acknowledgeExpiry] (Req 12.7).
  bool get expired => _expired;

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

  /// `POST /api/auth/login` with [identifier] as `email`, which LDAP
  /// usernames use too (Req 9.2–9.3). Other failures throw the Server's
  /// message as an [AppException] (Req 9.8).
  Future<LoginResult> login(String identifier, String password) async {
    final TokenReply reply;
    try {
      reply = await api.login(identifier, password);
    } on AppException catch (e) {
      if (e.message?.trim() == emailNotVerifiedMessage) {
        return const NeedsVerification();
      }
      rethrow;
    }
    final tempToken = reply.tempToken;
    if (reply.twoFAPending && tempToken != null) {
      return NeedsTwoFactor(tempToken);
    }
    await _signIn(reply);
    return const SignedIn();
  }

  /// `POST /api/auth/2fa/verify-temp` with [code] as a TOTP code, or as a
  /// backup code when [backupCode] is set (Req 10.1–10.3).
  Future<void> verifyTwoFactor(
    String tempToken,
    String code, {
    required bool backupCode,
  }) async => _signIn(
    await api.verifyTempToken(
      tempToken,
      code: backupCode ? null : code,
      backupCode: backupCode ? code : null,
    ),
  );

  /// Turns the Refresh_Token the SSO_Screen captured into a session
  /// (Req 13.6): refresh with it, keep the rotated cookie or the captured
  /// token, load `GET /api/user`, then store and notify. Any failure throws
  /// and leaves the App signed out.
  Future<void> exchangeSsoToken(String refreshToken) async {
    final result = await api.refresh(refreshToken);
    final success = switch (result) {
      RefreshSuccess() => result,
      RefreshRejected(:final status) => throw AppException(
        FailureKind.server,
        status: status,
        signedIn: false,
      ),
      RefreshFailed(:final error) => throw error,
    };
    // Held in memory, unannounced, so `GET /api/user` carries the token.
    _session = Session(
      accessToken: success.accessToken,
      refreshToken: success.refreshToken ?? refreshToken,
      user: success.user ?? const User(id: ''),
    );
    try {
      final user = await api.user();
      await _store(
        Session(
          accessToken: _session!.accessToken,
          refreshToken: _session!.refreshToken,
          user: user,
        ),
      );
    } catch (_) {
      _session = null;
      rethrow;
    }
  }

  /// Refreshes the Access_Token. Concurrent callers share one request
  /// (Req 12.4).
  ///
  /// - Success stores the new token, the rotated Refresh_Token or the old
  ///   one, and the returned user (Req 12.6).
  /// - A LibreChat_Refresh_Rejection clears the session, sets [expired] and
  ///   throws [FailureKind.sessionExpired] (Req 12.7).
  /// - Anything else keeps the session and throws the refresh's error
  ///   (Req 12.8).
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() {
    _refreshing = null;
  });

  Future<void> _refresh() async {
    final session = _session;
    if (session == null) {
      throw AppException(FailureKind.sessionExpired, signedIn: false);
    }
    final result = await api.refresh(session.refreshToken);
    // A sign-out or a new sign-in while the refresh ran wins over its result.
    if (!identical(_session, session)) return;
    switch (result) {
      case RefreshSuccess(:final accessToken, :final refreshToken, :final user):
        await _store(
          Session(
            accessToken: accessToken,
            refreshToken: refreshToken ?? session.refreshToken,
            user: user ?? session.user,
          ),
        );
      case RefreshRejected(:final status):
        _log?.info('auth', 'refresh_rejected', {'status': status});
        await _clearSession();
        _expired = true;
        notifyListeners();
        throw AppException(FailureKind.sessionExpired, signedIn: false);
      case RefreshFailed(:final error):
        _log?.info('auth', 'refresh_failed', {
          'kind': error.kind.name,
          'status': error.status,
        });
        throw error;
    }
  }

  /// `POST /api/auth/logout`, then clears the session whatever the result
  /// (Req 12.10). Declining the terms signs out too (Req 11.10).
  Future<void> signOut() async {
    if (_session != null) {
      try {
        await api.logout();
      } catch (e, st) {
        _log?.error('auth', 'logout_failed', e, st);
      }
    }
    await _clearSession();
    notifyListeners();
  }

  /// Clears [expired] once the session-expired notice was shown.
  void acknowledgeExpiry() {
    if (!_expired) return;
    _expired = false;
    notifyListeners();
  }

  /// Stores a login or two-factor reply. A `token` without the
  /// `refreshToken` cookie, or without a `user`, is malformed, because that
  /// session could never refresh.
  Future<void> _signIn(TokenReply reply) async {
    final (:token, :user, :refreshToken, twoFAPending: _, tempToken: _) = reply;
    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        user == null) {
      throw AppException(FailureKind.malformed, signedIn: false);
    }
    await _store(
      Session(accessToken: token, refreshToken: refreshToken, user: user),
    );
  }

  /// Writes [session] to the Secure_Store (Req 12.1), then makes it current.
  Future<void> _store(Session session) async {
    await _secure.writeSession(session.toJson());
    _session = session;
    notifyListeners();
  }

  /// Drops the session and empties the Cache. The Server_URL and the
  /// Custom_Headers stay (Req 12.11). Storage failures are logged, so the
  /// App is signed out in memory either way.
  Future<void> _clearSession() async {
    _session = null;
    try {
      await _secure.deleteSession();
    } catch (e, st) {
      _log?.error('auth', 'session_delete_failed', e, st);
    }
    try {
      await _cache.clearAll();
    } catch (e, st) {
      _log?.error('auth', 'cache_clear_failed', e, st);
    }
  }
}
