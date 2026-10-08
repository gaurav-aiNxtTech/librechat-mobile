import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/features/chat/composer/attachments.dart';

import '../../../support/property.dart';

/// The entry the Server's `getEndpointFileConfig` picks for each generated
/// endpoint, and whether the Server would fill its missing patterns from the
/// built-in list (a document-supported provider), which the check skips.
(EndpointFileConfig?, bool) _entry(FileConfig config, String endpoint) {
  final e = config.endpoints;
  return switch (endpoint) {
    'openAI' => (e['openAI'], true),
    'agents' => (e['agents'], false),
    'custom' => (e['custom'] ?? e['agents'], true),
    _ => (e[endpoint] ?? e['custom'] ?? e['agents'], false),
  };
}

/// The limits each file set breaks, in the check's order. Empty means the
/// reference predicate accepts.
List<AttachmentLimit> _broken(
  List<FileInfo> files,
  FileConfig config,
  String endpoint,
) {
  final fallback = config.endpoints['default'];
  final (entry, documentSupported) = _entry(config, endpoint);
  final disabled = entry?.disabled ?? fallback?.disabled ?? false;
  final fileLimit = entry?.fileLimit ?? fallback?.fileLimit;
  final fileSizeLimit = entry?.fileSizeLimit ?? fallback?.fileSizeLimit;
  final totalSizeLimit = entry?.totalSizeLimit ?? fallback?.totalSizeLimit;
  final own = entry?.supportedMimeTypes ?? const <String>[];
  final sources = own.isNotEmpty
      ? own
      : (entry != null && documentSupported)
      ? const <String>[]
      : fallback?.supportedMimeTypes ?? const <String>[];
  final patterns = sources.map(RegExp.new).toList();
  final total = files.fold(0, (sum, f) => sum + f.size);
  return [
    if (disabled) AttachmentLimit.disabled,
    // 0 means no check for the count and the total, a real limit per file.
    if (fileLimit case final limit? when limit > 0 && files.length > limit)
      AttachmentLimit.fileLimit,
    if (fileSizeLimit case final limit? when files.any((f) => f.size > limit))
      AttachmentLimit.fileSizeLimit,
    if (totalSizeLimit case final limit? when limit > 0 && total > limit)
      AttachmentLimit.totalSizeLimit,
    if (patterns.isNotEmpty &&
        !files.every((f) => patterns.any((p) => p.hasMatch(f.mimeType))))
      AttachmentLimit.mimeType,
  ];
}

void main() {
  // Feature: flutter-android-rewrite, Property 10: For any attachment set and FileConfig limits, the Composer's attachment check accepts the set exactly when a reference predicate does: the file count, every file size and the total size are within the selected endpoint's limits, and every MIME type matches an accepted pattern.
  // Validates: Requirements 26.4
  test('Property 10: Attachment acceptance matches its model', () async {
    await forAll(attachmentCaseGen, (c) {
      final verdict = checkAttachments(c.files, c.config, c.endpoint);
      final broken = _broken(c.files, c.config, c.endpoint);
      expect(verdict is AttachmentAccepted, broken.isEmpty, reason: '$verdict');
      if (verdict case AttachmentRejected(:final limit)) {
        expect(limit, broken.first);
      }
    });
  });
}
