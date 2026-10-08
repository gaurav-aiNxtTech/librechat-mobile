/// The SSE_Formatter: writes [SseEvent]s as Server-Sent Events text.
///
/// The inverse of `SseParser` for tests: Property 8 round-trips through it
/// and StreamClient tests build response bodies with it.
///
/// ```dart
/// server.on('GET', '/api/stream', respondChunks([
///   sseJson({'created': true}),
///   sseJson({'final': true}, event: 'message'),
/// ]));
/// ```
library;

import 'dart:convert';

import 'package:librechat_flutter/core/stream/sse_parser.dart';

/// The line terminators SSE allows.
enum SseLineEnding {
  lf('\n'),
  cr('\r'),
  crlf('\r\n');

  const SseLineEnding(this.text);

  /// The literal terminator.
  final String text;
}

/// Writes [event] as one SSE frame.
///
/// Each of [comments] becomes a `:<comment>` line, then `event: <name>` and
/// `id: <id>` when set, one `data: <piece>` line per `\n`-separated piece of
/// the data (so empty data writes one `data: ` line) and a closing blank
/// line. Every line ends with [ending].
String formatSseEvent(
  SseEvent event, {
  SseLineEnding ending = SseLineEnding.lf,
  List<String> comments = const [],
}) {
  final eol = ending.text;
  final out = StringBuffer();
  for (final comment in comments) {
    out.write(':$comment$eol');
  }
  if (event.event case final name?) out.write('event: $name$eol');
  if (event.id case final id?) out.write('id: $id$eol');
  for (final piece in event.data.split('\n')) {
    out.write('data: $piece$eol');
  }
  out.write(eol);
  return out.toString();
}

/// Writes [events] one after another with LF line endings.
String formatSse(Iterable<SseEvent> events) =>
    events.map(formatSseEvent).join();

/// One frame whose data is [json] encoded, named [event] when set.
String sseJson(Object? json, {String? event}) =>
    formatSseEvent(SseEvent(event: event, data: jsonEncode(json)));

/// Splits [bytes] at the offsets in [cuts], sorted first.
///
/// Repeated or boundary offsets produce empty chunks, which a parser must
/// tolerate as well.
List<List<int>> splitBytes(List<int> bytes, List<int> cuts) {
  final sorted = [...cuts]..sort();
  final chunks = <List<int>>[];
  var start = 0;
  for (final cut in sorted) {
    assert(cut >= 0 && cut <= bytes.length, 'cut $cut is out of range');
    chunks.add(bytes.sublist(start, cut));
    start = cut;
  }
  chunks.add(bytes.sublist(start));
  return chunks;
}
