import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_parser.dart';

/// The single segment of [text], which must be an [Artifact].
Artifact _only(String text) {
  final segments = parseArtifacts(text);
  expect(segments, hasLength(1), reason: '$segments');
  return segments.single as Artifact;
}

Artifact _art(
  String content, {
  String identifier = 'a',
  String type = 'text/html',
  String title = 'T',
  bool complete = true,
}) => Artifact(
  identifier: identifier,
  type: type,
  title: title,
  content: content,
  complete: complete,
);

const _open = ':::artifact{identifier="a" type="text/html" title="T"}';

Message _message(
  String id, {
  String text = '',
  bool user = false,
  List<ContentPart>? content,
}) => Message(
  messageId: id,
  conversationId: 'c',
  text: text,
  isCreatedByUser: user,
  content: content,
);

void main() {
  group('no artifacts', () {
    test('plain text is one TextSegment with the exact text', () {
      const text = 'Hello\n\n  world ::: not a block\n';
      expect(parseArtifacts(text), [const TextSegment(text)]);
    });

    test('empty and whitespace-only input give no segments', () {
      expect(parseArtifacts(''), isEmpty);
      expect(parseArtifacts(' \n\t\n'), isEmpty);
    });
  });

  group('attribute forms', () {
    test('double-quoted, single-quoted, unquoted and bare', () {
      final a = _only(
        ':::artifact{identifier="x y" type=\'text/html\' title=Hi flag}\n'
        '```\nbody\n```\n:::',
      );
      expect(a, _art('body', identifier: 'x y', title: 'Hi'));
    });

    test('whitespace around = is allowed', () {
      final a = _only(
        ':::artifact{identifier = "x"  type =text/html title=  \'T\'}\n'
        'body\n:::',
      );
      expect(a, _art('body', identifier: 'x'));
    });

    test('unknown attributes are ignored and the last duplicate wins', () {
      final a = _only(
        ':::artifact{version=2 identifier="old" identifier="a" '
        'type="text/html" title="T" data-x:y=1}\nbody\n:::',
      );
      expect(a, _art('body'));
    });

    test('absent attributes take the defaults', () {
      final a = _only(':::artifact{}\nbody\n:::');
      expect(
        a,
        const Artifact(
          identifier: '',
          type: 'text/plain',
          title: 'Artifact',
          content: 'body',
          complete: true,
        ),
      );
    });

    test('identifier falls back to id', () {
      expect(_only(':::artifact{id="z"}\nb\n:::').identifier, 'z');
      expect(
        _only(':::artifact{id="z" identifier="i"}\nb\n:::').identifier,
        'i',
      );
    });

    test('an explicit empty value stays empty', () {
      final a = _only(':::artifact{title="" type=\'\' identifier}\nb\n:::');
      expect(a.title, '');
      expect(a.type, '');
      expect(a.identifier, '');
    });

    test('a quoted value may hold } and spaces', () {
      expect(
        _only(':::artifact{title="a } b" type="x"}\nb\n:::').title,
        'a } b',
      );
    });

    test('an unquoted last value may hold }', () {
      expect(_only(':::artifact{type=x title=a}b}\nb\n:::').title, 'a}b');
    });

    test('surrounding whitespace on the opener line is allowed', () {
      expect(_only('  $_open  \nb\n:::'), _art('b'));
    });
  });

  group('malformed openers stay text', () {
    for (final opener in [
      ':::artifact {identifier="a"}',
      ':::artifact{identifier="a}',
      ':::artifact{identifier="a"',
      ':::artifact{1d="a"}',
      ':::artifact{a,b}',
    ]) {
      test(opener, () {
        final text = '$opener\nbody\n:::';
        expect(parseArtifacts(text), [TextSegment(text)]);
      });
    }
  });

  group('fences', () {
    test('a backtick fence of 3', () {
      expect(_only('$_open\n```\n<p>hi</p>\n```\n:::'), _art('<p>hi</p>'));
    });

    test('a backtick fence of 4 holds a ``` line', () {
      expect(_only('$_open\n````\na\n```\nb\n````\n:::'), _art('a\n```\nb'));
    });

    test('a tilde fence of 3', () {
      expect(_only('$_open\n~~~\na\n```\n~~~\n:::'), _art('a\n```'));
    });

    test('a longer closing fence closes', () {
      expect(_only('$_open\n```\na\n`````\n:::'), _art('a'));
    });

    test('a shorter fence or the other character does not close', () {
      final a = _only('$_open\n````\na\n```\n~~~~\nb\n````\n:::');
      expect(a, _art('a\n```\n~~~~\nb'));
    });

    test('an info string is dropped', () {
      expect(_only('$_open\n```html\na\n```\n:::'), _art('a'));
    });

    test('blank lines before the fence are skipped', () {
      expect(_only('$_open\n\n  \n```\na\n```\n\n:::'), _art('a'));
    });

    test('content keeps its leading and trailing blank lines', () {
      expect(_only('$_open\n```\n\na\n\n```\n:::'), _art('\na\n'));
    });

    test('an empty fence gives empty content', () {
      expect(_only('$_open\n```\n```\n:::'), _art(''));
    });
  });

  group('closing lines', () {
    test('::: lines inside a fence are content', () {
      expect(_only('$_open\n```\na\n:::\nb\n```\n:::'), _art('a\n:::\nb'));
    });

    test('a mid-line ::: is content', () {
      expect(_only('$_open\na ::: b\n:::'), _art('a ::: b'));
    });

    test('unfenced content runs to :::', () {
      expect(_only('$_open\n\na\n  b\n:::'), _art('\na\n  b'));
    });

    test('::: trailing does not close a block', () {
      expect(_only('$_open\na\n::: trailing\n::::'), _art('a\n::: trailing'));
    });
  });

  test('CRLF input gives LF content and the same artifact', () {
    const lf = '$_open\n```\na\nb\n```\n:::';
    expect(parseArtifacts(lf.replaceAll('\n', '\r\n')), parseArtifacts(lf));
    expect(_only(lf.replaceAll('\n', '\r\n')).content, 'a\nb');
  });

  group('incomplete', () {
    test('an unclosed fence runs to the end', () {
      expect(parseArtifacts('$_open\n```\na\n:::\nb'), [
        _art('a\n:::\nb', complete: false),
      ]);
    });

    test('an unfenced block without a close runs to the end', () {
      expect(parseArtifacts('$_open\na\nb'), [_art('a\nb', complete: false)]);
    });

    test('a fence that closed without ::: leaves the prose as text', () {
      expect(parseArtifacts('$_open\n```\na\n```\nThen prose.'), [
        _art('a', complete: false),
        const TextSegment('Then prose.'),
      ]);
    });

    test('an opener alone is an incomplete artifact', () {
      expect(parseArtifacts(_open), [_art('', complete: false)]);
    });
  });

  test('multiple artifacts keep text before, between and after', () {
    const text =
        'Intro\n'
        ':::artifact{identifier="a" type="text/html" title="T"}\n'
        '```\none\n```\n'
        ':::\n'
        'Middle\n'
        ':::artifact{identifier="b" type="image/svg+xml" title="S"}\n'
        'two\n'
        ':::\n'
        'Outro';
    expect(parseArtifacts(text), [
      const TextSegment('Intro\n'),
      _art('one'),
      const TextSegment('Middle\n'),
      _art('two', identifier: 'b', type: 'image/svg+xml', title: 'S'),
      const TextSegment('Outro'),
    ]);
  });

  test('an opener inside a prose code fence stays text', () {
    const text = 'Example:\n```md\n$_open\nb\n:::\n```\nDone';
    expect(parseArtifacts(text), [const TextSegment(text)]);
  });

  group('formatArtifact', () {
    test('writes the block with a fence longer than any backtick run', () {
      const a = Artifact(
        identifier: 'a',
        type: 'text/html',
        title: 'T',
        content: 'x ```` y',
      );
      expect(
        formatArtifact(a),
        ':::artifact{identifier="a" type="text/html" title="T"}\n'
        '`````\nx ```` y\n`````\n:::',
      );
    });

    test('a value with " is written in single quotes', () {
      const a = Artifact(
        identifier: 'a',
        type: 'text/html',
        title: 'Say "hi"',
        content: 'x',
      );
      expect(formatArtifact(a), contains("title='Say \"hi\"'"));
      expect(parseArtifacts(formatArtifact(a)), [a]);
    });

    for (final content in [
      '',
      '\n',
      'one line',
      'a\n:::\nb\n:::',
      '```\n~~~\n````````',
      '\n\nlead and trail\n\n',
    ]) {
      test('round trips ${describe(content)}', () {
        final a = Artifact(
          identifier: 'id: 1',
          type: 'application/vnd.react',
          title: 'Title {x} é 中',
          content: content,
        );
        expect(parseArtifacts(formatArtifact(a)), [a]);
      });
    }
  });

  group('artifactVersions', () {
    test('groups across messages in path order', () {
      String block(String id, String body) =>
          ':::artifact{identifier="$id" type="text/html" title="T"}\n'
          '$body\n:::';
      final versions = artifactVersions([
        _message('1', text: '${block('a', 'v1')}\n${block('b', 'b1')}'),
        _message('2', text: block('a', 'v2')),
      ]);
      expect(versions.keys, ['a', 'b']);
      expect(versions['a']!.map((a) => a.content), ['v1', 'v2']);
      expect(versions['b']!.map((a) => a.content), ['b1']);
    });

    test('reads text content parts over message.text', () {
      final versions = artifactVersions([
        _message(
          '1',
          text: '$_open\nignored\n:::',
          content: const [
            ContentPart(type: ContentPartType.text, text: '$_open\np1\n:::'),
            ContentPart(type: ContentPartType.think, think: '$_open\nx\n:::'),
            ContentPart(
              type: ContentPartType.textDelta,
              text: '$_open\np2\n:::',
            ),
          ],
        ),
      ]);
      expect(versions['a']!.map((a) => a.content), ['p1', 'p2']);
    });

    test('skips user messages, incomplete artifacts and empty ids', () {
      final versions = artifactVersions([
        _message('1', text: '$_open\nuser\n:::', user: true),
        _message('2', text: '$_open\nopen'),
        _message('3', text: ':::artifact{type="text/html"}\nnoid\n:::'),
        _message('4', text: '$_open\nkept\n:::'),
      ]);
      expect(versions.keys, ['a']);
      expect(versions['a']!.map((a) => a.content), ['kept']);
    });
  });

  test('artifactKind follows the KMP ladder', () {
    expect(artifactKind('application/vnd.mermaid'), ArtifactKind.mermaid);
    expect(artifactKind('application/vnd.react'), ArtifactKind.react);
    expect(artifactKind('image/svg+xml'), ArtifactKind.svg);
    expect(artifactKind('text/markdown'), ArtifactKind.markdown);
    expect(artifactKind('text/md'), ArtifactKind.markdown);
    expect(artifactKind('text/html'), ArtifactKind.html);
    expect(artifactKind('application/vnd.code-html'), ArtifactKind.html);
    expect(artifactKind('text/plain'), ArtifactKind.plain);
    expect(artifactKind('application/json'), ArtifactKind.code);
    expect(_art('x', type: 'image/svg+xml').kind, ArtifactKind.svg);
  });
}

String describe(String value) =>
    '"${value.replaceAll('\n', r'\n').replaceAll('`', "'")}"';
