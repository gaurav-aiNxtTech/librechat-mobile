import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/attachment.dart';
import '../../../core/models/content_part.dart';
import '../../../core/storage/settings_store.dart';
import '../artifacts/artifact_button.dart';
import '../artifacts/artifact_parser.dart';
import '../artifacts/artifact_viewer.dart';
import '../run/run_state.dart';
import 'activity_groups.dart';
import 'find_matches.dart';
import 'image_viewer.dart';
import 'markdown_text.dart';
import 'media_player.dart';
import 'thinking_block.dart';
import 'tool_call_card.dart';

/// The text of a `summary` part: its `content` string or the text of its
/// `{type: text}` blocks, else `text` (KMP `Compaction.summaryText`).
String summaryText(ContentPart part) {
  final content = part.content;
  if (content is List) {
    return [
      for (final block in content)
        if (block is Map && block['type'] == 'text' && block['text'] is String)
          block['text'] as String,
    ].join();
  }
  if (content is String) return content;
  return part.text ?? '';
}

/// What every part of one message shares.
///
/// [storagePrefix] scopes the expansion state of the message's cards (see
/// [CollapsibleCard]). [streaming] is true in the live reply, and [live]
/// also for the reply that just settled, which keeps its groups open
/// (Req 23.12). [artifactVersions] is the Active_Path's
/// [artifactVersions] map, which the Artifact_Viewer pages through
/// (Req 24.12); it is empty outside a stored conversation.
typedef PartContext = ({
  String storagePrefix,
  TextStyle? style,
  List<Attachment> attachments,
  bool streaming,
  bool live,
  Map<String, SubagentProgress> subagents,
  Map<String, List<Artifact>> artifactVersions,
});

/// One content part, picked by `type` from the Message_Renderer's part
/// table (Req 23.1–23.3, 23.9, 23.13). An unknown type renders nothing, so
/// the remaining parts still show (Req 23.14).
class ContentPartView extends StatelessWidget {
  const ContentPartView({
    super.key,
    required this.part,
    required this.index,
    required this.scope,
  });

  final ContentPart part;

  /// The part's index in the message's content, for its storage key.
  final int index;
  final PartContext scope;

  @override
  Widget build(BuildContext context) {
    final c = scope;
    final storageKey = '${c.storagePrefix}/part:${part.toolCall?.id ?? index}';
    // Whether the in-conversation search's current match is in this part,
    // which opens a collapsed block that holds it (Req 25.11).
    final holdsMatch = ChatSearchScope.holdsCurrent(context, index);
    return switch (part.type) {
      ContentPartType.text || ContentPartType.textDelta => switch (part.text) {
        null || '' => const SizedBox.shrink(),
        // While a search runs, a part with a match renders as plain text
        // with the matches highlighted instead of as Markdown (Req 25.11).
        final text =>
          searchHighlight(context, text, partIndex: index, style: c.style) ??
              ArtifactSegments(text, scope: c),
      },
      ContentPartType.think => _card(
        (part.think ?? '').trim().isEmpty
            ? null
            : ThinkingBlock(
                part.think!,
                // A fresh storage key is what lets initiallyExpanded win
                // over the expansion the user last chose.
                storageKey: holdsMatch ? '$storageKey/match' : storageKey,
                initiallyExpanded: holdsMatch,
                partIndex: index,
                style: c.style,
              ),
      ),
      ContentPartType.toolCall => _card(
        ToolCallCard(
          part: part,
          storageKey: storageKey,
          attachments: c.attachments,
          streaming: c.streaming,
          subagents: c.subagents,
        ),
      ),
      ContentPartType.imageUrl ||
      ContentPartType.imageFile ||
      ContentPartType.videoUrl ||
      ContentPartType.inputAudio => MediaPartView(part: part),
      ContentPartType.error => _card(
        _ErrorNotice(part.error ?? part.text ?? ''),
      ),
      ContentPartType.summary => _card(
        summaryText(part).trim().isEmpty
            ? null
            : _SummaryBlock(
                summaryText(part),
                storageKey: storageKey,
                style: c.style,
              ),
      ),
      ContentPartType.agentUpdate => _card(
        HandoffMarker(
          from: part.agentUpdate?['agentId'] as String?,
          to: part.agentId == null ? null : 'Agent ${part.agentId}', // KMP
        ),
      ),
      ContentPartType.steer => _card(
        part.steer is String && (part.steer as String).trim().isNotEmpty
            ? _SteerTurn(part.steer as String, style: c.style, partIndex: index)
            : null,
      ),
      // A filled label whose block was filtered out stays as a bare line
      // (KMP OrphanActivityLabel); groupParts consumes the rest.
      ContentPartType.activityLabel => _orphanLabel(context),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _card(Widget? child) => child == null
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child);

  Widget _orphanLabel(BuildContext context) {
    final text = part.activityLabel?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child:
          searchHighlight(context, text, partIndex: index, style: style) ??
          Text(text, style: style),
    );
  }
}

