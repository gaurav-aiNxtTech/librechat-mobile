import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_gate.dart';
import 'composer_controller.dart';

/// The longest excerpt a quote chip stages. A selection past it is cut at
/// the limit with an ellipsis, so one chip can never hide the Composer.
const maxQuoteLength = 1000;

/// [selection] as a quote chip's excerpt: the trimmed selection with its
/// inner runs of blank space collapsed to single spaces, cut to
/// [maxQuoteLength]. Returns `''` for a selection with no text, which
/// stages nothing.
String quoteExcerpt(String selection) {
  final text = selection.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length <= maxQuoteLength) return text;
  return '${text.substring(0, maxQuoteLength).trimRight()}…';
}

/// Whether [chatKey]'s Composer offers "Add to chat" (Req 25.10): the
/// Server must be new enough for quotes, and the selected endpoint must not
/// be an Assistants endpoint, which takes none.
final quotingAllowedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  chatKey,
) {
  if (!ref.watch(featureGatesProvider.select((g) => g.has(Feature.quotes)))) {
    return false;
  }
  final selection = ref.watch(composerSelectionProvider(chatKey));
  return selection != null && !selection.isAssistants;
});

/// Makes the text below it quotable (Req 25.10, KMP
/// AddToChatSelectionMenu.kt): a selection's toolbar gains "Add to chat",
/// which stages the selection as a quote chip on [chatKey]'s Composer.
///
/// The toolbar's own items stay as they are, so Copy, Select all and the
/// platform's text actions keep working. The item is left out entirely
/// while [quotingAllowedProvider] is false.
///
/// Flutter hands the selected text to [SelectionArea.onSelectionChanged],
/// so the excerpt is read from there rather than off the clipboard the way
/// the KMP_App has to.
class QuotableText extends ConsumerStatefulWidget {
  const QuotableText({super.key, required this.chatKey, required this.child});

  /// The Composer the quote goes to: [newChatKey] or a conversation id.
  final String chatKey;
  final Widget child;

  @override
  ConsumerState<QuotableText> createState() => _QuotableTextState();
}

class _QuotableTextState extends ConsumerState<QuotableText> {
  /// The latest selection, which "Add to chat" stages.
  String _selected = '';

  void _addToChat(SelectableRegionState state) {
    final quote = quoteExcerpt(_selected);
    state.hideToolbar();
    if (quote.isEmpty) return;
    ref.read(composerProvider(widget.chatKey).notifier).addQuote(quote);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        // New copy: the KMP_App's chip appearing is its own confirmation,
        // which a one-line chip row above the keyboard can miss.
        const SnackBar(content: Text('Added to chat')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(quotingAllowedProvider(widget.chatKey));
    return SelectionArea(
      onSelectionChanged: (content) => _selected = content?.plainText ?? '',
      contextMenuBuilder: allowed
          ? (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
              anchors: state.contextMenuAnchors,
              buttonItems: [
                ...state.contextMenuButtonItems,
                ContextMenuButtonItem(
                  // KMP selection_add_to_chat
                  label: 'Add to chat',
                  onPressed: () => _addToChat(state),
                ),
              ],
            )
          : null,
      child: widget.child,
    );
  }
}

/// The excerpts "Add to chat" staged, pinned above the Composer until the
/// next send carries them (Req 25.10, KMP PendingQuoteChipsSection.kt).
///
/// Each chip is one truncated line with the KMP_App's left accent and a ×
/// that drops it.
class PendingQuoteChips extends ConsumerWidget {
  const PendingQuoteChips({super.key, required this.chatKey});

  final String chatKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(composerProvider(chatKey).select((s) => s.quotes));
    if (quotes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = ref.read(composerProvider(chatKey).notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          for (final (index, quote) in quotes.indexed)
            Semantics(
              container: true,
              // KMP cd_quoted_excerpt
              label: 'Quoted excerpt: $quote',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: BorderDirectional(
                    start: BorderSide(color: colors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            quote,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Remove quote', // KMP cd_remove_quote
                      onPressed: () => controller.removeQuote(index),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
