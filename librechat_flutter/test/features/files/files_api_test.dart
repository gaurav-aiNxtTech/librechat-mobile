import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/features/files/files_api.dart';

import '../../support/test_server.dart';

/// [FilesApi] and [mergeFileConfig]: the upload's multipart shape, its
/// progress and cancel, and the megabyte limits the Server serves
/// (Req 26.2, 26.6).
void main() {
  group('mergeFileConfig', () {
    test('without a served config the Server defaults apply', () {
      final config = mergeFileConfig(null);
      expect(config, builtInFileConfig);
      final entry = config.endpoints['default']!;
      expect(entry.fileLimit, 10);
      expect(entry.fileSizeLimit, 512 * megabyte);
      expect(entry.totalSizeLimit, 512 * megabyte);
      expect(entry.supportedMimeTypes, builtInSupportedMimeTypes);
      expect(entry.disabled, isFalse);
      // The Server seeds these four beside `default`.
      expect(
        config.endpoints.keys,
        containsAll(['agents', 'assistants', 'azureAssistants', 'anthropic']),
      );
    });

    test('the served sizes are megabytes and the count is not', () {
      final config = mergeFileConfig(
        const FileConfig(
          endpoints: {
            'assistants': EndpointFileConfig(
              fileLimit: 5,
              fileSizeLimit: 10,
              totalSizeLimit: 50,
            ),
          },
          serverFileSizeLimit: 100,
        ),
      );
      final entry = config.endpoints['assistants']!;
      expect(entry.fileLimit, 5);
      expect(entry.fileSizeLimit, 10 * megabyte);
      expect(entry.totalSizeLimit, 50 * megabyte);
      expect(config.serverFileSizeLimit, 100 * megabyte);
    });

    test('a served entry keeps the built-in fields it leaves out', () {
      final config = mergeFileConfig(
        const FileConfig(
          endpoints: {'agents': EndpointFileConfig(fileLimit: 2)},
        ),
      );
      final entry = config.endpoints['agents']!;
      expect(entry.fileLimit, 2);
      expect(entry.fileSizeLimit, 512 * megabyte);
      expect(entry.supportedMimeTypes, builtInSupportedMimeTypes);
    });

    test('an entry the Server has no default for starts empty', () {
      // `default` fills these fields in at check time, not here, so the
      // resolution order stays the Server's.
      final config = mergeFileConfig(
        const FileConfig(
          endpoints: {'openAI': EndpointFileConfig(fileSizeLimit: 1)},
        ),
      );
      final entry = config.endpoints['openAI']!;
      expect(entry.fileSizeLimit, megabyte);
      expect(entry.fileLimit, isNull);
      expect(entry.supportedMimeTypes, isEmpty);
    });

    test('disabled zeroes the limits', () {
      final config = mergeFileConfig(
        const FileConfig(
          endpoints: {
            'openAI': EndpointFileConfig(disabled: true, fileSizeLimit: 10),
          },
        ),
      );
      final entry = config.endpoints['openAI']!;
      expect(entry.disabled, isTrue);
      expect(entry.fileLimit, 0);
      expect(entry.fileSizeLimit, 0);
      expect(entry.totalSizeLimit, 0);
    });

    test('text patterns override the built-in any-type list', () {
      expect(
        mergeFileConfig(null).text?.supportedMimeTypes,
        builtInTextMimeTypes,
      );
      final narrowed = mergeFileConfig(
        const FileConfig(
          text: MimeTypesConfig(supportedMimeTypes: [r'^text/plain$']),
        ),
      );
      expect(narrowed.text?.supportedMimeTypes, [r'^text/plain$']);
    });

    test('the built-in patterns match what the Server accepts', () {
      final patterns = builtInSupportedMimeTypes.map(RegExp.new).toList();
      bool accepts(String mime) => patterns.any((p) => p.hasMatch(mime));
      for (final mime in const [
        'text/plain',
        'text/markdown',
        'application/pdf',
        'application/json',
        'application/zip',
        'application/vnd.openxmlformats-officedocument.'
            'wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'image/png',
        'image/heic',
        'image/svg+xml',
        'video/mp4',
        'audio/mpeg',
        'message/rfc822',
      ]) {
        expect(accepts(mime), isTrue, reason: mime);
      }
      for (final mime in const [
        'application/octet-stream',
        'application/vnd.ms-powerpoint',
        'image/bmp',
        'text/plain; charset=utf-8',
      ]) {
        expect(accepts(mime), isFalse, reason: mime);
      }
    });
  });

  group('uploadMimeType', () {
    test('rewrites only the spellings the Server rejects', () {
      expect(uploadMimeType('text/x-sh'), 'application/x-sh');
      expect(
        uploadMimeType('text/x-sh; charset=utf-8'),
        'application/x-sh; charset=utf-8',
      );
      expect(uploadMimeType('image/png'), 'image/png');
      expect(uploadMimeType('  '), 'application/octet-stream');
    });
  });

  group('routes', () {
    late TestServer server;
    late Directory logDir;
    late DiagnosticLog log;
    late CacheDb db;
    late FilesApi api;

    setUp(() async {
      server = await TestServer.start();
      logDir = await Directory.systemTemp.createTemp('files_api_test');
      log = await DiagnosticLog.open(directory: logDir);
      db = CacheDb(NativeDatabase.memory());
      FlutterSecureStorage.setMockInitialValues({
        SecureStore.serverUrlKey: server.uri.toString(),
        SecureStore.sessionKey: jsonEncode({
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'user': {'_id': 'u1', 'role': 'USER'},
        }),
      });
      final secure = SecureStore();
      await secure.load();
      final auth = AuthService(secure: secure, cache: db);
      final client = ApiClient(secure: secure, auth: auth, log: log);
      auth.api = AuthApi(client);
      await auth.load();
      api = FilesApi(client);
    });

    tearDown(() async {
      await server.close();
      await db.close();
      await log.file();
      await logDir.delete(recursive: true);
    });

    test('GET /api/files/config converts the served megabytes', () async {
      server.on(
        'GET',
        '/api/files/config',
        respondJson({
          'endpoints': {
            'assistants': {'fileLimit': 5, 'fileSizeLimit': 10},
          },
        }),
      );

      final config = await api.config();

      expect(config.endpoints['assistants']?.fileSizeLimit, 10 * megabyte);
      expect(config.endpoints['default']?.fileLimit, 10);
    });

    test('an empty body leaves the Server defaults', () async {
      server.on('GET', '/api/files/config', respond());
      expect(await api.config(), builtInFileConfig);
    });

    test('POST /api/files sends the file and its fields', () async {
      server.on(
        'POST',
        '/api/files',
        respondJson({
          'file_id': 'f1',
          'filename': 'note.txt',
          'filepath': '/images/u1/note.txt',
          'type': 'text/plain',
          'bytes': 5,
        }),
      );

      final object = await api.upload(
        bytes: Uint8List.fromList(utf8.encode('hello')),
        filename: 'note.txt',
        type: 'text/plain',
        fileId: 'f1',
        endpoint: 'agents',
        agentId: 'a1',
        toolResource: 'context',
      );

      expect(object.fileId, 'f1');
      expect(object.filepath, '/images/u1/note.txt');
      final request = server.requestsTo('/api/files').single;
      expect(request.method, 'POST');
      expect(request.header('content-type'), contains('multipart/form-data'));
      final body = request.body;
      expect(body, contains('name="file"'));
      expect(body, contains('filename="note.txt"'));
      expect(body, contains('text/plain'));
      expect(body, contains('hello'));
      for (final field in const [
        'name="file_id"',
        'name="endpoint"',
        'name="agent_id"',
        'name="tool_resource"',
        'name="message_file"',
      ]) {
        expect(body, contains(field), reason: field);
      }
      // Only the fields the upload was given are sent.
      expect(body, isNot(contains('name="model"')));
      expect(body, isNot(contains('name="width"')));
    });

    test('an image sends its pixel size', () async {
      server.on('POST', '/api/files', respondJson({'file_id': 'f2'}));

      await api.upload(
        bytes: Uint8List(8),
        filename: 'photo.png',
        type: 'image/png',
        fileId: 'f2',
        width: 120,
        height: 90,
      );

      final body = server.requestsTo('/api/files').single.body;
      expect(body, contains('name="width"'));
      expect(body, contains('120'));
      expect(body, contains('name="height"'));
      expect(body, contains('90'));
    });

    test('progress is reported and a cancel ends the upload', () async {
      server.on(
        'POST',
        '/api/files',
        respondJson({
          'file_id': 'f3',
        }, delay: const Duration(milliseconds: 200)),
      );
      final token = CancelToken();
      var reported = 0;

      final upload = api.upload(
        bytes: Uint8List(64 * 1024),
        filename: 'big.bin',
        type: 'application/octet-stream',
        fileId: 'f3',
        onProgress: (_, _) => reported++,
        cancelToken: token,
      );
      token.cancel();

      await expectLater(
        upload,
        throwsA(
          isA<DioException>().having(
            (e) => CancelToken.isCancel(e),
            'isCancel',
            isTrue,
          ),
        ),
      );
      expect(reported, greaterThanOrEqualTo(0));
    });
  });
}
