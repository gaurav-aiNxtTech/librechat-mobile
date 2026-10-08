import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/chat/composer/prompt_variables.dart';

void main() {
  group('fillVariables', () {
    test('fills a placeholder', () {
      expect(fillVariables('Hi {{name}}!', {'name': 'Ada'}), 'Hi Ada!');
    });

    test('matches trimmed names and keys case-insensitively', () {
      expect(fillVariables('Hi {{ Name }}', {'name': 'Ada'}), 'Hi Ada');
      expect(fillVariables('Hi {{ Name }}', {' NAME ': 'Ada'}), 'Hi Ada');
    });

    test('a blank or missing value leaves the placeholder', () {
      expect(fillVariables('Hi {{name}}', {'name': ''}), 'Hi {{name}}');
      expect(fillVariables('Hi {{name}}', {'name': ' \t'}), 'Hi {{name}}');
      expect(fillVariables('Hi {{name}}', {'other': 'x'}), 'Hi {{name}}');
    });

    test('a later blank entry does not hide an earlier value', () {
      expect(fillVariables('{{name}}', {'name': 'Ada', 'NAME': ' '}), 'Ada');
    });

    test('server-filled names are never filled', () {
      const template =
          '{{current_date}} {{ Current_User }} {{ISO_DATETIME}} '
          '{{current_datetime}}';
      expect(
        fillVariables(template, {
          'current_date': 'x',
          'current_user': 'x',
          'iso_datetime': 'x',
          'CURRENT_DATETIME': 'x',
        }),
        template,
      );
    });

    test('a repeated name is filled everywhere', () {
      expect(
        fillVariables('{{topic}} and {{ Topic }}', {'topic': 'cats'}),
        'cats and cats',
      );
    });

    test('names with spaces, - and . work', () {
      expect(
        fillVariables('{{first name}} {{x-y}} {{a.b}}', {
          'First Name': '1',
          'x-y': '2',
          'a.b': '3',
        }),
        '1 2 3',
      );
    });

    test('a value is inserted literally', () {
      expect(fillVariables('{{a}}', {'a': r'$1\\'}), r'$1\\');
      expect(fillVariables('{{a}}', {'a': '{{b}}'}), '{{b}}');
    });

    test('non-placeholders stay as they are', () {
      const template = '{{}} {{ }} {{a{b}} {a} {{a} a}}';
      expect(fillVariables(template, {'a': 'X', 'b': 'Y', '': 'Z'}), template);
    });

    test('an empty map returns the template', () {
      expect(fillVariables('Hi {{name}}', const {}), 'Hi {{name}}');
    });
  });

  group('extractVariables', () {
    test('returns fillable names in first-appearance order', () {
      expect(extractVariables('{{b}} {{ a }} {{b}}'), ['b', 'a']);
    });

    test('dedupes case-insensitively and keeps the first spelling', () {
      expect(extractVariables('{{Topic}} {{topic}} {{ TOPIC }}'), ['Topic']);
    });

    test('skips server-filled names in any case', () {
      expect(
        extractVariables(
          '{{current_date}} {{ CURRENT_USER }} {{Iso_Datetime}} '
          '{{current_datetime}} {{x}}',
        ),
        ['x'],
      );
    });

    test('skips non-placeholders', () {
      expect(extractVariables('{{}} {{ }} {{a{b}} {a} {{a} a}}'), isEmpty);
    });

    test('names with spaces, - and . work', () {
      expect(extractVariables('{{first name}} {{x-y}} {{a.b}}'), [
        'first name',
        'x-y',
        'a.b',
      ]);
    });

    test('a template without placeholders has none', () {
      expect(extractVariables('plain text'), isEmpty);
    });
  });
}
