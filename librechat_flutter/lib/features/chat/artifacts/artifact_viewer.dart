/// The Artifact_Viewer (Req 24.7, 24.12–24.14, design "Artifacts and
/// Mermaid"): a full-height bottom sheet, or the `/artifact` route when the
/// Chat settings ask for fullscreen, showing one artifact with version
/// paging, a code/preview toggle, copy and share.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/ui/platform_actions.dart';
import '../render/code_block.dart';
import '../render/markdown_text.dart';
import 'artifact_button.dart';
import 'artifact_parser.dart';
import 'web_host.dart';

/// What the `/artifact` route carries in `extra`: the version to open and
/// the identifier's versions, oldest first.
typedef ArtifactArgs = ({Artifact artifact, List<Artifact> versions});

/// Whether [type] has anything to show besides its source: every type but
/// plain code (KMP `isPreviewableType`). Markdown and plain text preview
/// natively (Req 24.7); the rest go through the WebView_Host (Req 24.6).
bool artifactPreviewable(String type) =>
    artifactKind(type) != ArtifactKind.code;

/// Opens the Artifact_Viewer for [artifact] (Req 24.4): the bottom sheet,
/// or the `/artifact` route when AppSettings `artifactViewer` is
/// [ArtifactViewer.fullscreen]. [versions] are the identifier's versions in
/// the conversation, oldest first (Req 24.12).
Future<void> openArtifact(
  BuildContext context,
  WidgetRef ref,
  Artifact artifact, {
  List<Artifact> versions = const [],
}) async {
  final args = (artifact: artifact, versions: versions);
  if (ref.read(settingsProvider).artifactViewer == ArtifactViewer.fullscreen) {
    await context.push<void>(Routes.artifactFullscreen, extra: args);
    return;
  }
  await showArtifactSheet(context, args);
}

/// Shows the Artifact_Viewer as a full-height bottom sheet.
Future<void> showArtifactSheet(BuildContext context, ArtifactArgs args) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 1,
        child: ArtifactPanel(artifact: args.artifact, versions: args.versions),
      ),
    );

/// The Artifact_Viewer on the root navigator (`/artifact`), outside the
/// AppShell. A location without its `extra` payload, such as a restored
/// one, is sent back by the router.
class ArtifactFullscreenScreen extends StatelessWidget {
  const ArtifactFullscreenScreen({super.key, required this.args});

  final ArtifactArgs args;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ArtifactPanel(
        artifact: args.artifact,
        versions: args.versions,
        fullscreen: true,
      ),
    ),
  );
}

/// The viewer body both shells share: the header with the title, the
/// version pager, the code/preview toggle, copy, share and the fullscreen
/// or close action, over the preview or the source.
class ArtifactPanel extends ConsumerStatefulWidget {
  const ArtifactPanel({
    super.key,
    required this.artifact,
    this.versions = const [],
    this.fullscreen = false,
  });

  final Artifact artifact;

  /// The identifier's versions, oldest first. An empty list, or one that
  /// does not hold [artifact], shows [artifact] alone.
  final List<Artifact> versions;

  /// True on the `/artifact` route: a Close action instead of Fullscreen.
  final bool fullscreen;

  @override
  ConsumerState<ArtifactPanel> createState() => _ArtifactPanelState();
}

class _ArtifactPanelState extends ConsumerState<ArtifactPanel> {
  late final List<Artifact> _versions =
      widget.versions.contains(widget.artifact)
      ? widget.versions
      : [widget.artifact];
  late int _index = _versions.indexOf(widget.artifact);

  /// Set once the user asks for the source, and by the error's action
  /// (Req 24.14). A previewable artifact opens on its preview.
  bool _code = false;

  /// The page's last render error, cleared when the version changes.
  String? _error;

  Timer? _copied;

  Artifact get _current => _versions[_index];

  @override
  void dispose() {
    _copied?.cancel();
    super.dispose();
  }

  void _step(int delta) => setState(() {
    _index = _index + delta;
    _error = null;
  });

