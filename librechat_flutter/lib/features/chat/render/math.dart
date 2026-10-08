/// Rewrites Markdown math delimiters into the forms the Markdown renderer
/// reads (Req 22.3, 22.4): `$$…$$` becomes `\[…\]`, and a one-line `$…$`
/// becomes `\(…\)` when its content reads as LaTeX.
///
/// Code spans, fenced code blocks and escapes (`\$`, `\(`, …) are copied
/// verbatim. Inline `$…$` converts only when the content is non-empty, has
/// no leading or trailing whitespace, the closing `$` is not followed by a
/// digit, and the content contains one of `\ ^ _ { } =` or is a single
/// letter, so amounts such as `$5 and $10` stay as text. Text without a `$`
/// is returned unchanged.
String prepareMath(String text) {
  if (!text.contains(r'$')) return text;
  final out = StringBuffer();
  final length = text.length;
  var i = 0;
  while (i < length) {
    if (i == 0 || text.codeUnitAt(i - 1) == _newline) {
      final fenceEnd = _fenceEnd(text, i);
      if (fenceEnd != null) {
        out.write(text.substring(i, fenceEnd));
        i = fenceEnd;
        continue;
      }
    }
    final char = text.codeUnitAt(i);
    if (char == _backtick) {
      final run = _runLength(text, i, _backtick);
      final close = _closingBacktickRun(text, i + run, run);
      final end = close == null ? i + run : close + run;
      out.write(text.substring(i, end));
      i = end;
    } else if (char == _backslash) {
      final end = i + 2 > length ? length : i + 2;
      out.write(text.substring(i, end));
      i = end;
    } else if (char == _dollar && text.startsWith(r'$$', i)) {
      final close = _blockClose(text, i + 2);
      final content = close == null ? '' : text.substring(i + 2, close);
      if (close != null && content.trim().isNotEmpty) {
        out.write('\\[$content\\]');
        i = close + 2;
      } else {
        out.write(r'$$');
        i += 2;
      }
    } else if (char == _dollar) {
      final close = _inlineClose(text, i + 1);
      final content = close == null ? '' : text.substring(i + 1, close);
      if (close != null && _isInlineMath(text, content, close)) {
        out.write('\\($content\\)');
        i = close + 1;
      } else {
        out.write(r'$');
        i++;
      }
    } else {
      out.writeCharCode(char);
      i++;
    }
  }
  return out.toString();
}

const _newline = 0x0a;
const _space = 0x20;
const _backtick = 0x60;
const _tilde = 0x7e;
const _backslash = 0x5c;
const _dollar = 0x24;

final _latexMarks = RegExp(r'[\\^_{}=]');
final _singleLetter = RegExp(r'^[A-Za-z]$');
final _digit = RegExp(r'[0-9]');

bool _isInlineMath(String text, String content, int close) {
  if (content.isEmpty || content.trim() != content) return false;
  final next = close + 1;
  if (next < text.length && _digit.hasMatch(text[next])) return false;
  return _latexMarks.hasMatch(content) || _singleLetter.hasMatch(content);
}

int _runLength(String text, int start, int char) {
  var end = start;
  while (end < text.length && text.codeUnitAt(end) == char) {
    end++;
  }
  return end - start;
}

int _lineEnd(String text, int start) {
  final end = text.indexOf('\n', start);
  return end < 0 ? text.length : end;
}

/// The end of a fenced code block opening at [lineStart] (the end of its
/// closing line, or of the text when unclosed), or null when no fence opens
/// there. A fence is 0–3 spaces and then 3+ backticks or tildes.
int? _fenceEnd(String text, int lineStart) {
  final open = _fenceRun(text, lineStart);
  if (open == null) return null;
  var line = _lineEnd(text, lineStart);
  while (line < text.length) {
    final start = line + 1;
    final end = _lineEnd(text, start);
    final close = _fenceRun(text, start);
    if (close != null &&
        close.char == open.char &&
        close.length >= open.length &&
        text.substring(close.end, end).trim().isEmpty) {
      return end;
    }
    line = end;
  }
  return text.length;
}

({int char, int length, int end})? _fenceRun(String text, int lineStart) {
  var i = lineStart;
  while (i < text.length && i - lineStart < 3 && text.codeUnitAt(i) == _space) {
    i++;
  }
  if (i >= text.length) return null;
  final char = text.codeUnitAt(i);
  if (char != _backtick && char != _tilde) return null;
  final length = _runLength(text, i, char);
  if (length < 3) return null;
  return (char: char, length: length, end: i + length);
}

/// The start of the next backtick run of exactly [length] from [from].
int? _closingBacktickRun(String text, int from, int length) {
  var i = from;
  while (i < text.length) {
    if (text.codeUnitAt(i) == _backtick) {
      final run = _runLength(text, i, _backtick);
      if (run == length) return i;
      i += run;
    } else {
      i++;
    }
  }
  return null;
}

/// The next unescaped `$$` from [from], across lines.
int? _blockClose(String text, int from) {
  var i = from;
  while (i < text.length) {
    if (text.codeUnitAt(i) == _backslash) {
      i += 2;
    } else if (text.startsWith(r'$$', i)) {
      return i;
    } else {
      i++;
    }
  }
  return null;
}

/// The next unescaped `$` from [from] on the same line.
int? _inlineClose(String text, int from) {
  var i = from;
  while (i < text.length) {
    final char = text.codeUnitAt(i);
    if (char == _newline) return null;
    if (char == _backslash) {
      if (i + 1 < text.length && text.codeUnitAt(i + 1) == _newline) {
        return null;
      }
      i += 2;
    } else if (char == _dollar) {
      return i;
    } else {
      i++;
    }
  }
  return null;
}
