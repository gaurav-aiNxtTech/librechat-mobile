/// Why the Server_URL_Normalizer rejected an input (Req 8.4), with the text the
/// Server_URL_Screen shows under the URL field (Req 8.5).
enum UrlProblem {
  // KMP ServerUrlViewModel.kt.
  empty('Please enter a server URL'),
  // The KMP_App has no scheme, host or port checks, so these texts are new.
  scheme('Use an http:// or https:// URL'),
  host("Enter the server's host name"),
  port('Port must be a number from 1 to 65535');

  const UrlProblem(this.message);

  final String message;
}

/// Normalizes a typed Server_URL (Req 8.1–8.3), or reports the first problem
/// that applies, in the order Req 8.4 lists. Exactly one field is non-null.
///
/// The URL is split by hand rather than with `Uri.parse`, so each problem
/// stays exact. The output is `scheme://host[:port]path`, and normalizing it
/// again returns it unchanged (Req 8.6).
({String? url, UrlProblem? problem}) normalizeServerUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return (url: null, problem: UrlProblem.empty);
  if (!text.contains('://')) text = 'https://$text';

  final schemeEnd = text.indexOf('://');
  final scheme = text.substring(0, schemeEnd).toLowerCase();
  final rest = text.substring(schemeEnd + 3);

  // Everything from the first `?` or `#` is dropped, with any whitespace
  // before it. The authority runs to the first `/`, and the path follows.
  // Whitespace before that `/` is trimmed with `trimRight`, matching the input
  // `trim`, so it never stays in the host or port (Req 8.6).
  final beforeQuery = rest
      .substring(0, _indexOfAny(rest, const ['?', '#'], 0))
      .trimRight();
  final authorityEnd = _indexOfAny(beforeQuery, const ['/'], 0);
  final authority = beforeQuery.substring(0, authorityEnd).trimRight();
  final path = beforeQuery.substring(authorityEnd);

  // User info runs up to the last `@`; the port follows the last `:` outside
  // `[…]`, so an IPv6 literal keeps its colons.
  final hostPort = authority.substring(authority.lastIndexOf('@') + 1);
  final colon = hostPort.lastIndexOf(':');
  final hasPort = colon > hostPort.lastIndexOf(']');
  final host = (hasPort ? hostPort.substring(0, colon) : hostPort)
      .toLowerCase();
  final portText = hasPort ? hostPort.substring(colon + 1) : null;

  if (scheme != 'http' && scheme != 'https') {
    return (url: null, problem: UrlProblem.scheme);
  }
  // A colon left outside `[…]` after the port split, as in `a:b:443`, would
  // move into the port on the next normalization.
  if (host.isEmpty || host.replaceAll(_bracketLiteral, '').contains(':')) {
    return (url: null, problem: UrlProblem.host);
  }

  var port = '';
  if (portText != null) {
    final value = _digits.hasMatch(portText) ? int.tryParse(portText) : null;
    if (value == null || value < 1 || value > 65535) {
      return (url: null, problem: UrlProblem.port);
    }
    if (value != _defaultPort(scheme)) port = ':$value';
  }

  return (url: '$scheme://$host$port${_trimPathEnd(path)}', problem: null);
}

/// Strips trailing `/` and whitespace in any mix, such as `/a/ /`, until the
/// path ends in neither. Uses `trimRight` so the whitespace set matches the
/// input `trim`, which keeps the output stable (Req 8.6).
String _trimPathEnd(String path) {
  var current = path;
  while (true) {
    final next = current.trimRight().replaceFirst(_trailingSlashes, '');
    if (next == current) return current;
    current = next;
  }
}

/// Whether [uri] is on the Server_Authority of [serverUrl]: the same scheme,
/// host (compared case-insensitively) and port, with the default port filled
/// in where none is written (Req 4.3). Callers check each redirect hop.
bool isServerAuthority(Uri uri, String serverUrl) {
  final server = Uri.tryParse(serverUrl);
  if (server == null) return false;
  final scheme = uri.scheme.toLowerCase();
  return scheme == server.scheme.toLowerCase() &&
      uri.host.toLowerCase() == server.host.toLowerCase() &&
      _portOf(uri, scheme) == _portOf(server, scheme);
}

/// Resolves [path], which may carry a query, against [serverUrl] and keeps the
/// Server_URL's subpath (Req 4.1): `https://host/librechat` with
/// `/api/config` gives `https://host/librechat/api/config`. An absolute
/// `http(s)` URL passes through unchanged.
Uri serverUri(String serverUrl, String path) {
  final lower = path.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Uri.parse(path);
  }
  final base = serverUrl.replaceFirst(_trailingSlashes, '');
  final relative = path.isEmpty || path.startsWith('/') ? path : '/$path';
  return Uri.parse('$base$relative');
}

final _digits = RegExp(r'^[0-9]+$');
final _trailingSlashes = RegExp(r'/+$');
final _bracketLiteral = RegExp(r'\[[^\]]*\]');

int? _defaultPort(String scheme) => switch (scheme) {
  'https' => 443,
  'http' => 80,
  _ => null,
};

int? _portOf(Uri uri, String scheme) =>
    uri.hasPort ? uri.port : _defaultPort(scheme);

/// The index of the first of [chars] in [text] at or after [start], or the
/// length of [text] when none occurs.
int _indexOfAny(String text, List<String> chars, int start) {
  var end = text.length;
  for (final c in chars) {
    final i = text.indexOf(c, start);
    if (i != -1 && i < end) end = i;
  }
  return end;
}
