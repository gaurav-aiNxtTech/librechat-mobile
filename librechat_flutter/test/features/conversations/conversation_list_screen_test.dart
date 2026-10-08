import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/tag.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';

import '../../support/fakes.dart';
import 'conversation_list_harness.dart';

/// The Conversation_List in the drawer (Req 15, 45.1-45.3), on fakes.
void main() {
  const networkText = 'Network unavailable. Check your connection.';
  final now = DateTime.now().toUtc();

  Conversation convo(String id, String title, {bool? pinned}) => Conversation(
    conversationId: id,
    title: title,
    pinned: pinned,
    updatedAt: now,
  );

  final alpha = convo('c1', 'Alpha');
  final beta = convo('c2', 'Beta');

  ListHarness harness({List<Conversation> rows = const []}) =>
      ListHarness(repository: FakeConversationsRepository(rows: rows));

  Finder searchField() => find.byType(TextField);

  testWidgets('cached rows show before the fetch completes', (tester) async {
    final h = harness(rows: [alpha, beta]);
    final gate = Completer<void>();
    h.repository.gate = gate;
    await h.pump(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(h.repository.callsTo('refresh'), hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('nothing cached shows the loading state, then the empty state', (
    tester,
  ) async {
    final h = harness();
    final gate = Completer<void>();
    h.repository.gate = gate;
    final handle = tester.ensureSemantics();
    await h.pump(tester, settle: false);
    await tester.pump();

    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    expect(
      tester.getSemantics(spinner),
      matchesSemantics(label: 'Loading conversations', isLiveRegion: true),
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(find.text('Start a new chat to begin'), findsOneWidget);
    final region = find.ancestor(
      of: find.text('No conversations yet'),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
    );
    expect(region, findsOneWidget);
    handle.dispose();
  });

  testWidgets('a failure with nothing cached shows the ErrorView and Retry', (
    tester,
  ) async {
    final h = harness();
    h.repository.errors['refresh'] = AppException(FailureKind.network);
    await h.pump(tester);

    expect(find.text('Could not load conversations'), findsOneWidget);
    expect(find.text(networkText), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    h.repository
      ..errors.clear()
      ..refreshRows = [alpha];
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(h.repository.callsTo('refresh'), hasLength(2));
    expect(find.text('Could not load conversations'), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('a failure with cached rows keeps them and shows a SnackBar', (
    tester,
  ) async {
    final h = harness(rows: [alpha]);
    h.repository.errors['refresh'] = AppException(FailureKind.network);
    await h.pump(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.widgetWithText(SnackBar, networkText), findsOneWidget);
    expect(find.text('Could not load conversations'), findsNothing);
  });

  group('search', () {
    testWidgets('runs 500 ms after the last keystroke', (tester) async {
      final h = harness(rows: [alpha]);
      h.api.pages.add((
        conversations: [convo('r1', 'Found')],
        nextCursor: null,
      ));
      await h.pump(tester);

      await tester.enterText(searchField(), 'hel');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(searchField(), 'hello');
      await tester.pump(const Duration(milliseconds: 499));
      expect(h.api.callsTo('list'), isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(h.api.callsTo('list'), [
        [null, 25, false, 'hello', <String>[]],
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Found'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('clearing shows the grouped list at once', (tester) async {
      final h = harness(rows: [alpha]);
      h.api.pages.add((
        conversations: [convo('r1', 'Found')],
        nextCursor: null,
      ));
      await h.pump(tester);
      await tester.enterText(searchField(), 'hello');
      await tester.pump(searchDelay);
      await tester.pumpAndSettle();
      expect(find.text('Found'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Found'), findsNothing);
      expect(h.api.callsTo('list'), hasLength(1));
    });

    testWidgets('a blank query clears the results at once', (tester) async {
      final h = harness(rows: [alpha]);
      h.api.pages.add((
        conversations: [convo('r1', 'Found')],
        nextCursor: null,
      ));
      await h.pump(tester);
      await tester.enterText(searchField(), 'hello');
      await tester.pump(searchDelay);
      await tester.pumpAndSettle();

      await tester.enterText(searchField(), '   ');
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Found'), findsNothing);
      await tester.pump(searchDelay);
      expect(h.api.callsTo('list'), hasLength(1));
    });

    testWidgets('no results shows the empty results state', (tester) async {
      final h = harness(rows: [alpha]);
      await h.pump(tester);
      await tester.enterText(searchField(), 'zzz');
      await tester.pump(searchDelay);
      await tester.pumpAndSettle();
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
    });
  });

  group('Pinned', () {
    final pinned = convo('p1', 'Pinned chat', pinned: true);

    testWidgets('shows above the date groups with Feature.pin, and hides '
        'while searching', (tester) async {
      final h = harness(rows: [pinned, alpha]);
      h.api.pages.add((conversations: [pinned], nextCursor: null));
      await h.pump(tester);

      expect(find.text('Pinned'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Pinned chat')).dy,
        lessThan(tester.getTopLeft(find.text('Today')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Today')).dy,
        lessThan(tester.getTopLeft(find.text('Alpha')).dy),
      );

      await tester.enterText(searchField(), 'pin');
      await tester.pump(searchDelay);
      await tester.pumpAndSettle();
      expect(find.text('Pinned chat'), findsOneWidget);
      expect(find.text('Pinned'), findsNothing);
    });

    testWidgets('is absent without Feature.pin', (tester) async {
      final h = harness(rows: [pinned, alpha]);
      await h.pump(tester, missing: {Feature.pin});
      expect(find.text('Pinned'), findsNothing);
      expect(find.text('Pinned chat'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('tag chips', () {
    testWidgets('show "{tag} ({count})" and a selection reloads with tags', (
      tester,
    ) async {
      final h = harness(rows: [alpha]);
      h.api.tagsReply = const [Tag(tag: 'work', count: 3)];
      h.api.pages.add((
        conversations: [convo('t1', 'Tagged')],
        nextCursor: null,
      ));
      await h.pump(tester);

      expect(find.widgetWithText(FilterChip, 'work (3)'), findsOneWidget);
      await tester.tap(find.text('work (3)'));
      await tester.pump();
      expect(h.api.callsTo('list'), [
        [
          null,
          25,
          false,
          '',
          ['work'],
        ],
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Tagged'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      await tester.tap(find.text('work (3)'));
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(h.api.callsTo('list'), hasLength(1));
    });

    testWidgets('are hidden without Feature.bookmarks', (tester) async {
      final h = harness(rows: [alpha]);
      h.api.tagsReply = const [Tag(tag: 'work', count: 3)];
      await h.pump(tester, missing: {Feature.bookmarks});
      expect(find.byType(FilterChip), findsNothing);
      expect(h.api.callsTo('tags'), isEmpty);
    });
  });

  group('paging', () {
    final many = [for (var i = 0; i < 30; i++) convo('c$i', 'Chat $i')];

    testWidgets('scrolling near the end loads the next page', (tester) async {
      final h = harness(rows: many);
      h.repository.refreshCursor = 'cursor-2';
      await h.pump(tester);
      expect(h.repository.callsTo('loadMore'), isEmpty);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('loadMore'), [
        ['cursor-2'],
      ]);
    });

    testWidgets('a failed page shows the Retry row', (tester) async {
      final h = harness(rows: many);
      h.repository
        ..refreshCursor = 'cursor-2'
        ..errors['loadMore'] = AppException(FailureKind.network);
      await h.pump(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
      expect(h.repository.callsTo('loadMore'), hasLength(1));

      h.repository.errors.clear();
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('loadMore'), hasLength(2));
      expect(find.widgetWithText(TextButton, 'Retry'), findsNothing);
    });
  });

  testWidgets('pull to refresh calls refresh', (tester) async {
    final h = harness(rows: [alpha]);
    await h.pump(tester);
    expect(h.repository.callsTo('refresh'), hasLength(1));

    await tester.fling(find.text('Alpha'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(h.repository.callsTo('refresh'), hasLength(2));
  });

  testWidgets('a row tap opens Routes.chat(id) and marks the row selected', (
    tester,
  ) async {
    final h = harness(rows: [alpha, beta]);
    await h.pump(tester);
    bool selected(String title) =>
        tester.widget<ListTile>(find.widgetWithText(ListTile, title)).selected;
    expect(selected('Alpha'), isFalse);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(h.path, Routes.chat('c1'));
    expect(selected('Alpha'), isTrue);
    expect(selected('Beta'), isFalse);
  });

  testWidgets('an untitled row shows "New Chat"', (tester) async {
    final h = harness(
      rows: [Conversation(conversationId: 'u', updatedAt: now)],
    );
    await h.pump(tester);
    expect(find.text('New Chat'), findsOneWidget);
  });

  testWidgets('tap targets meet the guidelines', (tester) async {
    final h = harness(rows: [alpha, convo('p1', 'Pinned chat', pinned: true)]);
    h.api.tagsReply = const [Tag(tag: 'work', count: 3)];
    final handle = tester.ensureSemantics();
    await h.pump(tester);
    await tester.enterText(searchField(), 'x');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.byTooltip('Import conversations'), findsOneWidget);
    expect(find.byTooltip('Conversation actions'), findsNWidgets(2));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.pump(searchDelay);
    await tester.pumpAndSettle();
    handle.dispose();
  });
}

/// Past the search debounce.
const searchDelay = Duration(milliseconds: 500);
