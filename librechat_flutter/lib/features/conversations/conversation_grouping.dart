import 'package:intl/intl.dart';

import '../../core/models/conversation.dart';

/// One date group of the Conversation_List.
typedef ConversationGroup = ({String label, List<Conversation> conversations});

/// Sorts [conversations] newest first and groups them by local calendar-day
/// distance from [now] (Req 15.2, 15.3): "Today" (including future times),
/// "Yesterday", "Previous 7 Days", "Previous 30 Days", then one group per
/// month ("January 2025"). The labels follow the KMP `toRelativeDateGroup`.
///
/// A conversation without `updatedAt` counts as updated at [now]. Equal
/// times keep their input order, and adjacent groups with the same label
/// merge.
List<ConversationGroup> groupConversations(
  List<Conversation> conversations,
  DateTime now,
) {
  DateTime effective(Conversation c) => c.updatedAt ?? now;

  // List.sort is not stable, so ties fall back to the input index.
  final indexed = [
    for (var i = 0; i < conversations.length; i++) (i, conversations[i]),
  ];
  indexed.sort((a, b) {
    final byTime = effective(b.$2).compareTo(effective(a.$2));
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });

  final today = _day(now.toLocal());
  final groups = <ConversationGroup>[];
  for (final (_, conversation) in indexed) {
    final local = effective(conversation).toLocal();
    final label = _label(today.difference(_day(local)).inDays, local);
    if (groups.isNotEmpty && groups.last.label == label) {
      groups.last.conversations.add(conversation);
    } else {
      groups.add((label: label, conversations: [conversation]));
    }
  }
  return groups;
}

/// The local calendar date as a UTC midnight, so day differences ignore
/// daylight-saving shifts.
DateTime _day(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

String _label(int days, DateTime local) {
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days <= 7) return 'Previous 7 Days';
  if (days <= 30) return 'Previous 30 Days';
  return DateFormat('MMMM y').format(local);
}
