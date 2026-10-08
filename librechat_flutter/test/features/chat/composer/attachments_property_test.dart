import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/features/chat/composer/attachments.dart';

import '../../../support/property.dart';

/// The limits each file set breaks, in the check's order. Empty means the
/// reference predicate accepts.
List<AttachmentLimit> _broken(
  List<FileInfo> files,
  FileConfig config,
  String endpoint,
) {
  final entry = config.endpoints[endpoint] ?? config.endpoints['default'];
  if (entry == null) return const [];
  final total = files.fold(0, (sum, f) => sum + f.size);
  final patterns = entry.supportedMimeTypes.map(RegExp.new).toList();
  return [
    if (entry.disabled) AttachmentLimit.disabled,
    if (entry.fileLimit case final limit? when files.length > limit)
      AttachmentLimit.fileLimit,
    if (entry.fileSizeLimit case final limit?
        when files.any((f) => f.size > limit))
      AttachmentLimit.fileSizeLimit,
    if (entry.totalSizeLimit case final limit? when total > limit)
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
