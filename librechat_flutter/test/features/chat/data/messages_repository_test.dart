import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';

import '../../../support/fakes.dart';

Message _m(String id, {String conversation = 'c1', int minutes = 0}) => Message(
  messageId: id,
  conversationId: conversation,
  text: id,
  createdAt: DateTime.utc(2026, 3, 1).add(Duration(minutes: minutes)),
);

void main() {
  late CacheDb db;
  late FakeMessagesApi api;
  late MessagesRepository repository;
  String? user = 'u1';

  setUp(() {
    db = CacheDb(NativeDatabase.memory());
    api = FakeMessagesApi();
    user = 'u1';
    repository = MessagesRepository(api, db, currentUser: () => user);
  });

  tearDown(() => db.close());

  Future<List<String>> cached(String conversationId) async => [
    for (final m in await repository.watch(conversationId).first) m.messageId,
  ];

  test(
    'watch lists one conversation oldest first, skipping bad rows',
    () async {
      await repository.upsert('c1', [_m('b', minutes: 2), _m('a', minutes: 1)]);
      await repository.upsert('c2', [_m('x', conversation: 'c2')]);
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              id: 'bad',
              conversationId: 'c1',
              json: '{"text":',
              createdAt: 0,
            ),
          );

      expect(await cached('c1'), ['a', 'b']);
      expect(await cached('c2'), ['x']);
    },
  );

  group('fetch', () {
    test('replaces only that conversation\'s rows', () async {
      await repository.upsert('c1', [_m('stale')]);
      await repository.upsert('c2', [_m('other', conversation: 'c2')]);
      api.messages['c1'] = [_m('a', minutes: 1), _m('b', minutes: 2)];

      final fetched = await repository.fetch('c1');

      expect([for (final m in fetched) m.messageId], ['a', 'b']);
      expect(await cached('c1'), ['a', 'b']);
      expect(await cached('c2'), ['other']);
      expect(api.requests, ['c1']);
    });

    test('never shows an empty list in between', () async {
      await repository.upsert('c1', [_m('old')]);
      final seen = <List<String>>[];
      final sub = repository
          .watch('c1')
          .listen((list) => seen.add([for (final m in list) m.messageId]));
      await pumpEventQueue();
      api.messages['c1'] = [_m('new')];

      await repository.fetch('c1');
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.first, ['old']);
      expect(seen.last, ['new']);
      expect(seen, isNot(contains(isEmpty)));
    });

    test('a failure keeps the rows', () async {
      await repository.upsert('c1', [_m('kept')]);
      api.error = StateError('offline');

      await expectLater(repository.fetch('c1'), throwsStateError);
      expect(await cached('c1'), ['kept']);
    });

    test('a user change during the request skips the write', () async {
      await repository.upsert('c1', [_m('kept')]);
      api
        ..messages['c1'] = [_m('new')]
        ..gate = Completer<void>();

      final fetching = repository.fetch('c1');
      user = 'u2';
      api.gate!.complete();

      expect([for (final m in await fetching) m.messageId], ['new']);
      expect(await cached('c1'), ['kept']);
    });
  });

  test('upsert replaces a message by id', () async {
    await repository.upsert('c1', [_m('a')]);
    await repository.upsert('c1', [_m('a').copyWith(text: 'edited')]);

    final rows = await repository.watch('c1').first;
    expect(rows.single.text, 'edited');
  });

  test('drafts save, replace, read and delete by key', () async {
    expect(await repository.draft('new'), isNull);

    await repository.saveDraft('new', 'hello');
    await repository.saveDraft('new', 'hello again');
    await repository.saveDraft('c1', 'other');
    expect(await repository.draft('new'), 'hello again');

    await repository.deleteDraft('new');
    expect(await repository.draft('new'), isNull);
    expect(await repository.draft('c1'), 'other');

    await repository.saveDraft('c1', '   ');
    expect(await repository.draft('c1'), isNull);
  });
}
