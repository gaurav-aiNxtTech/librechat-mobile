// groupParts label cases (Task 17.5), ported from the KMP
// `feature/chat/.../util/ContentSegmentsTest.kt`.
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/features/chat/render/activity_groups.dart';

ContentPart text(String value) =>
    ContentPart(type: ContentPartType.text, text: value);

ContentPart think(String value) =>
    ContentPart(type: ContentPartType.think, think: value);

ContentPart tool(
  String? id, {
  String name = 'search',
  String? output = 'done',
}) => ContentPart(
  type: ContentPartType.toolCall,
  toolCall: ToolCall(id: id, name: name, output: output),
);

ContentPart label(
  String? value, {
  bool? pending,
  String? status,
  List<String>? toolCallIds,
}) => ContentPart(
  type: ContentPartType.activityLabel,
  activityLabel: value,
  pending: pending,
  status: status,
  toolCallIds: toolCallIds,
);

ContentPart phase(String? value, {int? endIndex, bool? pending}) => ContentPart(
  type: ContentPartType.activityLabel,
  activityLabel: value,
  activityLabelType: 'phase',
  activityEndIndex: endIndex,
  pending: pending,
);

ContentPart steer() =>
    const ContentPart(type: ContentPartType.steer, steer: {'text': 'stop'});

List<int> indices(PartGroup group) => [for (final e in group.entries) e.index];

/// The groups in short form: `p<i>` for a SinglePart, `g[<i>,…]` for a group.
List<String> shape(List<PartGroup> groups) => [
  for (final g in groups)
    switch (g) {
      SinglePart(:final entry) => 'p${entry.index}',
      ActivityGroup() => 'g${indices(g)}',
    },
];

ActivityGroup onlyGroup(List<ContentPart> parts) {
  final groups = groupParts(parts);
  expect(groups, hasLength(1));
  return groups.single as ActivityGroup;
}

