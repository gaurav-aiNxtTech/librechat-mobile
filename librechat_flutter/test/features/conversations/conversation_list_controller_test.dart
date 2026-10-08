import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/tag.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/features/conversations/conversation_list_controller.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../support/fakes.dart';

/// The ConversationListController's results-mode edge cases, on fakes.
void main() {
  late FakeConversationsRepository repository;
  late FakeAuthService auth;
  late ValueNotifier<Set<Feature>> missing;
  late ProviderContainer container;

  FakeConversationsApi api() => repository.fakeApi;
  Session session(String user) => Session(
    accessToken: 'a',
    refreshToken: 'r',
    user: User(id: user),
  );
  Conversation convo(String id) => Conversation(conversationId: id);
  List<String?> ids(List<Conversation>? rows) => [
    for (final c in rows ?? const <Conversation>[]) c.conversationId,
  ];

  setUp(() async {
    repository = FakeConversationsRepository(rows: [convo('c1')]);
    auth = FakeAuthService()
      ..emit(serverUrl: 'https://chat.example.com/', session: session('u1'));
    missing = ValueNotifier<Set<Feature>>({});
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        serverConfigProvider.overrideWith(
          () => FakeServerConfig(const ServerInfo(config: StartupConfig())),
        ),
        missingFeaturesProvider.overrideWithValue(missing),
        conversationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(conversationListControllerProvider, (_, _) {});
    await pumpEventQueue();
  });

  tearDown(() => container.dispose());

  ConversationListController controller() =>
      container.read(conversationListControllerProvider.notifier);
  ConversationListState state() =>
      container.read(conversationListControllerProvider);

  /// Searches [query] now, answering [page].
  Future<void> search(String query, ConversationPage page) async {
    api().pages.add(page);
    controller().setQuery(query);
    await controller().refresh();
  }

  test(
    'an import refresh keeps a results page that is still loading',
    () async {
      await search('hello', (conversations: [convo('r1')], nextCursor: 'rc2'));
      final gate = Completer<void>();
      api()
        ..gate = gate
        ..pages.add((conversations: [convo('r2')], nextCursor: null));
      final more = controller().loadMore();
      api().gate = null;
      expect(state().loadingMore, isTrue);

      await controller().refreshList();
      gate.complete();
      await more;

      expect(ids(state().results), ['r1', 'r2']);
      expect(state().loadingMore, isFalse);
      expect(state().resultsCursor, isNull);
    },
  );

  test('results pages use the query and tags that made the cursor', () async {
    await search('hello', (conversations: [convo('r1')], nextCursor: 'rc2'));
    // Typed but not yet searched: the debounce is still pending.
    controller().setQuery('hello world');

    await controller().loadMore();

    expect(api().callsTo('list').last, ['rc2', 25, false, 'hello', <String>[]]);
  });

  group('Feature.bookmarks turning off', () {
    setUp(() async {
      api().tagsReply = const [Tag(tag: 'work', count: 1)];
      await controller().reloadTags();
    });

    test('drops a tag filter with a blank query back to the list', () async {
      api().pages.add((conversations: [convo('t1')], nextCursor: null));
      controller().toggleTag('work');
      await pumpEventQueue();
      expect(ids(state().results), ['t1']);

      missing.value = {Feature.bookmarks};
      await pumpEventQueue();

      expect(state().tags, isEmpty);
      expect(state().selectedTags, isEmpty);
      expect(state().results, isNull);
    });

    test('searches the query again without the tags', () async {
      controller().toggleTag('work');
      await search('hello', (conversations: [convo('t1')], nextCursor: null));
      expect(api().callsTo('list').last, [
        null,
        25,
        false,
        'hello',
        ['work'],
      ]);

      api().pages.add((conversations: [convo('h1')], nextCursor: null));
      missing.value = {Feature.bookmarks};
      await pumpEventQueue();

      expect(api().callsTo('list').last, [
        null,
        25,
        false,
        'hello',
        <String>[],
      ]);
      expect(ids(state().results), ['h1']);
    });
  });

  test('a search still out when the user changes is dropped', () async {
    final gate = Completer<void>();
    api()
      ..gate = gate
      ..pages.add((conversations: [convo('old')], nextCursor: null));
    controller().setQuery('hello');
    final pending = controller().refresh();
    api().gate = null;

    auth.emit(serverUrl: 'https://chat.example.com/', session: session('u2'));
    expect(state().query, '');
    gate.complete();
    await pending;
    await pumpEventQueue();

    expect(state().results, isNull);
    expect(state().searching, isFalse);
  });
}
