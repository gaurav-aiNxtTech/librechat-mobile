import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message.dart';
import '../run/run_service.dart';
import '../run/run_state.dart';
import 'message_view.dart';

/// The streaming reply of the Run under [runKey] (Req 18.7-18.9, 22.8).
///
/// Only this widget watches the Run's parts, so each flushed event rebuilds
/// the live reply alone (Req 18.8). Until the Run delivers content it shows
/// the waiting indicator (Req 18.9); then the parts render as a message
/// with a cursor at the end while the Stream is open (Req 22.8). A detached
/// Run shows its error under the partial reply (Req 19.7).
class LiveReplyView extends ConsumerWidget {
  const LiveReplyView({super.key, required this.runKey});

  /// The Run's key: a conversation id or a landing visit's `new:<uuid>`.
  final String runKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(
      runServiceProvider.select((s) => s.runs[s.movedTo[runKey] ?? runKey]),
    );
    if (run == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final error = run.error;
    if (!run.hasContent && error == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Semantics(
          liveRegion: true,
          child: Text(
            'Waiting for response…', // KMP waiting_for_response
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final streaming = run.phase != RunPhase.detached;
    return MessageView(
      Message(
        messageId: 'live:${run.key}',
        conversationId: run.conversationId ?? '',
        sender: run.selection.modelLabel ?? run.selection.model,
        content: run.parts,
        attachments: run.attachments.isEmpty ? null : run.attachments,
      ),
      streaming: streaming,
      // A detached Run's groups stay open too: it is still the live reply.
      justSettled: true,
      subagents: run.subagents,
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streaming) const _StreamingCursor(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The cursor after the streamed text (Req 22.8). It does not blink, so it
/// never keeps frames scheduled, and TalkBack skips it.
class _StreamingCursor extends StatelessWidget {
  const _StreamingCursor();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: 8,
        height: 16,
        child: ColoredBox(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
