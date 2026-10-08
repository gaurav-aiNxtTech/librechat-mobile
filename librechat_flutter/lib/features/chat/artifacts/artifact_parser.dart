/// The Artifact_Parser (Req 24.1–24.3, design "Artifacts and Mermaid"): a
/// pure line scanner that splits a reply into text and `:::artifact{…}`
/// blocks, plus [formatArtifact] for the reverse and [artifactVersions] for
/// the viewer's version pager.
///
/// A block opens with a line `:::artifact{…}`. When its next non-blank line
/// is a fence of 3+ backticks or tildes, the content runs to a closing fence
/// of the same character that is at least as long; otherwise the content is
/// unfenced and runs to the closing line. A `:::` line closes the block, and
/// `:::` lines inside a fence are content. A block without its closing `:::`
/// is an incomplete [Artifact] (`complete: false`), which the chat renders as
/// a CodeBlock.
library;

import 'dart:math';

import '../../../core/models/content_part.dart';
import '../../../core/models/message.dart';

/// One piece of a parsed reply: a [TextSegment] or an [Artifact].
sealed class Segment {
  const Segment();
}

/// Reply text between artifacts, LF-normalized and never whitespace-only.
final class TextSegment extends Segment {
  const TextSegment(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is TextSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextSegment(${_quoted(text)})';
}

/// A `:::artifact{identifier type title}` block. [content] is exact, with
/// LF line breaks; [complete] is false when the closing `:::` is missing.
final class Artifact extends Segment {
  const Artifact({
    required this.identifier,
    required this.type,
    required this.title,
    required this.content,
    this.complete = true,
  });

  final String identifier;
  final String type;
  final String title;
  final String content;
  final bool complete;

  /// The renderer family of [type].
  ArtifactKind get kind => artifactKind(type);

  @override
  bool operator ==(Object other) =>
      other is Artifact &&
      other.identifier == identifier &&
      other.type == type &&
      other.title == title &&
      other.content == content &&
      other.complete == complete;

  @override
  int get hashCode => Object.hash(identifier, type, title, content, complete);

  @override
  String toString() =>
      'Artifact(identifier: ${_quoted(identifier)}, type: ${_quoted(type)}, '
      'title: ${_quoted(title)}, content: ${_quoted(content)}, '
      'complete: $complete)';
}

/// The renderer and icon families of an artifact type.
enum ArtifactKind { mermaid, react, svg, markdown, html, plain, code }

/// Classifies an artifact MIME [type], ported from KMP `ArtifactType.from`.
/// The order matters: `application/vnd.code-html` is html, not code.
ArtifactKind artifactKind(String type) {
  if (type.contains('mermaid')) return ArtifactKind.mermaid;
  if (type.contains('react')) return ArtifactKind.react;
  if (type.contains('svg')) return ArtifactKind.svg;
  if (type.contains('markdown') || type == 'text/md') {
    return ArtifactKind.markdown;
  }
  if (type.contains('html')) return ArtifactKind.html;
  if (type == 'text/plain') return ArtifactKind.plain;
  return ArtifactKind.code;
}

/// Splits [text] into text and artifact segments, in order. Whitespace-only
/// text is dropped, so `''` gives `[]`.
List<Segment> parseArtifacts(String text) {
  final source = text.replaceAll('\r\n', '\n');
  if (source.isEmpty) return const [];
  final lines = source.split('\n');
  // starts[i] is the offset of line i; starts[lines.length] is past the end.
  final starts = <int>[0];
  for (final line in lines) {
    starts.add(starts.last + line.length + 1);
  }
  String slice(int fromLine, int toLine) => source.substring(
    min(starts[fromLine], source.length),
    min(starts[toLine], source.length),
  );

  final segments = <Segment>[];
  void addText(String value) {
    if (value.trim().isNotEmpty) segments.add(TextSegment(value));
  }

  var textStart = 0;
  _Fence? proseFence;
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (proseFence != null) {
      if (_isClosingFence(line, proseFence)) proseFence = null;
      i++;
      continue;
    }
    final fence = _fenceOf(line);
    if (fence != null) {
      proseFence = fence;
      i++;
      continue;
    }
    final attributes = _openerAttributes(line);
    if (attributes == null) {
      i++;
      continue;
    }
    addText(slice(textStart, i));
    final (artifact, next) = _scanBlock(lines, i + 1, attributes);
    segments.add(artifact);
    textStart = next;
    i = next;
  }
  addText(slice(textStart, lines.length));
  return segments;
}

