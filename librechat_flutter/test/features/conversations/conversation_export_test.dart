import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/features/conversations/conversation_export.dart';

Message _message(
  String id, {
  bool user = false,
  String text = '',
  List<ContentPart>? content,
}) => Message(
  messageId: id,
  conversationId: 'c1',
  isCreatedByUser: user,
  text: text,
  content: content,
);

final _messages = [
  _message('m1', user: true, text: 'Hello'),
  _message(
    'm2',
    text: 'ignored when parts exist',
    content: const [
      ContentPart(type: ContentPartType.think, think: 'Pondering'),
      ContentPart(type: ContentPartType.text, text: 'Answer'),
      ContentPart(type: ContentPartType.toolCall),
    ],
  ),
  _message('m3', text: 'Plain text', content: const []),
];

void main() {
  final now = DateTime(2026, 3, 5, 9, 7);

  group('exportConversationMarkdown', () {
    test('writes the KMP format', () {
      expect(
        exportConversationMarkdown(const Conversation(), _messages, now),
        '# Untitled Conversation\n'
        'Exported on 2026-03-05 09:07\n'
        '\n'
        '## User\n'
        'Hello\n'
        '\n'
        '## Assistant\n'
        '[Thinking] Pondering\n'
        'Answer\n'
        '\n'
        '## Assistant\n'
        'Plain text',
      );
    });

    test('uses the title, and with no messages ends after the date', () {
      expect(
        exportConversationMarkdown(
          const Conversation(title: 'Trip plans'),
          const [],
          now,
        ),
        '# Trip plans\nExported on 2026-03-05 09:07',
      );
    });
  });

  group('exportConversationJson', () {
    test('is the conversation plus its messages', () {
      final text = exportConversationJson(
        const Conversation(conversationId: 'c1', title: 'T'),
        _messages,
      );
      final json = jsonDecode(text) as Map<String, Object?>;
      expect(json['conversationId'], 'c1');
      expect(json['title'], 'T');
      expect(json['messages'], hasLength(3));
      expect((json['messages']! as List).first, containsPair('text', 'Hello'));
      expect(text, contains('\n  "conversationId"'), reason: 'pretty printed');
    });
  });

  group('parseConversationExport', () {
    test('reads an export back', () {
      const conversation = Conversation(conversationId: 'c1', title: 'T');
      final parsed = parseConversationExport(
        exportConversationJson(conversation, _messages),
      );
      expect(parsed.conversation, conversation);
      expect(parsed.messages, _messages);
    });

    test('an export without messages has none', () {
      final parsed = parseConversationExport('{"title": "T"}');
      expect(parsed.conversation.title, 'T');
      expect(parsed.messages, isEmpty);
    });

    test('rejects text that is not a JSON object', () {
      expect(() => parseConversationExport('not json'), throwsFormatException);
      expect(() => parseConversationExport('[1, 2]'), throwsFormatException);
      expect(
        () => parseConversationExport('{"messages": [{"text": "no id"}]}'),
        throwsFormatException,
      );
    });
  });

  group('exportFileName', () {
    test('replaces characters outside [a-zA-Z0-9._-]', () {
      expect(
        exportFileName('Trip: Lisbon/Porto v1.2', markdown: false),
        'Trip__Lisbon_Porto_v1.2.json',
      );
      expect(exportFileName('Café-plan_ok', markdown: true), 'Caf_-plan_ok.md');
    });

    test('falls back to conversation', () {
      expect(exportFileName(null, markdown: true), 'conversation.md');
      expect(exportFileName('   ', markdown: false), 'conversation.json');
    });
  });
}
