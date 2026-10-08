import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/stream/sse_parser.dart';

import '../../support/sse_formatter.dart';

/// Parses [chunks], each a `String` (UTF-8 encoded) or a `List<int>`.
Future<List<SseEvent>> _parse(List<Object> chunks) => Stream.fromIterable(
  chunks.map((c) => c is String ? utf8.encode(c) : c as List<int>),
).transform(const SseParser()).toList();

void main() {
  group('SseParser', () {
    test('joins multi-line data with LF', () async {
      expect(await _parse(['data: a\ndata: b\ndata:\n\n']), [
        const SseEvent(data: 'a\nb\n'),
      ]);
    });

    test('ignores comment lines', () async {
      expect(await _parse([': keep-alive\ndata: a\n:\n: more\ndata: b\n\n']), [
        const SseEvent(data: 'a\nb'),
      ]);
    });

    test('accepts CR, LF and CRLF line endings', () async {
      for (final ending in SseLineEnding.values) {
        final eol = ending.text;
        expect(
          await _parse(['event: e${eol}data: a${eol}data: b$eol$eol']),
          [const SseEvent(event: 'e', data: 'a\nb')],
          reason: ending.name,
        );
      }
    });

    test('counts a CRLF split between chunks as one line end', () async {
      // Two line ends would make a blank line and dispatch `a` on its own.
      expect(await _parse(['data: a\r', '\ndata: b\r\n\r\n']), [
        const SseEvent(data: 'a\nb'),
      ]);
    });

    test('ends a line at a chunk-final CR followed by another field', () async {
      expect(await _parse(['data: a\r', 'data: b\r\r']), [
        const SseEvent(data: 'a\nb'),
      ]);
      expect(await _parse(['data: a\r\r', 'data: b\r\r']), [
        const SseEvent(data: 'a'),
        const SseEvent(data: 'b'),
      ]);
    });

    test('keeps a 4-byte character split across chunks', () async {
      final bytes = utf8.encode('data: x😀y\n\n');
      final start = utf8.encode('data: x').length;
      for (var cut = start + 1; cut < start + 4; cut++) {
        expect(
          await _parse([bytes.sublist(0, cut), bytes.sublist(cut)]),
          [const SseEvent(data: 'x😀y')],
          reason: 'cut at $cut',
        );
      }
    });

    test('strips one leading BOM and keeps a second U+FEFF', () async {
      const bom = [0xEF, 0xBB, 0xBF];
      expect(await _parse([bom, 'data: a\n\n']), [const SseEvent(data: 'a')]);
      // A BOM split across chunks is still the leading BOM.
      expect(await _parse([bom.sublist(0, 1), bom.sublist(1), 'data: a\n\n']), [
        const SseEvent(data: 'a'),
      ]);
      // After the stripped BOM the field name is `\ufeffdata`, an unknown field.
      expect(await _parse([bom, bom, 'data: a\n\n']), isEmpty);
      // A U+FEFF anywhere but the very start is content.
      expect(await _parse([bom, 'data: \ufeffa\n\n']), [
        const SseEvent(data: '\ufeffa'),
      ]);
      expect(await _parse(['data: a\n\n\ufeffdata: b\n\n']), [
        const SseEvent(data: 'a'),
      ]);
    });

    test(
      'treats a line without a colon as a field with an empty value',
      () async {
        expect(await _parse(['data\ndata\n\n']), [const SseEvent(data: '\n')]);
        expect(await _parse(['id\ndata: a\n\n']), [
          const SseEvent(data: 'a', id: ''),
        ]);
      },
    );

    test('accepts a value without a space after the colon', () async {
      expect(await _parse(['event:e\nid:1\ndata:x\n\n']), [
        const SseEvent(event: 'e', data: 'x', id: '1'),
      ]);
    });

    test('drops exactly one leading space of the value', () async {
      expect(await _parse(['data:  x\n\n']), [const SseEvent(data: ' x')]);
      expect(await _parse(['event:  e\ndata: a\n\n']), [
        const SseEvent(event: ' e', data: 'a'),
      ]);
    });

    test('ignores an id holding NUL', () async {
      expect(await _parse(['id: 1\nid: a\u0000b\ndata: x\n\n']), [
        const SseEvent(data: 'x', id: '1'),
      ]);
      expect(await _parse(['id: a\u0000b\ndata: x\n\n']), [
        const SseEvent(data: 'x'),
      ]);
    });

    test('ignores retry and unknown fields', () async {
      expect(await _parse(['retry: 1000\nfoo: bar\nDATA: no\ndata: a\n\n']), [
        const SseEvent(data: 'a'),
      ]);
    });

    test('dispatches nothing for a blank line without data', () async {
      expect(await _parse(['\n\nevent: e\nid: 1\n\n: c\n\n']), isEmpty);
      // The discarded event and id do not leak into the next event.
      expect(await _parse(['event: e\nid: 1\n\ndata: a\n\n']), [
        const SseEvent(data: 'a'),
      ]);
    });

    test('leaves the event name null when absent or empty', () async {
      expect(await _parse(['data: a\n\nevent:\ndata: b\n\n']), [
        const SseEvent(data: 'a'),
        const SseEvent(data: 'b'),
      ]);
      expect((await _parse(['data: a\n\n'])).single.event, isNull);
    });

    test('does not carry an id to the next event', () async {
      expect(await _parse(['id: 7\ndata: a\n\ndata: b\n\n']), [
        const SseEvent(data: 'a', id: '7'),
        const SseEvent(data: 'b'),
      ]);
    });

    test('drops a partial event at the end of the stream', () async {
      expect(await _parse(['data: a\n\ndata: b\n']), [
        const SseEvent(data: 'a'),
      ]);
      expect(await _parse(['data: a\n\nevent: e\ndata: b']), [
        const SseEvent(data: 'a'),
      ]);
    });

    test('gives each bound stream fresh state', () async {
      const parser = SseParser();
      final first = Stream<List<int>>.value(utf8.encode('event: e\ndata: a\n'));
      expect(await first.transform(parser).toList(), isEmpty);
      final second = Stream<List<int>>.value(utf8.encode('data: b\n\n'));
      expect(await second.transform(parser).toList(), [
        const SseEvent(data: 'b'),
      ]);
    });

    test('forwards stream errors', () async {
      final stream = Stream<List<int>>.error(const FormatException('boom'));
      expect(
        stream.transform(const SseParser()).toList(),
        throwsFormatException,
      );
    });
  });

  group('SSE formatter', () {
    test('writes comments, event, id, data lines and a blank line', () {
      expect(
        formatSseEvent(
          const SseEvent(event: 'e', data: 'a\nb', id: '1'),
          ending: SseLineEnding.crlf,
          comments: const ['c'],
        ),
        ':c\r\nevent: e\r\nid: 1\r\ndata: a\r\ndata: b\r\n\r\n',
      );
      expect(formatSseEvent(const SseEvent(data: '')), 'data: \n\n');
    });

    test('formatSse and sseJson write LF frames', () {
      expect(
        formatSse(const [SseEvent(data: 'a'), SseEvent(data: 'b')]),
        'data: a\n\ndata: b\n\n',
      );
      expect(
        sseJson({'k': 1}, event: 'message'),
        'event: message\ndata: {"k":1}\n\n',
      );
    });

    test('splitBytes cuts at sorted offsets and allows empty chunks', () {
      expect(splitBytes([1, 2, 3], [2, 0, 2]), [
        <int>[],
        [1, 2],
        <int>[],
        [3],
      ]);
      expect(splitBytes([1, 2], []), [
        [1, 2],
      ]);
    });
  });
}
