import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/features/chat/data/conversation_messages.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';

import '../../../support/fakes.dart';

Message _m(String id, {String? parent, int minutes = 0, String? text}) =>
    Message(
      messageId: id,
      conversationId: 'c1',
      parentMessageId: parent ?? rootParentId,
      text: text ?? id,
      createdAt: DateTime.utc(2026, 3, 1).add(Duration(minutes: minutes)),
    );

List<String> _ids(Iterable<Message> messages) => [
  for (final m in messages) m.messageId,
];

void main() {
  late CacheDb db;
  late FakeMessagesApi api;
  late MessagesRepository repository;
  late ProviderContainer container;
  var temporary = false;

  setUp(() {
    db = CacheDb(NativeDatabase.memory());
    api = FakeMessagesApi();
    repository = MessagesRepository(api, db, currentUser: () => 'u1');
    temporary = false;
    container = ProviderContainer(
      overrides: [
        messagesRepositoryProvider.overrideWithValue(repository),
        isTemporaryChatProvider.overrideWith((ref, id) => temporary),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  final provider = conversationMessagesProvider('c1');

  /// Keeps the provider alive and records every state.
  List<AsyncValue<ConversationMessages>> open() {
    final states = <AsyncValue<ConversationMessages>>[];
    container.listen(
      provider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    return states;
  }

  ConversationMessages data() => container.read(provider).requireValue;
  ConversationMessagesNotifier notifier() => container.read(provider.notifier);

  Future<List<String>> cached() async =>
      _ids(await repository.watch('c1').first);

  test('shows the cached messages first, then the Server\'s', () async {
    await repository.upsert('c1', [_m('a')]);
    api
      ..messages['c1'] = [_m('a', text: 'server'), _m('b', parent: 'a')]
      ..gate = Completer<void>();
    open();

    final first = await container.read(provider.future);
    expect(_ids(first.messages), ['a']);
    expect(first.refreshing, isTrue);

    api.gate!.complete();
    await pumpEventQueue();
    expect(_ids(data().messages), ['a', 'b']);
    expect(data().messages.first.text, 'server');
    expect(data().refreshing, isFalse);
    expect(await cached(), ['a', 'b']);
  });

  test('with nothing cached it loads, and an empty result settles', () async {
    api.gate = Completer<void>();
    final states = open();
    await pumpEventQueue();
    expect(states.last.isLoading, isTrue);

    api.gate!.complete();
    await pumpEventQueue();
    expect(data().messages, isEmpty);
    expect(data().refreshing, isFalse);
  });

  test('a failed fetch keeps the cached messages and reports it', () async {
    await repository.upsert('c1', [_m('a')]);
    api.error = StateError('offline');
    open();
    await pumpEventQueue();

    expect(_ids(data().messages), ['a']);
    expect(data().refreshError, isStateError);
    expect(data().refreshing, isFalse);
  });

  test(
    'a failed fetch with nothing cached is an error that reload retries',
    () async {
      api.error = StateError('offline');
      open();
      await pumpEventQueue();
      expect(container.read(provider).hasError, isTrue);

      api
        ..error = null
        ..messages['c1'] = [_m('a')];
      await notifier().reload();
      expect(_ids(data().messages), ['a']);
      expect(data().refreshError, isNull);
    },
  );

  test(
    'applyFinal shows the turn at once and survives a stale emission',
    () async {
      await repository.upsert('c1', [_m('a')]);
      api.messages['c1'] = [_m('a')];
      open();
      await pumpEventQueue();

      notifier().applyFinal(
        FinalTurn(
          messages: [
            _m('u', parent: 'a', minutes: 1),
            _m('r', parent: 'u', minutes: 2),
          ],
          selection: const {'a': 'u'},
          justSettledId: 'r',
        ),
      );
      expect(_ids(data().path), ['a', 'u', 'r']);
      expect(data().justSettledId, 'r');
      expect(data().selection, {'a': 'u'});

      // A Cache write of another row emits before RunService's upsert lands.
      await repository.upsert('c1', [_m('a', text: 'renamed')]);
      await pumpEventQueue();
      expect(_ids(data().path), ['a', 'u', 'r']);
      expect(data().messages.first.text, 'renamed');
    },
  );

  test(
    'local messages are kept, never cached and never the next parent',
    () async {
      api.messages['c1'] = [_m('a')];
      open();
      await pumpEventQueue();
      expect(data().nextParentId, 'a');

      notifier().addLocal([
        _m('opt', parent: 'a', minutes: 1),
        _m('partial', parent: 'opt', minutes: 2),
      ]);
      expect(_ids(data().path), ['a', 'opt', 'partial']);
      expect(data().localIds, {'opt', 'partial'});
      expect(data().nextParentId, 'a');
      expect(await cached(), ['a']);

      // The Server saved the user message after all.
      api.messages['c1'] = [_m('a'), _m('opt', parent: 'a', minutes: 1)];
      await notifier().reload();
      expect(data().localIds, {'partial'});
      expect(data().nextParentId, 'opt');
    },
  );

  test('select rebuilds the Active_Path from the chosen Sibling', () async {
    api.messages['c1'] = [
      _m('a'),
      _m('r1', parent: 'a', minutes: 1),
      _m('r2', parent: 'a', minutes: 2),
    ];
    open();
    await pumpEventQueue();
    expect(_ids(data().path), ['a', 'r2']);

    notifier().select(selectSibling(data().path, 1, 'r1'));
    expect(_ids(data().path), ['a', 'r1']);
  });

  test('upsertMessage shows and caches the message', () async {
    api.messages['c1'] = [_m('a')];
    open();
    await pumpEventQueue();

    await notifier().upsertMessage(_m('a', text: 'edited'));
    await pumpEventQueue();
    expect(data().messages.single.text, 'edited');
    expect((await repository.watch('c1').first).single.text, 'edited');
  });

  test('a temporary chat never touches the Cache', () async {
    temporary = true;
    await repository.upsert('c1', [_m('cached')]);
    api.messages['c1'] = [_m('a')];
    open();
    await pumpEventQueue();
    expect(_ids(data().messages), ['a']);

    await notifier().upsertMessage(_m('b', parent: 'a', minutes: 1));
    expect(_ids(data().messages), ['a', 'b']);
    expect(await cached(), ['cached']);
  });
}
