import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import '../../../core/models/attachment.dart';
import '../../../core/models/file_config.dart';

/// A picked file as the attachment check sees it.
final class FileInfo {
  const FileInfo({
    required this.name,
    required this.size,
    required this.mimeType,
  });

  /// Reads the mime type from [name] and, when given, the file's
  /// [headerBytes], falling back to `application/octet-stream`.
  factory FileInfo.detect({
    required String name,
    required int size,
    List<int>? headerBytes,
  }) => FileInfo(
    name: name,
    size: size,
    mimeType:
        lookupMimeType(name, headerBytes: headerBytes) ??
        'application/octet-stream',
  );

  final String name;

  /// Bytes.
  final int size;
  final String mimeType;

  @override
  bool operator ==(Object other) =>
      other is FileInfo &&
      other.name == name &&
      other.size == size &&
      other.mimeType == mimeType;

  @override
  int get hashCode => Object.hash(name, size, mimeType);

  @override
  String toString() => 'FileInfo($name, $size, $mimeType)';
}

/// The FileConfig limits, in the order [checkAttachments] checks them.
enum AttachmentLimit {
  disabled,
  fileLimit,
  fileSizeLimit,
  totalSizeLimit,
  mimeType,
}

/// The outcome of [checkAttachments].
sealed class AttachmentVerdict {
  const AttachmentVerdict();
}

final class AttachmentAccepted extends AttachmentVerdict {
  const AttachmentAccepted();

  @override
  bool operator ==(Object other) => other is AttachmentAccepted;

  @override
  int get hashCode => (AttachmentAccepted).hashCode;

  @override
  String toString() => 'AttachmentAccepted()';
}

/// The set broke [limit]. [fileName] names the offending file for
/// [AttachmentLimit.fileSizeLimit] and [AttachmentLimit.mimeType].
final class AttachmentRejected extends AttachmentVerdict {
  const AttachmentRejected(this.limit, {this.fileName});

  final AttachmentLimit limit;
  final String? fileName;

  @override
  bool operator ==(Object other) =>
      other is AttachmentRejected &&
      other.limit == limit &&
      other.fileName == fileName;

  @override
  int get hashCode => Object.hash(limit, fileName);

  @override
  String toString() => 'AttachmentRejected(${limit.name}, $fileName)';
}

/// Checks [files] against [endpoint]'s limits in [config] (Req 26.3, 26.4).
/// [endpointType] is the endpoint's type when it has one (`custom` for a
/// custom endpoint), as the Server takes it.
///
/// The limits resolve field by field, as the Server's
/// `getEndpointFileConfig` and `mergeWithDefault` do (see [_resolveLimits]):
/// each field is the matched entry's, else `default`'s. With neither set, the
/// field does not restrict.
///
/// The set passes exactly when uploads are not disabled, the count is within
/// `fileLimit`, each size is within `fileSizeLimit`, the sum is within
/// `totalSizeLimit`, and each mime type matches one of `supportedMimeTypes`.
/// A `fileLimit` or `totalSizeLimit` of 0 does not restrict (the Server
/// checks only a positive one), while a `fileSizeLimit` of 0 does (the
/// Server's upload filter compares every file against it). An empty pattern
/// list does not restrict, and a pattern that is not a valid regex is ignored
/// (the KMP check fails open the same way). A rejection names the first
/// broken limit, in that order.
AttachmentVerdict checkAttachments(
  List<FileInfo> files,
  FileConfig config,
  String endpoint, {
  String? endpointType,
}) {
  final limits = _resolveLimits(config, endpoint, endpointType);
  if (limits.disabled ?? false) {
    return const AttachmentRejected(AttachmentLimit.disabled);
  }

  final fileLimit = limits.fileLimit;
  if (fileLimit != null && fileLimit > 0 && files.length > fileLimit) {
    return const AttachmentRejected(AttachmentLimit.fileLimit);
  }

  final fileSizeLimit = limits.fileSizeLimit;
  if (fileSizeLimit != null) {
    for (final file in files) {
      if (file.size > fileSizeLimit) {
        return AttachmentRejected(
          AttachmentLimit.fileSizeLimit,
          fileName: file.name,
        );
      }
    }
  }

  final totalSizeLimit = limits.totalSizeLimit;
  if (totalSizeLimit != null && totalSizeLimit > 0) {
    final total = files.fold(0, (sum, file) => sum + file.size);
    if (total > totalSizeLimit) {
      return const AttachmentRejected(AttachmentLimit.totalSizeLimit);
    }
  }

  final patterns = [
    for (final source in limits.supportedMimeTypes) ?_compile(source),
  ];
  if (patterns.isNotEmpty) {
    for (final file in files) {
      if (!patterns.any((p) => p.hasMatch(file.mimeType))) {
        return AttachmentRejected(
          AttachmentLimit.mimeType,
          fileName: file.name,
        );
      }
    }
  }
  return const AttachmentAccepted();
}

