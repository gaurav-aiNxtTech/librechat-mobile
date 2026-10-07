import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'test_server.dart';

void main() {
  late TestServer server;
  late HttpClient client;

  setUp(() async {
    server = await TestServer.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
  });

  Future<HttpClientResponse> send(
    String method,
    String path, {
    Map<String, String> headers = const {},
    String? body,
    bool followRedirects = true,
  }) async {
    final request = await client.openUrl(method, server.url(path));
    request.followRedirects = followRedirects;
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    return request.close();
  }

  Future<String> text(HttpClientResponse response) =>
      response.transform(utf8.decoder).join();

  test('binds to 127.0.0.1 on a free port', () {
    expect(server.uri.host, '127.0.0.1');
    expect(server.uri.port, greaterThan(0));
  });

  test('records method, target, headers and body in arrival order', () async {
    server.on('POST', '/api/items', respond(status: 201));
    await send('GET', '/api/items?page=2');
    await send(
      'POST',
      '/api/items',
      headers: {
        'Authorization': 'Bearer t',
        'Content-Type': 'application/json',
      },
      body: '{"name":"a"}',
    );

    expect(server.requests.map((r) => '$r'), [
      'GET /api/items?page=2',
      'POST /api/items',
    ]);
    final post = server.requestsTo('/api/items').last;
    expect(post.header('authorization'), 'Bearer t');
    expect(post.json, {'name': 'a'});
    expect(server.requests.first.uri.queryParameters, {'page': '2'});
  });

  test('queued handlers answer once, in order, before the route', () async {
    server
      ..on('GET', '/x', respond(body: 'route'))
      ..enqueue('GET', '/x', respond(status: 401, body: 'first'))
      ..enqueue('GET', '/x', respond(body: 'second'));

    final statuses = <int>[];
    final bodies = <String>[];
    for (var i = 0; i < 3; i++) {
      final response = await send('GET', '/x?ignored=1');
      statuses.add(response.statusCode);
      bodies.add(await text(response));
    }
    expect(statuses, [401, 200, 200]);
    expect(bodies, ['first', 'second', 'route']);
  });

  test('an unscripted request gets a 404 naming it', () async {
    final response = await send('DELETE', '/nope');
    expect(response.statusCode, 404);
    expect(await text(response), 'No scripted response for DELETE /nope');
  });

  test('respondJson sets the content type and encodes the body', () async {
    server.on(
      'GET',
      '/api/config',
      respondJson({'a': 1}, headers: {'x-k': 'v'}),
    );
    final response = await send('GET', '/api/config');
    expect(response.headers.contentType?.mimeType, 'application/json');
    expect(response.headers.value('x-k'), 'v');
    expect(jsonDecode(await text(response)), {'a': 1});
  });

  test('redirect sends a Location', () async {
    server.on('GET', '/old', redirect('/new'));
    final response = await send('GET', '/old', followRedirects: false);
    expect(response.statusCode, 302);
    expect(response.headers.value('location'), '/new');
  });

  test(
    'respondChunks delivers each chunk separately and ends cleanly',
    () async {
      server.on(
        'GET',
        '/stream',
        respondChunks([
          'data: 1\n\n',
          '',
          'data: 2\n\n',
        ], gap: const Duration(milliseconds: 20)),
      );
      final response = await send('GET', '/stream');
      expect(response.headers.contentType?.mimeType, 'text/event-stream');
      final chunks = await response.transform(utf8.decoder).toList();
      expect(chunks, ['data: 1\n\n', 'data: 2\n\n']);
    },
  );

  test(
    'respondChunks with dropAtEnd errors the body after the chunks',
    () async {
      server.on(
        'GET',
        '/stream',
        respondChunks(['data: 1\n\n'], dropAtEnd: true),
      );
      final response = await send('GET', '/stream');
      final received = <String>[];
      await expectLater(
        response.transform(utf8.decoder).forEach(received.add),
        throwsA(isA<HttpException>()),
      );
      expect(received, ['data: 1\n\n']);
    },
  );

  test('dropConnection closes without a response', () async {
    server.on('GET', '/drop', dropConnection());
    await expectLater(send('GET', '/drop'), throwsA(isA<HttpException>()));
  });

  test('hang never answers', () async {
    server.on('GET', '/slow', hang());
    await expectLater(
      send('GET', '/slow').timeout(const Duration(milliseconds: 200)),
      throwsA(isA<TimeoutException>()),
    );
    expect(server.requestsTo('/slow'), hasLength(1));
  });
}
