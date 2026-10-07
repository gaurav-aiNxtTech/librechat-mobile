import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../models/user.dart';
import '../network/api_client.dart';
import '../network/app_exception.dart';
import '../network/server_url.dart';

/// The body of a login or two-factor response, with the Refresh_Token read
/// from its `refreshToken` Set-Cookie header (Req 9.4, 10.3).
typedef TokenReply = ({
  String? token,
  User? user,
  bool twoFAPending,
  String? tempToken,
  String? refreshToken,
});

/// What `POST /api/auth/refresh` came to, decided by [classifyRefresh].
sealed class RefreshResult {
  const RefreshResult();
}

/// A 2xx with a `token`. [refreshToken] is the rotated cookie and [user] the
/// returned user, each null when the response carries none.
final class RefreshSuccess extends RefreshResult {
  const RefreshSuccess(this.accessToken, {this.refreshToken, this.user});

  final String accessToken;
  final String? refreshToken;
  final User? user;
}

/// A LibreChat_Refresh_Rejection: the Server ended the session (Req 12.7).
final class RefreshRejected extends RefreshResult {
  const RefreshRejected(this.status);

  final int status;
}

/// Any other outcome. The session stays, and waiting requests fail with
/// [error] (Req 12.8).
final class RefreshFailed extends RefreshResult {
  const RefreshFailed(this.error);

  final AppException error;
}

/// The bodies LibreChat's `refreshController` sends with its own 401 and 403
/// rejections. Registered in `scripts/mirrors.json` for the KMP app.
const refreshRejectionBodies = [
  'Invalid refresh token',
  'Invalid OpenID refresh token',
  'No session found',
  'Refresh token expired or not found for this user',
  'OPENID_SESSION_MISSING',
];

/// Classifies one refresh response, fetched without following redirects.
///
/// [headers] use lowercase names, as dio gives them. [body] is the raw text.
/// Network errors, timeouts and gateway errors never reach here: ApiClient
/// throws them, and they are failures too.
RefreshResult classifyRefresh(
  int status,
  Map<String, List<String>> headers,
  String body,
  String serverUrl,
) {
  if (status >= 200 && status < 300) {
    if (status == 200 && body.trim() == 'Refresh token not provided') {
      return RefreshRejected(status);
    }
    final json = _tryDecode(body);
    final token = json is Map ? json['token'] : null;
    if (token is! String || token.isEmpty) {
      return RefreshFailed(AppException(FailureKind.malformed, status: status));
    }
    return RefreshSuccess(
      token,
      refreshToken: refreshTokenFrom(headers['set-cookie']),
      user: _tryUser(json is Map ? json['user'] : null),
    );
  }
  if (status == 401 || status == 403) {
    final lower = body.toLowerCase();
    if (refreshRejectionBodies.any((b) => lower.contains(b.toLowerCase()))) {
      return RefreshRejected(status);
    }
  }
  if (status >= 300 && status < 400) {
    final location = headers['location']?.first;
    if (location != null && _isLoginRedirect(location, serverUrl)) {
      return RefreshRejected(status);
    }
  }
  return RefreshFailed(
    AppException(
      FailureKind.server,
      status: status,
      message: ApiClient.errorText(body),
    ),
  );
}

