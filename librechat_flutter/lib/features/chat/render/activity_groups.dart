import '../../../core/models/content_part.dart';

/// A content part and its index in the message's `content` list.
typedef IndexedPart = ({int index, ContentPart part});

/// One rendered unit of a message's content: a part on its own or an
/// activity group (Req 23.10–23.12).
sealed class PartGroup {
  const PartGroup();

  /// Identity for the group's expansion state.
  String get key;

  List<IndexedPart> get entries;
}

/// A part that renders on its own.
final class SinglePart extends PartGroup {
  const SinglePart(this.entry);

  final IndexedPart entry;

  @override
  String get key => 'part:${entry.index}';

  @override
  List<IndexedPart> get entries => [entry];

  @override
  bool operator ==(Object other) => other is SinglePart && other.entry == entry;

  @override
  int get hashCode => entry.hashCode;

  @override
  String toString() => 'SinglePart(${entry.index}, ${entry.part.type})';
}

/// A run of reasoning and tool calls under one collapsible header. A labeled
/// group carries the model's own summary; an untitled one is the legacy run
/// of two or more tool calls (Req 23.10, 23.11).
final class ActivityGroup extends PartGroup {
  const ActivityGroup({
    required this.key,
    required this.entries,
    required this.label,
    required this.failed,
    required this.toolCount,
    required this.completed,
  });

  @override
  final String key;

  @override
  final List<IndexedPart> entries;

  /// The trimmed `activity_label` text, or `''` for an untitled group.
  final String label;

  /// The label's batch status is `failed` or `partial`.
  final bool failed;

  /// The `tool_call` entries. Absorbed reasoning is not counted.
  final int toolCount;

  /// The label settled (filled and not pending), or every tool call returned
  /// a non-empty output.
  final bool completed;

  /// Groups start collapsed once [completed], except in the live reply and in
  /// `justSettledId` (Req 23.12); [live] is true for both. A saved reply whose
  /// tools never returned (aborted, errored or detached) stays expanded so
  /// the unfinished calls show, as KMP's `collapsedByDefault` does.
  bool startsCollapsed({required bool live}) => !live && completed;

  @override
  bool operator ==(Object other) =>
      other is ActivityGroup &&
      other.key == key &&
      other.label == label &&
      other.failed == failed &&
      other.toolCount == toolCount &&
      other.completed == completed &&
      _sameEntries(other.entries, entries);

  @override
  int get hashCode => Object.hash(
    key,
    label,
    failed,
    toolCount,
    completed,
    Object.hashAll(entries),
  );

  @override
  String toString() =>
      'ActivityGroup($key, label: "$label", '
      'entries: ${[for (final e in entries) e.index]}, failed: $failed, '
      'toolCount: $toolCount, completed: $completed)';
}

