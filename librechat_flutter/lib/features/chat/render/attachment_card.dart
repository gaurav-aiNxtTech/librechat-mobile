import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../core/models/attachment.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/ui/platform_actions.dart';
import '../data/file_downloads.dart';
import 'image_viewer.dart';
import 'markdown_text.dart';
import 'thinking_block.dart';

// ─── Pure helpers ────────────────────────────────────────────────────

/// Attachment types that carry a payload rather than a file: citation
/// sources, memory writes and MCP UI resources (upstream
/// `TAttachmentMetadata`). They never render as a file.
const _payloadTypes = {'web_search', 'file_search', 'memory', 'ui_resources'};

/// Empty-folder markers the code sandbox leaves (upstream
/// `SANDBOX_PLACEHOLDER_LEAVES`).
final _sandboxPlaceholder = RegExp(
  r'^_\.(?:dirkeep|gitkeep)-[0-9a-f]{6}$',
  caseSensitive: false,
);

/// A dotfile the sandbox renamed, such as `_.config-abcdef.txt`.
final _sanitizedDotfile = RegExp(
  r'^_\.(.+?)-[0-9a-f]{6}(\.[^.]+)?$',
  caseSensitive: false,
);

/// Upstream `imageExtRegex`. SVG is left out on purpose, as upstream does.
final _imageExtension = RegExp(
  r'\.(?:jpg|jpeg|png|gif|webp|heic|heif)$',
  caseSensitive: false,
);

/// Whether [a] is an office document's deferred preview
/// (`application/vnd.librechat.<ext>-preview`).
bool isOfficePreview(Attachment a) {
  final type = a.type;
  return type != null &&
      type.startsWith('application/vnd.librechat.') &&
      type.endsWith('-preview');
}

/// The attachment's file name: `filename`, else the last `filepath`
/// segment.
String? attachmentName(Attachment a) {
  final name = a.filename;
  if (name != null && name.isNotEmpty) return name;
  final path = a.filepath;
  if (path == null || path.isEmpty) return null;
  final last = path.split('/').last;
  return last.isEmpty ? null : last;
}

/// [name] as shown: a sandbox-renamed dotfile gets its dot back
/// (`_.config-abcdef.txt` → `.config.txt`, upstream `getDisplayFileName`).
String displayFilename(String name) {
  final m = _sanitizedDotfile.firstMatch(name);
  if (m == null || m.end != name.length) return name;
  return '.${m.group(1)}${m.group(2) ?? ''}';
}

/// Whether [a] renders as an inline image: an `image/*` type or an image
/// file extension (upstream `isImageAttachment`).
bool isImageAttachment(Attachment a) {
  if (a.type?.startsWith('image/') ?? false) return true;
  final name = attachmentName(a);
  return name != null && _imageExtension.hasMatch(name);
}

/// The image URL of [a] for AppImage (KMP `resolveAttachmentUrl`): an
/// absolute or `data:` filepath as is, any other filepath off the Server
/// root, else `/api/files/{file_id}`.
String? attachmentImageUrl(Attachment a) {
  final path = a.filepath;
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    return path.startsWith('/') ? path : '/$path';
  }
  final id = a.fileId;
  return id == null || id.isEmpty ? null : '/api/files/$id';
}

bool _isFile(Attachment a) {
  if (_payloadTypes.contains(a.type)) return false;
  final name = attachmentName(a);
  return name == null || !_sandboxPlaceholder.hasMatch(name);
}

/// [list] without repeats of one `file_id`, or of one name when there is
/// no id. An attachment with neither is dropped: there is nothing to show.
List<Attachment> _distinct(Iterable<Attachment> list) {
  final seen = <String>{};
  return [
    for (final a in list)
      if ((a.fileId ?? attachmentName(a)) case final key? when seen.add(key)) a,
  ];
}

/// The files a tool call produced, which its card draws (KMP
/// `partitionToolCallAttachments`): the attachments with its id, without
/// payloads, sandbox placeholders and office previews, which the message
/// draws.
List<Attachment> toolCallAttachments(
  List<Attachment> attachments,
  String? toolCallId,
) {
  if (toolCallId == null) return const [];
  return _distinct(
    attachments.where(
      (a) => a.toolCallId == toolCallId && _isFile(a) && !isOfficePreview(a),
    ),
  );
}