const _defaultKey = 'default';
const _customKey = 'custom';
const _agentsKey = 'agents';

/// The Server's standard endpoint keys in `getEndpointFileConfig`.
const _standardEndpoints = {
  _defaultKey,
  _agentsKey,
  'assistants',
  'azureAssistants',
  'openAI',
  'azureOpenAI',
  'anthropic',
  'google',
  'bedrock',
};

/// The Server's `documentSupportedProviders`, lower-cased.
const _documentSupportedProviders = {
  'anthropic',
  'openai',
  'bedrock',
  'custom',
  'google',
  'vertexai',
  'mistralai',
  'mistral',
  'deepseek',
  'moonshot',
  'openrouter',
  'xai',
};

/// The Server's `normalizeEndpointName`.
String _normalize(String name) =>
    name.toLowerCase() == 'ollama' ? 'ollama' : name;

/// The limits in effect for [endpoint], following the Server's
/// `getEndpointFileConfig` lookup order:
///
/// - a custom endpoint ([endpointType] `custom`, or a name outside
///   [_standardEndpoints]) takes its own entry, else a non-standard entry
///   with the same normalized name, else `custom`, else `agents`;
/// - any other takes the [endpointType] entry, else the [endpoint] entry,
///   else the normalized name's, else `agents` for the agents endpoint.
///
/// The matched entry is merged over `default` field by field
/// (`mergeWithDefault`); with no match, `default` applies as it is. Two
/// Server steps are left out because the App doesn't have their inputs:
/// the Server's built-in defaults under the served `default` entry, and the
/// built-in mime list it substitutes for a document-supported provider whose
/// entry has no patterns. For the latter the mime check is skipped, and the
/// Server's own check stands.
EndpointFileConfig _resolveLimits(
  FileConfig config,
  String endpoint,
  String? endpointType,
) {
  final endpoints = config.endpoints;
  final fallback = endpoints[_defaultKey] ?? const EndpointFileConfig();

  EndpointFileConfig merge(EndpointFileConfig entry, String key) =>
      EndpointFileConfig(
        disabled: entry.disabled ?? fallback.disabled,
        fileLimit: entry.fileLimit ?? fallback.fileLimit,
        fileSizeLimit: entry.fileSizeLimit ?? fallback.fileSizeLimit,
        totalSizeLimit: entry.totalSizeLimit ?? fallback.totalSizeLimit,
        supportedMimeTypes: entry.supportedMimeTypes.isNotEmpty
            ? entry.supportedMimeTypes
            : _documentSupportedProviders.contains(key.toLowerCase())
            ? const []
            : fallback.supportedMimeTypes,
      );

  final normalized = _normalize(endpoint);
  final normalizedType = _normalize(endpointType ?? '');
  final isCustom =
      endpointType == _customKey ||
      (!_standardEndpoints.contains(normalizedType) &&
          normalized.isNotEmpty &&
          !_standardEndpoints.contains(normalized));

  if (isCustom) {
    if (endpoint.isNotEmpty) {
      if (endpoints[endpoint] case final entry?) return merge(entry, endpoint);
    }
    for (final MapEntry(:key, :value) in endpoints.entries) {
      if (!_standardEndpoints.contains(key) && _normalize(key) == normalized) {
        return merge(value, key);
      }
    }
    if (endpoints[_customKey] case final entry?) return merge(entry, endpoint);
    if (endpoints[_agentsKey] case final entry?) return merge(entry, endpoint);
    return fallback;
  }

  for (final key in [?endpointType, endpoint, normalized]) {
    if (key.isEmpty) continue;
    if (endpoints[key] case final entry?) return merge(entry, key);
  }
  final isAgents =
      (normalizedType.isNotEmpty ? normalizedType : normalized) == _agentsKey;
  final agents = endpoints[_agentsKey];
  if (isAgents && agents != null) return merge(agents, _agentsKey);
  return fallback;
}

RegExp? _compile(String source) {
  try {
    return RegExp(source);
  } on FormatException {
    return null;
  }
}

