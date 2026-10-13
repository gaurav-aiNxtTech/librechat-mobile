// CodeBlock highlighting memo, plain fallbacks and copy (Req 22.2).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/render/code_block.dart';
import 'package:librechat_flutter/features/chat/render/markdown_text.dart';

import '../../../support/fakes.dart';

void main() {
  group('CodeHighlighter', () {
    test('a repeat lookup reuses the memoized span', () {
      final memo = CodeHighlighter();
      final first = memo.highlight('dart', 'final a = 1;', Brightness.dark);
      expect(first, isNotNull);
      expect(first!.toPlainText(), 'final a = 1;');
      expect(first.children, isNotEmpty);
      expect(
        memo.highlight('dart', 'final a = 1;', Brightness.dark),
        same(first),
      );
      expect(memo.length, 1);
    });

    test('aliases and info strings resolve to the bundled grammar', () {
      final memo = CodeHighlighter();
      for (final info in ['py', 'Python', 'python title=a.py']) {
        expect(
          memo.highlight(info, 'x = 1', Brightness.light),
          isNotNull,
          reason: info,
        );
      }
      expect(memo.length, 1);
    });

    test('an unknown or absent language is not highlighted', () {
      final memo = CodeHighlighter();
      expect(memo.highlight('', 'x', Brightness.dark), isNull);
      expect(memo.highlight('nosuchlang', 'x', Brightness.dark), isNull);
      expect(memo.length, 0);
    });

    test('holds 64 entries and drops the least recently used', () {
      final memo = CodeHighlighter();
      expect(memo.capacity, 64);
      final first = memo.highlight('json', '0', Brightness.dark);
      final second = memo.highlight('json', '1', Brightness.dark);
      for (var i = 2; i < 64; i++) {
        memo.highlight('json', '$i', Brightness.dark);
      }
      expect(memo.length, 64);
      // Touch the first so the second becomes the oldest, then overflow.
      expect(memo.highlight('json', '0', Brightness.dark), same(first));
      memo.highlight('json', '64', Brightness.dark);
      expect(memo.length, 64);
      expect(memo.highlight('json', '0', Brightness.dark), same(first));
      expect(memo.highlight('json', '1', Brightness.dark), isNot(same(second)));
    });
  });

  group('CodeBlock', () {
    Future<FakePlatformActions> pump(WidgetTester tester, Widget child) async {
      final platform = FakePlatformActions();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [platformActionsProvider.overrideWithValue(platform)],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
      return platform;
    }

    testWidgets('shows the language and copies with a 3 s check mark', (
      tester,
    ) async {
      final platform = await pump(
        tester,
        const CodeBlock(language: 'kotlin', code: 'val a = 1'),
      );
      expect(find.text('kotlin'), findsOneWidget);
      expect(find.bySemanticsLabel('kotlin code block'), findsOneWidget);
      expect(find.byTooltip('Copy code'), findsOneWidget);

      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();
      expect(platform.copies, ['val a = 1']);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byTooltip('Copied'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.content_copy), findsOneWidget);
    });

    testWidgets('an unclosed fence renders plain', (tester) async {
      await pump(
        tester,
        const CodeBlock(language: 'dart', code: 'final a', closed: false),
      );
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(RichText),
        ),
      );
      final span = text.text as TextSpan;
      expect(span.toPlainText(), 'final a');
      expect((span.children!.single as TextSpan).children, isNull);
    });

    testWidgets('a fence without a language is labelled code', (tester) async {
      await pump(tester, const CodeBlock(language: '', code: 'plain'));
      expect(find.text('code'), findsOneWidget);
      expect(find.text('plain', findRichText: true), findsOneWidget);
    });

    testWidgets('MarkdownText renders fences as CodeBlocks', (tester) async {
      final platform = await pump(
        tester,
        const MarkdownText('Run:\n\n```bash\necho hi\n```\n'),
      );
      final block = tester.widget<CodeBlock>(find.byType(CodeBlock));
      expect(block.language, 'bash');
      expect(block.code, 'echo hi');
      expect(block.closed, isTrue);
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();
      expect(platform.copies, ['echo hi']);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
