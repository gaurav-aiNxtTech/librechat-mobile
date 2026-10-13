/// The artifact widgets inside a reply (Req 24.3–24.5, design "Artifacts
/// and Mermaid"): the [ArtifactButton] that opens the Artifact_Viewer, the
/// [InlineArtifactCard] for the types the Chat settings render inline, the
/// [IncompleteArtifactView] for a block whose closing `:::` never arrived,
/// and the pure type metadata the viewer shares with them.
library;

import 'package:flutter/material.dart';

import '../../../core/storage/settings_store.dart';
import '../render/code_block.dart';
import '../render/markdown_text.dart';
import 'artifact_parser.dart';
import 'web_host.dart';

/// The human label of an artifact [type], ported from KMP
/// `artifactTypeLabel`.
String artifactTypeLabel(String type) => switch (artifactKind(type)) {
  ArtifactKind.mermaid => 'Mermaid Diagram',
  ArtifactKind.react => 'React Component',
  ArtifactKind.svg => 'SVG Image',
  ArtifactKind.markdown => 'Markdown Document',
  ArtifactKind.html => 'HTML Page',
  ArtifactKind.plain => 'Plain Text',
  ArtifactKind.code => 'Code',
};

/// The icon of an artifact [type], ported from KMP `artifactTypeIcon`.
IconData artifactTypeIcon(String type) => switch (artifactKind(type)) {
  ArtifactKind.mermaid => Icons.account_tree,
  ArtifactKind.react => Icons.widgets,
  ArtifactKind.svg => Icons.image,
  ArtifactKind.markdown => Icons.article,
  ArtifactKind.html => Icons.web,
  ArtifactKind.plain || ArtifactKind.code => Icons.code,
};

/// The CodeBlock fence language for an artifact [type]. The parser keeps
/// no fence info string, so the type decides; an unbundled or empty name
/// renders as plain monospace.
String artifactLanguage(String type) => switch (artifactKind(type)) {
  ArtifactKind.mermaid => 'mermaid',
  ArtifactKind.react => 'jsx',
  ArtifactKind.svg => 'xml',
  ArtifactKind.markdown => 'markdown',
  ArtifactKind.html => 'html',
  ArtifactKind.plain || ArtifactKind.code => '',
};

/// The Chat settings' inline type for [type], or null for the types that
/// never render inline: plain text and code show as a button either way.
InlineArtifact? inlineArtifactType(String type) => switch (artifactKind(type)) {
  ArtifactKind.html => InlineArtifact.html,
  ArtifactKind.react => InlineArtifact.react,
  ArtifactKind.svg => InlineArtifact.svg,
  ArtifactKind.mermaid => InlineArtifact.mermaid,
  ArtifactKind.markdown => InlineArtifact.markdown,
  ArtifactKind.plain || ArtifactKind.code => null,
};

/// The file extension for sharing an artifact of [type], without the dot
/// (KMP `ArtifactDownloadHelper.extensionForArtifact`, which also reads the
/// fence language the Dart parser does not keep).
String artifactFileExtension(String type) {
  if (type.contains('mermaid')) return 'mmd';
  if (type.contains('html')) return 'html';
  if (type.contains('react')) return 'jsx';
  if (type.contains('svg')) return 'svg';
  if (type.contains('css')) return 'css';
  if (type.contains('json')) return 'json';
  if (type.contains('xml')) return 'xml';
  if (type.contains('markdown') || type == 'text/md') return 'md';
  return 'txt';
}

/// The MIME type to share an artifact of [type] under (KMP
/// `mimeTypeForExtension`).
String artifactShareMimeType(String type) =>
    switch (artifactFileExtension(type)) {
      'html' => 'text/html',
      'svg' => 'image/svg+xml',
      'jsx' => 'text/javascript',
      'css' => 'text/css',
      'json' => 'application/json',
      'xml' => 'application/xml',
      'md' => 'text/markdown',
      _ => 'text/plain',
    };