/// Writes [artifact] as a `:::artifact{…}` block that [parseArtifacts] reads
/// back as the same identifier, type, title and content (Req 24.2).
///
/// The content goes in a backtick fence one longer than its longest backtick
/// run (at least 3). A value that contains `"` is written in `'` quotes. A
/// value that holds both quote kinds or a line break, or content with a `\r`,
/// cannot round-trip. [Artifact.complete] is not written.
String formatArtifact(Artifact artifact) {
  final fence = '`' * max(3, _longestRun(artifact.content, '`') + 1);
  return ':::artifact{identifier=${_attr(artifact.identifier)} '
      'type=${_attr(artifact.type)} title=${_attr(artifact.title)}}\n'
      '$fence\n${artifact.content}\n$fence\n:::';
}

/// The complete artifacts of the Active_Path [path], grouped by identifier
/// in path order, each list oldest first. User messages, incomplete
/// artifacts and artifacts without an identifier are skipped.
Map<String, List<Artifact>> artifactVersions(List<Message> path) {
  final versions = <String, List<Artifact>>{};
  for (final message in path) {
    if (message.isCreatedByUser) continue;
    final parts = message.content;
    final texts = parts == null || parts.isEmpty
        ? [message.text]
        : [
            for (final part in parts)
              if ((part.type == ContentPartType.text ||
                      part.type == ContentPartType.textDelta) &&
                  part.text != null)
                part.text!,
          ];
    for (final text in texts) {
      for (final segment in parseArtifacts(text)) {
        if (segment is Artifact &&
            segment.complete &&
            segment.identifier.isNotEmpty) {
          (versions[segment.identifier] ??= []).add(segment);
        }
      }
    }
  }
  return versions;
}

/// Reads the block after its opener line, starting at [from]. Returns the
/// artifact and the index of the first line after it.
(Artifact, int) _scanBlock(
  List<String> lines,
  int from,
  Map<String, String> attributes,
) {
  Artifact artifact(String content, {required bool complete}) => Artifact(
    identifier: attributes['identifier'] ?? attributes['id'] ?? '',
    type: attributes['type'] ?? 'text/plain',
    title: attributes['title'] ?? 'Artifact',
    content: content,
    complete: complete,
  );

  var first = from;
  while (first < lines.length && lines[first].trim().isEmpty) {
    first++;
  }
  final fence = first < lines.length ? _fenceOf(lines[first]) : null;

  if (fence == null) {
    // Unfenced: leading blank lines belong to the content.
    var end = from;
    while (end < lines.length && !_isCloser(lines[end])) {
      end++;
    }
    final content = lines.sublist(from, end).join('\n');
    if (end == lines.length) {
      return (artifact(content, complete: false), end);
    }
    return (artifact(content, complete: true), end + 1);
  }

  final contentStart = first + 1;
  var end = contentStart;
  while (end < lines.length && !_isClosingFence(lines[end], fence)) {
    end++;
  }
  final content = lines.sublist(contentStart, end).join('\n');
  if (end == lines.length) {
    return (artifact(content, complete: false), end);
  }
  var closer = end + 1;
  while (closer < lines.length && lines[closer].trim().isEmpty) {
    closer++;
  }
  if (closer < lines.length && _isCloser(lines[closer])) {
    return (artifact(content, complete: true), closer + 1);
  }
  // The fence closed but `:::` never came: keep the prose after it as text.
  return (artifact(content, complete: false), end + 1);
}

