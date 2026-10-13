// Citation sources, marker links and the source sheet (Req 22.6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/render/markdown_text.dart';
import 'package:librechat_flutter/features/chat/render/message_view.dart';

import '../../../support/fakes.dart';

const _web = Attachment(
  type: 'web_search',
  webSearch: {
    'organic': [
      {
        'link': 'https://example.com/a',
        'title': 'Result A',
        'snippet': 'About A',
      },
      {'link': 'https://example.com/b'},
    ],
    'topStories': [
      {'link': 'https://example.com/news', 'title': 'Story'},
    ],
  },
);

const _files = Attachment(
  type: 'file_search',
  fileSearch: {
    'sources': [
      {'fileName': 'report.pdf', 'content': 'The passage'},
      {'content': 'No name'},
    ],
  },
);

void main() {
  group('citationSources', () {
    test('lists web results, then top stories, then file passages', () {
      expect(citationSources(const [_web, _files]), [
        (title: 'Result A', url: 'https://example.com/a', snippet: 'About A'),
        (
          title: 'https://example.com/b',
          url: 'https://example.com/b',
          snippet: null,
        ),
        (title: 'Story', url: 'https://example.com/news', snippet: null),
        (title: 'report.pdf', url: null, snippet: 'The passage'),
        (title: 'File', url: null, snippet: 'No name'),
      ]);
    });

    test('ignores other attachments and malformed payloads', () {
      expect(
        citationSources(const [
          Attachment(filename: 'a.png'),
          Attachment(webSearch: {'organic': 'nope'}),
        ]),
        isEmpty,
      );
    });
  });

  group('linkCitations', () {
    test('links bracket and lenticular markers in range', () {
      expect(
        linkCitations('A [1] and B\u30102\u2020report.pdf\u3011.', 2),
        'A [1](citation:1) and B[2](citation:2).',
      );
    });

    test('leaves markers out of range or without sources', () {
      expect(linkCitations('A [3] and [0]', 2), 'A [3] and [0]');
      const text = 'A [1]';
      expect(identical(linkCitations(text, 0), text), isTrue);
    });

    test('leaves links, references, escapes and code alone', () {
      for (final text in [
        '[1](https://example.com)',
        'see [docs][1]',
        '[1]: https://example.com',
        r'\[1] literal',
        'code `a[1]` here',
        '```\nlist[1]\n```',
      ]) {
        expect(linkCitations(text, 5), text, reason: text);
      }
    });

    test('citationNumber reads only citation links', () {
      expect(citationNumber('citation:3'), 3);
      expect(citationNumber('https://example.com'), isNull);
    });
  });

  testWidgets('a marker tap opens the source sheet, and Open the browser', (
    tester,
  ) async {
    final platform = FakePlatformActions();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformActionsProvider.overrideWithValue(platform)],
        child: const MaterialApp(
          home: Scaffold(
            body: MarkdownText('Per the source [1].', attachments: [_web]),
          ),
        ),
      ),
    );
    await tester.tap(find.text('1', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Citation 1'), findsOneWidget);
    expect(find.text('Result A'), findsOneWidget);
    expect(find.text('About A'), findsOneWidget);
    expect(platform.opened, isEmpty);

    await tester.tap(find.byTooltip('Open citation URL'));
    await tester.pumpAndSettle();
    expect(platform.opened, [Uri.parse('https://example.com/a')]);
    expect(find.text('Citation 1'), findsNothing);
  });

  testWidgets('a message text part links citations to its attachments', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformActionsProvider.overrideWithValue(FakePlatformActions()),
          settingsProvider.overrideWith(FakeSettingsStore.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MessageView(
              Message(
                messageId: 'm',
                conversationId: 'c',
                content: [
                  ContentPart(
                    type: ContentPartType.text,
                    text: 'Per the source [1].',
                  ),
                ],
                attachments: [_web],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('1', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(CitationSheet), findsOneWidget);
    expect(find.text('Result A'), findsOneWidget);
  });
}
