/// What went wrong, coarsely, so the UI can pick its copy without reading an
/// exception's own text (Req 4.11).
enum FailureKind {
  /// No usable connection: DNS, a refused or reset socket, the connect timeout.
  network,

  /// The request was sent but no complete response came back in time.
  timeout,

  /// A 2xx body that did not decode.
  malformed,

  /// An access gateway answered instead of the Server (Req 5.9).
  gateway,

  /// A 4xx or 5xx response not covered by another kind.
  server,

  /// A 404 on a feature-tagged route (Req 6.7).
  unsupported,

  /// The Server rejected the refresh, so the session is over.
  sessionExpired,

  /// Anything unrecognised.
  unknown,
}

/// The one failure type that ApiClient and Stream_Client raise.
///
/// [message] is the Server's own text from the error body. [userMessage]
/// shows it only for [FailureKind.server] and only when it passes
/// [looksLikeUserMessage]. [signedIn] picks the gateway copy (Req 5.9).
class AppException implements Exception {
  AppException(this.kind, {this.status, this.message, this.signedIn = true});

  final FailureKind kind;
  final int? status;
  final String? message;
  final bool signedIn;

  /// Leaves out [message], which may carry a URL with a token in it.
  @override
  String toString() => 'AppException(${kind.name}, status: $status)';
}

// KMP FailureMessages.kt.
const _network = 'Network unavailable. Check your connection.';
const _timeout = 'The server took too long to respond.';
const _malformed = 'Unexpected response from the server.';
const _gatewaySignedIn =
    "Your server's access gateway rejected this request. "
    'Check Server connection in Settings.';
const _unknown = 'Something went wrong. Please try again.';
// KMP ConfigRepositoryImpl.kt, shown before sign-in on the Server_URL_Screen.
const _gatewaySignedOut =
    "Your server's access gateway rejected this request. "
    'Check the gateway headers under Advanced.';
// KMP settings strings.xml `api_keys_not_supported`.
const _unsupported = 'This feature is not supported on your server version.';
// KMP shared strings.xml `session_expired_message`.
const _sessionExpired = 'Your session has expired. Sign in again to continue.';

/// The text a widget shows for [error]. Anything that is not an
/// [AppException] gets the unknown copy, so no raw exception text leaks.
String userMessage(Object error) {
  if (error is! AppException) return _unknown;
  return switch (error.kind) {
    FailureKind.network => _network,
    FailureKind.timeout => _timeout,
    FailureKind.malformed => _malformed,
    FailureKind.gateway =>
      error.signedIn ? _gatewaySignedIn : _gatewaySignedOut,
    FailureKind.server => _serverMessage(error),
    FailureKind.unsupported => _unsupported,
    FailureKind.sessionExpired => _sessionExpired,
    FailureKind.unknown => _unknown,
  };
}

String _serverMessage(AppException error) {
  final text = error.message;
  if (text != null && looksLikeUserMessage(text)) return text.trim();
  final status = error.status;
  if (status == null) return _unknown;
  // KMP LibreChatHttpClient.kt status fallbacks.
  return switch (status) {
    400 => 'Bad request',
    403 => 'Access denied',
    404 => 'Not found',
    429 => 'Too many requests. Please try again later.',
    >= 500 && <= 599 => 'Server error. Please try again later.',
    _ => 'Request failed (HTTP $status)',
  };
}

/// Whether Server-authored [text] reads as a sentence for a person, after
/// KMP `looksLikeUserMessage`. A gateway's HTML page, a redirect URL with a
/// token in its query, or a raw token fails.
///
/// After trimming: not empty, at most 200 characters, no `<`, `>`, CR, LF
/// or `://`, and no run of more than 40 characters without a space.
bool looksLikeUserMessage(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.length > 200) return false;
  if (trimmed.contains(_markupOrBreak) || trimmed.contains('://')) {
    return false;
  }
  return !trimmed.split(' ').any((run) => run.length > 40);
}

final _markupOrBreak = RegExp('[<>\r\n]');