/// How one attachment reaches the model (Req 26.5).
enum UploadRoute {
  /// The provider reads the file itself. No `tool_resource` is sent, which
  /// is what every attachment did before the choice existed.
  provider,

  /// The Server extracts the file to text and injects it each turn.
  text;

  /// The `tool_resource` form field an upload on this route carries; null
  /// on [provider], where upstream sends no such field at all.
  String? get toolResource => this == text ? 'context' : null;
}

/// The `application/*` types the Server can read as plain text
/// (`file-config.ts` `textualApplicationTypes`).
const _textualApplicationTypes = {
  'application/json',
  'application/xml',
  'application/yaml',
  'application/sql',
  'application/typescript',
  'application/x-sh',
  'application/csv',
};

/// The types the Server's built-in document parser extracts
/// (`file-config.ts` `documentParserMimeTypes`).
final _documentParserTypes = [
  RegExp(
    r'^application/(vnd\.ms-excel|msexcel|x-msexcel|x-ms-excel|x-excel|'
    r'x-dos_ms_excel|xls|x-xls|'
    r'vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet)$',
  ),
  RegExp(r'^application/pdf$'),
  RegExp(
    r'^application/vnd\.openxmlformats-officedocument\.'
    r'wordprocessingml\.document$',
  ),
  RegExp(r'^application/vnd\.oasis\.opendocument\.spreadsheet$'),
  RegExp(r'^application/vnd\.oasis\.opendocument\.text$'),
];

/// Whether the Server can turn [mimeType] into text: the `text/` tree, the
/// types its document parser reads (PDF, Word, Excel, OpenDocument) and the
/// textual `application/` types (KMP `isTextExtractable`).
bool isTextExtractable(String mimeType) =>
    mimeType.startsWith('text/') ||
    _textualApplicationTypes.contains(mimeType) ||
    _documentParserTypes.any((p) => p.hasMatch(mimeType));

/// Whether [file] may be delivered as extracted text (Req 26.5).
///
/// An image never is: the Server's attachment pass stops at the extracted
/// text and the model would see no image at all. Everything else must be a
/// type the Server can extract and one `fileConfig.text` accepts — the
/// text path has its own list, not the endpoint's provider allowlist. An
/// empty or absent list closes the path, as the Server's own `checkType`
/// does, rather than opening it the way an empty endpoint allowlist does.
bool canDeliverAsText(FileInfo file, FileConfig config) {
  if (file.mimeType.startsWith('image/')) return false;
  if (!isTextExtractable(file.mimeType)) return false;
  final patterns = [
    for (final source in config.text?.supportedMimeTypes ?? const <String>[])
      ?_compile(source),
  ];
  return patterns.any((p) => p.hasMatch(file.mimeType));
}

/// The message a rejected set shows, naming the broken limit (Req 26.3).
/// [endpoint] and [endpointType] are the ones [checkAttachments] was given,
/// so the named figure is the limit that actually applied.
String attachmentLimitMessage(
  AttachmentRejected rejection,
  FileConfig config,
  String endpoint, {
  String? endpointType,
}) {
  final limits = _resolveLimits(config, endpoint, endpointType);
  final name = rejection.fileName ?? 'This file';
  return switch (rejection.limit) {
    // KMP com_ui_attach_error_disabled
    AttachmentLimit.disabled => 'File uploads are off for this endpoint.',
    AttachmentLimit.fileLimit =>
      'You can attach at most ${limits.fileLimit} files at a time.',
    AttachmentLimit.fileSizeLimit =>
      '$name is larger than the server limit of '
          '${formatByteSize(limits.fileSizeLimit ?? 0)}.',
    AttachmentLimit.totalSizeLimit =>
      'The attachments are larger than the server limit of '
          '${formatByteSize(limits.totalSizeLimit ?? 0)} in total.',
    AttachmentLimit.mimeType => '$name is not a type this endpoint accepts.',
  };
}

const _sizeUnits = ['KB', 'MB', 'GB', 'TB'];

/// [bytes] as a short size, one decimal at most (KMP `formatByteSize`).
String formatByteSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  var value = bytes / 1024;
  var unit = 0;
  // Roll up while the value would print as 1024 at one decimal, so 1023.99
  // KB reads as 1 MB instead of "1024 KB".
  while (value >= 1023.95 && unit < _sizeUnits.length - 1) {
    value /= 1024;
    unit++;
  }
  final tenths = (value * 10).round();
  final text = tenths % 10 == 0 ? '${tenths ~/ 10}' : (tenths / 10).toString();
  return '$text ${_sizeUnits[unit]}';
}