/// One `text` or `text_delta` part, split by the Artifact_Parser
/// (Req 24.1): the reply text as [MarkdownText], each complete Artifact as
/// an [ArtifactButton] or, for the types the Chat settings mark inline and
/// outside the live reply, an [InlineArtifactCard] (Req 24.4, 24.5), and an
/// unclosed block as its source (Req 24.3).
///
/// Only this part links citations (Req 22.6); summaries, steer turns and
/// reasoning keep their markers as plain text.
class ArtifactSegments extends ConsumerWidget {
  const ArtifactSegments(this.text, {super.key, required this.scope});

  final String text;
  final PartContext scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = parseArtifacts(text);
    // Text with no artifact block renders exactly as it did before, as one
    // Markdown document.
    if (!segments.any((segment) => segment is Artifact)) return _markdown(text);
    final inline = ref.watch(settingsProvider.select((s) => s.inlineArtifacts));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final segment in segments)
          switch (segment) {
            TextSegment(text: final value) => _markdown(value),
            final Artifact artifact when !artifact.complete =>
              IncompleteArtifactView(artifact, streaming: scope.streaming),
            final Artifact artifact => _artifact(
              context,
              ref,
              artifact,
              inline,
            ),
          },
      ],
    );
  }

  Widget _markdown(String value) => MarkdownText(
    value,
    style: scope.style,
    attachments: scope.attachments,
    streaming: scope.streaming,
  );

  Widget _artifact(
    BuildContext context,
    WidgetRef ref,
    Artifact artifact,
    Set<InlineArtifact> inline,
  ) {
    final versions = scope.artifactVersions[artifact.identifier] ?? const [];
    void open() =>
        unawaited(openArtifact(context, ref, artifact, versions: versions));
    final inlineType = inlineArtifactType(artifact.type);
    // An artifact renders inline only after the reply has settled
    // (Req 24.5): a half-written page has nothing to show.
    if (!scope.streaming && inlineType != null && inline.contains(inlineType)) {
      return InlineArtifactCard(
        artifact: artifact,
        onTap: open,
        style: scope.style,
      );
    }
    return ArtifactButton(
      artifact: artifact,
      onTap: open,
      versionCount: versions.length,
    );
  }
}

/// The AppImage URL of an `image_url` or `image_file` part, or null.
///
/// `image_url` is a URL string or `{url}`. `image_file` is `{file_id,
/// filepath}` (KMP `resolveImageFilePartUrl`): an absolute or `data:`
/// filepath as is, an `/images/` path off the Server root, any other path
/// through `/api/files/`, else `/api/files/{file_id}`.
String? imagePartUrl(ContentPart part) {
  if (part.type == ContentPartType.imageUrl) {
    final raw = part.imageUrl;
    final url = raw is Map ? raw['url'] : raw;
    return url is String && url.trim().isNotEmpty ? url : null;
  }
  final file = part.imageFile;
  final path = file?['filepath'];
  if (path is String && path.isNotEmpty) {
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    if (path.startsWith('/images/')) return path;
    return '/api/files/${path.replaceFirst(RegExp('^/+'), '')}';
  }
  final id = file?['file_id'];
  return id is String && id.isNotEmpty ? '/api/files/$id' : null;
}

