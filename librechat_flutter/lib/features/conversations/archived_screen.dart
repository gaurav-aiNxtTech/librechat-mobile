import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/shell/shell_menu_button.dart';
import '../../core/models/conversation.dart';
import '../../core/network/app_exception.dart';
import '../../core/ui/error_view.dart';
import 'archived_controller.dart';
import 'conversation_actions.dart';
import 'conversation_list_screen.dart' show pagingThreshold;

/// `Routes.archivedConversations`: the archived conversations, with open,
/// unarchive and delete (Req 16).
class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(archivedControllerProvider);
    final controller = ref.read(archivedControllerProvider.notifier);

    ref.listen(archivedControllerProvider.select((s) => s.error), (
      previous,
      error,
    ) {
      if (error == null || previous != null) return;
      if (ref.read(archivedControllerProvider).items.isEmpty) return;
      _toast(context, userMessage(error));
    });

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.leading(context),
        title: const Text(
          'Archived Conversations', // KMP archived_conversations
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: _body(context, state, controller),
      ),
    );
  }

  static void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Widget _body(
    BuildContext context,
    ArchivedState state,
    ArchivedController controller,
  ) {
    if (state.items.isEmpty) {
      final Widget body;
      if (state.loading) {
        body = const CircularProgressIndicator(
          semanticsLabel:
              'Loading conversations', // New copy: the KMP_App has none
        );
      } else if (state.error case final error?) {
        return ErrorView(
          title:
              'Could not load archived conversations', // KMP could_not_load_archived
          message: userMessage(error),
          onRetry: () => unawaited(controller.refresh()),
        );
      } else {
        final theme = Theme.of(context);
        body = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No archived conversations', // KMP no_archived_conversations
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                // KMP archived_will_appear_here
                'Archived conversations will appear here',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: Semantics(liveRegion: true, child: body)),
            ),
          ],
        ),
      );
    }

    final items = state.items;
    final hasFooter =
        state.loadingMore ||
        state.pageError != null ||
        state.nextCursor != null;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (hasFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          if (state.pageError != null) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'), // New copy: the KMP_App has none
                  onPressed: () => unawaited(controller.retryPage()),
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
        if (index >= items.length - pagingThreshold &&
            state.nextCursor != null &&
            !state.loadingMore &&
            state.pageError == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) unawaited(controller.loadMore());
          });
        }
        return _row(context, items[index], controller);
      },
    );
  }

  Widget _row(
    BuildContext context,
    Conversation conversation,
    ArchivedController controller,
  ) {
    final id = conversation.conversationId;
    return ListTile(
      title: Text(
        conversationTitle(conversation),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      onTap: id == null ? null : () => context.go(Routes.chat(id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.unarchive_outlined),
            tooltip: 'Unarchive', // KMP cd_unarchive
            onPressed: () =>
                unawaited(_unarchive(context, conversation, controller)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete', // KMP cd_delete
            onPressed: id == null
                ? null
                : () => unawaited(_delete(context, conversation, controller)),
          ),
        ],
      ),
    );
  }

  Future<void> _unarchive(
    BuildContext context,
    Conversation conversation,
    ArchivedController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.unarchive(conversation);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(userMessage(e))));
    }
  }

  Future<void> _delete(
    BuildContext context,
    Conversation conversation,
    ArchivedController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmDeleteConversation(context, conversation)) return;
    try {
      await controller.delete(conversation.conversationId!);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(userMessage(e))));
    }
  }
}
