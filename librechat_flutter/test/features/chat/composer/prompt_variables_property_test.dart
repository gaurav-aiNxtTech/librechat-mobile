import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/chat/composer/prompt_variables.dart';

import '../../../support/property.dart';

const _serverFilled = {
  'current_date',
  'current_user',
  'iso_datetime',
  'current_datetime',
};

/// A hand-written scanner restating the rule without the regex: at `{{`,
/// the first brace after it must be `}}` with non-empty text between.
String _model(String template, Map<String, String> values) {
  final lookup = <String, String>{};
  for (final entry in values.entries) {
    if (entry.value.trim().isEmpty) continue;
    lookup[entry.key.trim().toLowerCase()] = entry.value;
  }
  final out = StringBuffer();
  var i = 0;
  while (i < template.length) {
    if (template.startsWith('{{', i)) {
      var j = i + 2;
      while (j < template.length && template[j] != '{' && template[j] != '}') {
        j++;
      }
      final isPlaceholder = j > i + 2 && template.startsWith('}}', j);
      if (isPlaceholder) {
        final raw = template.substring(i, j + 2);
        final name = template.substring(i + 2, j).trim().toLowerCase();
        final fillable = name.isNotEmpty && !_serverFilled.contains(name);
        out.write(fillable ? (lookup[name] ?? raw) : raw);
        i = j + 2;
        continue;
      }
    }
    out.write(template[i]);
    i++;
  }
  return out.toString();
}

void main() {
  // Feature: flutter-android-rewrite, Property 11: For any template and value map, the Prompt_Variable_Parser replaces exactly the fillable placeholders whose trimmed, case-insensitive name has a non-blank value, and leaves every other placeholder and all other text unchanged.
  // Validates: Requirements 27.9
  test('Property 11: Prompt variable filling matches its model', () async {
    await forAll(promptFillCaseGen, (c) {
      final (template, values) = c;
      expect(fillVariables(template, values), _model(template, values));
    });
  });
}
