import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../support/fakes.dart';

/// A conversation updated [minutes] after a fixed instant.
Conversation _c(String id, {int minutes = 0, String? title}) => Conversation(
  conversationId: id,
  title: title ?? id,
  updatedAt: DateTime.utc(2026, 3, 1).add(Duration(minutes: minutes)),
);

void main() {
  late CacheDb db;
  late FakeConversationsApi api;
  late ConversationsRepository repository;
  String? user = 'u1';

  setUp(() {
    db = CacheDb(NativeDatabase.memory());
    api = FakeConversationsApi();
    user = 'u1';
    repository = ConversationsRepository(api, db, currentUser: () => user);
  });

  tearDown(() => db.close());

  /// Every cached row by id, decoded.
  Future<Map<String, Conversation>> rows() async => {
    for (final row in await db.select(db.conversations).get())
      row.id: Conversation.fromJson(
        jsonDecode(row.json) as Map<String, Object?>,
      ),
  };

  Future<List<String?>> listed() async => [
    for (final c in await repository.watchList().first) c.conversationId,
  ];

  group('refresh', () {
    test('replaces every row with page 1', () async {
      await repository.upsert(_c('stale'));
      await repository.upsert(_c('archived').copyWith(isArchived: true));
      api.pages.add((
        conversations: [_c('a', minutes: 1), _c('b', minutes: 2)],
        nextCursor: 'n1',
      ));

      expect(await repository.refresh(), 'n1');

      expect((await rows()).keys, unorderedEquals(['a', 'b']));
      expect(api.callsTo('list').single, [null, 25, false, null, const []]);
    });

    test('never shows an empty list in between', () async {
      await repository.upsert(_c('old'));
      final seen = <List<String?>>[];
      final sub = repository.watchList().listen(
        (list) => seen.add([for (final c in list) c.conversationId]),
      );
      await pumpEventQueue();
      api.pages.add((conversations: [_c('new')], nextCursor: null));

      await repository.refresh();
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, ['old']);
      expect(seen.last, ['new']);
      expect(seen, isNot(contains(isEmpty)));
    });

    test('a failure keeps the rows', () async {
      await repository.upsert(_c('kept'));
      api.error = StateError('offline');

      await expectLater(repository.refresh(), throwsStateError);
      expect((await rows()).keys, ['kept']);
    });
  });

  test('loadMore appends the page at the cursor', () async {
    api.pages
      ..add((conversations: [_c('a', minutes: 2)], nextCursor: 'n1'))
      ..add((
        conversations: [
          _c('b', minutes: 1),
          _c('a', minutes: 2, title: 'A2'),
        ],
        nextCursor: null,
      ));
    await repository.refresh();

    expect(await repository.loadMore('n1'), isNull);

    expect(api.callsTo('list').last.first, 'n1');
    final cached = await rows();
    expect(cached.keys, unorderedEquals(['a', 'b']));
    expect(cached['a']?.title, 'A2', reason: 'a repeated row updates');
  });

  test('watchList is newest first, without archived or broken rows', () async {
    await repository.upsert(_c('mid', minutes: 5));
    await repository.upsert(_c('new', minutes: 9));
    await repository.upsert(_c('old', minutes: 1));
    await repository.upsert(_c('gone', minutes: 7).copyWith(isArchived: true));
    await repository.upsert(const Conversation(title: 'no id'));
    await db
        .into(db.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: 'broken',
            json: '{not json',
            updatedAt: DateTime.utc(2027).millisecondsSinceEpoch,
          ),
        );

    expect(await listed(), ['new', 'mid', 'old']);
  });

  group('rename', () {
    test('writes the Server row after success', () async {
      await repository.upsert(_c('c1'));
      api.renameReply = _c('c1', title: 'Server title');

      final saved = await repository.rename(_c('c1'), 'Typed');

      expect(api.callsTo('rename').single, ['c1', 'Typed']);
      expect(saved.title, 'Server title');
      expect((await rows())['c1']?.title, 'Server title');
    });

    test('without a Server row, writes the local rename', () async {
      await repository.upsert(_c('c1'));

      await repository.rename(_c('c1'), 'Typed');

      expect((await rows())['c1']?.title, 'Typed');
    });

    test('a failure leaves the row unchanged', () async {
      await repository.upsert(_c('c1', title: 'Before'));
      api.error = StateError('rejected');

      await expectLater(repository.rename(_c('c1'), 'After'), throwsStateError);
      expect((await rows())['c1']?.title, 'Before');
    });
  });

  group('setPinned', () {
    test('writes the pin after success', () async {
      await repository.upsert(_c('c1'));
      api.pinReply = _c('c1');

      await repository.setPinned(_c('c1'), true);

      expect(api.callsTo('pin').single, ['c1', true]);
      expect((await rows())['c1']?.pinned, isTrue);
    });

    test('a failure leaves the row unchanged', () async {
      await repository.upsert(_c('c1'));
      api.error = StateError('rejected');

      await expectLater(repository.setPinned(_c('c1'), true), throwsStateError);
      expect((await rows())['c1']?.pinned, isNull);
    });
  });

  group('setTags', () {
    test("writes the Server's tag list after success", () async {
      await repository.upsert(_c('c1'));
      api.setTagsReply = ['work'];

      final saved = await repository.setTags(_c('c1'), ['work', 'x']);

      expect(api.callsTo('setConversationTags').single, [
        'c1',
        ['work', 'x'],
      ]);
      expect(saved.tags, ['work']);
      expect((await rows())['c1']?.tags, ['work']);
    });

    test('a failure leaves the row unchanged', () async {
      await repository.upsert(_c('c1').copyWith(tags: ['old']));
      api.error = StateError('rejected');

      await expectLater(
        repository.setTags(_c('c1'), ['new']),
        throwsStateError,
      );
      expect((await rows())['c1']?.tags, ['old']);
    });
  });

  test('archive hides the row and unarchive restores it', () async {
    await repository.upsert(_c('c1'));
    await repository.upsert(_c('c2', minutes: 1));
    api.archiveReply = _c('c1', title: 'Server');

    await repository.setArchived(_c('c1'), true);

    expect(api.callsTo('archive').single, ['c1', true]);
    expect(await listed(), ['c2']);
    expect((await rows())['c1']?.isArchived, isTrue);

    api.archiveReply = null;
    await repository.setArchived(_c('c1'), false);

    expect(await listed(), ['c2', 'c1']);
  });

  test('delete removes the row and its messages rows', () async {
    await repository.upsert(_c('c1'));
    await repository.upsert(_c('c2'));
    for (final (id, convo) in [('m1', 'c1'), ('m2', 'c1'), ('m3', 'c2')]) {
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: id,
              conversationId: convo,
              json: '{}',
              createdAt: 0,
            ),
          );
    }

    await repository.delete('c1');

    expect(api.callsTo('delete').single, ['c1']);
    expect((await rows()).keys, ['c2']);
    final messages = await db.select(db.messages).get();
    expect(messages.map((m) => m.id), ['m3']);
  });

  test('a failed delete keeps the row', () async {
    await repository.upsert(_c('c1'));
    api.error = StateError('rejected');

    await expectLater(repository.delete('c1'), throwsStateError);
    expect((await rows()).keys, ['c1']);
  });

  test('duplicate sends "Copy of" and caches the copy', () async {
    api.duplicateReply = _c('copy-1', minutes: 3, title: 'Copy of T');

    final copy = await repository.duplicate(_c('c1', title: 'T'));
    await repository.duplicate(const Conversation(conversationId: 'c2'));

    expect(api.callsTo('duplicate'), [
      ['c1', 'Copy of T'],
      ['c2', 'Copy of New Chat'],
    ]);
    expect(copy.conversationId, 'copy-1');
    expect(await listed(), ['copy-1']);
  });

  test('importFile only uploads; the caller refreshes', () async {
    await repository.upsert(_c('before'));
    final bytes = Uint8List.fromList([1, 2, 3]);

    await repository.importFile(bytes, 'export.json');

    expect([for (final (m, _) in api.calls) m], ['importFile']);
    expect(api.callsTo('importFile').single, [bytes, 'export.json']);
    expect(await listed(), ['before']);
  });

  test('a rejected import leaves the list unchanged', () async {
    await repository.upsert(_c('before'));
    api.error = StateError('413');

    await expectLater(
      repository.importFile(Uint8List(1), 'big.json'),
      throwsStateError,
    );
    expect([for (final (m, _) in api.calls) m], ['importFile']);
    expect(await listed(), ['before']);
  });

  group('a user change during the request skips the write', () {
    /// Runs [action] with the request held until the user signs out.
    Future<void> signOutDuring(Future<Object?> Function() action) async {
      user = 'u1';
      api.gate = Completer<void>();
      final pending = action();
      await pumpEventQueue();
      user = null;
      api.gate!.complete();
      await pending;
    }

    test('refresh', () async {
      await repository.upsert(_c('mine'));
      api.pages.add((conversations: [_c('theirs')], nextCursor: null));

      await signOutDuring(repository.refresh);

      expect((await rows()).keys, ['mine']);
    });

    test('loadMore', () async {
      api.pages.add((conversations: [_c('theirs')], nextCursor: null));

      await signOutDuring(() => repository.loadMore('n1'));

      expect(await rows(), isEmpty);
    });

    test('rename, pin, archive, tags and duplicate', () async {
      await repository.upsert(_c('c1', title: 'Before'));
      final before = (await rows())['c1'];

      await signOutDuring(() => repository.rename(_c('c1'), 'After'));
      await signOutDuring(() => repository.setPinned(_c('c1'), true));
      await signOutDuring(() => repository.setArchived(_c('c1'), true));
      await signOutDuring(() => repository.setTags(_c('c1'), ['t']));
      await signOutDuring(() => repository.duplicate(_c('c1')));

      expect(await rows(), {'c1': before});
    });

    test('delete', () async {
      await repository.upsert(_c('c1'));

      await signOutDuring(() => repository.delete('c1'));

      expect((await rows()).keys, ['c1']);
    });
  });
}
