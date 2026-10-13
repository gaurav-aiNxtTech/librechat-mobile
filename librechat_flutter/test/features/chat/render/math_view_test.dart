// Math rendering through Math.tex and the invalid-TeX fallback
// (Req 22.3, 22.5).
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/chat/render/markdown_text.dart';
import 'package:librechat_flutter/features/chat/render/math.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );

  testWidgets('valid TeX renders natively with the source as its label', (
    tester,
  ) async {
    await pump(
      tester,
      const MathView(r'x^2', style: TextStyle(fontSize: 16), inline: true),
    );
    expect(find.byType(Math), findsOneWidget);
    expect(find.text(r'x^2'), findsNothing);
    expect(find.bySemanticsLabel(r'x^2'), findsOneWidget);
  });

  testWidgets('invalid TeX shows its source in monospace', (tester) async {
    await pump(
      tester,
      const MathView(r'\frac{a', style: TextStyle(fontSize: 16), inline: false),
    );
    final fallback = tester.widget<Text>(find.text(r'\frac{a'));
    expect(fallback.style?.fontFamily, 'monospace');
  });

  testWidgets('MarkdownText renders inline and block math', (tester) async {
    await pump(
      tester,
      const MarkdownText(
        r'Area $x^2$ costs $5.'
        '\n\n'
        r'$$\frac{a}{b}$$'
        '\n',
      ),
    );
    final views = tester.widgetList<MathView>(find.byType(MathView)).toList();
    expect(views.map((v) => (v.tex, v.inline)), [
      ('x^2', true),
      (r'\frac{a}{b}', false),
    ]);
    expect(find.textContaining(r'$5', findRichText: true), findsOneWidget);
  });
}
