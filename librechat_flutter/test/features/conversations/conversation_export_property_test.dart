import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/conversations/conversation_export.dart';

import '../../support/property.dart';

void main() {
  // Feature: flutter-android-rewrite, Property 6: For any Conversation and
  // list of Messages, parseConversationExport(exportConversationJson(
  // conversation, messages)) returns an equal Conversation and an equal
  // message list.
  // Validates: Requirements 16.11
  test('Property 6: Conversation export round trip', () async {
    await forAll(zip2(conversationGen, listOf(messageGen, max: 20)), (c) {
      final (conversation, messages) = c;
      final parsed = parseConversationExport(
        exportConversationJson(conversation, messages),
      );
      expect(parsed.conversation, conversation);
      expect(parsed.messages, messages);
    });
  });
}