void main() {
  test('empty input gives no groups', () {
    expect(groupParts(const []), isEmpty);
  });

  test('a label claims its batch including the leading reasoning', () {
    final group = onlyGroup([
      think('planning'),
      tool('t1'),
      label(' Searched the codebase '),
    ]);
    expect(group.label, 'Searched the codebase');
    expect(indices(group), [0, 1]);
    expect(group.toolCount, 1, reason: 'absorbed reasoning is not a tool');
  });

  test('without a label, reasoning stays standalone and two tools group', () {
    final groups = groupParts([think('planning'), tool('t1'), tool('t2')]);
    expect(shape(groups), ['p0', 'g[1, 2]']);
    expect((groups[1] as ActivityGroup).label, '');
  });

  test('a single unlabeled tool call stays single', () {
    expect(shape(groupParts([tool('t1')])), ['p0']);
  });

  test('a blank label is invisible and forms no group', () {
    final groups = groupParts([tool('t1'), label(null, pending: true)]);
    expect(shape(groups), ['p0']);
    final whitespace = groupParts([tool('t1'), label('   ')]);
    expect(shape(whitespace), ['p0']);
  });

  test('a blank label still merges its batch with the next one', () {
    final group = onlyGroup([tool('t1'), label(''), tool('t2')]);
    expect(indices(group), [0, 2]);
    expect(group.label, '');
  });

  test('a filled label cannot reach back past a blank one', () {
    final groups = groupParts([
      tool('t1'),
      label(''),
      tool('t2'),
      label('Ran the second batch'),
    ]);
    expect(shape(groups), ['p0', 'g[2]']);
    expect((groups[1] as ActivityGroup).label, 'Ran the second batch');
  });

  test('an orphan label renders as a SinglePart', () {
    final groups = groupParts([text('hi'), label('Looked something up')]);
    expect(shape(groups), ['p0', 'p1']);
  });

  test('an orphan label over a handoff call is dropped', () {
    final groups = groupParts([
      tool('h1', name: 'lc_transfer_to_billing', output: null),
      label('Handing off', toolCallIds: ['h1']),
    ]);
    expect(shape(groups), ['p0']);
  });

  test('handoff calls never fold into a group', () {
    final groups = groupParts([
      tool('h1', name: 'lc_transfer_to_billing', output: null),
      tool('h2', name: 'lc_transfer_to_sales', output: null),
    ]);
    expect(shape(groups), ['p0', 'p1']);
  });

  test('a text part breaks the block', () {
    final groups = groupParts([
      tool('t1'),
      tool('t2'),
      text('interjection'),
      tool('t3'),
      tool('t4'),
    ]);
    expect(shape(groups), ['g[0, 1]', 'p2', 'g[3, 4]']);
  });

  test('a steer part breaks the block, so no group spans it', () {
    final groups = groupParts([
      tool('t1'),
      tool('t2'),
      steer(),
      tool('t3'),
      tool('t4'),
    ]);
    expect(shape(groups), ['g[0, 1]', 'p2', 'g[3, 4]']);
  });

  test('the key stays stable when the label absorbs leading reasoning', () {
    final before = groupParts([think('planning'), tool('t1'), tool('t2')]);
    final after = onlyGroup([
      think('planning'),
      tool('t1'),
      tool('t2'),
      label('Searched'),
    ]);
    expect(before[1].key, 'tool:t1');
    expect(after.key, before[1].key);
  });

  test('the key falls back to the first tool index, then the block', () {
    final group = onlyGroup([
      think('planning'),
      tool(null, name: 'a', output: 'x'),
      tool('', name: 'b', output: 'y'),
      label('Did two things'),
    ]);
    expect(group.key, 'toolidx:1');
    expect(onlyGroup([think('a'), label('Thought')]).key, 'block:0');
  });

  test('a SinglePart key is its index', () {
    expect(groupParts([text('a'), text('b')])[1].key, 'part:1');
  });

  test('a settled label counts as completion when a tool returned ""', () {
    final group = onlyGroup([tool('t1', output: ''), label('Checked config')]);
    expect(group.completed, isTrue);
  });

  test('a pending filled label is not completion proof', () {
    final group = onlyGroup([
      tool('t1', output: ''),
      tool('t2', output: ''),
      label('Working', pending: true),
    ]);
    expect(group.completed, isFalse);
    expect(group.label, 'Working');
  });

  test('an untitled group completes when every tool returned', () {
    expect(onlyGroup([tool('t1'), tool('t2')]).completed, isTrue);
    expect(
      onlyGroup([tool('t1'), tool('t2', output: null)]).completed,
      isFalse,
    );
  });

  test('failed is set for a failed or partial batch only', () {
    expect(
      onlyGroup([tool('t1'), label('Tried', status: 'failed')]).failed,
      isTrue,
    );
    expect(
      onlyGroup([tool('t1'), label('Tried', status: 'partial')]).failed,
      isTrue,
    );
    expect(onlyGroup([tool('t1'), label('Tried')]).failed, isFalse);
  });

  test('a trailing phase label does not claim the tail', () {
    final groups = groupParts([
      think('planning'),
      tool('t1'),
      label('Searched the docs'),
      text('Here is the answer.'),
      phase('Researching'),
    ]);
    expect(shape(groups), ['g[0, 1]', 'p3']);
    expect((groups[0] as ActivityGroup).label, 'Searched the docs');
  });

  test('a phase label alone renders nothing', () {
    final groups = groupParts([tool('t1'), text('done'), phase('Researching')]);
    expect(shape(groups), ['p0', 'p1']);
  });

  test('a phase label is skipped with grouping off', () {
    final groups = groupParts([
      text('lane text'),
      phase('Researching'),
    ], grouping: false);
    expect(shape(groups), ['p0']);
  });

  test('an empty phase label is skipped', () {
    expect(shape(groupParts([text('answer'), phase(null)])), ['p0']);
  });

  test('a late batch label consumed by a finalized phase is suppressed', () {
    final groups = groupParts([
      tool('t1'),
      tool('t2'),
      text('Here is the answer.'),
      label('Searched the docs'),
      phase('Researching', endIndex: 2),
    ]);
    expect(shape(groups), ['g[0, 1]', 'p2']);
    expect((groups[0] as ActivityGroup).label, '');
  });

  test('a pending phase marker consumes nothing', () {
    final groups = groupParts([
      tool('t1'),
      text('answer'),
      label('Searched'),
      phase(null, endIndex: 1, pending: true),
    ]);
    expect(shape(groups), ['p0', 'p1', 'p2']);
  });

  test('a phase marker with no end index consumes nothing', () {
    final groups = groupParts([
      tool('t1'),
      text('answer'),
      label('Searched'),
      phase('Researching'),
    ]);
    expect(shape(groups), ['p0', 'p1', 'p2']);
  });

  test('a batch label inside the phase span is not consumed', () {
    final groups = groupParts([
      think('planning'),
      tool('t1'),
      label('Searched the docs'),
      text('Here is the answer.'),
      phase('Researching', endIndex: 3),
    ]);
    expect(shape(groups), ['g[0, 1]', 'p3']);
    expect((groups[0] as ActivityGroup).label, 'Searched the docs');
  });

  test('multiple phase markers lower the earliest end together', () {
    final groups = groupParts([
      tool('t1'),
      text('mid'),
      label('First batch'), // consumed: the end is already 1
      phase('Phase one', endIndex: 4), // min(1, 4) keeps 1
      label('Second batch'), // consumed: 1 <= 4
      phase('Phase two', endIndex: 1), // seen first, end 1
    ]);
    expect(shape(groups), ['p0', 'p1']);
  });

  test('grouping off gives only SingleParts in order', () {
    final groups = groupParts([
      think('a'),
      tool('t1'),
      tool('t2'),
      label('Searched'),
      text('b'),
    ], grouping: false);
    expect(shape(groups), ['p0', 'p1', 'p2', 'p3', 'p4']);
  });

  test('completed groups start collapsed except in the live reply', () {
    final group = onlyGroup([tool('t1'), tool('t2')]);
    expect(group.completed, isTrue);
    expect(group.startsCollapsed(live: false), isTrue);
    expect(group.startsCollapsed(live: true), isFalse);
  });

  test('a labelled completed group starts collapsed', () {
    final group = onlyGroup([tool('t1'), label('Read the file')]);
    expect(group.startsCollapsed(live: false), isTrue);
  });

  test('a saved group whose tools never returned starts expanded', () {
    final group = onlyGroup([
      tool('t1', output: null),
      tool('t2', output: null),
    ]);
    expect(group.completed, isFalse);
    expect(group.startsCollapsed(live: false), isFalse);
    expect(group.startsCollapsed(live: true), isFalse);
  });

  test('a saved group with a pending label starts expanded', () {
    final group = onlyGroup([
      tool('t1', output: null),
      label('Working', pending: true),
    ]);
    expect(group.startsCollapsed(live: false), isFalse);
  });

  test('groups compare by value', () {
    final parts = [think('a'), tool('t1'), label('Searched')];
    expect(groupParts(parts), groupParts(List.of(parts)));
  });
}