/// The attachments a message draws after its parts: every file except
/// those a tool card in [toolCallIds] already draws. Search sources are
/// citations (Req 22.6) and memory writes belong to their tool card, so
/// payload types are left out. Office previews always render here.
List<Attachment> messageAttachments(
  List<Attachment> attachments,
  Set<String> toolCallIds,
) => _distinct(
  attachments.where(
    (a) =>
        _isFile(a) &&
        (isOfficePreview(a) || !toolCallIds.contains(a.toolCallId)),
  ),
);

/// The MIME type an app opens [a] as: its `type` when that is a real
/// type, else one guessed from [fileName].
String? attachmentMimeType(Attachment a, String fileName) {
  final type = a.type;
  if (type != null && type.contains('/') && !isOfficePreview(a)) return type;
  return lookupMimeType(fileName);
}

/// Text from an HTML office preview, for plain display: block ends become
/// line breaks, list items get a bullet, tags go and entities decode. The
/// HTML is never rendered, so nothing in it can run.
String htmlToPlainText(String html) {
  var s = html.replaceAll(
    RegExp(
      r'<(script|style|head)\b[^>]*>[\s\S]*?</\1\s*>',
      caseSensitive: false,
    ),
    '',
  );
  s = s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li\b[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'</t[dh]\s*>', caseSensitive: false), '\t')
      .replaceAll(
        RegExp(
          r'</(p|div|h[1-6]|tr|ul|ol|table|blockquote|pre|section)\s*>',
          caseSensitive: false,
        ),
        '\n\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), '');
  s = s.replaceAllMapped(
    RegExp(r'&(#x[0-9a-f]+|#\d+|[a-z]+);', caseSensitive: false),
    (m) {
      final e = m.group(1)!;
      final lower = e.toLowerCase();
      if (lower.startsWith('#x')) {
        final code = int.tryParse(lower.substring(2), radix: 16);
        return code == null ? m.group(0)! : String.fromCharCode(code);
      }
      if (lower.startsWith('#')) {
        final code = int.tryParse(lower.substring(1));
        return code == null ? m.group(0)! : String.fromCharCode(code);
      }
      return switch (lower) {
            'amp' => '&',
            'lt' => '<',
            'gt' => '>',
            'quot' => '"',
            'apos' => "'",
            'nbsp' => ' ',
            _ => null,
          } ??
          m.group(0)!;
    },
  );
  return s
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

// ─── Widgets ─────────────────────────────────────────────────────────

/// A message's or tool call's attachments (Req 23.4, 23.6, 23.7) in the
/// KMP order: file cards, office previews, then images inline.
///
/// [storagePrefix] scopes the office previews' expansion state.
class AttachmentList extends StatelessWidget {
  const AttachmentList(
    this.attachments, {
    super.key,
    required this.storagePrefix,
  });

  final List<Attachment> attachments;
  final String storagePrefix;

  @override
  Widget build(BuildContext context) {
    final office = [
      for (final a in attachments)
        if (isOfficePreview(a)) a,
    ];
    final images = [
      for (final a in attachments)
        if (!isOfficePreview(a) && isImageAttachment(a))
          if (attachmentImageUrl(a) case final url?) (a, url),
    ];
    final imaged = {for (final (a, _) in images) a};
    final files = [
      for (final a in attachments)
        if (!isOfficePreview(a) && !imaged.contains(a)) a,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final a in files) AttachmentCard(a),
        for (final a in office)
          OfficePreviewCard(
            a,
            storageKey:
                '$storagePrefix/attachment:${a.fileId ?? attachmentName(a)}',
          ),
        for (final (a, url) in images)
          InlineImage(
            url,
            name: switch (attachmentName(a)) {
              final name? => displayFilename(name),
              null => null,
            },
            width: a.width,
            height: a.height,
          ),
      ],
    );
  }
}

/// A file attachment as a card (Req 23.6): a tap downloads it through
/// ApiClient to a local file and opens it with open_filex, and Save hands
/// the bytes to the document picker.
class AttachmentCard extends ConsumerStatefulWidget {
  const AttachmentCard(this.attachment, {super.key, this.label});

  final Attachment attachment;

  /// The card's text in place of the file name.
  final String? label;

