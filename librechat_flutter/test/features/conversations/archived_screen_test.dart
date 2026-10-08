import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';

import 'conversation_list_harness.dart';

/// The Archived_Screen (Req 16), on fakes.
void main() {
  const networkText = 'Network unavailable. Check your connection.';
  const old = Conversation(
    conversationId: 'a1',
    title: 'Old chat',
    isArchived: true,
  );
  const older = Conversation(
    conversationId: 'a2',
    title: 'Older chat',
    isArchived: true,
  );

  Finder rowButton(String title, String tooltip) => find.descendant(
    of: find.widgetWithText(ListTile, title),
    matching: find.byTooltip(tooltip),
  );

  testWidgets('loads isArchived=true pages without the Cache', (tester) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old, older], nextCursor: null));
    await h.pump(tester, archived: true);

    expect(find.text('Archived Conversations'), findsOneWidget);
    expect(find.text('Old chat'), findsOneWidget);
    expect(find.text('Older chat'), findsOneWidget);
    expect(h.api.callsTo('list'), [
      [null, 25, true, null, <String>[]],
    ]);
    expect(h.repository.callsTo('refresh'), isEmpty);
  });

  testWidgets('shows the empty state', (tester) async {
    final h = ListHarness();
    await h.pump(tester, archived: true);
    expect(find.text('No archived conversations'), findsOneWidget);
    expect(
      find.text('Archived conversations will appear here'),
      findsOneWidget,
    );
  });

  testWidgets('a failure shows the ErrorView, and Retry loads again', (
    tester,
  ) async {
    final h = ListHarness();
    h.api.error = AppException(FailureKind.network);
    await h.pump(tester, archived: true);
    expect(find.text('Could not load archived conversations'), findsOneWidget);
    expect(find.text(networkText), findsOneWidget);

    h.api
      ..error = null
      ..pages.add((conversations: [old], nextCursor: null));
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Old chat'), findsOneWidget);
    expect(h.api.callsTo('list'), hasLength(2));
  });

  testWidgets('Unarchive removes the row through the repository', (
    tester,
  ) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old, older], nextCursor: null));
    await h.pump(tester, archived: true);

    await tester.tap(rowButton('Old chat', 'Unarchive'));
    await tester.pumpAndSettle();
    expect(h.repository.callsTo('setArchived'), [
      [old, false],
    ]);
    expect(find.text('Old chat'), findsNothing);
    expect(find.text('Older chat'), findsOneWidget);
  });

  testWidgets('an Unarchive failure keeps the row and shows the message', (
    tester,
  ) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old], nextCursor: null));
    h.repository.errors['setArchived'] = AppException(FailureKind.network);
    await h.pump(tester, archived: true);

    await tester.tap(rowButton('Old chat', 'Unarchive'));
    await tester.pumpAndSettle();
    expect(find.text('Old chat'), findsOneWidget);
    expect(find.widgetWithText(SnackBar, networkText), findsOneWidget);
  });

  testWidgets('Delete confirms, then removes the row', (tester) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old, older], nextCursor: null));
    await h.pump(tester, archived: true);

    await tester.tap(rowButton('Old chat', 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Are you sure you want to delete "Old chat"? This action cannot be '
        'undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.repository.callsTo('delete'), [
      ['a1'],
    ]);
    expect(find.text('Old chat'), findsNothing);
  });

  testWidgets('a row tap opens Routes.chat(id)', (tester) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old], nextCursor: null));
    await h.pump(tester, archived: true);
    await tester.tap(find.text('Old chat'));
    await tester.pumpAndSettle();
    expect(h.path, Routes.chat('a1'));
  });

  testWidgets('scrolling near the end loads the next archived page', (
    tester,
  ) async {
    final h = ListHarness();
    h.api.pages
      ..add((
        conversations: [
          for (var i = 0; i < 25; i++)
            Conversation(
              conversationId: 'a$i',
              title: 'Archived $i',
              isArchived: true,
            ),
        ],
        nextCursor: 'cursor-2',
      ))
      ..add((conversations: [older], nextCursor: null));
    await h.pump(tester, archived: true);
    expect(h.api.callsTo('list'), hasLength(1));

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(h.api.callsTo('list').last, [
      'cursor-2',
      25,
      true,
      null,
      <String>[],
    ]);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Older chat'), findsOneWidget);
  });

  testWidgets('pull to refresh loads page 1 again', (tester) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old], nextCursor: null));
    await h.pump(tester, archived: true);
    await tester.fling(find.text('Old chat'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(h.api.callsTo('list'), hasLength(2));
  });

  testWidgets('tap targets meet the guidelines', (tester) async {
    final h = ListHarness();
    h.api.pages.add((conversations: [old, older], nextCursor: null));
    final handle = tester.ensureSemantics();
    await h.pump(tester, archived: true);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
