/// The Message_Tree (Req 17.3–17.5, 17.7): links a conversation's messages
/// by `parentMessageId` and picks the displayed Active_Path. Pure.
///
/// Siblings are keyed by their parent's id. Every root shares the key
/// [rootParentId], so the walk always starts there.
library;

import '../../../core/models/message.dart';

/// The `parentMessageId` of a conversation's first message (Root_Parent_Id).
const rootParentId = '00000000-0000-0000-0000-000000000000';

/// The Active_Path: a chain that starts at a root, in which each later
/// message's parent is the message before it (Req 17.5).
///
/// At each level the walk takes `selection[key]` when that names a child of
/// the level, otherwise the newest child (Req 17.4). The key of the first
/// level is [rootParentId] and the key of each later level is the id of the
/// message chosen above it.
///
/// When [anchorId] names a message whose ancestors lead to a root, the walk
/// goes through those ancestors, overriding [selection], and ends at the
/// anchor. An unknown or unreachable anchor is ignored.
List<Message> activePath(
  List<Message> messages,
  Map<String, String> selection, {
  String? anchorId,
}) {
  final tree = _Tree(messages);
  final forced = anchorId == null ? null : tree.ancestry(anchorId);
  final path = <Message>[];
  final visited = <String>{};
  var key = rootParentId;
  while (true) {
    final children = tree.children[key];
    if (children == null || children.isEmpty) break;
    final wanted = forced?[key] ?? selection[key];
    final chosen = children.lastWhere(
      (m) => m.messageId == wanted,
      orElse: () => children.last,
    );
    // Malformed data, such as a message whose id is its own key, would loop.
    if (!visited.add(chosen.messageId)) break;
    path.add(chosen);
    if (forced != null && chosen.messageId == anchorId) break;
    key = chosen.messageId;
  }
  return path;
}

/// The Siblings of [m] in [messages], oldest to newest, [m] included when it
/// is in the set.
List<Message> siblingsOf(List<Message> messages, Message m) {
  final tree = _Tree(messages);
  final own = tree.byId[m.messageId] ?? m;
  return List.unmodifiable(tree.children[tree.keyOf(own)] ?? const []);
}

/// The Siblings at each level of [path], oldest to newest, from one pass
/// over [messages]: element `i` is [siblingsOf] `path[i]`. The Chat_Screen
/// reads its SiblingNavigators from here (Req 17.6).
List<List<Message>> pathSiblings(List<Message> messages, List<Message> path) {
  final tree = _Tree(messages);
  return List.unmodifiable([
    for (final m in path)
      List<Message>.unmodifiable(
        tree.children[tree.keyOf(tree.byId[m.messageId] ?? m)] ?? [m],
      ),
  ]);
}

/// The selection that shows [siblingId] at level [index] of [path] (Req 17.7).
///
/// It keeps the path's choices above [index] plus the new Sibling, so every
/// lower level falls back to its newest Sibling. [path] must be an
/// [activePath] result, whose level keys follow from the chain itself.
Map<String, String> selectSibling(
  List<Message> path,
  int index,
  String siblingId,
) {
  RangeError.checkValidIndex(index, path, 'index');
  String keyAt(int i) => i == 0 ? rootParentId : path[i - 1].messageId;
  return {
    for (var i = 0; i < index; i++) keyAt(i): path[i].messageId,
    keyAt(index): siblingId,
  };
}

/// The deduplicated messages and their Sibling groups.
class _Tree {
  _Tree(List<Message> messages) {
    // Dedupe by messageId: the last copy wins, at the first copy's position.
    final order = <String, int>{};
    for (final m in messages) {
      order.putIfAbsent(m.messageId, () => order.length);
      byId[m.messageId] = m;
    }
    for (final m in byId.values) {
      children.putIfAbsent(keyOf(m), () => []).add(m);
    }
    for (final group in children.values) {
      group.sort((a, b) {
        final byTime = _compareCreatedAt(a.createdAt, b.createdAt);
        return byTime != 0 ? byTime : order[a.messageId]! - order[b.messageId]!;
      });
    }
  }

  /// Insertion order is the first copy's position.
  final byId = <String, Message>{};

  /// Sibling groups by key, oldest to newest.
  final children = <String, List<Message>>{};

  /// [rootParentId] for a root (Req 17.3), otherwise the parent's id.
  String keyOf(Message m) {
    final parent = m.parentMessageId;
    if (parent == null || parent.isEmpty || !byId.containsKey(parent)) {
      return rootParentId;
    }
    return parent;
  }

  /// The forced choice at each level from a root down to [anchorId], or
  /// null when the anchor is unknown or its ancestors do not reach a root.
  Map<String, String>? ancestry(String anchorId) {
    final forced = <String, String>{};
    var current = byId[anchorId];
    while (current != null) {
      final key = keyOf(current);
      if (forced.containsKey(key)) return null;
      forced[key] = current.messageId;
      if (key == rootParentId) return forced;
      current = byId[key];
    }
    return null;
  }
}

/// Older first. A message without `createdAt` has not been dated by the
/// Server yet, so it sorts as newest.
int _compareCreatedAt(DateTime? a, DateTime? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