/// One attachment the Composer holds (Req 26.6-26.8).
///
/// [uploaded] is the Server's answer, which the next message carries; until
/// it arrives the chip shows [progress] and can cancel, and [error] offers
/// a retry. A file picked from the Files_Manager is already on the Server,
/// so it starts uploaded and keeps no [bytes].
@immutable
final class StagedAttachment {
  const StagedAttachment({
    required this.fileId,
    required this.info,
    this.route = UploadRoute.provider,
    this.bytes,
    this.progress,
    this.uploaded,
    this.error,
  });

  /// The uuid sent as `file_id`, and the attachment's identity in the
  /// Composer. A file already on the Server keeps the Server's id.
  final String fileId;
  final FileInfo info;
  final UploadRoute route;

  /// The bytes, kept for the upload and for a retry; null once the file is
  /// on the Server.
  final Uint8List? bytes;

  /// The share of the file sent so far, or null before the first report.
  final double? progress;
  final Attachment? uploaded;
  final String? error;

  String get name => info.name;
  bool get isImage => info.mimeType.startsWith('image/');

  /// Whether the upload is still running, which holds back Send (Req 26.7).
  bool get isUploading => uploaded == null && error == null;

  StagedAttachment copyWith({
    UploadRoute? route,
    double? progress,
    Attachment? uploaded,
    String? error,
    bool clearProgress = false,
    bool clearError = false,
  }) => StagedAttachment(
    fileId: fileId,
    info: info,
    route: route ?? this.route,
    bytes: bytes,
    progress: clearProgress ? null : progress ?? this.progress,
    uploaded: uploaded ?? this.uploaded,
    error: clearError ? null : error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is StagedAttachment &&
      other.fileId == fileId &&
      other.info == info &&
      other.route == route &&
      other.bytes == bytes &&
      other.progress == progress &&
      other.uploaded == uploaded &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(fileId, info, route, bytes, progress, uploaded, error);

  @override
  String toString() =>
      'StagedAttachment($name, ${route.name}, '
      '${uploaded != null ? 'uploaded' : error ?? 'uploading'})';
}

/// Where the Composer takes an attachment from (Req 26.1). Files already on
/// the Server come through `attachServerFiles` instead, which the
/// Files_Manager's picker mode calls once that screen lands.
enum AttachSource {
  files('Files', Icons.insert_drive_file_outlined), // KMP tool_files
  photos('Photos', Icons.photo_library_outlined), // KMP tool_photos
  camera('Camera', Icons.photo_camera_outlined); // KMP tool_camera

  const AttachSource(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The Composer's attach button, which offers the [AttachSource]s
/// (Req 26.1, KMP cd_attach_file).
class AttachButton extends StatelessWidget {
  const AttachButton({super.key, required this.onSource, this.enabled = true});

  final ValueChanged<AttachSource> onSource;

  /// False while the endpoint takes no uploads, where the button stays
  /// visible but does nothing.
  final bool enabled;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AttachSource>(
    enabled: enabled,
    tooltip: 'Attach file', // KMP cd_attach_file
    icon: const Icon(Icons.add),
    onSelected: onSource,
    itemBuilder: (context) => [
      for (final source in AttachSource.values)
        PopupMenuItem(
          value: source,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(source.icon),
            title: Text(source.label),
          ),
        ),
    ],
  );
}

/// The attachment chips above the Composer's text field (Req 26.6-26.8).
///
/// A chip uploading shows its progress and cancels on the X; a failed one
/// shows the error, retries on a tap and drops on the X; a finished one
/// only drops.
class AttachmentChips extends StatelessWidget {
  const AttachmentChips({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onCancel,
    required this.onRetry,
  });

  final List<StagedAttachment> files;
  final ValueChanged<StagedAttachment> onRemove;
  final ValueChanged<StagedAttachment> onCancel;
  final ValueChanged<StagedAttachment> onRetry;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          for (final file in files)
            InputChip(
              key: ValueKey(file.fileId),
              avatar: _Status(file: file, colors: colors),
              label: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // A chip is as wide as its label, which a long filename makes
              // wider than the screen.
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tooltip: file.error,
              onPressed: file.error == null ? null : () => onRetry(file),
              deleteIcon: const Icon(Icons.close, size: 18),
              deleteButtonTooltipMessage: file.isUploading
                  ? 'Cancel upload' // KMP cd_cancel_upload
                  : 'Remove ${file.name}', // KMP cd_remove_file
              onDeleted: () =>
                  file.isUploading ? onCancel(file) : onRemove(file),
              backgroundColor: file.error == null
                  ? null
                  : colors.errorContainer,
            ),
        ],
      ),
    );
  }
}

