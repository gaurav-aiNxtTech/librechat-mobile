import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_parser.dart';

import '../../../support/property.dart';

/// A written artifact block inside surrounding text, and the four values the
/// parser must read back.
typedef _Case = ({
  String text,
  String identifier,
  String type,
  String title,
  String content,
});

/// One attribute, written double-quoted, single-quoted, unquoted (a
/// non-empty value without whitespace) or bare (an empty value).
String _attribute(Random r, String name, String value) {
  final forms = <String>[
    '$name="$value"',
    "$name='$value'",
    if (value.isNotEmpty && !value.contains(RegExp(r'\s'))) '$name=$value',
    if (value.isEmpty) name,
  ];
  return forms[r.nextInt(forms.length)];
}

/// A hand-written opener line with shuffled attributes and 1–2 space
/// separators, sometimes with an extra attribute the parser ignores.
String _opener(Random r, String identifier, String type, String title) {
  final attributes = [
    _attribute(r, 'identifier', identifier),
    _attribute(r, 'type', type),
    _attribute(r, 'title', title),
    if (r.nextInt(3) == 0) 'version=2',
  ]..shuffle(r);
  final buffer = StringBuffer(':::artifact{');
  for (var i = 0; i < attributes.length; i++) {
    if (i > 0) buffer.write(' ' * (1 + r.nextInt(2)));
    buffer.write(attributes[i]);
  }
  buffer.write('}');
  return buffer.toString();
}

/// A fenced block with 0–2 blank lines between the opener and the fence.
String _fenced(Random r, String opener, String char, String content) {
  final fence = char * intRange(3, 6)(r);
  final blanks = '\n' * r.nextInt(3);
  return '$opener\n$blanks$fence\n$content\n$fence\n:::';
}

/// Unfenced content must not look like an opening fence.
bool _unfencedSafe(String content) {
  for (final line in content.split('\n')) {
    if (line.trim().isEmpty) continue;
    final start = line.trimLeft();
    return !start.startsWith('`') && !start.startsWith('~');
  }
  return true;
}

final Gen<_Case> _case = Gen((r) {
  final identifier = artifactValueGen(r);
  final type = artifactTypeGen(r);
  final title = artifactValueGen(r);
  final String content;
  final String block;
  switch (r.nextInt(4)) {
    case 0:
      content = artifactContentGen(fenceLines: true)(r);
      block = formatArtifact(
        Artifact(
          identifier: identifier,
          type: type,
          title: title,
          content: content,
        ),
      );
    case 1:
      content = artifactContentGen()(r);
      block = _fenced(r, _opener(r, identifier, type, title), '`', content);
    case 2:
      content = artifactContentGen()(r);
      block = _fenced(r, _opener(r, identifier, type, title), '~', content);
    default:
      content = artifactContentGen().where(_unfencedSafe)(r);
      block = '${_opener(r, identifier, type, title)}\n$content\n:::';
  }
  final before = artifactProseGen(r);
  final after = artifactProseGen(r);
  var text = [
    if (before.isNotEmpty) before,
    block,
    if (after.isNotEmpty) after,
  ].join('\n');
  if (r.nextBool()) text = text.replaceAll('\n', '\r\n');
  return (
    text: text,
    identifier: identifier,
    type: type,
    title: title,
    content: content,
  );
});

void main() {
  // Feature: flutter-android-rewrite, Property 9: For any artifact identifier, type, title and content, writing them as a `:::artifact{...}` block and parsing the text with the Artifact_Parser yields one Artifact with the same four values.
  // Validates: Requirements 24.2
  test('Property 9: Artifact write and parse round trip', () async {
    await forAll(_case, (c) {
      final reason = describeCase(c.text);
      final artifacts = parseArtifacts(c.text).whereType<Artifact>().toList();
      expect(artifacts, hasLength(1), reason: reason);
      final artifact = artifacts.single;
      expect(artifact.identifier, c.identifier, reason: reason);
      expect(artifact.type, c.type, reason: reason);
      expect(artifact.title, c.title, reason: reason);
      expect(artifact.content, c.content, reason: reason);
      expect(artifact.complete, isTrue, reason: reason);
    }, runs: 100);
  });
}
