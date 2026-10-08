import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../../core/models/conversation.dart';
import '../../core/models/message.dart';

/// A full JSON export (Req 16.10, 16.11): the conversation's fields plus a
/// `messages` list, pretty printed. [parseConversationExport] reads it back.
String exportConversationJson(
  Conversation conversation,
  List<Message> messages,
) => const JsonEncoder.withIndent('  ').convert({
  ...conversation.toJson(),
  'messages': [for (final m in messages) m.toJson()],
});

/// Reads an [exportConversationJson] file. Throws [FormatException] when
/// [text] is not a JSON object or its fields don't decode. An absent
/// `messages` key reads as no messages.
({Conversation conversation, List<Message> messages}) parseConversationExport(
  String text,
) {
  final json = jsonDecode(text);
  if (json is! Map) {
    throw const FormatException('A conversation export is a JSON object');
  }
  final map = json.cast<String, Object?>();
  try {
    final messages = map['messages'] as List?;
    return (
      conversation: Conversation.fromJson(map),
      messages: [
        for (final item in messages ?? const [])
          Message.fromJson((item as Map).cast<String, Object?>()),
      ],
    );
  } on TypeError catch (e) {
    throw FormatException('Not a conversation export: $e');
  } on CheckedFromJsonException catch (e) {
    throw FormatException('Not a conversation export: ${e.message}');
  }
}

/// The KMP `ConversationExporter.exportAsMarkdown` text: a title, the
/// export time in local time, then one `## User` or `## Assistant` block per
/// message in Server order.
String exportConversationMarkdown(
  Conversation conversation,
  List<Message> messages,
  DateTime now,
) {
  final out = StringBuffer()
    ..writeln('# ${conversation.title ?? 'Untitled Conversation'}')
    ..writeln(
      'Exported on ${DateFormat('yyyy-MM-dd HH:mm').format(now.toLocal())}',
    )
    ..writeln();
  for (final message in messages) {
    out
      ..writeln('## ${message.isCreatedByUser ? 'User' : 'Assistant'}')
      ..writeln(_messageText(message))
      ..writeln();
  }
  return out.toString().trimRight();
}

/// The content parts' text, thinking prefixed with `[Thinking] `, one per
/// line; `text` when there are no parts.
String _messageText(Message message) {
  final parts = message.content;
  if (parts == null || parts.isEmpty) return message.text;
  return [
    for (final part in parts)
      ?(part.text ?? (part.think != null ? '[Thinking] ${part.think}' : null)),
  ].join('\n');
}

final _unsafeFileNameChars = RegExp('[^a-zA-Z0-9._-]');

/// The export file name: the title with every character outside
/// `[a-zA-Z0-9._-]` replaced by `_` (KMP `ConversationActionEffects`), or
/// `conversation` for a missing or blank title, then `.md` or `.json`.
String exportFileName(String? title, {required bool markdown}) {
  final base = (title == null || title.trim().isEmpty)
      ? 'conversation'
      : title.replaceAll(_unsafeFileNameChars, '_');
  return '$base.${markdown ? 'md' : 'json'}';
}
