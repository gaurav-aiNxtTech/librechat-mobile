/// A scripted HTTP server for HTTP and stream tests.
///
/// It binds a dart:io [HttpServer] to 127.0.0.1 on port 0, answers each
/// request from a script and records every request in arrival order. Use it
/// from plain `test()` only: `testWidgets` swaps HttpClient for a fake that
/// answers 400.
///
/// ```dart
/// late TestServer server;
/// setUp(() async => server = await TestServer.start());
/// tearDown(() => server.close());
///
/// server.on('GET', '/api/config', respondJson({'appTitle': 'LibreChat'}));
/// server.enqueue('POST', '/api/auth/refresh', respond(status: 401));
/// ```
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Answers one request. Every handler must close or detach [response].
typedef TestHandler =
    FutureOr<void> Function(RecordedRequest request, HttpResponse response);

/// A request as the server received it, with its whole body.
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.bodyBytes,
  });

  final String method;

  /// The request target: path and query, without scheme or host.
  final Uri uri;

  /// Header names are lowercase.
  final Map<String, List<String>> headers;

  final List<int> bodyBytes;

  String get path => uri.path;

  String get body => utf8.decode(bodyBytes, allowMalformed: true);

  Object? get json => jsonDecode(body);

  /// The header's values joined with `, `, or null when absent.
  String? header(String name) => headers[name.toLowerCase()]?.join(', ');

  @override
  String toString() => '$method $uri';
}

class TestServer {
  TestServer._(this._server) {
    _server.listen(_handle);
  }

  /// Starts a server on 127.0.0.1 with a free port.
  static Future<TestServer> start() async =>
      TestServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final _requests = <RecordedRequest>[];
  final _queued = <String, List<TestHandler>>{};
  final _routes = <String, TestHandler>{};

  /// `http://127.0.0.1:<port>`.
  Uri get uri => Uri(scheme: 'http', host: '127.0.0.1', port: _server.port);

  /// [path] (with an optional query) resolved against [uri].
  Uri url(String path) => uri.resolve(path);

  /// Every request so far, in arrival order.
  List<RecordedRequest> get requests => List.unmodifiable(_requests);

  /// The recorded requests to [path], in arrival order.
  List<RecordedRequest> requestsTo(String path) =>
      _requests.where((r) => r.path == path).toList();

  /// Answers every [method] request to [path] (the query is ignored) with
  /// [handler], after any [enqueue]d handlers are used up.
  void on(String method, String path, TestHandler handler) =>
      _routes[_key(method, path)] = handler;

  /// Answers only the next [method] request to [path] with [handler].
  /// Queued handlers run in the order they were added, before [on].
  void enqueue(String method, String path, TestHandler handler) =>
      _queued.putIfAbsent(_key(method, path), () => []).add(handler);

  /// Stops the server and drops open connections, including hung ones.
  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final headers = <String, List<String>>{};
    request.headers.forEach((name, values) => headers[name] = values);
    final body = await request.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    final recorded = RecordedRequest(
      method: request.method,
      uri: request.uri,
      headers: headers,
      bodyBytes: body,
    );
    _requests.add(recorded);

    final key = _key(request.method, request.uri.path);
    final queue = _queued[key];
    final handler = (queue != null && queue.isNotEmpty)
        ? queue.removeAt(0)
        : _routes[key] ??
              respond(
                status: HttpStatus.notFound,
                body: 'No scripted response for $key',
              );
    await handler(recorded, request.response);
  }

  static String _key(String method, String path) =>
      '${method.toUpperCase()} $path';
}

/// Responds with [status], [headers] and a text [body].
TestHandler respond({
  int status = HttpStatus.ok,
  Map<String, String> headers = const {},
  String body = '',
  Duration? delay,
}) => (_, response) async {
  if (delay != null) await Future<void>.delayed(delay);
  response.statusCode = status;
  headers.forEach(response.headers.set);
  response.write(body);
  await response.close();
};

/// Responds with [json] encoded as `application/json`.
TestHandler respondJson(
  Object? json, {
  int status = HttpStatus.ok,
  Map<String, String> headers = const {},
  Duration? delay,
}) => respond(
  status: status,
  headers: {'content-type': 'application/json; charset=utf-8', ...headers},
  body: jsonEncode(json),
  delay: delay,
);

/// Redirects to [location], which may be relative or on another server.
TestHandler redirect(String location, {int status = HttpStatus.found}) =>
    respond(status: status, headers: {'location': location});

/// Sends [chunks] as separate HTTP chunks, [gap] apart, then ends the body.
/// With [dropAtEnd] it closes the connection mid-body instead, so the client
/// sees an error rather than a clean end. Feeds SSE and chunked bodies.
TestHandler respondChunks(
  List<String> chunks, {
  int status = HttpStatus.ok,
  Map<String, String> headers = const {'content-type': 'text/event-stream'},
  Duration gap = Duration.zero,
  bool dropAtEnd = false,
}) => (_, response) async {
  response.statusCode = status;
  headers.forEach(response.headers.set);
  response.headers.chunkedTransferEncoding = true;
  response.persistentConnection = false;
  // Framing the chunks by hand on the raw socket is what lets the body stop
  // without its terminating chunk.
  final socket = await response.detachSocket();
  for (final chunk in chunks) {
    final bytes = utf8.encode(chunk);
    // A zero-length chunk would end the body early.
    if (bytes.isEmpty) continue;
    socket
      ..write('${bytes.length.toRadixString(16)}\r\n')
      ..add(bytes)
      ..write('\r\n');
    await socket.flush();
    if (gap > Duration.zero) await Future<void>.delayed(gap);
  }
  if (dropAtEnd) {
    socket.destroy();
  } else {
    socket.write('0\r\n\r\n');
    await socket.close();
  }
};

/// Never responds, for timeout tests. [TestServer.close] drops the connection.
TestHandler hang() =>
    (_, _) => Completer<void>().future;

/// Closes the connection without sending a response.
TestHandler dropConnection() => (_, response) async {
  final socket = await response.detachSocket(writeHeaders: false);
  socket.destroy();
};
