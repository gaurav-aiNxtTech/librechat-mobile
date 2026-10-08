import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/tag.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/conversations/conversation_export.dart';

import '../../support/fakes.dart';
import 'conversation_list_harness.dart';

/// The row actions and the import flow (Req 16), on fakes.
void main() {
  final now = DateTime.now().toUtc();
  final alpha = Conversation(
    conversationId: 'c1',
    title: 'Alpha',
    updatedAt: now,
  );
  const serverError = 'Server error. Please try again later.';

  ListHarness harness({List<Conversation>? rows}) => ListHarness(
    repository: FakeConversationsRepository(rows: rows ?? [alpha]),
  );

  Future<void> openActions(
    WidgetTester tester, {
    String title = 'Alpha',
  }) async {
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, title),
        matching: find.byTooltip('Conversation actions'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String action) async {
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(ListTile, action),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder dialogButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );

  testWidgets('the sheet lists the actions in the KMP order', (tester) async {
    final h = harness();
    await h.pump(tester, config: const StartupConfig(sharedLinksEnabled: true));
    await openActions(tester);
    final labels = [
      'Rename',
      'Pin',
      'Tags',
      'Share',
      'Duplicate',
      'Export',
      'Archive',
      'Delete',
    ];
    final ys = [
      for (final label in labels)
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.text(label),
              ),
            )
            .dy,
    ];
    expect([...ys]..sort(), ys);
  });

  testWidgets('a long press opens the sheet too', (tester) async {
    final h = harness();
    await h.pump(tester);
    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  group('rename', () {
    testWidgets('saves the trimmed title and the row follows', (tester) async {
      final h = harness();
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Rename');

      expect(find.text('Rename conversation'), findsOneWidget);
      expect(
        find.text('Enter a new title for this conversation.'),
        findsOneWidget,
      );
      final field = find.widgetWithText(TextField, 'Title');
      await tester.enterText(field, '   ');
      await tester.pump();
      expect(tester.widget<TextButton>(dialogButton('Save')).onPressed, isNull);

      await tester.enterText(field, ' Renamed ');
      await tester.pump();
      await tester.tap(dialogButton('Save'));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('rename'), [
        [alpha, 'Renamed'],
      ]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Renamed'), findsOneWidget);
    });

    testWidgets('a failure keeps the dialog and the text', (tester) async {
      final h = harness();
      await h.pump(tester);
      h.repository.errors['rename'] = AppException(
        FailureKind.server,
        status: 500,
      );
      await openActions(tester);
      await choose(tester, 'Rename');
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Next');
      await tester.pump();
      await tester.tap(dialogButton('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Rename conversation'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Next'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, serverError), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('confirms with the KMP copy, then removes the row', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Delete');

      expect(find.text('Delete conversation'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Alpha"? This action cannot be '
          'undone.',
        ),
        findsOneWidget,
      );
      await tester.tap(dialogButton('Delete'));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('delete'), [
        ['c1'],
      ]);
      expect(find.text('Alpha'), findsNothing);
      expect(h.path, Routes.newChat);
    });

    testWidgets('Cancel sends nothing; an untitled row reads "this '
        'conversation"', (tester) async {
      final h = harness(
        rows: [Conversation(conversationId: 'u1', updatedAt: now)],
      );
      await h.pump(tester);
      await openActions(tester, title: 'New Chat');
      await choose(tester, 'Delete');
      expect(
        find.text(
          'Are you sure you want to delete "this conversation"? This action '
          'cannot be undone.',
        ),
        findsOneWidget,
      );
      await tester.tap(dialogButton('Cancel'));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('delete'), isEmpty);
    });

    testWidgets('deleting the open conversation goes to Routes.newChat', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester, initialLocation: Routes.chat('c1'));
      expect(h.path, Routes.chat('c1'));
      await openActions(tester);
      await choose(tester, 'Delete');
      await tester.tap(dialogButton('Delete'));
      await tester.pumpAndSettle();
      expect(h.path, Routes.newChat);
    });

    testWidgets('deleting another conversation stays put', (tester) async {
      final beta = alpha.copyWith(conversationId: 'c2', title: 'Beta');
      final h = harness(rows: [alpha, beta]);
      await h.pump(tester, initialLocation: Routes.chat('c2'));
      await openActions(tester);
      await choose(tester, 'Delete');
      await tester.tap(dialogButton('Delete'));
      await tester.pumpAndSettle();
      expect(h.path, Routes.chat('c2'));
    });
  });

  testWidgets('Pin toggles to Unpin', (tester) async {
    final h = harness();
    await h.pump(tester);
    await openActions(tester);
    await choose(tester, 'Pin');
    expect(h.repository.callsTo('setPinned'), [
      [alpha, true],
    ]);
    expect(find.text('Pinned'), findsOneWidget);

    await openActions(tester);
    expect(find.widgetWithText(ListTile, 'Unpin'), findsOneWidget);
    await choose(tester, 'Unpin');
    expect(h.repository.callsTo('setPinned').last, [
      alpha.copyWith(pinned: true),
      false,
    ]);
  });

  testWidgets('Pin and Tags are hidden without their features', (tester) async {
    final h = harness();
    await h.pump(tester, missing: {Feature.pin, Feature.bookmarks});
    await openActions(tester);
    expect(find.widgetWithText(ListTile, 'Pin'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Tags'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Rename'), findsOneWidget);
  });

  testWidgets('Archive hides the row', (tester) async {
    final h = harness();
    await h.pump(tester);
    await openActions(tester);
    await choose(tester, 'Archive');
    expect(h.repository.callsTo('setArchived'), [
      [alpha, true],
    ]);
    expect(find.text('Alpha'), findsNothing);
  });

  group('tags', () {
    Future<ListHarness> openTags(WidgetTester tester) async {
      final h = harness();
      h.api
        ..tagsReply = const [Tag(tag: 'work'), Tag(tag: 'home')]
        ..conversations['c1'] = alpha.copyWith(tags: ['work']);
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Tags');
      return h;
    }

    bool checked(WidgetTester tester, String tag) => tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, tag))
        .value!;

    testWidgets('loads the current tags and saves the selection', (
      tester,
    ) async {
      final h = await openTags(tester);
      expect(h.api.callsTo('get'), [
        ['c1'],
      ]);
      expect(checked(tester, 'work'), isTrue);
      expect(checked(tester, 'home'), isFalse);

      await tester.tap(find.text('home'));
      await tester.pump();
      final tagCalls = h.api.callsTo('tags').length;
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(h.repository.callsTo('setTags'), [
        [
          alpha,
          ['work', 'home'],
        ],
      ]);
      expect(find.text('home'), findsNothing);
      expect(h.api.callsTo('tags').length, greaterThan(tagCalls));
    });

    testWidgets('shows the empty copy without tags', (tester) async {
      final h = harness();
      h.api.conversations['c1'] = alpha;
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Tags');
      expect(find.text('No tags yet. Add one below.'), findsOneWidget);
    });

    testWidgets('Add tag creates and selects it', (tester) async {
      final h = await openTags(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Add new tag'),
        ' urgent ',
      );
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pumpAndSettle();
      expect(h.api.callsTo('createTag'), [
        ['urgent'],
      ]);
      expect(checked(tester, 'urgent'), isTrue);
    });

    testWidgets('rename and delete a tag', (tester) async {
      final h = await openTags(tester);
      await tester.tap(find.byTooltip('Rename tag').first);
      await tester.pumpAndSettle();
      expect(find.text('Rename tag'), findsWidgets);
      await tester.enterText(find.widgetWithText(TextField, 'Tag'), 'job');
      await tester.pump();
      await tester.tap(dialogButton('Save'));
      await tester.pumpAndSettle();
      expect(h.api.callsTo('renameTag'), [
        ['work', 'job'],
      ]);
      expect(checked(tester, 'job'), isTrue);

      await tester.tap(find.byTooltip('Delete tag').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Delete "home"? It is removed from every conversation.'),
        findsOneWidget,
      );
      await tester.tap(dialogButton('Delete'));
      await tester.pumpAndSettle();
      expect(h.api.callsTo('deleteTag'), [
        ['home'],
      ]);
      expect(find.widgetWithText(CheckboxListTile, 'home'), findsNothing);
    });

    testWidgets('a load failure closes the sheet with the message', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester);
      h.api.error = AppException(FailureKind.network);
      await openActions(tester);
      await choose(tester, 'Tags');
      expect(find.text('Add new tag'), findsNothing);
      expect(
        find.text('Network unavailable. Check your connection.'),
        findsOneWidget,
      );
    });
  });

  group('share', () {
    const shared = StartupConfig(sharedLinksEnabled: true);

    testWidgets('is hidden without sharedLinksEnabled', (tester) async {
      final h = harness();
      await h.pump(tester);
      await openActions(tester);
      expect(find.widgetWithText(ListTile, 'Share'), findsNothing);
    });

    testWidgets('reuses an existing link and copies it', (tester) async {
      final h = harness();
      h.api.sharedLinkReply = 'existing';
      await h.pump(tester, config: shared);
      await openActions(tester);
      await choose(tester, 'Share');

      const url = 'https://chat.example.com/share/existing';
      expect(find.text(url), findsOneWidget);
      expect(h.api.callsTo('createShareLink'), isEmpty);
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(h.platform.copies, [url]);
      expect(find.widgetWithText(SnackBar, 'Link copied!'), findsOneWidget);
    });

    testWidgets('creates a link when none exists and shares it', (
      tester,
    ) async {
      final h = harness();
      await h.pump(tester, config: shared);
      await openActions(tester);
      await choose(tester, 'Share');

      expect(h.api.callsTo('createShareLink'), [
        ['c1'],
      ]);
      await choose(tester, 'Share');
      expect(h.platform.shares, ['https://chat.example.com/share/share-1']);
    });
  });

  testWidgets('Duplicate opens the copy', (tester) async {
    final h = harness();
    await h.pump(tester);
    await openActions(tester);
    await choose(tester, 'Duplicate');
    expect(h.repository.callsTo('duplicate'), [
      [alpha],
    ]);
    expect(h.path, Routes.chat('copy'));
  });

  group('export', () {
    final messages = [
      const Message(
        messageId: 'm1',
        conversationId: 'c1',
        text: 'Hi',
        isCreatedByUser: true,
      ),
      const Message(messageId: 'm2', conversationId: 'c1', text: 'Hello'),
    ];

    Future<ListHarness> export(WidgetTester tester, String format) async {
      final h = harness();
      h.messages.messages['c1'] = messages;
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Export');
      expect(find.text('Export format'), findsOneWidget);
      expect(
        find.text('Full data export, can be imported back'),
        findsOneWidget,
      );
      expect(find.text('Readable text format'), findsOneWidget);
      await tester.tap(find.text(format));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('JSON saves the full export', (tester) async {
      final h = await export(tester, 'JSON');
      expect(h.messages.requests, ['c1']);
      final save = h.platform.saves.single;
      expect(save.fileName, 'Alpha.json');
      expect(save.mimeType, 'application/json');
      expect(utf8.decode(save.bytes), exportConversationJson(alpha, messages));
      expect(
        find.widgetWithText(SnackBar, 'Conversation exported'),
        findsOneWidget,
      );
    });

    testWidgets('Markdown saves the readable text', (tester) async {
      final h = await export(tester, 'Markdown');
      final save = h.platform.saves.single;
      expect(save.fileName, 'Alpha.md');
      expect(save.mimeType, 'text/markdown');
      final text = utf8.decode(save.bytes);
      expect(text, startsWith('# Alpha\nExported on '));
      expect(text, endsWith('## User\nHi\n\n## Assistant\nHello'));
    });

    testWidgets('a cancelled save shows nothing', (tester) async {
      final h = harness();
      h.platform.saveResult = false;
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Export');
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      expect(h.platform.saves, hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a messages failure shows the message', (tester) async {
      final h = harness();
      h.messages.error = AppException(FailureKind.network);
      await h.pump(tester);
      await openActions(tester);
      await choose(tester, 'Export');
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      expect(h.platform.saves, isEmpty);
      expect(
        find.text('Network unavailable. Check your connection.'),
        findsOneWidget,
      );
    });
  });

  group('import', () {
    PickedFile file(String name, List<int> bytes, {int? size}) => (
      name: name,
      size: size ?? bytes.length,
      read: () async => Uint8List.fromList(bytes),
    );

    Future<void> import(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Import conversations'));
      await tester.pumpAndSettle();
    }

    testWidgets('a file over the limit is refused before upload', (
      tester,
    ) async {
      final h = harness();
      h.platform.picked = file('big.json', List.filled(11, 0));
      await h.pump(
        tester,
        config: const StartupConfig(conversationImportMaxFileSize: 10),
      );
      await import(tester);
      expect(
        find.text("This file is larger than the server's import limit."),
        findsOneWidget,
      );
      expect(h.repository.callsTo('importFile'), isEmpty);
    });

    testWidgets('success uploads and shows the export title', (tester) async {
      final h = harness();
      final bytes = utf8.encode(
        exportConversationJson(const Conversation(title: 'Trip'), const []),
      );
      h.platform.picked = file('trip.json', bytes);
      h.repository.importCursor = 'next';
      await h.pump(
        tester,
        config: StartupConfig(conversationImportMaxFileSize: bytes.length),
      );
      await import(tester);
      expect(h.repository.callsTo('importFile'), [
        [bytes, 'trip.json'],
      ]);
      expect(find.widgetWithText(SnackBar, 'Imported: Trip'), findsOneWidget);
    });

    testWidgets('a file that is not an export reads as its file name', (
      tester,
    ) async {
      final h = harness();
      h.platform.picked = file('chats.json', utf8.encode('[1, 2]'));
      await h.pump(tester);
      await import(tester);
      expect(h.repository.callsTo('importFile'), hasLength(1));
      expect(find.widgetWithText(SnackBar, 'Imported: chats'), findsOneWidget);
    });

    testWidgets('a cancelled pick does nothing', (tester) async {
      final h = harness();
      await h.pump(tester);
      await import(tester);
      expect(h.platform.picks, 1);
      expect(h.repository.callsTo('importFile'), isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a Server rejection shows its message and keeps the list', (
      tester,
    ) async {
      final h = harness();
      h.platform.picked = file('bad.json', utf8.encode('{}'));
      h.repository.errors['importFile'] = AppException(
        FailureKind.server,
        status: 413,
        message: 'File exceeds the maximum allowed size',
      );
      await h.pump(tester);
      await import(tester);
      expect(
        find.widgetWithText(SnackBar, 'File exceeds the maximum allowed size'),
        findsOneWidget,
      );
      expect(find.text('Alpha'), findsOneWidget);
    });
  });

  testWidgets('the actions sheet meets the tap-target guidelines', (
    tester,
  ) async {
    final h = harness();
    final handle = tester.ensureSemantics();
    await h.pump(tester, config: const StartupConfig(sharedLinksEnabled: true));
    await openActions(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the tags sheet meets the tap-target guidelines', (tester) async {
    final h = harness();
    h.api
      ..tagsReply = const [Tag(tag: 'work')]
      ..conversations['c1'] = alpha;
    final handle = tester.ensureSemantics();
    await h.pump(tester);
    await openActions(tester);
    await choose(tester, 'Tags');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
