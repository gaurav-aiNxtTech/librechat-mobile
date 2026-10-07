import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/images/image_loader.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

import '../../support/test_server.dart';

void main() {
  late TestServer server;
  late Directory tempDir;
  late Directory imageDir;
  late DiagnosticLog log;
  late CacheDb db;
  late ApiClient api;
  late ImageLoader loader;

  setUp(() async {
    server = await TestServer.start();
    tempDir = await Directory.systemTemp.createTemp('image_loader_test');
    imageDir = Directory('${tempDir.path}/images');
    log = await DiagnosticLog.open(directory: tempDir);
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: server.uri.toString(),
      SecureStore.sessionKey: jsonEncode({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': {'_id': 'u1'},
      }),
    });
    final secure = SecureStore();
    await secure.load();
    db = CacheDb(NativeDatabase.memory());
    final auth = AuthService(secure: secure, cache: db);
    await auth.load();
    api = ApiClient(secure: secure, auth: auth, log: log);
    loader = ImageLoader(api, imageDir);
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await tempDir.delete(recursive: true);
  });

  test('decodes a data: URI in place without a request', () async {
    final image = await loader.load(
      'data:image/svg+xml;base64,${base64Encode(utf8.encode('<svg/>'))}',
    );

    expect(utf8.decode(image.bytes), '<svg/>');
    expect(image.svg, isTrue);
    expect(server.requests, isEmpty);
  });

  test('concurrent loads of one URL share one request', () async {
    server.on(
      'GET',
      '/images/u1/avatar.png',
      respond(
        headers: {'content-type': 'image/png'},
        body: 'png-bytes',
        delay: const Duration(milliseconds: 50),
      ),
    );

    final images = await Future.wait([
      loader.load('/images/u1/avatar.png'),
      loader.load(server.url('/images/u1/avatar.png').toString()),
    ]);

    expect(server.requestsTo('/images/u1/avatar.png'), hasLength(1));
    expect(utf8.decode(images[0].bytes), 'png-bytes');
    expect(images[1].bytes, images[0].bytes);
    expect(images[0].svg, isFalse);
  });

  test('clear() empties the disk cache', () async {
    server.on(
      'GET',
      '/images/u1/avatar.png',
      respond(headers: {'content-type': 'image/png'}, body: 'png-bytes'),
    );
    await loader.load('/images/u1/avatar.png');
    expect(imageDir.listSync(), hasLength(1));

    await loader.clear();

    expect(imageDir.existsSync() ? imageDir.listSync() : const [], isEmpty);
    // Memory is empty too, so the next load goes back to the Server.
    await loader.load('/images/u1/avatar.png');
    expect(server.requestsTo('/images/u1/avatar.png'), hasLength(2));
  });

  void servePng(String path, String body) => server.on(
    'GET',
    path,
    respond(headers: {'content-type': 'image/png'}, body: body),
  );

  test('a later load is served from memory', () async {
    servePng('/images/u1/avatar.png', 'png-bytes');
    await loader.load('/images/u1/avatar.png');
    // Without the disk copy, only memory can answer.
    await imageDir.delete(recursive: true);

    final image = await loader.load('/images/u1/avatar.png');

    expect(utf8.decode(image.bytes), 'png-bytes');
    expect(server.requestsTo('/images/u1/avatar.png'), hasLength(1));
  });

  test('after a restart the image is served from disk', () async {
    servePng('/images/u1/avatar.png', 'png-bytes');
    await loader.load('/images/u1/avatar.png');

    final restarted = ImageLoader(api, imageDir);
    final image = await restarted.load('/images/u1/avatar.png');

    expect(utf8.decode(image.bytes), 'png-bytes');
    expect(image.svg, isFalse);
    expect(server.requestsTo('/images/u1/avatar.png'), hasLength(1));
  });

  test('SVG is detected by content type and by bytes', () async {
    // A leading comment hides the SVG from the byte check.
    server.on(
      'GET',
      '/images/by-type',
      respond(
        headers: {'content-type': 'image/svg+xml'},
        body: '<!-- icon --><svg/>',
      ),
    );
    server.on(
      'GET',
      '/images/by-bytes',
      respond(
        headers: {'content-type': 'application/octet-stream'},
        body: '\n  <?xml version="1.0"?><svg/>',
      ),
    );

    expect((await loader.load('/images/by-type')).svg, isTrue);
    expect((await loader.load('/images/by-bytes')).svg, isTrue);
    // The type survives a restart through the file name.
    final restarted = ImageLoader(api, imageDir);
    expect((await restarted.load('/images/by-type')).svg, isTrue);
    expect(server.requests, hasLength(2));
  });

  test('a failed request throws and caches nothing', () async {
    server.enqueue('GET', '/images/u1/avatar.png', respond(status: 500));
    servePng('/images/u1/avatar.png', 'png-bytes');

    await expectLater(
      loader.load('/images/u1/avatar.png'),
      throwsA(
        isA<AppException>()
            .having((e) => e.kind, 'kind', FailureKind.server)
            .having((e) => e.status, 'status', 500),
      ),
    );
    expect(imageDir.existsSync() ? imageDir.listSync() : const [], isEmpty);

    final image = await loader.load('/images/u1/avatar.png');
    expect(utf8.decode(image.bytes), 'png-bytes');
    expect(server.requestsTo('/images/u1/avatar.png'), hasLength(2));
  });

  test('the memory LRU evicts the least recently used entry', () async {
    final small = ImageLoader(api, imageDir, maxMemoryBytes: 10);
    for (final name in ['a', 'b', 'c']) {
      servePng('/images/$name.png', '$name$name$name$name');
    }
    await small.load('/images/a.png');
    await small.load('/images/b.png');
    // 12 bytes pass the 10-byte cap, so a, the oldest, goes.
    await small.load('/images/c.png');
    await imageDir.delete(recursive: true);

    await small.load('/images/b.png');
    await small.load('/images/c.png');
    expect(server.requests, hasLength(3));
    await small.load('/images/a.png');
    expect(server.requestsTo('/images/a.png'), hasLength(2));
  });
}
