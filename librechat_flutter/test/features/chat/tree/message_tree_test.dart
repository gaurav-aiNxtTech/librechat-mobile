// Message_Tree examples (Task 11.1).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';

Message msg(String id, String? parent, [int? minute]) => Message(
  messageId: id,
  conversationId: 'c',
  parentMessageId: parent,
  createdAt: minute == null ? null : DateTime.utc(2025, 1, 1, 0, minute),
);

List<String> ids(List<Message> path) => [for (final m in path) m.messageId];

void main() {
  // u1 ─ a1 ─ u2 ─ a2
  //   └─ a1b ─ u3
  final branched = [
    msg('u1', rootParentId, 0),
    msg('a1', 'u1', 1),
    msg('u2', 'a1', 2),
    msg('a2', 'u2', 3),
    msg('a1b', 'u1', 4),
    msg('u3', 'a1b', 5),
  ];

  group('activePath', () {
    test('empty input gives an empty path', () {
      expect(activePath(const [], const {}), isEmpty);
    });

    test('takes the newest Sibling at each level', () {
      expect(ids(activePath(branched, const {})), ['u1', 'a1b', 'u3']);
    });

    test('follows a selection that names a child', () {
      expect(ids(activePath(branched, const {'u1': 'a1'})), [
        'u1',
        'a1',
        'u2',
        'a2',
      ]);
    });

    test('ignores a stale selection', () {
      expect(ids(activePath(branched, const {'u1': 'gone'})), [
        'u1',
        'a1b',
        'u3',
      ]);
    });

    test('empty, root and missing parents are all roots', () {
      final messages = [
        msg('r1', rootParentId, 0),
        msg('r2', '', 1),
        msg('r3', 'missing', 2),
        msg('r4', null, 3),
      ];
      expect(ids(activePath(messages, const {})), ['r4']);
      expect(ids(activePath(messages, const {rootParentId: 'r3'})), ['r3']);
      expect(ids(siblingsOf(messages, messages.first)), [
        'r1',
        'r2',
        'r3',
        'r4',
      ]);
    });

    test('createdAt ties keep list order and undated is newest', () {
      final tied = [
        msg('r', rootParentId, 0),
        msg('x', 'r', 1),
        msg('y', 'r', 1),
      ];
      expect(ids(activePath(tied, const {})), ['r', 'y']);
      final undated = [
        msg('r', rootParentId, 0),
        msg('x', 'r'),
        msg('y', 'r', 9),
      ];
      expect(ids(activePath(undated, const {})), ['r', 'x']);
    });

    test('a later duplicate replaces the earlier copy', () {
      final messages = [
        msg('r', rootParentId, 0),
        msg('a', 'r', 1),
        msg('b', 'r', 2),
        msg('b', 'a', 2),
      ];
      expect(ids(activePath(messages, const {})), ['r', 'a', 'b']);
    });

    test('stops on a self-keyed message', () {
      final messages = [msg(rootParentId, rootParentId, 0)];
      expect(ids(activePath(messages, const {})), [rootParentId]);
    });

    test('the anchor overrides the selection and ends the path', () {
      expect(ids(activePath(branched, const {'u1': 'a1b'}, anchorId: 'u2')), [
        'u1',
        'a1',
        'u2',
      ]);
    });

    test('an unknown or cyclic anchor is ignored', () {
      expect(ids(activePath(branched, const {}, anchorId: 'gone')), [
        'u1',
        'a1b',
        'u3',
      ]);
      final cyclic = [...branched, msg('x', 'y', 6), msg('y', 'x', 7)];
      expect(ids(activePath(cyclic, const {}, anchorId: 'x')), [
        'u1',
        'a1b',
        'u3',
      ]);
    });
  });

  group('siblingsOf', () {
    test('lists the level oldest to newest', () {
      expect(ids(siblingsOf(branched, msg('a1', 'u1'))), ['a1', 'a1b']);
      expect(ids(siblingsOf(branched, msg('u2', 'a1'))), ['u2']);
    });
  });

  group('selectSibling', () {
    test('keeps the choices above and drops the ones below', () {
      final path = activePath(branched, const {'u1': 'a1'});
      expect(selectSibling(path, 1, 'a1b'), {rootParentId: 'u1', 'u1': 'a1b'});
      expect(selectSibling(path, 0, 'u1'), {rootParentId: 'u1'});
    });

    test('lower levels fall back to the newest Sibling', () {
      final messages = [...branched, msg('a2b', 'u2', 8)];
      final path = activePath(messages, const {'u1': 'a1', 'u2': 'a2'});
      expect(ids(path), ['u1', 'a1', 'u2', 'a2']);
      final selection = selectSibling(path, 1, 'a1');
      expect(ids(activePath(messages, selection)), ['u1', 'a1', 'u2', 'a2b']);
    });

    test('rejects an index outside the path', () {
      expect(() => selectSibling(const [], 0, 'x'), throwsRangeError);
    });
  });

  group('pathSiblings', () {
    test('matches siblingsOf at every level of the path', () {
      final path = activePath(branched, const {'u1': 'a1'});
      final levels = pathSiblings(branched, path);
      expect(levels.map(ids).toList(), [
        ['u1'],
        ['a1', 'a1b'],
        ['u2'],
        ['a2'],
      ]);
      for (var i = 0; i < path.length; i++) {
        expect(ids(levels[i]), ids(siblingsOf(branched, path[i])));
      }
    });
  });
}