final _unsafeFileChars = RegExp(r'[^A-Za-z0-9._\- ]');

/// The share file name of [artifact]: its title with the characters a file
/// name cannot hold replaced, capped at 100, plus the type's extension
/// (Req 24.13, KMP `sanitizeFileName`, which neither trims nor guards the
/// blank title that would leave a bare `.md`).
String artifactFileName(Artifact artifact) {
  final safe = artifact.title.replaceAll(_unsafeFileChars, '_').trim();
  final name = safe.isEmpty ? 'artifact' : safe;
  final capped = name.length > 100 ? name.substring(0, 100) : name;
  return '$capped.${artifactFileExtension(artifact.type)}';
}

/// A complete Artifact as a button (Req 24.4): the type's icon and label,
/// the title, and the number of versions when the identifier has more than
/// one. A tap opens the Artifact_Viewer.
class ArtifactButton extends StatelessWidget {
  const ArtifactButton({
    super.key,
    required this.artifact,
    required this.onTap,
    this.versionCount = 1,
  });

  final Artifact artifact;
  final VoidCallback onTap;

  /// How many versions of the identifier the conversation holds.
  final int versionCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        color: colors.secondaryContainer,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: _ArtifactHeader(
            artifact: artifact,
            versionCount: versionCount,
            onSurface: colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

/// An Artifact rendered inline (Req 24.5): Markdown natively (Req 24.7),
/// and HTML, React, SVG and Mermaid in a WebView capped to
/// [inlineMaxHeightFraction] of the window. The header opens the
/// Artifact_Viewer, which shows the whole artifact.
class InlineArtifactCard extends StatelessWidget {
  const InlineArtifactCard({
    super.key,
    required this.artifact,
    required this.onTap,
    this.style,
  });

  final Artifact artifact;
  final VoidCallback onTap;

  /// The body style for a Markdown artifact (Req 22.9).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Widget body;
    if (hasWebPreview(artifact.type)) {
      body = InlineWebView(
        buildArtifactHtml(artifact, dark: isDarkSurface(colors)),
      );
    } else if (artifact.kind == ArtifactKind.markdown) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: MarkdownText(artifact.content, style: style),
      );
    } else {
      // Plain text and code never turn on inline; show the source anyway.
      body = Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: CodeBlock(
          language: artifactLanguage(artifact.type),
          code: artifact.content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: _ArtifactHeader(
                artifact: artifact,
                onSurface: colors.onSurface,
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

/// The icon, title, type label, version count and open affordance both
/// artifact cards share (KMP ArtifactButton.kt).
class _ArtifactHeader extends StatelessWidget {
  const _ArtifactHeader({
    required this.artifact,
    required this.onSurface,
    this.versionCount = 1,
  });

  final Artifact artifact;
  final Color onSurface;
  final int versionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = onSurface.withValues(alpha: 0.7);
    return Semantics(
      button: true,
      label: 'Open artifact', // KMP cd_open_artifact
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 12,
          children: [
            Icon(artifactTypeIcon(artifact.type), size: 20, color: onSurface),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artifact.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artifactTypeLabel(artifact.type),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (versionCount > 1)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 20,
                  child: Center(
                    child: Text(
                      '$versionCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ExcludeSemantics(
              child: Icon(Icons.open_in_new, size: 16, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// An artifact without its closing `:::` (Req 24.3): the title, an
/// "Incomplete" note and the source as a CodeBlock, so a truncated or
/// still-streaming reply keeps its text on screen (KMP IncompleteArtifact).
class IncompleteArtifactView extends StatelessWidget {
  const IncompleteArtifactView(
    this.artifact, {
    super.key,
    this.streaming = false,
  });

  final Artifact artifact;

  /// True in the live reply, where the fence is still open.
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  artifact.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Incomplete', // KMP artifact_incomplete
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          CodeBlock(
            language: artifactLanguage(artifact.type),
            code: artifact.content,
            closed: !streaming,
          ),
        ],
      ),
    );
  }
}
