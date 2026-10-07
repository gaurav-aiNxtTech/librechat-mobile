import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The app's [DiagnosticLog]. `main()` opens the log and injects it with
/// `overrideWithValue`.
final diagnosticLogProvider = Provider<DiagnosticLog>(
  (ref) => throw UnimplementedError('diagnosticLogProvider is not overridden'),
);

/// An error that knows which of its fields are safe to log, such as its
/// FailureKind and HTTP status. [DiagnosticLog.error] adds these attributes,
/// still redacted, after the error's type. Errors are never logged through
/// `toString()`, because dio messages embed URLs and headers.
abstract interface class DiagnosticError {
  Map<String, Object?> get diagnosticAttributes;
}

/// The on-device diagnostic log that the Data settings export shares (Req 41.5).
///
/// Each entry is one line: UTC time, level, tag, event and `key=value`
/// attributes. Every attribute goes through [redact], so tokens, cookie values,
/// Custom_Headers values, passwords and message content never reach the file
/// (Req 46.3). The file keeps at most the newest 1 MB of entries (Req 46.4).
class DiagnosticLog {
  DiagnosticLog._(this._file, this._size);

  /// Size at which the log is rewritten.
  static const int maxBytes = 1024 * 1024;

  /// Size the log is cut back to, keeping the newest entries.
  static const int keepBytes = 768 * 1024;

  /// Longest logged attribute value, in characters.
  static const int maxValueLength = 200;

  static const String redacted = '[redacted]';
  static const String fileName = 'diagnostic.log';

  final File _file;
  int _size;

  /// Every write runs on this chain, so entries land in call order.
  Future<void> _tail = Future<void>.value();
  final BytesBuilder _pending = BytesBuilder(copy: false);
  bool _scheduled = false;
  RandomAccessFile? _raf;