bool _sameEntries(List<IndexedPart> a, List<IndexedPart> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const _phase = 'phase';
const _transferPrefix = 'lc_transfer_to_';

/// Splits a message's content into the groups the bubble renders
/// (Req 23.10–23.12). Ported from the KMP `groupContentParts`
/// (`feature/chat/.../util/ContentSegments.kt`) without steer segmentation:
/// a steer part breaks a block like any other part.
///
/// - Phase labels (`activity_label_type == "phase"`) are skipped, filled or
///   blank, and so is a batch label that a finalized phase span consumed.
/// - With [grouping] off (comparison panes, Req 30.5) every other part is a
///   [SinglePart].
/// - Otherwise a filled label claims the `think`/`tool_call` run before it,
///   back to the last blank label, as one titled [ActivityGroup]. A blank
///   label is invisible and only moves that claim boundary. Runs that no
///   label claims follow the legacy rule: two or more consecutive tool calls
///   form an untitled group, and reasoning stays standalone.
List<PartGroup> groupParts(List<ContentPart> parts, {bool grouping = true}) {
  if (parts.isEmpty) return [];
  final consumed = _batchLabelsConsumedByPhase(parts);
  final entries = <IndexedPart>[
    for (var i = 0; i < parts.length; i++)
      if (!_isPhaseLabel(parts[i]) && !consumed.contains(i))
        (index: i, part: parts[i]),
  ];
  if (!grouping) return [for (final e in entries) SinglePart(e)];

  final result = <PartGroup>[];
  var block = <IndexedPart>[];
  // Position in `block` just past the latest blank label. A filled label may
  // claim only the parts after it, its own batch.
  var claimStart = 0;

  void flushUnlabeled() {
    var run = <IndexedPart>[];
    void flushRun() {
      if (run.length >= 2) {
        result.add(_activityGroup(run, null));
      } else {
        result.addAll(run.map(SinglePart.new));
      }
      run = [];
    }

    for (final entry in block) {
      if (_isGroupableToolCall(entry.part)) {
        run.add(entry);
      } else {
        flushRun();
        result.add(SinglePart(entry));
      }
    }
    flushRun();
    block = [];
    claimStart = 0;
  }

  for (final entry in entries) {
    final part = entry.part;
    if (_isGroupableToolCall(part) || part.type == ContentPartType.think) {
      block.add(entry);
      continue;
    }
    if (part.type == ContentPartType.activityLabel) {
      if (_labelText(part).isEmpty) {
        claimStart = block.length;
        continue;
      }
      final claimed = block.sublist(claimStart);
      block = block.sublist(0, claimStart);
      flushUnlabeled();
      if (claimed.isNotEmpty) {
        result.add(_activityGroup(claimed, part));
      } else if (!_coversTransferCall(part, parts)) {
        result.add(SinglePart(entry));
      }
      continue;
    }
    flushUnlabeled();
    result.add(SinglePart(entry));
  }
  flushUnlabeled();
  return result;
}

ActivityGroup _activityGroup(List<IndexedPart> entries, ContentPart? label) {
  final text = label == null ? '' : _labelText(label);
  final tools = [
    for (final e in entries)
      if (e.part.type == ContentPartType.toolCall) e,
  ];
  // The Server settles a filled label only after every output returned, so a
  // tool that legitimately returned '' still completes the group.
  final settled = text.isNotEmpty && label?.pending != true;
  return ActivityGroup(
    key: _groupKey(entries),
    entries: List.unmodifiable(entries),
    label: text,
    failed: label?.status == 'failed' || label?.status == 'partial',
    toolCount: tools.length,
    completed:
        settled ||
        tools.every((e) => e.part.toolCall?.output?.isNotEmpty == true),
  );
}

/// Anchored to the first tool call, so the key holds when a label lands and
/// absorbs the block's leading reasoning.
String _groupKey(List<IndexedPart> entries) {
  for (final e in entries) {
    final id = e.part.toolCall?.id;
    if (id != null && id.isNotEmpty) return 'tool:$id';
  }
  for (final e in entries) {
    if (e.part.type == ContentPartType.toolCall) return 'toolidx:${e.index}';
  }
  return 'block:${entries.first.index}';
}

String _labelText(ContentPart part) =>
    part.type == ContentPartType.activityLabel
    ? (part.activityLabel?.trim() ?? '')
    : '';

bool _isPhaseLabel(ContentPart part) =>
    part.type == ContentPartType.activityLabel &&
    part.activityLabelType == _phase;

bool _isBatchLabel(ContentPart part) =>
    part.type == ContentPartType.activityLabel && !_isPhaseLabel(part);

/// Handoffs never fold into a group: their card already names the
/// destination.
bool _isGroupableToolCall(ContentPart part) {
  if (part.type != ContentPartType.toolCall) return false;
  final call = part.toolCall;
  if (call == null) return false;
  return call.name?.startsWith(_transferPrefix) != true;
}

/// True when [label] names a part whose tool call is a handoff.
bool _coversTransferCall(ContentPart label, List<ContentPart> parts) {
  final ids = label.toolCallIds;
  if (ids == null || ids.isEmpty) return false;
  return parts.any((p) {
    final call = p.toolCall;
    return call != null &&
        ids.contains(call.id) &&
        call.name?.startsWith(_transferPrefix) == true;
  });
}

/// Indices of batch labels a finalized phase span consumed: a backward walk
/// where each finalized phase marker (not pending, with an
/// `activity_end_index`) lowers the earliest phase end, and each batch label
/// met afterwards at or past that end is consumed. Mirrors the KMP
/// `findLateBatchLabelsConsumedByPhase`.
Set<int> _batchLabelsConsumedByPhase(List<ContentPart> parts) {
  int? earliestEnd;
  final consumed = <int>{};
  for (var index = parts.length - 1; index >= 0; index--) {
    final part = parts[index];
    final phaseEnd = _isPhaseLabel(part) && part.pending != true
        ? part.activityEndIndex
        : null;
    if (phaseEnd != null) {
      final current = earliestEnd ?? index;
      earliestEnd = phaseEnd < current ? phaseEnd : current;
    } else if (earliestEnd != null &&
        earliestEnd <= index &&
        _isBatchLabel(part)) {
      consumed.add(index);
    }
  }
  return consumed;
}