  Future<void> _copy() async {
    await ref.read(platformActionsProvider).copy(_current.content);
    if (!mounted) return;
    _copied?.cancel();
    setState(() {
      _copied = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copied = null);
      });
    });
  }

  Future<void> _share() => ref
      .read(platformActionsProvider)
      .shareFile(
        fileName: artifactFileName(_current),
        bytes: utf8.encode(_current.content),
        mimeType: artifactShareMimeType(_current.type),
      );

  /// Leaves the sheet and opens the `/artifact` route on the version in
  /// view (Req 24.13).
  void _expand() {
    final args = (artifact: _current, versions: _versions);
    // The router is read before the pop, which takes this widget's context
    // out of the tree.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push<void>(Routes.artifactFullscreen, extra: args));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final artifact = _current;
    final previewable = artifactPreviewable(artifact.type);
    final showCode = _code || !previewable;
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.fullscreen ? 4 : 16,
            end: 4,
          ),
          child: Row(
            children: [
              if (widget.fullscreen)
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  tooltip: 'Close', // KMP cd_close
                  icon: const Icon(Icons.close),
                ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    artifact.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_versions.length > 1)
                _VersionNav(
                  index: _index,
                  count: _versions.length,
                  onPrevious: _index > 0 ? () => _step(-1) : null,
                  onNext: _index < _versions.length - 1 ? () => _step(1) : null,
                ),
              if (previewable)
                IconButton(
                  onPressed: () => setState(() => _code = !_code),
                  tooltip: showCode
                      ? 'View preview' // KMP artifact_view_preview
                      : 'View source', // KMP artifact_view_source
                  icon: Icon(showCode ? Icons.visibility : Icons.code),
                ),
              IconButton(
                onPressed: _copy,
                tooltip: _copied != null
                    ? 'Copied' // KMP cd_copied
                    : 'Copy code', // KMP cd_copy_code
                icon: Icon(
                  _copied != null ? Icons.check : Icons.content_copy,
                  color: _copied != null ? colors.primary : null,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(_share()),
                tooltip: 'Share artifact', // KMP cd_share_artifact
                icon: const Icon(Icons.share),
              ),
              if (!widget.fullscreen)
                IconButton(
                  onPressed: _expand,
                  tooltip: 'Fullscreen', // KMP cd_fullscreen
                  icon: const Icon(Icons.fullscreen),
                ),
            ],
          ),
        ),
        if (error != null && !showCode)
          _RenderError(
            message: error,
            onViewCode: () => setState(() => _code = true),
          ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The preview stays mounted across toggles, so the WebView
              // is not rebuilt and reloaded; the source layers over it.
              if (previewable)
                _ArtifactPreview(
                  artifact: artifact,
                  onError: (message) {
                    if (mounted) setState(() => _error = message);
                  },
                ),
              if (showCode)
                ColoredBox(
                  color: colors.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CodeBlock(
                      language: artifactLanguage(artifact.type),
                      code: artifact.content,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The preview of one artifact: Markdown and plain text natively
/// (Req 24.7), and HTML, SVG, React and Mermaid in the WebView_Host
/// (Req 24.6).
class _ArtifactPreview extends StatelessWidget {
  const _ArtifactPreview({required this.artifact, required this.onError});

  final Artifact artifact;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (hasWebPreview(artifact.type)) {
      return WebContentView(
        buildArtifactHtml(artifact, dark: isDarkSurface(colors)),
        onError: onError,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: artifact.kind == ArtifactKind.markdown
          ? MarkdownText(artifact.content)
          : SelectableText(
              artifact.content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
    );
  }
}

/// "vN/M" with previous and next (Req 24.12, KMP ArtifactVersionNav).
class _VersionNav extends StatelessWidget {
  const _VersionNav({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous version', // KMP cd_previous_version
          icon: const Icon(Icons.keyboard_arrow_left),
        ),
        Text(
          'v${index + 1}/$count', // KMP artifact_version
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Next version', // KMP cd_next_version
          icon: const Icon(Icons.keyboard_arrow_right),
        ),
      ],
    );
  }
}

/// A page that failed to render (Req 24.14): the error, with an action
/// that switches to the source.
class _RenderError extends StatelessWidget {
  const _RenderError({required this.message, required this.onViewCode});

  final String message;
  final VoidCallback onViewCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: colors.errorContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewCode,
                child: const Text('View code'), // KMP cd_view_code
              ),
            ],
          ),
        ),
      ),
    );
  }
}
