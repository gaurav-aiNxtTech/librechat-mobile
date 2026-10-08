// prepareMath money and escape cases (Task 17.5).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/chat/render/math.dart';

void main() {
  void unchanged(String text) => expect(prepareMath(text), text);

  group('stays as text', () {
    test(r'amounts: $5 and $10', () => unchanged(r'$5 and $10'));
    test(r'a lone amount: costs $5.', () => unchanged(r'costs $5.'));
    test(r'escaped dollars', () => unchanged(r'\$5 and \$10'));
    test(r'an escaped opener: \$x$', () => unchanged(r'\$x$'));
    test(r'content that is not LaTeX: $abc$', () => unchanged(r'$abc$'));
    test(r'padded content: $ x $', () => unchanged(r'$ x $'));
    test(r'a closer followed by a digit: $x$5', () => unchanged(r'$x$5'));
    test('inline math spans one line only', () => unchanged('\$x\n\$'));
    test(r'an empty block: $$$$', () => unchanged(r'$$$$'));
    test('text without a dollar', () {
      const text = 'plain text with \\(x\\) and `code`';
      expect(identical(prepareMath(text), text), isTrue);
    });
  });

  group('converts', () {
    test(r'$x$', () => expect(prepareMath(r'$x$'), r'\(x\)'));
    test(r'$x^2$', () => expect(prepareMath(r'$x^2$'), r'\(x^2\)'));
    test(r'$a=b$', () => expect(prepareMath(r'$a=b$'), r'\(a=b\)'));
    test(
      r'$E = mc^2$',
      () => expect(prepareMath(r'$E = mc^2$'), r'\(E = mc^2\)'),
    );
    test(
      'an amount next to math',
      () => expect(
        prepareMath(r'Price $5, area $x^2$'),
        r'Price $5, area \(x^2\)',
      ),
    );
    test(
      'a block',
      () => expect(prepareMath(r'$$\frac{a}{b}$$'), r'\[\frac{a}{b}\]'),
    );
    test(
      'a multi-line block keeps its newlines',
      () => expect(
        prepareMath('Before\n\$\$\na + b\n= c\n\$\$\nafter'),
        'Before\n\\[\na + b\n= c\n\\]\nafter',
      ),
    );
  });

  group('skips code', () {
    test('an inline code span', () => unchanged(r'see `$x$` here'));
    test('a double-backtick span', () => unchanged(r'see ``a ` $x$`` here'));
    test('an unmatched backtick is literal', () {
      expect(prepareMath(r'a ` b $x$'), r'a ` b \(x\)');
    });
    test('a backtick fence', () => unchanged('```tex\n\$x\$\n```'));
    test('a tilde fence', () => unchanged('~~~\n\$x^2\$\n~~~'));
    test('math after a closed fence converts', () {
      expect(prepareMath('```\n\$x\$\n```\n\$y\$'), '```\n\$x\$\n```\n\\(y\\)');
    });
    test(
      'an unclosed fence runs to the end',
      () => unchanged('text\n```\n\$x\$\n\$\$a\$\$'),
    );
  });

  group('leaves existing delimiters', () {
    test(r'\(x\) with a dollar', () => unchanged(r'\(x\) costs $5'));
    test(r'\[x\] with a dollar', () => unchanged(r'\[x\] costs $5'));
  });
}
