import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/feature_gate.dart';
import '../../core/models/conversation.dart';
import '../../core/network/app_exception.dart';
import '../../core/ui/error_view.dart';
import 'conversation_actions.dart';
import 'conversation_grouping.dart';
import 'conversation_list_controller.dart';

/// How close to the end of the built list the next page starts loading.
const pagingThreshold = 5;

/// The Conversation_List: the drawer and sidebar body under "New Chat"
/// (Req 15, 16). Search, tag chips, the Pinned section and date groups, or
/// the flat search results; paging, pull to refresh and the row actions.
/// [onOpen] navigates to a route, closing a modal drawer first.
class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key, required this.onOpen});

  final void Function(String route) onOpen;

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

/// One built row of the list.
sealed class _Item {
  const _Item();
}

class _Header extends _Item {
  const _Header(this.label);
  final String label;
}

class _Row extends _Item {
  const _Row(this.conversation, this.id);
  final Conversation conversation;
  final String id;
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ConversationListController get _controller =>
      ref.read(conversationListControllerProvider.notifier);

  void _clearSearch() {
    _search.clear();
    _controller.setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationListControllerProvider);
    final gates = ref.watch(featureGatesProvider);
    final showPinned = gates.has(Feature.pin);
    final showTags = gates.has(Feature.bookmarks);
    final path = GoRouterState.of(context).uri.path;

    // A failure with rows on screen keeps them and shows a SnackBar
    // (Req 45.3); with nothing to show, the ErrorView takes the list's place.
    ref.listen(conversationListControllerProvider.select((s) => s.error), (
      previous,
      error,
    ) {
      if (error == null || previous != null) return;
      final s = ref.read(conversationListControllerProvider);
      final hasRows = s.results != null || s.cached.isNotEmpty;
      if (!hasRows) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(userMessage(error))));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
          child: Row(
            children: [
              Expanded(child: _searchField()),
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                tooltip:
                    'Import conversations', // New copy: the KMP_App has none
                onPressed: () => unawaited(
                  importConversations(
                    context,
                    ref,
                    onImported: () {
                      if (mounted) unawaited(_controller.refreshList());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showTags && state.tags.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final tag in state.tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${tag.tag} (${tag.count})'),
                      selected: state.selectedTags.contains(tag.tag),
                      onSelected: (_) => _controller.toggleTag(tag.tag),
                    ),
                  ),
              ],
            ),
          ),
        if (state.searching)
          const LinearProgressIndicator(
            semanticsLabel:
                'Loading conversations', // New copy: the KMP_App has none
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: _list(state, showPinned: showPinned, path: path),
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return ValueListenableBuilder(
      valueListenable: _search,
      builder: (context, value, _) => TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onChanged: _controller.setQuery,
        decoration: InputDecoration(
          // KMP search_conversations
          hintText: 'Search conversations\u2026',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search', // KMP cd_clear_search
                  onPressed: _clearSearch,
                ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          isDense: true,
        ),
      ),
    );
  }

  List<_Item> _items(ConversationListState state, {required bool showPinned}) {
    final results = state.results;
    if (results != null) {
      return [
        for (final c in results)
          if (c.conversationId case final id?) _Row(c, id),
      ];
    }
    final rows = [
      for (final c in state.cached)
        if (c.conversationId != null) c,
    ];
    final pinned = showPinned
        ? [
            for (final c in rows)
              if (c.pinned == true) c,
          ]
        : const <Conversation>[];
    final rest = showPinned
        ? [
            for (final c in rows)
              if (c.pinned != true) c,
          ]
        : rows;
    return [
      if (pinned.isNotEmpty) ...[
        const _Header('Pinned'), // KMP pinned
        for (final c in pinned) _Row(c, c.conversationId!),
      ],
      for (final group in groupConversations(rest, DateTime.now())) ...[
        _Header(group.label),
        for (final c in group.conversations) _Row(c, c.conversationId!),
      ],
    ];
  }

  Widget _list(
    ConversationListState state, {
    required bool showPinned,
    required String path,
  }) {
    final inResults = state.results != null;
    final items = _items(state, showPinned: showPinned);
    final cursor = inResults ? state.resultsCursor : state.nextCursor;
    final hasFooter =
        items.isNotEmpty &&
        (state.loadingMore || state.pageError != null || cursor != null);

    if (items.isEmpty) {
      final Widget body;
      if (!inResults && state.loading) {
        body = Semantics(
          liveRegion: true,
          child: const CircularProgressIndicator(
            semanticsLabel:
                'Loading conversations', // New copy: the KMP_App has none
          ),
        );
      } else if (state.error case final error?) {
        return ErrorView(
          title:
              'Could not load conversations', // KMP could_not_load_conversations
          message: userMessage(error),
          onRetry: () => unawaited(_controller.refresh()),
        );
      } else {
        body = _EmptyState(
          title: inResults
              ? 'No results found' // KMP no_results_found
              : 'No conversations yet', // KMP no_conversations_yet
          message: inResults
              ? 'Try a different search term' // KMP try_different_search
              : 'Start a new chat to begin', // KMP start_new_chat
        );
      }
      // Scrollable, so pull to refresh works on the empty list too.
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: body),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: items.length + (hasFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) return _footer(state);
        if (index >= items.length - pagingThreshold &&
            cursor != null &&
            !state.loadingMore &&
            state.pageError == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_controller.loadMore());
          });
        }
        return switch (items[index]) {
          _Header(:final label) => _GroupHeader(label),
          _Row(:final conversation, :final id) => _ConversationRow(
            conversation: conversation,
            selected: path == Routes.chat(id),
            onTap: () => widget.onOpen(Routes.chat(id)),
            onActions: () => unawaited(_actions(conversation)),
          ),
        };
      },
    );
  }

  Widget _footer(ConversationListState state) {
    if (state.pageError != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'), // KMP retry
            onPressed: () => unawaited(_controller.retryPage()),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          semanticsLabel:
              'Loading conversations', // New copy: the KMP_App has none
        ),
      ),
    );
  }

  Future<void> _actions(Conversation conversation) => showConversationActions(
    context,
    ref,
    conversation,
    onOpen: widget.onOpen,
    onChanged: (updated) {
      if (mounted) {
        _controller.resultChanged(conversation.conversationId!, updated);
      }
    },
    onTagsChanged: () {
      if (mounted) unawaited(_controller.reloadTags());
    },
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onActions,
  });

  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        title: Text(
          conversationTitle(conversation),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        minTileHeight: 48,
        shape: const StadiumBorder(),
        selected: selected,
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        onTap: onTap,
        onLongPress: onActions,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Conversation actions', // KMP cd_conversation_actions
          onPressed: onActions,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
