import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/network/api_client.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';
import 'package:librechat_flutter/features/chat/data/messages_api.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';

import '../../support/test_server.dart';

/// [ConversationsApi] and [MessagesApi] route, query and body shapes against
/// a scripted Server (Req 4.5, 15, 16).
void main() {
  late TestServer server;
  late Directory logDir;
  late DiagnosticLog log;
  late CacheDb db;
  late ApiClient client;
  late ConversationsApi api;

  setUp(() async {
    server = await TestServer.start();
    logDir = await Directory.systemTemp.createTemp('conversations_api_test');
    log = await DiagnosticLog.open(directory: logDir);
    db = CacheDb(NativeDatabase.memory());
    // Wires AuthService and ApiClient the way `main()` does.
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
    client = ApiClient(secure: secure, auth: auth, log: log);
    auth.api = AuthApi(client);
    await auth.load();
    api = ConversationsApi(client);
  });

  tearDown(() async {
    await server.close();
    await db.close();
    await log.file();
    await logDir.delete(recursive: true);
  });

  RecordedRequest only(String path) => server.requestsTo(path).single;

  group('GET /api/convos', () {
    test('sends the defaults and decodes the page', () async {
      server.on(
        'GET',
        '/api/convos',
        respondJson({
          'conversations': [
            {'conversationId': 'c1', 'title': 'One', 'pinned': true},
            {'conversationId': 'c2', 'isArchived': false},
          ],
          'nextCursor': 'next-1',
        }),
      );

      final page = await api.list();

      final request = only('/api/convos');
      expect(request.method, 'GET');
      expect(request.uri.queryParametersAll, {
        'limit': ['25'],
        'isArchived': ['false'],
      });
      expect(request.header('authorization'), 'Bearer access-1');
      expect(page.conversations.map((c) => c.conversationId), ['c1', 'c2']);
      expect(page.conversations.first.pinned, isTrue);
      expect(page.nextCursor, 'next-1');
    });

    test('sends cursor, archived, trimmed search and repeated tags', () async {
      server.on('GET', '/api/convos', respondJson({'nextCursor': null}));

      final page = await api.list(
        cursor: 'cur-2',
        limit: 10,
        isArchived: true,
        search: '  lisbon trip ',
        tags: ['work', 'a b'],
      );

      expect(only('/api/convos').uri.queryParametersAll, {
        'cursor': ['cur-2'],
        'limit': ['10'],
        'isArchived': ['true'],
        'search': ['lisbon trip'],
        'tags': ['work', 'a b'],
      });
      expect(page.conversations, isEmpty, reason: 'absent reads as empty');
      expect(page.nextCursor, isNull);
    });

    test('a blank search is not sent', () async {
      server.on('GET', '/api/convos', respondJson({'conversations': []}));

      await api.list(search: '   ');

      expect(
        only('/api/convos').uri.queryParameters,
        isNot(contains('search')),
      );
    });
  });

  test('GET /api/convos/{id} encodes the id', () async {
    server.on(
      'GET',
      '/api/convos/a%20b',
      respondJson({
        'conversationId': 'a b',
        'tags': ['work'],
      }),
    );

    final conversation = await api.get('a b');

    expect(server.requests.single.uri.toString(), '/api/convos/a%20b');
    expect(conversation.tags, ['work']);
  });

  group('Arg_Envelope routes', () {
    test('POST /api/convos/update', () async {
      server.on(
        'POST',
        '/api/convos/update',
        respondJson({'conversationId': 'c1', 'title': 'New'}, status: 201),
      );

      final saved = await api.rename('c1', 'New');

      final request = only('/api/convos/update');
      expect(request.method, 'POST');
      expect(request.json, {
        'arg': {'conversationId': 'c1', 'title': 'New'},
      });
      expect(saved?.title, 'New');
    });

    test('POST /api/convos/archive', () async {
      server.on(
        'POST',
        '/api/convos/archive',
        respondJson({'conversationId': 'c1', 'isArchived': true}),
      );

      final saved = await api.archive('c1', true);

      expect(only('/api/convos/archive').json, {
        'arg': {'conversationId': 'c1', 'isArchived': true},
      });
      expect(saved?.isArchived, isTrue);
    });

    test('POST /api/convos/pin', () async {
      server.on(
        'POST',
        '/api/convos/pin',
        respondJson({'conversationId': 'c1', 'pinned': false}),
      );

      final saved = await api.pin('c1', false);

      expect(only('/api/convos/pin').json, {
        'arg': {'conversationId': 'c1', 'pinned': false},
      });
      expect(saved?.pinned, isFalse);
    });

    test('DELETE /api/convos', () async {
      server.on(
        'DELETE',
        '/api/convos',
        respondJson({'acknowledged': true, 'deletedCount': 1}, status: 201),
      );

      await api.delete('c1');

      final request = only('/api/convos');
      expect(request.method, 'DELETE');
      expect(request.json, {
        'arg': {'conversationId': 'c1'},
      });
    });

    test('a body that is not a conversation reads as null', () async {
      server.on('POST', '/api/convos/update', respondJson([], status: 201));

      expect(await api.rename('c1', 'New'), isNull);
    });
  });

  group('POST /api/convos/duplicate', () {
    test('sends no Arg_Envelope and decodes conversation', () async {
      server.on(
        'POST',
        '/api/convos/duplicate',
        respondJson({
          'conversation': {'conversationId': 'copy-1', 'title': 'Copy of T'},
          'messages': [
            {'messageId': 'm1', 'conversationId': 'copy-1'},
          ],
        }, status: 201),
      );

      final copy = await api.duplicate('c1', 'Copy of T');

      expect(only('/api/convos/duplicate').json, {
        'conversationId': 'c1',
        'title': 'Copy of T',
      });
      expect(copy.conversationId, 'copy-1');
      expect(copy.title, 'Copy of T');
    });

    test('falls back to the whole body', () async {
      server.on(
        'POST',
        '/api/convos/duplicate',
        respondJson({'conversationId': 'copy-2'}, status: 201),
      );

      expect((await api.duplicate('c1', 'x')).conversationId, 'copy-2');
    });
  });

  test('POST /api/convos/import uploads the multipart file field', () async {
    server.on(
      'POST',
      '/api/convos/import',
      respondJson({'message': 'Conversation(s) imported'}, status: 201),
    );

    await api.importFile(
      Uint8List.fromList(utf8.encode('{"title":"T"}')),
      'export.json',
    );

    final request = only('/api/convos/import');
    expect(request.method, 'POST');
    expect(request.header('content-type'), startsWith('multipart/form-data'));
    expect(
      request.body,
      contains(
        'content-disposition: form-data; name="file"; '
        'filename="export.json"',
      ),
    );
    expect(request.body, contains('content-type: application/json'));
    expect(request.body, contains('{"title":"T"}'));
  });

  test('an import rejection surfaces the Server message', () async {
    server.on(
      'POST',
      '/api/convos/import',
      respondJson({
        'message': 'File exceeds the maximum allowed size',
      }, status: 413),
    );

    await expectLater(
      api.importFile(Uint8List(1), 'big.json'),
      throwsA(
        isA<AppException>()
            .having((e) => e.status, 'status', 413)
            .having(
              (e) => e.message,
              'message',
              'File exceeds the maximum allowed size',
            ),
      ),
    );
  });

  group('tags', () {
    test('GET /api/tags decodes the list', () async {
      server.on(
        'GET',
        '/api/tags',
        respondJson([
          {'_id': 'x', 'tag': 'work', 'count': 2, 'position': 0},
          {'tag': 'later'},
        ]),
      );

      final tags = await api.tags();

      expect(only('/api/tags').method, 'GET');
      expect(tags.map((t) => (t.tag, t.count)), [('work', 2), ('later', 0)]);
    });

    test('POST /api/tags', () async {
      server.on('POST', '/api/tags', respondJson({'tag': 'new'}, status: 201));

      expect((await api.createTag('new')).tag, 'new');
      expect(only('/api/tags').json, {'tag': 'new'});
    });

    test('PUT /api/tags/{tag} encodes the tag', () async {
      server.on('PUT', '/api/tags/a%2Fb%20c', respondJson({'tag': 'd'}));

      expect((await api.renameTag('a/b c', 'd')).tag, 'd');
      final request = server.requests.single;
      expect(request.method, 'PUT');
      expect(request.uri.toString(), '/api/tags/a%2Fb%20c');
      expect(request.json, {'tag': 'd'});
    });

    test('DELETE /api/tags/{tag} encodes the tag', () async {
      server.on('DELETE', '/api/tags/a%2Fb', respondJson({'tag': 'a/b'}));

      await api.deleteTag('a/b');

      final request = server.requests.single;
      expect(request.method, 'DELETE');
      expect(request.uri.toString(), '/api/tags/a%2Fb');
      expect(request.body, isEmpty);
    });

    test('PUT /api/tags/convo/{id} sends tags and reads names', () async {
      server.on(
        'PUT',
        '/api/tags/convo/c1',
        respondJson([
          'work',
          {'tag': 'later'},
        ]),
      );

      final tags = await api.setConversationTags('c1', ['work', 'later']);

      final request = only('/api/tags/convo/c1');
      expect(request.method, 'PUT');
      expect(request.json, {
        'tags': ['work', 'later'],
      });
      expect(tags, ['work', 'later']);
    });

    test('a tag list reply that is not a list echoes the request', () async {
      server.on('PUT', '/api/tags/convo/c1', respondJson({'ok': true}));

      expect(await api.setConversationTags('c1', ['a']), ['a']);
    });

    test('a 404 without a message marks Bookmarks missing', () async {
      await expectLater(
        api.tags(),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unsupported,
          ),
        ),
      );
      expect(client.missingFeatures.value, {Feature.bookmarks});
    });
  });

  group('share links', () {
    test('GET /api/share/link/{id} reuses a successful shareId', () async {
      server.on(
        'GET',
        '/api/share/link/c1',
        respondJson({
          'success': true,
          'shareId': 'share-9',
          'conversationId': 'c1',
        }),
      );

      expect(await api.sharedLinkId('c1'), 'share-9');
      expect(only('/api/share/link/c1').method, 'GET');
    });

    test('success false is no link', () async {
      server.on(
        'GET',
        '/api/share/link/c1',
        respondJson({'success': false, 'shareId': null}),
      );

      expect(await api.sharedLinkId('c1'), isNull);
    });

    test('POST /api/share/{id} sends an empty object', () async {
      server.on(
        'POST',
        '/api/share/c1',
        respondJson({'shareId': 'share-new'}, status: 201),
      );

      expect(await api.createShareLink('c1'), 'share-new');
      expect(only('/api/share/c1').json, <String, Object?>{});
    });
  });

  test('a pin 404 marks Feature.pin missing', () async {
    await expectLater(
      api.pin('c1', true),
      throwsA(
        isA<AppException>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unsupported,
        ),
      ),
    );
    expect(client.missingFeatures.value, {Feature.pin});
  });

  test('GET /api/messages/{id} decodes the messages in order', () async {
    server.on(
      'GET',
      '/api/messages/c%201',
      respondJson([
        {'messageId': 'm1', 'conversationId': 'c 1', 'isCreatedByUser': true},
        {'messageId': 'm2', 'conversationId': 'c 1', 'text': 'Hi'},
      ]),
    );

    final messages = await MessagesApi(client).list('c 1');

    final request = server.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.toString(), '/api/messages/c%201');
    expect(messages.map((m) => m.messageId), ['m1', 'm2']);
    expect(messages.first.isCreatedByUser, isTrue);
    expect(messages.last.text, 'Hi');
  });

  // The message actions' request shapes (Task 21.3).
  group('POST /api/convos/fork', () {
    test('sends the mode, the split and the path\'s leaf, and decodes the '
        'new conversation with its messages (Req 25.9)', () async {
      server.on(
        'POST',
        '/api/convos/fork',
        respondJson({
          'conversation': {'conversationId': 'fork-1', 'title': 'Trip plans'},
          'messages': [
            {'messageId': 'u1', 'conversationId': 'fork-1'},
            {'messageId': 'a1', 'conversationId': 'fork-1', 'text': 'Hi'},
          ],
        }, status: 201),
      );

      final forked = await api.fork(
        conversationId: 'c1',
        messageId: 'a1',
        option: 'targetLevel',
        splitAtTarget: true,
        latestMessageId: 'leaf-1',
      );

      final request = only('/api/convos/fork');
      expect(request.method, 'POST');
      expect(request.json, {
        'conversationId': 'c1',
        'messageId': 'a1',
        'option': 'targetLevel',
        'splitAtTarget': true,
        'latestMessageId': 'leaf-1',
      });
      expect(forked.conversation.conversationId, 'fork-1');
      expect(forked.conversation.title, 'Trip plans');
      expect(forked.messages.map((m) => m.messageId), ['u1', 'a1']);
    });

    test('leaves out an absent leaf and reads absent messages as '
        'empty', () async {
      server.on(
        'POST',
        '/api/convos/fork',
        respondJson({
          'conversation': {'conversationId': 'fork-2'},
        }, status: 201),
      );

      final forked = await api.fork(
        conversationId: 'c1',
        messageId: 'a1',
        option: 'directPath',
        splitAtTarget: false,
      );

      expect(only('/api/convos/fork').json, {
        'conversationId': 'c1',
        'messageId': 'a1',
        'option': 'directPath',
        'splitAtTarget': false,
      });
      expect(forked.messages, isEmpty);
    });
  });

  group('PUT /api/messages/{conversationId}/{messageId}', () {
    test('saves the text into a content part by index and reads the '
        'Server\'s message (Req 25.3)', () async {
      server.on(
        'PUT',
        '/api/messages/c1/a1',
        respondJson({
          'messageId': 'a1',
          'conversationId': 'c1',
          'content': [
            {'type': 'text', 'text': 'Saved answer'},
          ],
        }),
      );

      final saved = await MessagesApi(
        client,
      ).update('c1', 'a1', text: 'Saved answer', index: 1);

      final request = only('/api/messages/c1/a1');
      expect(request.method, 'PUT');
      expect(request.json, {'text': 'Saved answer', 'index': 1});
      expect(saved.messageId, 'a1');
      expect(saved.content!.single.text, 'Saved answer');
    });

    test('leaves out the index for a message with no content parts', () async {
      server.on(
        'PUT',
        '/api/messages/c1/u1',
        respondJson({
          'messageId': 'u1',
          'conversationId': 'c1',
          'text': 'Edited',
        }),
      );

      final saved = await MessagesApi(
        client,
      ).update('c1', 'u1', text: 'Edited');

      expect(only('/api/messages/c1/u1').json, {'text': 'Edited'});
      expect(saved.text, 'Edited');
    });

    test('encodes both ids', () async {
      server.on(
        'PUT',
        '/api/messages/c%201/a%2Fb',
        respondJson({'messageId': 'a/b', 'conversationId': 'c 1'}),
      );

      await MessagesApi(client).update('c 1', 'a/b', text: 'x');

      expect(
        server.requests.single.uri.toString(),
        '/api/messages/c%201/a%2Fb',
      );
    });
  });

  group('PUT /api/messages/{conversationId}/{messageId}/feedback', () {
    test('sends the rating, the reason tag and the comment, and reads the '
        'stored feedback (Req 25.6)', () async {
      server.on(
        'PUT',
        '/api/messages/c1/a1/feedback',
        respondJson({
          'messageId': 'a1',
          'conversationId': 'c1',
          'feedback': {
            'rating': 'thumbsDown',
            'tag': 'inaccurate',
            'text': 'Wrong dates',
          },
        }),
      );

      final feedback = await MessagesApi(client).setFeedback(
        'c1',
        'a1',
        rating: 'thumbsDown',
        tag: 'inaccurate',
        text: 'Wrong dates',
      );

      final request = only('/api/messages/c1/a1/feedback');
      expect(request.method, 'PUT');
      expect(request.json, {
        'feedback': {
          'rating': 'thumbsDown',
          'tag': 'inaccurate',
          'text': 'Wrong dates',
        },
      });
      expect(feedback!.rating, FeedbackRating.thumbsDown);
      expect(feedback.tag, 'inaccurate');
      expect(feedback.text, 'Wrong dates');
    });

    test('leaves out an absent comment', () async {
      server.on(
        'PUT',
        '/api/messages/c1/a1/feedback',
        respondJson({
          'feedback': {'rating': 'thumbsUp', 'tag': 'creative_solution'},
        }),
      );

      final feedback = await MessagesApi(
        client,
      ).setFeedback('c1', 'a1', rating: 'thumbsUp', tag: 'creative_solution');

      expect(only('/api/messages/c1/a1/feedback').json, {
        'feedback': {'rating': 'thumbsUp', 'tag': 'creative_solution'},
      });
      expect(feedback!.rating, FeedbackRating.thumbsUp);
      expect(feedback.text, isNull);
    });

    test('a clear sends an empty body and reads no feedback '
        '(Req 25.7)', () async {
      server.on(
        'PUT',
        '/api/messages/c1/a1/feedback',
        respondJson({'messageId': 'a1', 'conversationId': 'c1'}),
      );

      expect(await MessagesApi(client).clearFeedback('c1', 'a1'), isNull);

      final request = only('/api/messages/c1/a1/feedback');
      expect(request.method, 'PUT');
      expect(request.json, <String, Object?>{});
    });

    test('a 404 marks the feedback feature missing', () async {
      await expectLater(
        MessagesApi(client).setFeedback('c1', 'a1', rating: 'x', tag: 'y'),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            FailureKind.unsupported,
          ),
        ),
      );
      expect(client.missingFeatures.value, {Feature.feedback});
    });
  });
}