  @override
  ConsumerState<AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends ConsumerState<AttachmentCard> {
  var _busy = false;

  String get _name {
    final name = attachmentName(widget.attachment);
    return name == null ? 'Attachment' : displayFilename(name); // KMP
  }

  /// A `file_id` downloads through the files route; an absolute filepath
  /// downloads directly.
  bool get _downloadable =>
      widget.attachment.fileId != null ||
      (widget.attachment.filepath?.startsWith(RegExp('https?://')) ?? false);

  Future<void> _run(Future<String?> Function() act) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final problem = await act();
      if (problem != null) {
        messenger.showSnackBar(SnackBar(content: Text(problem)));
      }
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _open() async {
    final a = widget.attachment;
    final file = await ref.read(fileDownloadsProvider).attachmentFile(a, _name);
    final result = await ref
        .read(platformActionsProvider)
        .openFile(file.path, mimeType: attachmentMimeType(a, _name));
    return switch (result) {
      OpenFileResult.opened => null,
      OpenFileResult.noApp => 'No app can open this file',
      // Shown with the unknown-error copy by [_run].
      OpenFileResult.failed => throw StateError('Opening $_name failed'),
    };
  }

  Future<String?> _save() async {
    final a = widget.attachment;
    final bytes = await ref.read(fileDownloadsProvider).attachmentBytes(a);
    await ref
        .read(platformActionsProvider)
        .saveFile(
          fileName: _name,
          bytes: bytes,
          mimeType: attachmentMimeType(a, _name) ?? 'application/octet-stream',
        );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = _downloadable && !_busy;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: _downloadable,
              label: 'Attached file: $_name', // KMP cd_attached_file
              excludeSemantics: true,
              child: InkWell(
                onTap: enabled ? () => _run(_open) : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        if (_busy)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            fileTypeIcon(widget.attachment.type),
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        Expanded(
                          child: Text(
                            widget.label ?? _name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_downloadable)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Save to device', // KMP cd_save_to_device
              onPressed: enabled ? () => _run(_save) : null,
            ),
        ],
      ),
    );
  }
}

/// The icon for a MIME [type] (KMP `fileTypeIcon`).
IconData fileTypeIcon(String? type) {
  if (type == null) return Icons.insert_drive_file_outlined;
  if (type.startsWith('application/pdf')) return Icons.picture_as_pdf_outlined;
  if (type.startsWith('text/')) return Icons.description_outlined;
  if (type.contains('spreadsheet') ||
      type.contains('csv') ||
      type.contains('excel')) {
    return Icons.table_chart_outlined;
  }
  if (type.contains('document') || type.contains('word')) {
    return Icons.description_outlined;
  }
  if (type.startsWith('audio/')) return Icons.audio_file_outlined;
  if (type.startsWith('video/')) return Icons.video_file_outlined;
  return Icons.attach_file;
}

/// An office document's deferred preview (Req 23.7, KMP OfficePreviewCard)
/// in the state the Server reports: `pending` spins, `ready` shows the
/// extracted text, and `failed` shows `previewError`. A missing status
/// counts as ready. A ready preview without text is a file card.
class OfficePreviewCard extends StatelessWidget {
  const OfficePreviewCard(
    this.attachment, {
    super.key,
    required this.storageKey,
  });

  final Attachment attachment;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final a = attachment;
    final name = a.filename ?? '';
    final text = a.text;
    switch (a.status ?? 'ready') {
      case 'pending':
        return _OfficeStatus(
          // KMP office_preview_preparing
          label: 'Preparing preview of $name…',
          trailing: const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case 'failed':
        return _OfficeStatus(
          // KMP office_preview_failed
          label: "Couldn't preview $name (${a.previewError ?? ''})",
          trailing: Icon(Icons.error_outline, size: 18, color: colors.error),
        );
    }
    if (text == null || text.trim().isEmpty) {
      // KMP office_preview_unavailable
      return AttachmentCard(a, label: '$name — preview not available');
    }
    final body = switch (a.textFormat) {
      'markdown' ||
      'md' => MarkdownText(text, style: theme.textTheme.bodyMedium),
      'html' => SelectableText(
        htmlToPlainText(text),
        style: theme.textTheme.bodyMedium,
      ),
      _ => SelectableText(text, style: theme.textTheme.bodyMedium),
    };
    return CollapsibleCard(
      storageKey: storageKey,
      initiallyExpanded: true,
      icon: Icon(Icons.description_outlined, size: 18, color: colors.primary),
      title: Text(name, style: theme.textTheme.titleSmall),
      children: [body],
    );
  }
}

/// One line for a pending or failed preview (KMP OfficeStatusChip).
class _OfficeStatus extends StatelessWidget {
  const _OfficeStatus({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 8,
          children: [
            Icon(Icons.description_outlined, size: 18, color: colors.primary),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
