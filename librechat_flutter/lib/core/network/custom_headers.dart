/// Why the Header_Validator rejected a Custom_Headers row (Req 5.2), with the
/// reason text the editor shows next to the row (Req 5.3). The texts are the
/// KMP `core/ui` strings `server_headers_error_name`,
/// `server_headers_error_reserved` and `server_headers_error_value`.
enum HeaderProblem {
  name('Not a valid header name.'),
  reserved("This header is set by the app and can't be overridden."),
  value("This value contains characters that can't be sent.");

  const HeaderProblem(this.message);

  final String message;
}

/// The Reserved_Header_Names, in lowercase (KMP `CustomHeaderRules`).
const reservedHeaderNames = {
  'host',
  'content-length',
  'transfer-encoding',
  'connection',
  'upgrade',
  'te',
  'authorization',
  'user-agent',
  'accept',
  'accept-encoding',
  'content-type',
  'expect',
  'proxy-authorization',
};

/// Validates one name/value row after trimming both fields, and reports the
/// first problem that holds, in the order Req 5.2 lists, or null.
HeaderProblem? validateHeader(String name, String value) {
  final n = name.trim();
  if (n.isEmpty || !n.codeUnits.every(_isTokenChar)) return HeaderProblem.name;
  if (reservedHeaderNames.contains(n.toLowerCase())) {
    return HeaderProblem.reserved;
  }
  if (!value.trim().codeUnits.every(_isValueChar)) return HeaderProblem.value;
  return null;
}

/// Builds Custom_Headers from editor rows (Req 5.4): trims each name and
/// value, skips rows that are then empty on both sides, and keeps the last row
/// for each name compared case-insensitively. The kept row's name spelling is
/// used, at the position where that name first appeared.
Map<String, String> buildCustomHeaders(Iterable<(String, String)> rows) {
  final byLowerName = <String, (String, String)>{};
  for (final (name, value) in rows) {
    final n = name.trim();
    final v = value.trim();
    if (n.isEmpty && v.isEmpty) continue;
    byLowerName[n.toLowerCase()] = (n, v);
  }
  return {for (final (n, v) in byLowerName.values) n: v};
}

/// The single `Cookie` header for a request that carries the Refresh_Token
/// (Req 5.8): `refreshToken=<token>` first, then each trimmed, non-empty
/// `;`-separated segment of [customCookie] whose cookie name is not exactly
/// `refreshToken`, joined by `; `. Cookie names are case-sensitive (RFC 6265),
/// so a `refreshtoken` segment is kept. The result always holds exactly one
/// `refreshToken` segment.
String mergeCookieHeader(String? customCookie, String refreshToken) {
  final segments = ['refreshToken=$refreshToken'];
  for (final part in (customCookie ?? '').split(';')) {
    final segment = part.trim();
    if (segment.isEmpty) continue;
    final eq = segment.indexOf('=');
    final cookieName = (eq == -1 ? segment : segment.substring(0, eq)).trim();
    if (cookieName != 'refreshToken') segments.add(segment);
  }
  return segments.join('; ');
}

// RFC 7230 tchar: letters, digits and these specials.
const _tokenSpecials = "!#\$%&'*+-.^_`|~";

bool _isTokenChar(int c) =>
    (c >= 0x61 && c <= 0x7A) || // a-z
    (c >= 0x41 && c <= 0x5A) || // A-Z
    (c >= 0x30 && c <= 0x39) || // 0-9
    _tokenSpecials.codeUnits.contains(c);

// Printable US-ASCII plus horizontal tab.
bool _isValueChar(int c) => c == 0x09 || (c >= 0x20 && c <= 0x7E);
