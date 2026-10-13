import 'package:flutter/material.dart';

/// "n / m" with previous and next controls for a message whose level holds
/// more than one Sibling (Req 17.6, KMP SiblingNavigator.kt). [index] is the
/// shown Sibling, oldest first. [onSelect] gets the index to show, or is
/// null while a Run is live, which disables both controls (Req 25.14).
class SiblingNavigator extends StatelessWidget {
  const SiblingNavigator({
    super.key,
    required this.index,
    required this.count,
    required this.onSelect,
  });

  final int index;
  final int count;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final select = onSelect;
    return Semantics(
      container: true,
      value: 'Response ${index + 1} of $count', // KMP stateDescription
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: select != null && index > 0
                ? () => select(index - 1)
                : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous response', // KMP cd_previous_response
          ),
          ExcludeSemantics(
            child: Text(
              '${index + 1} / $count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            onPressed: select != null && index < count - 1
                ? () => select(index + 1)
                : null,
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next response', // KMP cd_next_response
          ),
        ],
      ),
    );
  }
}
