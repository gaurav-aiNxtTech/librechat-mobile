/// Server-Sent Events parsing: bytes in, [SseEvent]s out.
///
/// Follows the WHATWG "event stream interpretation" rules with the design's
/// one deviation: an event's `id` belongs to that event only, so there is no
/// carried-over last-event-id.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One dispatched SSE event.
@immutable
class SseEvent {
  const SseEvent({this.event, required this.data, this.id});

  /// The `event:` name, or `null` for the default (unnamed) event.
  final String? event;

  /// The `data:` lines joined by `\n`.
  final String data;

  /// The `id:` of this event, or `null` when it carried none.
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is SseEvent &&
      other.event == event &&
      other.data == data &&
      other.id == id;

  @override
  int get hashCode => Object.hash(event, data, id);

  /// Shows [data] JSON-encoded so whitespace and line breaks stay visible.
  @override
  String toString() =>
      'SseEvent(event: $event, id: $id, data: ${jsonEncode(data)})';
}

/// Turns a byte stream into [SseEvent]s.
///
/// Each [bind] gets fresh state, so one parser instance may serve several
/// streams.
class SseParser extends StreamTransformerBase<List<int>, SseEvent> {
  const SseParser();

  @override
  Stream<SseEvent> bind(Stream<List<int>> stream) => Stream.eventTransformed(
    stream
        // Malformed bytes become U+FFFD instead of failing the stream; the
        // decoder keeps a multibyte character split across chunks intact.
        // It also skips one leading BOM (even split across chunks), which is
        // exactly WHATWG's rule, so a second U+FEFF reaches the parser as
        // content. Stripping again here would drop that second one.
        .transform(const Utf8Decoder(allowMalformed: true))
        // CR, LF and CRLF all end a line, and a CRLF split across chunks
        // counts once because a chunk-final CR waits for the next chunk.
        .transform(const LineSplitter()),
    _SseSink.new,
  );
}

/// The per-stream field and dispatch state machine.
class _SseSink implements EventSink<String> {
  _SseSink(this._out);

  final EventSink<SseEvent> _out;

  final StringBuffer _data = StringBuffer();
  bool _sawData = false;
  String? _event;
  String? _id;

  @override
  void add(String line) {
    if (line.isEmpty) {
      _dispatch();
      return;
    }
    // A line starting with a colon is a comment (keep-alives use these).
    if (line.startsWith(':')) return;

    // Split at the first colon; without one the whole line is the field name
    // and the value is empty.
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    // Exactly one leading space is syntax, any further spaces are content.
    if (value.startsWith(' ')) value = value.substring(1);

    switch (field) {
      case 'data':
        _data
          ..write(value)
          ..write('\n');
        _sawData = true;
      case 'event':
        // An empty type means the default event, so the name stays null.
        _event = value.isEmpty ? null : value;
      case 'id':
        // WHATWG ignores an id holding NUL.
        if (!value.contains('\u0000')) _id = value;
      default:
        // `retry` (reconnect timing is the StreamClient's own ladder) and
        // unknown fields are ignored.
        break;
    }
  }

  /// Ends the current event at a blank line.
  void _dispatch() {
    // WHATWG dispatches nothing when no data line was seen.
    if (_sawData) {
      final data = _data.toString();
      _out.add(
        SseEvent(
          event: _event,
          // Remove the `\n` appended after the last data line.
          data: data.substring(0, data.length - 1),
          id: _id,
        ),
      );
    }
    _data.clear();
    _sawData = false;
    _event = null;
    // Design rule: no carried-over last-event-id, so the id resets too.
    _id = null;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _out.addError(error, stackTrace);

  @override
  void close() {
    // A partial event at end of stream (no closing blank line) is dropped,
    // as WHATWG requires.
    _out.close();
  }
}