  /// Opens `<app support dir>/diagnostic.log`, or the same file name in
  /// [directory] when given. A log left above [maxBytes] is cut back first.
  static Future<DiagnosticLog> open({Directory? directory}) async {
    final dir = directory ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, fileName));
    final size = await file.exists() ? await file.length() : 0;
    final log = DiagnosticLog._(file, size);
    // An entry cut short by a crash still ends its line, so the next entry
    // starts on its own.
    if (size > 0 && await _lastByte(file, size) != 0x0A) {
      log._chain(Uint8List.fromList(const [0x0A]));
    } else if (size > maxBytes) {
      log._chain(Uint8List(0));
    }
    return log;
  }

  static Future<int> _lastByte(File file, int size) async {
    final raf = await file.open();
    try {
      await raf.setPosition(size - 1);
      return await raf.readByte();
    } finally {
      await raf.close();
    }
  }

  /// Logs [event] under [tag] with redacted [attrs].
  void info(String tag, String event, [Map<String, Object?> attrs = const {}]) {
    _enqueue('INFO', tag, event, attrs);
  }

  /// Logs [error] by its type, plus its [DiagnosticError] attributes and the
  /// top frames of [stack]. The error's message is never logged.
  void error(String tag, String event, Object error, [StackTrace? stack]) {
    final attrs = <String, Object?>{'type': error.runtimeType.toString()};
    if (error is DiagnosticError) {
      for (final MapEntry(:key, :value) in error.diagnosticAttributes.entries) {
        attrs.putIfAbsent(key, () => value);
      }
    }
    if (stack != null) attrs['stack'] = _frames(stack);
    _enqueue('ERROR', tag, event, attrs);
  }

  /// Writes and flushes pending entries, then returns the log file for export.
  Future<File> file() async {
    await _tail;
    try {
      await _raf?.flush();
    } on FileSystemException {
      await _close().catchError((Object _) {});
    }
    if (!await _file.exists()) await _file.create(recursive: true);
    return _file;
  }

  /// Formats one attribute value for the log (Req 46.3).
  ///
  /// Sensitive keys become [redacted]. In the value, URLs lose their user
  /// info, query and fragment; JWT-shaped strings, `Bearer …` credentials and
  /// `…token=…` pairs are replaced; the result stops at [maxValueLength].
  static String redact(String key, Object? value) {
    if (_sensitiveKey.hasMatch(key)) return redacted;
    final String text = switch (value) {
      null => 'null',
      Enum() => value.name,
      Duration() => '${value.inMilliseconds}ms',
      DateTime() => value.toUtc().toIso8601String(),
      _ => value.toString(),
    };
    var out = text
        .replaceAllMapped(_urlUserInfo, (m) => m[1]!)
        .replaceAllMapped(_urlQuery, (m) => '${m[1]}${m[2]}')
        .replaceAll(_jwt, redacted)
        .replaceAllMapped(_bearer, (m) => '${m[1]} $redacted')
        .replaceAllMapped(_tokenPair, (m) => '${m[1]}=$redacted');
    if (out.length > maxValueLength) {
      var end = maxValueLength;
      // Don't split a surrogate pair.
      final last = out.codeUnitAt(end - 1);
      if (last >= 0xD800 && last <= 0xDBFF) end--;
      out = out.substring(0, end);
    }
    return out;
  }

  static final RegExp _sensitiveKey = RegExp(
    'token|cookie|authorization|password|secret|header|content|text|message|prompt',
    caseSensitive: false,
  );

  /// `scheme://user:pass@` → `scheme://`.
  static final RegExp _urlUserInfo = RegExp(
    r'([A-Za-z][A-Za-z0-9+.\-]*://)[^\s/?#@]+@',
  );

  /// A URL or an absolute path, followed by its query and/or fragment.
  static final RegExp _urlQuery = RegExp(
    r'(^|[\s"(<\[=,])((?:[A-Za-z][A-Za-z0-9+.\-]*://|/)[^\s?#"]*)[?#][^\s"]*',
  );

  static final RegExp _jwt = RegExp(
    r'eyJ[A-Za-z0-9_\-]*\.[A-Za-z0-9_\-]*(?:\.[A-Za-z0-9_\-]*)?',
  );

  static final RegExp _bearer = RegExp(
    r'\b(Bearer)\s+[^\s,;"]+',
    caseSensitive: false,
  );

  /// `refreshToken=…`, `token=…` and other `…token…=` pairs, as in cookies.
  static final RegExp _tokenPair = RegExp(
    r'([\w.\-]*token[\w.\-]*)=[^\s;&,"]*',
    caseSensitive: false,
  );

  static final RegExp _unsafeName = RegExp(r'[^\w.\-]');
  static final RegExp _lineBreaks = RegExp(
    r'[\r\n\t\x00-\x08\x0B\x0C\x0E-\x1F]+',
  );

  void _enqueue(
    String level,
    String tag,
    String event,
    Map<String, Object?> attrs,
  ) {
    _chain(utf8.encode(_format(level, tag, event, attrs)));
  }

  /// Queues [bytes] behind earlier entries. Entries queued while a write runs
  /// go out together in the next write, still in call order.
  void _chain(Uint8List bytes) {
    _pending.add(bytes);
    if (_scheduled) return;
    _scheduled = true;
    _tail = _tail
        .then((_) {
          _scheduled = false;
          return _write(_pending.takeBytes());
        })
        .catchError((Object e) async {
          // Logging must never break the app; the next write reopens the file.
          await _close().catchError((Object _) {});
          if (kDebugMode) {
            debugPrint('DiagnosticLog write failed: ${e.runtimeType}');
          }
        });
  }

  Future<void> _close() async {
    final raf = _raf;
    _raf = null;
    await raf?.close();
  }

  static String _format(
    String level,
    String tag,
    String event,
    Map<String, Object?> attrs,
  ) {
    final buffer = StringBuffer()
      ..write(DateTime.now().toUtc().toIso8601String())
      ..write(' ')
      ..write(level)
      ..write(' ')
      ..write(_name(tag))
      ..write(' ')
      ..write(_name(event));
    for (final MapEntry(:key, :value) in attrs.entries) {
      final name = _name(key);
      buffer
        ..write(' ')
        ..write(name)
        ..write('=')
        ..write(_quote(redact(name, value)));
    }
    buffer.write('\n');
    return buffer.toString();
  }

  /// Tags, events and keys are code identifiers; anything else is replaced.
  static String _name(String raw) {
    final name = raw.replaceAll(_unsafeName, '_');
    return name.isEmpty ? '_' : name;
  }

  /// Keeps an entry on one line and quotes values with spaces or quotes.
  static String _quote(String value) {
    final flat = value.replaceAll(_lineBreaks, ' ');
    if (flat.isEmpty) return '""';
    if (!flat.contains(' ') && !flat.contains('"')) return flat;
    return '"${flat.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }

  static String _frames(StackTrace stack) => stack
      .toString()
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(5)
      .join(' | ');

  /// Appends [bytes], cutting the file back to its newest [keepBytes] first
  /// when the append would take it past [maxBytes].
  Future<void> _write(Uint8List bytes) async {
    if (_size + bytes.length <= maxBytes) {
      if (bytes.isEmpty) return;
      final raf = _raf ??= await _file.open(mode: FileMode.append);
      await raf.writeFrom(bytes);
      _size += bytes.length;
      return;
    }
    await _close();
    final existing = await _file.exists()
        ? await _file.readAsBytes()
        : Uint8List(0);
    final all = Uint8List(existing.length + bytes.length)
      ..setAll(0, existing)
      ..setAll(existing.length, bytes);
    final kept = _newest(all);
    // Write a sibling and rename over the log, so a crash can't leave it half-written.
    final temp = File('${_file.path}.tmp');
    await temp.writeAsBytes(kept, flush: true);
    await temp.rename(_file.path);
    _size = kept.length;
  }

  /// The newest [keepBytes] of [data], starting after a line break.
  static Uint8List _newest(Uint8List data) {
    if (data.length <= keepBytes) return data;
    var start = data.length - keepBytes;
    // Starting right after a newline is already a line boundary.
    if (data[start - 1] != 0x0A) {
      final nl = data.indexOf(0x0A, start);
      start = nl < 0 ? data.length : nl + 1;
    }
    return Uint8List.sublistView(data, start);
  }
}