/// A chip's leading glyph: the upload's progress, a failure, the text-route
/// badge, or the file's kind.
class _Status extends StatelessWidget {
  const _Status({required this.file, required this.colors});

  final StagedAttachment file;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (file.isUploading) {
      return Semantics(
        label: 'Uploading ${file.name}', // KMP cd_uploading_file
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: file.progress,
          ),
        ),
      );
    }
    if (file.error != null) {
      return Icon(
        Icons.error_outline,
        color: colors.onErrorContainer,
        semanticLabel: 'Upload failed, tap to retry', // KMP cd_retry_upload
      );
    }
    // Only the text route is marked: the provider route is what every
    // attachment has always done, so labelling it would be noise.
    if (file.route == UploadRoute.text) {
      return Icon(
        Icons.notes,
        color: colors.tertiary,
        semanticLabel: 'Sent as text', // KMP cd_upload_route_text
      );
    }
    return Icon(
      file.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
      semanticLabel: 'Attached file: ${file.name}', // KMP cd_attached_file
    );
  }
}

/// Asks how each of [files] should be delivered before anything is
/// uploaded (Req 26.5), and answers one route per file in the same order,
/// or null when the user backed out.
///
/// [choosable] marks, per file, whether both routes are open. A file with
/// one usable route is still listed, with its control disabled: the user
/// picked it, and leaving it out reads as having dropped it.
Future<List<UploadRoute>?> showDeliverySheet(
  BuildContext context, {
  required List<FileInfo> files,
  required List<bool> choosable,
}) => showModalBottomSheet<List<UploadRoute>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => _DeliverySheet(files: files, choosable: choosable),
);

/// The delivery sheet (KMP UploadRoutingSheet.kt). A sheet rather than a
/// dialog so a long pick keeps its buttons reachable.
class _DeliverySheet extends StatefulWidget {
  const _DeliverySheet({required this.files, required this.choosable});

  final List<FileInfo> files;
  final List<bool> choosable;

  @override
  State<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<_DeliverySheet> {
  late final List<UploadRoute> _routes = [
    // A file with one route is already on it: the only reason it is not
    // choosable is that text delivery is closed for its type.
    for (final _ in widget.files) UploadRoute.provider,
  ];

  int get _choosableCount => widget.choosable.where((c) => c).length;

  void _applyToAll(UploadRoute route) => setState(() {
    for (var i = 0; i < _routes.length; i++) {
      if (widget.choosable[i]) _routes[i] = route;
    }
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.files.length == 1
                    ? 'How should this be sent?' // KMP title_single
                    : 'How should these be sent?', // KMP title
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.files.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _DeliveryRow(
                  file: widget.files[index],
                  route: _routes[index],
                  choosable: widget.choosable[index],
                  onChanged: (route) => setState(() => _routes[index] = route),
                ),
              ),
            ),
            if (_choosableCount > 1)
              Row(
                children: [
                  Text(
                    'Use for all', // KMP upload_routing_apply_all
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _applyToAll(UploadRoute.provider),
                    child: const Text('To the model'),
                  ),
                  TextButton(
                    onPressed: () => _applyToAll(UploadRoute.text),
                    child: const Text('As text'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'), // KMP cancel
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_routes),
                  child: const Text('Attach'), // KMP upload_routing_attach
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One file's row in the delivery sheet: its name, the two routes and one
/// line saying what each actually does.
class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.file,
    required this.route,
    required this.choosable,
    required this.onChanged,
  });

  final FileInfo file;
  final UploadRoute route;
  final bool choosable;
  final ValueChanged<UploadRoute> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          file.name,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        SegmentedButton<UploadRoute>(
          selected: {route},
          onSelectionChanged: choosable
              ? (selected) => onChanged(selected.first)
              : null,
          segments: const [
            ButtonSegment(
              value: UploadRoute.provider,
              label: Text('To the model'), // KMP option_provider
            ),
            ButtonSegment(
              value: UploadRoute.text,
              label: Text('As text'), // KMP option_text
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          switch ((choosable, route)) {
            // KMP routeExplanation
            (false, UploadRoute.provider) =>
              'This model can only take this file directly.',
            (false, _) =>
              "This model can't read this file, so its text is sent instead.",
            (_, UploadRoute.provider) => 'The model reads the file itself.',
            (_, _) => 'The server reads the file and sends its text.',
          },
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
