import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/conversations/conversation_grouping.dart';

import '../../support/property.dart';

void main() {
  // Feature: flutter-android-rewrite, Property 5: For any list of
  // conversations and current time, groupConversations places every
  // conversation in exactly one group, gives each group a distinct label, and
  // leaves no conversation in a group older than any conversation in a later
  // group.
  // Validates: Requirements 15.3
  test('Property 5: Date groups partition the list, newest first', () async {
    await forAll(groupingCaseGen, (c) {
      final groups = groupConversations(c.conversations, c.now);
      DateTime effective(DateTime? t) => t ?? c.now;

      final flattened = [
        for (final g in groups)
          for (final convo in g.conversations) convo.conversationId,
      ];
      expect(
        flattened..sort(),
        [for (final convo in c.conversations) convo.conversationId]..sort(),
        reason: 'every conversation is in exactly one group',
      );

      final labels = [for (final g in groups) g.label];
      expect(labels.toSet(), hasLength(labels.length), reason: '$labels');

      for (final g in groups) {
        expect(g.conversations, isNotEmpty, reason: g.label);
      }
      for (var i = 0; i < groups.length; i++) {
        final oldest = groups[i].conversations
            .map((x) => effective(x.updatedAt))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        for (final later in groups.skip(i + 1)) {
          for (final x in later.conversations) {
            expect(
              effective(x.updatedAt).isAfter(oldest),
              isFalse,
              reason: '${later.label} is newer than ${groups[i].label}',
            );
          }
        }
      }
    });
  });
}