/// An image, video or audio part (Req 23.4, 23.5, 23.8): images inline
/// through AppImage with a tap to the fullscreen viewer, video and audio in
/// the inline players.
class MediaPartView extends StatelessWidget {
  const MediaPartView({super.key, required this.part});

  final ContentPart part;

  @override
  Widget build(BuildContext context) {
    final Widget? child = switch (part.type) {
      ContentPartType.imageUrl ||
      ContentPartType.imageFile => switch (imagePartUrl(part)) {
        final url? => Align(
          alignment: AlignmentDirectional.centerStart,
          child: InlineImage(
            url,
            semanticLabel: 'Embedded image in message', // KMP cd_embedded_image
          ),
        ),
        null => null,
      },
      ContentPartType.videoUrl => switch (videoSource(part)) {
        final source? => VideoPartPlayer(source: source),
        null => null,
      },
      ContentPartType.inputAudio => AudioPartPlayer(source: audioSource(part)),
      _ => null,
    };
    if (child == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    );
  }
}

/// One activity group (Req 23.10–23.12): a header with the group's label,
/// or "Used N tools", expanding to its reasoning and tool calls. It starts
/// collapsed only when the message is not live and its tools completed.
class ActivityGroupView extends StatelessWidget {
  const ActivityGroupView({
    super.key,
    required this.group,
    required this.scope,
  });

  final ActivityGroup group;
  final PartContext scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = group.label.isEmpty
        ? 'Used ${group.toolCount} tools' // KMP activity_used_n_tools
        : group.label;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: group.failed ? colors.error : colors.onSurfaceVariant,
    );
    // The group opens when the search's current match is in one of its
    // parts, and a fresh storage key is what lets initiallyExpanded win
    // over the expansion the user last chose (Req 25.11). A match in the
    // header itself needs no expansion: the header is always on screen.
    final holdsMatch = group.entries.any(
      (e) => ChatSearchScope.holdsCurrent(context, e.index),
    );
    final storageKey = '${scope.storagePrefix}/group:${group.key}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        key: PageStorageKey(holdsMatch ? '$storageKey/match' : storageKey),
        initiallyExpanded:
            holdsMatch || !group.startsCollapsed(live: scope.live),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        minTileHeight: 40,
        leading: Icon(
          Icons.build_outlined,
          size: 16,
          color: colors.onSurfaceVariant,
        ),
        title:
            searchHighlight(
              context,
              label,
              // Null for an untitled group, whose "Used N tools" line is
              // the App's own text and not part of the conversation.
              partIndex: group.label.isEmpty ? null : group.labelIndex,
              style: labelStyle,
            ) ??
            Text(label, style: labelStyle),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsetsDirectional.only(start: 12),
        children: [
          for (final e in group.entries)
            ContentPartView(part: e.part, index: e.index, scope: scope),
        ],
      ),
    );
  }
}

/// An `error` part as an error notice (Req 23.9). The text stays
/// selectable, so it can be copied into a report.
class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(Icons.error_outline, size: 18, color: colors.onErrorContainer),
            Expanded(
              child: SelectableText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A `summary` part as a collapsible context summary (Req 23.9).
class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock(this.text, {required this.storageKey, this.style});

  final String text;
  final String storageKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return CollapsibleCard(
      storageKey: storageKey,
      icon: Icon(Icons.notes, size: 20, color: colors.primary),
      title: Text(
        'Summarized earlier messages', // KMP label_summary
        style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
      ),
      children: [MarkdownText(text, style: style)],
    );
  }
}

/// A `steer` part: the user's words at the place they entered the reply
/// (Req 23.9, KMP SteerContentPart).
class _SteerTurn extends StatelessWidget {
  const _SteerTurn(this.text, {this.style, required this.partIndex});

  final String text;
  final TextStyle? style;

  /// The part's index, so a search match in it highlights (Req 25.11).
  final int partIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = style?.copyWith(color: colors.onSecondaryContainer);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 6,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'You', // KMP sender_you
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'sent while replying', // KMP steer_sent_during_reply
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            searchHighlight(context, text, partIndex: partIndex, style: body) ??
                MarkdownText(text, style: body),
          ],
        ),
      ),
    );
  }
}