const _openerPrefix = ':::artifact{';

/// The attributes of an opener line, or null when [line] is not one.
Map<String, String>? _openerAttributes(String line) {
  final trimmed = line.trim();
  if (!trimmed.startsWith(_openerPrefix) || !trimmed.endsWith('}')) {
    return null;
  }
  return _parseAttributes(
    trimmed.substring(_openerPrefix.length, trimmed.length - 1),
  );
}

final _nameStart = RegExp(r'[A-Za-z_:]');
final _nameChar = RegExp(r'[A-Za-z0-9_.:\-]');
final _space = RegExp(r'\s');

/// Parses `k="v"`, `k='v'`, `k=v` and bare `k`. The last duplicate wins.
/// Returns null for a malformed string, so the line stays text.
Map<String, String>? _parseAttributes(String source) {
  final attributes = <String, String>{};
  var pos = 0;
  bool isSpace(int at) => _space.hasMatch(source[at]);
  void skipSpace() {
    while (pos < source.length && isSpace(pos)) {
      pos++;
    }
  }

  while (true) {
    skipSpace();
    if (pos >= source.length) return attributes;
    if (!_nameStart.hasMatch(source[pos])) return null;
    final nameStart = pos;
    pos++;
    while (pos < source.length && _nameChar.hasMatch(source[pos])) {
      pos++;
    }
    final name = source.substring(nameStart, pos);
    final afterName = pos;
    skipSpace();
    if (pos >= source.length || source[pos] != '=') {
      // A bare attribute: rewind so the next name starts after the spaces.
      pos = afterName;
      attributes[name] = '';
      continue;
    }
    pos++;
    skipSpace();
    if (pos >= source.length) {
      attributes[name] = '';
      return attributes;
    }
    final quote = source[pos];
    if (quote == '"' || quote == "'") {
      final close = source.indexOf(quote, pos + 1);
      if (close < 0) return null;
      attributes[name] = source.substring(pos + 1, close);
      pos = close + 1;
    } else {
      final valueStart = pos;
      while (pos < source.length && !isSpace(pos)) {
        pos++;
      }
      attributes[name] = source.substring(valueStart, pos);
    }
  }
}

/// A code fence: its character and run length.
typedef _Fence = ({String char, int length});

/// The fence [line] opens, or null. An info string after the run is allowed.
_Fence? _fenceOf(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.isEmpty) return null;
  final char = trimmed[0];
  if (char != '`' && char != '~') return null;
  final length = _leadingRun(trimmed, char);
  return length >= 3 ? (char: char, length: length) : null;
}

/// Whether [line] is only a run of [fence]'s character at least as long.
bool _isClosingFence(String line, _Fence fence) {
  final trimmed = line.trim();
  return trimmed.length >= fence.length &&
      _leadingRun(trimmed, fence.char) == trimmed.length;
}

final _closer = RegExp(r'^:{3,}$');

/// Whether [line] closes a block: 3+ colons and nothing else.
bool _isCloser(String line) => _closer.hasMatch(line.trim());

int _leadingRun(String text, String char) {
  var n = 0;
  while (n < text.length && text[n] == char) {
    n++;
  }
  return n;
}

/// The longest run of [char] anywhere in [text].
int _longestRun(String text, String char) {
  var longest = 0;
  var run = 0;
  for (var i = 0; i < text.length; i++) {
    run = text[i] == char ? run + 1 : 0;
    if (run > longest) longest = run;
  }
  return longest;
}

String _attr(String value) => value.contains('"') ? "'$value'" : '"$value"';

String _quoted(String value) =>
    '"${value.replaceAll('\\', r'\\').replaceAll('\n', r'\n').replaceAll('"', r'\"')}"';
