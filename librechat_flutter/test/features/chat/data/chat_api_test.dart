import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';

import '../../../support/test_server.dart';

/// [ChatApi] routes and reply shapes against a scripted Server (Req 18.2,
/// 19.6, 20.2, 21.10).
void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late CacheDb db;
  late ChatApi api;

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('chat_api_test');
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
    api = ChatApi(client, statusRetryDelay: Duration.zero);
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  test('start posts the payload to the endpoint\'s route and reads the '
      'Stream id', () async {
    server.on(
      'POST',
      '/api/agents/chat/openAI',
      respondJson({
        'streamId': 's1',
        'conversationId': 'c1',
        'status': 'started',
        'generationCreatedAt': 1700000000000,
      }),
    );

    final start = await api.start('openAI', {'text': 'Hi'});

    final request = server.requestsTo('/api/agents/chat/openAI').single;
    expect(request.json, {'text': 'Hi'});
    expect(request.header('authorization'), 'Bearer access-1');
    expect(start.streamId, 's1');
    expect(start.generationCreatedAt, 1700000000000);
  });

  test('start falls back to the conversation id as the Stream id', () async {
    server.on(
      'POST',
      '/api/agents/chat/agents',
      respondJson({'conversationId': 'c1'}),
    );

    final start = await api.start('agents', const {});

    expect(start.streamId, 'c1');
    expect(start.generationCreatedAt, isNull);
  });

  test('generateTitle reads the title', () async {
    server.on(
      'GET',
      '/api/convos/gen_title/c1',
      respondJson({'title': 'Trip plans'}),
    );

    expect(await api.generateTitle('c1'), 'Trip plans');
  });

  test('abort names the Run, or "new" while its Stream id is '
      'unknown', () async {
    server.on(
      'POST',
      '/api/agents/chat/abort',
      respondJson({'success': true, 'aborted': 's1'}),
    );

    await api.abort(streamId: 's1', isTemporary: true, generationCreatedAt: 7);
    await api.abort(streamId: null, isTemporary: false);

    final [first, second] = server.requestsTo('/api/agents/chat/abort');
    expect(first.json, {
      'abortKey': 's1',
      'conversationId': 's1',
      'endpoint': 'agents',
      'isTemporary': true,
      'generationCreatedAt': 7,
    });
    expect(second.json, {
      'conversationId': 'new',
      'endpoint': 'agents',
      'isTemporary': false,
    });
  });

  test('status reads the Run, retrying while the Server is not '
      'ready', () async {
    server
      ..enqueue(
        'GET',
        '/api/agents/chat/status/c1',
        respondJson({'code': 'SERVER_NOT_READY'}, status: 503),
      )
      ..on(
        'GET',
        '/api/agents/chat/status/c1',
        respondJson({
          'active': true,
          'streamId': 'c1',
          'status': 'requires_action',
          'createdAt': 1700000000000,
          'pendingAction': {'actionId': 'a1', 'payload': <String, Object?>{}},
        }),
      );

    final status = await api.status('c1');

    expect(server.requestsTo('/api/agents/chat/status/c1'), hasLength(2));
    expect(status.active, isTrue);
    expect(status.streamId, 'c1');
    expect(status.createdAt, 1700000000000);
    expect(status.pendingAction!.actionId, 'a1');
  });

  test('status reads an ended Run, and gives up on a Server that stays '
      'not ready', () async {
    server.enqueue(
      'GET',
      '/api/agents/chat/status/c1',
      respondJson({'active': false}),
    );
    final ended = await api.status('c1');
    expect(ended.active, isFalse);
    expect(ended.pendingAction, isNull);

    server.on(
      'GET',
      '/api/agents/chat/status/c1',
      respondJson({'code': 'SERVER_NOT_READY'}, status: 503),
    );
    await expectLater(
      api.status('c1'),
      throwsA(isA<AppException>().having((e) => e.status, 'status', 503)),
    );
    expect(
      server.requestsTo('/api/agents/chat/status/c1'),
      hasLength(2 + ChatApi.statusRetries),
    );
  });
}
