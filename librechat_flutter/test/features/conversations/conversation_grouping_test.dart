import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/features/conversations/conversation_grouping.dart';

/// A conversation updated at the local time [local], as the wire gives it.
Conversation _at(String id, DateTime? local) =>
    Conversation(conversationId: id, updatedAt: local?.toUtc());

/// Each group as `[label, [ids]]`, which `expect` compares deeply.
List<List<Object?>> _shape(List<ConversationGroup> groups) => [
  for (final g in groups)
    [
      g.label,
      [for (final c in g.conversations) c.conversationId],
    ],
];

void main() {
  final now = DateTime(2026, 3, 15, 12);

  String labelFor(DateTime local) =>
      groupConversations([_at('x', local)], now).single.label;

  test('labels by calendar-day distance', () {
    expect(labelFor(DateTime(2026, 3, 15, 0, 0, 1)), 'Today');
    expect(labelFor(DateTime(2026, 3, 14, 23, 59)), 'Yesterday');
    expect(labelFor(DateTime(2026, 3, 13, 23)), 'Previous 7 Days');
    expect(labelFor(DateTime(2026, 3, 8)), 'Previous 7 Days');
    expect(labelFor(DateTime(2026, 3, 7, 23, 59)), 'Previous 30 Days');
    expect(labelFor(DateTime(2026, 2, 13)), 'Previous 30 Days');
    expect(labelFor(DateTime(2026, 2, 12, 23, 59)), 'February 2026');
    expect(labelFor(DateTime(2025, 1, 31)), 'January 2025');
  });

  test('a future time is Today', () {
    expect(labelFor(DateTime(2026, 3, 16, 9)), 'Today');
  });

  test('a missing updatedAt is Today', () {
    expect(groupConversations([_at('x', null)], now).single.label, 'Today');
  });

  test('just after midnight, a minute before it is Yesterday', () {
    final groups = groupConversations([
      _at('late', DateTime(2026, 3, 14, 23, 59, 59)),
    ], DateTime(2026, 3, 15, 0, 0, 1));
    expect(groups.single.label, 'Yesterday');
  });

  test('sorts newest first and merges adjacent labels', () {
    final groups = groupConversations([
      _at('old', DateTime(2025, 1, 2)),
      _at('today1', DateTime(2026, 3, 15, 8)),
      _at('week', DateTime(2026, 3, 10)),
      _at('today2', DateTime(2026, 3, 15, 11)),
      _at('jan', DateTime(2025, 1, 20)),
    ], now);

    expect(_shape(groups), [
      [
        'Today',
        ['today2', 'today1'],
      ],
      [
        'Previous 7 Days',
        ['week'],
      ],
      [
        'January 2025',
        ['jan', 'old'],
      ],
    ]);
  });

  test('equal times keep their input order', () {
    final t = DateTime(2026, 3, 12, 10);
    final groups = groupConversations([
      _at('a', t),
      _at('b', t),
      _at('missing', null),
      _at('c', t),
    ], now);

    expect(_shape(groups), [
      [
        'Today',
        ['missing'],
      ],
      [
        'Previous 7 Days',
        ['a', 'b', 'c'],
      ],
    ]);
  });

  test('an empty list has no groups', () {
    expect(groupConversations(const [], now), isEmpty);
  });
}