/// The value of the first non-empty `refreshToken` cookie in [setCookies].
String? refreshTokenFrom(List<String>? setCookies) {
  for (final cookie in setCookies ?? const <String>[]) {
    final pair = cookie.split(';').first.trim();
    final eq = pair.indexOf('=');
    if (eq < 0 || pair.substring(0, eq).trim() != 'refreshToken') continue;
    final value = pair.substring(eq + 1).trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}

/// Upstream's `res.redirect('/login')`: a hop on the Server_Authority whose
/// path is `/login` at the host root or under the Server_URL's subpath. A
/// forward-auth portal on another host never matches.
bool _isLoginRedirect(String location, String serverUrl) {
  final target = serverUri(serverUrl, '/api/auth/refresh').resolve(location);
  if (!isServerAuthority(target, serverUrl)) return false;
  final path = target.path.replaceFirst(_trailingSlashes, '');
  final base = Uri.parse(serverUrl).path.replaceFirst(_trailingSlashes, '');
  return path == '/login' || path == '$base/login';
}

final _trailingSlashes = RegExp(r'/+$');

Object? _tryDecode(String body) {
  try {
    return body.trim().isEmpty ? null : jsonDecode(body);
  } on FormatException {
    return null;
  }
}

User? _tryUser(Object? json) {
  if (json is! Map) return null;
  try {
    return User.fromJson(json.cast<String, Object?>());
  } on TypeError {
    return null;
  } on CheckedFromJsonException {
    return null;
  }
}

/// Every auth route (design `#### AuthService`). Only AuthService calls the
/// session routes; the screens call the account routes directly.
class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  /// `POST /api/auth/login`. LDAP usernames go in `email` too (Req 9.2).
  Future<TokenReply> login(String email, String password) async => _tokenReply(
    await _api.send(
      'POST',
      '/api/auth/login',
      data: {'email': email, 'password': password},
    ),
  );

  /// `POST /api/auth/2fa/verify-temp` with a TOTP [code] or a [backupCode]
  /// (Req 10.1–10.2).
  Future<TokenReply> verifyTempToken(
    String tempToken, {
    String? code,
    String? backupCode,
  }) async => _tokenReply(
    await _api.send(
      'POST',
      '/api/auth/2fa/verify-temp',
      data: {'tempToken': tempToken, 'token': ?code, 'backupCode': ?backupCode},
    ),
  );

  /// `POST /api/auth/refresh` with only the `refreshToken` cookie (Req 12.5)
  /// and redirects off, so a 3xx to `/login` is visible.
  Future<RefreshResult> refresh(String refreshToken) async {
    final response = await _api.send(
      'POST',
      '/api/auth/refresh',
      refreshCookie: refreshToken,
      followRedirects: false,
      checkStatus: false,
    );
    // dio decodes a JSON content type; anything else arrives as text.
    final data = response.data;
    return classifyRefresh(
      response.statusCode ?? 0,
      response.headers.map,
      data is String ? data : (data == null ? '' : jsonEncode(data)),
      _api.serverUrl!,
    );
  }

  /// `POST /api/auth/logout`.
  Future<void> logout() => _api.send('POST', '/api/auth/logout');

  /// `GET /api/user`.
  Future<User> user() => _api.json('GET', '/api/user', _decodeUser);

  /// `POST /api/auth/register`; returns the Server's message (Req 11.1–11.3).
  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) => _api.json(
    'POST',
    '/api/auth/register',
    _message,
    data: {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    },
  );

  /// `POST /api/auth/requestPasswordReset` (Req 11.4–11.5). The `link` is
  /// present when the Server has no email service.
  Future<({String? message, String? link})> requestPasswordReset(
    String email,
  ) => _api.json(
    'POST',
    '/api/auth/requestPasswordReset',
    (json) => (message: _message(json), link: _field(json, 'link')),
    data: {'email': email},
  );

  /// `POST /api/auth/resetPassword` (Req 11.6).
  Future<String?> resetPassword({
    required String userId,
    required String token,
    required String password,
    required String confirmPassword,
  }) => _api.json(
    'POST',
    '/api/auth/resetPassword',
    _message,
    data: {
      'userId': userId,
      'token': token,
      'password': password,
      'confirm_password': confirmPassword,
    },
  );

  /// `POST /api/user/verify/resend` (Req 11.7).
  Future<String?> resendVerification(String email) => _api.json(
    'POST',
    '/api/user/verify/resend',
    _message,
    data: {'email': email},
  );

  /// `GET /api/user/terms`: whether the user accepted the terms (Req 11.8).
  Future<bool> termsAccepted() => _api.json(
    'GET',
    '/api/user/terms',
    (json) => (json as Map)['termsAccepted'] == true,
  );

  /// `POST /api/user/terms/accept` (Req 11.9).
  Future<void> acceptTerms() => _api.send('POST', '/api/user/terms/accept');

  /// Reads a login or two-factor response. A body that is not an object, or
  /// a `user` that doesn't decode, is malformed.
  static TokenReply _tokenReply(Response<Object?> response) {
    try {
      var json = response.data;
      if (json is String) json = json.trim().isEmpty ? null : jsonDecode(json);
      final map = json as Map;
      final user = map['user'];
      return (
        token: map['token'] as String?,
        user: user == null ? null : _decodeUser(user),
        twoFAPending: map['twoFAPending'] == true,
        tempToken: map['tempToken'] as String?,
        refreshToken: refreshTokenFrom(response.headers['set-cookie']),
      );
    } on FormatException {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    } on TypeError {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    } on CheckedFromJsonException {
      throw AppException(FailureKind.malformed, status: response.statusCode);
    }
  }

  static User _decodeUser(Object? json) =>
      User.fromJson((json! as Map).cast<String, Object?>());

  static String? _message(Object? json) => _field(json, 'message');

  static String? _field(Object? json, String key) {
    final value = json is Map ? json[key] : null;
    return value is String ? value : null;
  }
}
