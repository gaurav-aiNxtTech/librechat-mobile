import 'package:flutter/material.dart';

import 'find_matches.dart';
import 'markdown_text.dart';

/// A card with a tappable header that expands to [children], shared by the
/// thinking block, the context summary and the tool call card.
///
/// [storageKey] keeps the expansion through PageStorage, so a block the
/// user opened stays open after its message scrolls out of the list and
/// back. ExpansionTile announces the expanded or collapsed state.
class CollapsibleCard extends StatelessWidget {
  const CollapsibleCard({
    super.key,
    required this.storageKey,
    required this.icon,
    required this.title,
    required this.children,
    this.status,
    this.initiallyExpanded = false,
  });

  final String storageKey;
  final Widget icon;
  final Widget title;

  /// A widget after the title, such as a spinner or a failure icon.
  final Widget? status;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        key: PageStorageKey(storageKey),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: icon,
        title: Row(
          children: [
            Expanded(child: title),
            if (status case final status?) ...[
              const SizedBox(width: 8),
              status,
            ],
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: AlignmentDirectional.centerStart,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [expansionBody(storageKey, children)],
      ),
    );
  }
}

/// [children] under their own PageStorageKey. Without it a scrollable in
/// the body (a code block, the tool arguments) shares the ExpansionTile's
/// PageStorage identifier and reads its expanded bool as a scroll offset.
Widget expansionBody(String storageKey, List<Widget> children) => KeyedSubtree(
  key: PageStorageKey('$storageKey/body'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  ),
);

/// A `think` part: the model's reasoning, collapsed under "Thinking"
/// (KMP ThinkingContentPart).
class ThinkingBlock extends StatelessWidget {
  const ThinkingBlock(
    this.text, {
    super.key,
    required this.storageKey,
    this.partIndex,
    this.initiallyExpanded = false,
    this.style,
  });

  final String text;
  final String storageKey;

  /// The part's index, so a search match in the reasoning highlights
  /// (Req 25.11). Null outside a message's content.
  final int? partIndex;

  /// Open from the start, for a block that holds the search's current
  /// match (Req 25.11).
  final bool initiallyExpanded;

  /// The chat body style (Req 22.9).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = style?.copyWith(color: colors.onSurfaceVariant);
    return CollapsibleCard(
      storageKey: storageKey,
      initiallyExpanded: initiallyExpanded,
      icon: Icon(Icons.psychology_outlined, color: colors.primary, size: 20),
      title: Text(
        'Thinking', // KMP label_thinking
        style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
      ),
      children: [
        searchHighlight(context, text, partIndex: partIndex, style: body) ??
            MarkdownText(text, style: body),
      ],
    );
  }
}
