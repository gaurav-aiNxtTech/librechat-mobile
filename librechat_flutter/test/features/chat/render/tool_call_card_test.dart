// ToolCallCard titles, variants and answered questions (Req 23.1-23.3, 23.13).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/render/tool_call_card.dart';
import 'package:librechat_flutter/features/chat/run/run_state.dart';

import '../../../support/fakes.dart';

ContentPart _call(
  String name, {
  String id = 't1',
  Object? args,
  String? output,
  String? status,
}) => ContentPart(
  type: ContentPartType.toolCall,
  toolCall: ToolCall(id: id, name: name, args: args, output: output),
  status: status,
);

void main() {
  group('titles (Req 23.2)', () {
    test('the intent titles the card only when it is the first key', () {
      const first = '{"intent": "Look up the weather", "city": "Oslo"}';
      const later = '{"city": "Oslo", "intent": "Look up the weather"}';
      expect(
        toolTitle(const ToolCall(name: 'weather', args: first)),
        'Look up the weather',
      );
      expect(
        toolTitle(const ToolCall(name: 'weather', args: later)),
        'weather',
      );
      // A map mid-stream counts the same as the saved JSON string.
      expect(
        toolTitle(const ToolCall(name: 'weather', args: {'intent': 'Go'})),
        'Go',
      );
    });

    test('a blank or non-string intent falls back to the tool name', () {
      expect(
        toolTitle(const ToolCall(name: 'calc', args: '{"intent": "  "}')),
        'calc',
      );
      expect(
        toolTitle(const ToolCall(name: 'calc', args: {'intent': 3})),
        'calc',
      );
      expect(toolTitle(const ToolCall()), 'Tool Call');
    });

    test('arguments that are no object at all fall back to the name', () {
      for (final args in <Object?>[
        null,
        '',
        '   ',
        'not json',
        '[{"intent": "Look up"}]',
        '42',
        <String, Object?>{},
      ]) {
        expect(
          toolTitle(ToolCall(name: 'calc', args: args)),
          'calc',
          reason: 'args: $args',
        );
      }
    });

    test('a nameless call falls back to the generic title', () {
      expect(toolTitle(const ToolCall(name: '')), 'Tool Call');
      expect(toolTitle(null), 'Tool Call');
    });

    test('the shown arguments leave out an intent used as the title', () {
      const args = '{"intent": "Look up", "city": "Oslo"}';
      expect(jsonDecode(displayArgs(args)!), {'city': 'Oslo'});
      expect(displayArgs('{"intent": "Look up"}'), isNull);
      expect(displayArgs('not json'), 'not json');
      expect(displayArgs(null), isNull);
    });
  });

  test('toolVariant follows the KMP dispatcher', () {
    expect(toolVariant('lc_transfer_to_writer'), ToolVariant.handoff);
    expect(toolVariant('ask_user_question'), ToolVariant.askUser);
    expect(toolVariant('subagent'), ToolVariant.subagent);
    expect(toolVariant('file_search'), ToolVariant.fileSearch);
    expect(toolVariant('retrieval'), ToolVariant.fileSearch);
    expect(toolVariant('web_search'), ToolVariant.webSearch);
    expect(toolVariant('google_search'), ToolVariant.webSearch);
    expect(toolVariant('set_memory'), ToolVariant.memory);
    expect(toolVariant('image_gen_oai'), ToolVariant.imageGen);
    expect(toolVariant('dalle'), ToolVariant.imageGen);
    expect(toolVariant('calculator'), ToolVariant.generic);
    expect(toolVariant(null), ToolVariant.generic);
  });

  group('payload helpers', () {
    test('webSources reads the call\'s attachments, deduplicated by link', () {
      const attachments = [
        Attachment(
          type: 'web_search',
          toolCallId: 't1',
          webSearch: {
            'organic': [
              {'title': 'Docs', 'link': 'https://www.example.com/docs'},
              {'title': 'Again', 'link': 'https://www.example.com/docs'},
            ],
            'topStories': [
              {'link': 'https://news.example.org/a'},
            ],
          },
        ),
        Attachment(
          type: 'web_search',
          toolCallId: 'other',
          webSearch: {
            'organic': [
              {'title': 'Elsewhere', 'link': 'https://other.example'},
            ],
          },
        ),
      ];
      final sources = webSources(
        attachments,
        const ToolCall(id: 't1', name: 'web_search'),
      );
      expect(sources, [
        (title: 'Docs', url: 'https://www.example.com/docs'),
        (title: 'news.example.org', url: 'https://news.example.org/a'),
      ]);
    });

    test('webSources falls back to the output\'s results', () {
      const call = ToolCall(
        id: 't1',
        output: '{"results": [{"title": "A", "url": "https://a.example"}]}',
      );
      expect(webSources(const [], call), [
        (title: 'A', url: 'https://a.example'),
      ]);
      expect(webSources(const [], const ToolCall(output: 'plain')), isEmpty);
    });

    test('fileCitations merges by file, most relevant first', () {
      const attachments = [
        Attachment(
          type: 'file_search',
          toolCallId: 't1',
          fileSearch: {
            'sources': [
              {
                'fileId': 'a',
                'fileName': 'a.pdf',
                'relevance': 0.4,
                'pages': [1],
              },
              {'fileId': 'b', 'fileName': 'b.pdf', 'relevance': 0.9},
              {
                'fileId': 'a',
                'fileName': 'a.pdf',
                'relevance': 0.6,
                'pages': [3],
              },
            ],
          },
        ),
      ];
      final files = fileCitations(attachments, const ToolCall(id: 't1'));
      expect(
        [for (final f in files) (f.name, f.relevance)],
        [('b.pdf', 90), ('a.pdf', 60)],
      );
      expect(files.last.pages, [1, 3]);
    });

    test('memoryChanges reads the attachments, else the output', () {
      const attachments = [
        Attachment(
          type: 'memory',
          toolCallId: 't1',
          memory: {'type': 'update', 'key': 'name', 'value': 'Sam'},
        ),
        Attachment(
          type: 'memory',
          toolCallId: 't1',
          memory: {'type': 'delete', 'key': 'pet'},
        ),
      ];
      expect(memoryChanges(attachments, const ToolCall(id: 't1')), [
        (kind: MemoryChangeKind.update, key: 'name', text: 'Sam'),
        (kind: MemoryChangeKind.delete, key: 'pet', text: 'Memory deleted'),
      ]);
      expect(memoryChanges(const [], const ToolCall(output: 'Saved it.')), [
        (kind: MemoryChangeKind.update, key: null, text: 'Saved it.'),
      ]);
    });
  });

  group('answered questions (Req 23.13)', () {
    const question = (
      question: 'Which database?',
      header: null,
      options: [
        (label: 'PostgreSQL', value: 'pg'),
        (label: 'SQLite', value: 'sqlite'),
      ],
      multiSelect: true,
    );

    test('an answer reads as the picked options\' labels', () {
      expect(askAnswerLabel(question, 'pg').label, 'PostgreSQL');
      expect(
        askAnswerLabel(question, 'pg, sqlite').label,
        'PostgreSQL, SQLite',
      );
      expect(askAnswerLabel(question, 'pg, mysql').label, 'pg, mysql');
      expect(askAnswerLabel(question, askUserDeclinedAnswer).declined, isTrue);
    });

    test('a batch pairs each question with its answer by id', () {
      final records = askRecords(
        const ToolCall(
          name: 'ask_user_question',
          args: {
            'questions': [
              {'id': 'q1', 'question': 'First?'},
              {'id': 'q2', 'question': 'Second?'},
            ],
          },
          output: '{"answers": {"q2": "Yes"}}',
        ),
      );
      expect(
        [for (final r in records) r.question?.question],
        ['First?', 'Second?'],
      );
      expect([for (final r in records) r.answer], ['', 'Yes']);
    });
  });

  group('ToolCallCard', () {
    late FakePlatformActions platform;

    setUp(() => platform = FakePlatformActions());

    Future<void> pump(
      WidgetTester tester,
      ContentPart part, {
      List<Attachment> attachments = const [],
      bool streaming = false,
      Map<String, SubagentProgress> subagents = const {},
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [platformActionsProvider.overrideWithValue(platform)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ToolCallCard(
                part: part,
                storageKey: 'm/part:t1',
                attachments: attachments,
                streaming: streaming,
                subagents: subagents,
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('expands to the arguments and the output (Req 23.1)', (
      tester,
    ) async {
      await pump(
        tester,
        _call(
          'weather',
          args: '{"intent": "Check the forecast", "city": "Oslo"}',
          output: 'Sunny',
        ),
      );
      expect(find.text('Check the forecast'), findsOneWidget);
      expect(find.text('Output:'), findsNothing);

      await tester.tap(find.text('Check the forecast'));
      await tester.pumpAndSettle();
      expect(find.text('Input:'), findsOneWidget);
      expect(find.textContaining('"city": "Oslo"'), findsOneWidget);
      expect(find.text('Output:'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
    });

    testWidgets('a live call spins until its output or terminal status', (
      tester,
    ) async {
      await pump(tester, _call('calc'), streaming: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pump(tester, _call('calc', status: 'failed'), streaming: true);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The tile merges the badge's label into its own.
      expect(find.bySemanticsLabel(RegExp('Failed')), findsOneWidget);

      await pump(tester, _call('calc', output: '4'), streaming: true);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // A saved call never spins.
      await pump(tester, _call('calc'));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('web search lists the sources and opens one on tap', (
      tester,
    ) async {
      await pump(
        tester,
        _call('web_search', output: '{}'),
        attachments: const [
          Attachment(
            type: 'web_search',
            toolCallId: 't1',
            webSearch: {
              'organic': [
                {'title': 'Example Docs', 'link': 'https://example.com/docs'},
              ],
            },
          ),
        ],
      );
      await tester.tap(find.text('Searched the web'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Search result: Example Docs'));
      expect(platform.opened, [Uri.parse('https://example.com/docs')]);
    });

    testWidgets('web search without sources falls back to the generic card', (
      tester,
    ) async {
      await pump(tester, _call('web_search', output: 'nothing'));
      expect(find.text('Searched the web'), findsNothing);
      expect(find.text('web_search'), findsOneWidget);
    });

    testWidgets('file search lists the matched files', (tester) async {
      await pump(
        tester,
        _call('file_search', output: 'digest'),
        attachments: const [
          Attachment(
            type: 'file_search',
            toolCallId: 't1',
            fileSearch: {
              'sources': [
                {'fileId': 'f', 'fileName': 'notes.pdf', 'relevance': 0.75},
              ],
            },
          ),
        ],
      );
      await tester.tap(find.text('Searched your files'));
      await tester.pumpAndSettle();
      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('a memory call shows the changed memories', (tester) async {
      await pump(
        tester,
        _call('set_memory', output: 'ok'),
        attachments: const [
          Attachment(
            type: 'memory',
            toolCallId: 't1',
            memory: {'type': 'update', 'key': 'name', 'value': 'Sam'},
          ),
        ],
      );
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('name'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets('image generation shows progress until the image arrives', (
      tester,
    ) async {
      final part = _call('image_gen_oai', output: 'done');
      await pump(tester, part, streaming: true);
      expect(find.text('Generating image…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await pump(
        tester,
        part,
        streaming: true,
        attachments: const [Attachment(type: 'image/png', toolCallId: 't1')],
      );
      expect(find.text('Image generated'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('an answered question renders as a record', (tester) async {
      const args = {
        'question': 'Which database?',
        'options': [
          {'label': 'PostgreSQL', 'value': 'pg'},
        ],
      };
      await pump(tester, _call('ask_user_question', args: args, output: 'pg'));
      expect(find.text('Asked'), findsOneWidget);
      expect(find.text('Which database?'), findsOneWidget);
      expect(
        find.text('You answered: PostgreSQL', findRichText: true),
        findsOneWidget,
      );
      // A record, not a tool card.
      expect(find.text('ask_user_question'), findsNothing);

      await pump(
        tester,
        _call('ask_user_question', args: args, output: askUserDeclinedAnswer),
      );
      expect(find.text('You skipped this question'), findsOneWidget);
    });

    testWidgets('a subagent card is titled and spun by its live progress', (
      tester,
    ) async {
      await pump(
        tester,
        _call('subagent'),
        streaming: true,
        subagents: const {
          'run-1': SubagentProgress(
            status: SubagentStatus.running,
            parentToolCallId: 't1',
            type: 'researcher',
          ),
        },
      );
      expect(find.text('researcher'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a transfer call renders as a handoff marker', (tester) async {
      await pump(tester, _call('lc_transfer_to_writer'));
      expect(
        find.bySemanticsLabel('Agent handoff from unknown to writer'),
        findsOneWidget,
      );
    });
  });
}
