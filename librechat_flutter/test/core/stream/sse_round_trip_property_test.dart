import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/stream/sse_parser.dart';

import '../../support/property.dart';
import '../../support/sse_formatter.dart';

void main() {
  // Feature: flutter-android-rewrite, Property 8: For any list of events, writing them with the SSE_Formatter, splitting the bytes at arbitrary positions and parsing the chunks with the SSE_Parser yields the original events.
  // Validates: Requirements 18.5
  //
  // Each parsed event is expected to carry its own id (null when it had none),
  // not the previous event's: the design's parser rule has no carried-over
  // last-event-id, and "yields the original events" says the same, so the
  // property's "a missing id expects the previous one" aside is not followed.
  test('Property 8: SSE format, chunk and parse round trip', () async {
    await forAll(sseCase, (c) async {
      final bytes = [
        if (c.bom) ...[0xEF, 0xBB, 0xBF],
        ...utf8.encode(
          c.frames
              .map(
                (f) => formatSseEvent(
                  f.event,
                  ending: f.ending,
                  comments: f.comments,
                ),
              )
              .join(),
        ),
      ];
      // Offsets anywhere in [0, length], including inside multibyte
      // characters and CRLF pairs; duplicates make empty chunks.
      final cuts = c.cutSeeds.map((s) => s % (bytes.length + 1)).toList()
        ..sort();
      final parsed = await Stream.fromIterable(
        splitBytes(bytes, cuts),
      ).transform(const SseParser()).toList();
      expect(parsed, c.frames.map((f) => f.event).toList());
    });
  });
}
