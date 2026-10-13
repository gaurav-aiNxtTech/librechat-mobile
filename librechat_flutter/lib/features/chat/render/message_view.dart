import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/content_part.dart';
import '../../../core/models/message.dart';
import '../../../core/storage/settings_store.dart';
import '../artifacts/artifact_parser.dart';
import '../run/run_state.dart';
import 'activity_groups.dart';
import 'attachment_card.dart';
import 'content_part_view.dart';

/// The chat text scale for AppSettings `chatFontSize` (KMP ChatScreen.kt
/// `fontSizeMultiplier`), applied on top of the system text scale (Req 22.9).
double chatFontScale(ChatFontSize size) => switch (size) {
  ChatFontSize.small => 0.85,
  ChatFontSize.medium => 1.0,
  ChatFontSize.large => 1.2,
};

/// The parts [message] renders: its `content` when non-empty, otherwise its
/// `text` as one text part.
List<ContentPart> displayParts(Message message) {
  final content = message.content;
  if (content != null && content.isNotEmpty) return content;
  return [ContentPart(type: ContentPartType.text, text: message.text)];
}

/// The author label of [message]: "You" for the user, otherwise the
/// Server's `sender` (KMP sender_you, sender_assistant).
String authorLabel(Message message) {
  if (message.isCreatedByUser) return 'You'; // KMP sender_you
  final sender = message.sender?.trim();
  return sender == null || sender.isEmpty
      ? 'Assistant' // KMP sender_assistant
      : sender;
}

/// One stored message: the author header, the content and [actions], laid
/// out by AppSettings `messageLayout` and sized by `chatFontSize`
/// (Req 22.9).
///
/// [MessageLayout.thread] stacks every message under its author.
/// [MessageLayout.twoSided] puts the user's messages in a bubble on the
/// right. The parts go through [groupParts] (Req 23.10–23.12), and each
/// group renders as an [ActivityGroupView] or a [ContentPartView]. The
/// uploaded `files` sit above the parts and the `attachments` below them
/// ([messageAttachments], Req 23.4, 23.6, 23.7).
class MessageView extends ConsumerWidget {
  const MessageView(
    this.message, {
    super.key,
    this.actions,
    this.editor,
    this.streaming = false,
    this.justSettled = false,
    this.grouping = true,
    this.subagents = const {},
    this.artifactVersions = const {},
  });

  final Message message;

  /// The row under the content, such as the SiblingNavigator (Req 17.6).
  final Widget? actions;

  /// The inline edit field, which takes the content's place while the user
  /// edits the message (Req 25.1, 25.3). The uploaded `files` stay above
  /// it, as in the KMP_App, so it is clear a Submit keeps them.
  final Widget? editor;

  /// The live reply: tool calls without an output show a spinner.
  final bool streaming;

  /// The reply that has just finished streaming (`justSettledId`). Like the
  /// live reply, its activity groups start expanded (Req 23.12).
  final bool justSettled;

  /// Off in comparison panes, which render every part on its own (Req 30.5).
  final bool grouping;

  /// The live Run's subagents, for the `subagent` tool cards (Req 31.3).
  final Map<String, SubagentProgress> subagents;

  /// The Active_Path's artifacts by identifier, oldest first, which the
  /// Artifact_Viewer pages through (Req 24.12). Empty off a conversation,
  /// where an artifact is its own only version.
  final Map<String, List<Artifact>> artifactVersions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (fontSize, layout) = ref.watch(
      settingsProvider.select((s) => (s.chatFontSize, s.messageLayout)),
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bubble = layout == MessageLayout.twoSided && message.isCreatedByUser;
    final base = theme.textTheme.bodyLarge!;
    final style = base.copyWith(
      fontSize: base.fontSize! * chatFontScale(fontSize),
      color: bubble ? colors.onSecondaryContainer : colors.onSurface,
    );
    final PartContext scope = (
      storagePrefix: message.messageId,
      style: style,
      attachments: message.attachments ?? const [],
      streaming: streaming,
      live: streaming || justSettled,
      subagents: subagents,
      artifactVersions: artifactVersions,
    );
    final parts = displayParts(message);
    // The uploaded files go above the text, as in the KMP_App; the
    // attachments go after the parts, except those a tool card draws.
    final files = messageAttachments(message.files ?? const [], const {});
    final attachments = messageAttachments(scope.attachments, {
      for (final p in parts)
        if (p.type == ContentPartType.toolCall) ?p.toolCall?.id,
    });
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AttachmentList(
              files,
              storagePrefix: '${message.messageId}/files',
            ),
          ),

        if (editor case final editor?)
          editor
        else ...[
          for (final group in groupParts(parts, grouping: grouping))
            switch (group) {
              ActivityGroup() => ActivityGroupView(group: group, scope: scope),
              SinglePart(:final entry) => ContentPartView(
                part: entry.part,
                index: entry.index,
                scope: scope,
              ),
            },
          if (attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AttachmentList(
                attachments,
                storagePrefix: message.messageId,
              ),
            ),
        ],
      ],
    );
    final header = Semantics(
      header: true,
      child: Text(
        authorLabel(message),
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );

    if (bubble) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // No visible header in a bubble; TalkBack still reads the
            // author first.
            Semantics(
              container: true,
              label: authorLabel(message),
              child: LayoutBuilder(
                builder: (context, constraints) => ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.85,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
            ?actions,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 4), content, ?actions],
      ),
    );
  }
}
