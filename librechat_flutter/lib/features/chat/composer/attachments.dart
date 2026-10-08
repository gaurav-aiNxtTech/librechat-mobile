import 'package:mime/mime.dart';

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
///
/// The limits are `endpoints[endpoint] ?? endpoints['default']`, taken as a
/// whole entry; with neither, the set passes. The set passes exactly when
/// uploads are not disabled, the count is within `fileLimit`, each size is
/// within `fileSizeLimit`, the sum is within `totalSizeLimit`, and each mime
/// type matches one of `supportedMimeTypes`. A null limit or an empty
/// pattern list does not restrict, and a limit of 0 does. A pattern that is
/// not a valid regex is ignored (the KMP check fails open the same way). A
/// rejection names the first broken limit, in that order.
AttachmentVerdict checkAttachments(
  List<FileInfo> files,
  FileConfig config,
  String endpoint,
) {
  final limits = config.endpoints[endpoint] ?? config.endpoints['default'];
  if (limits == null) return const AttachmentAccepted();
  if (limits.disabled) {
    return const AttachmentRejected(AttachmentLimit.disabled);
  }

  final fileLimit = limits.fileLimit;
  if (fileLimit != null && files.length > fileLimit) {
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
  if (totalSizeLimit != null) {
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

RegExp? _compile(String source) {
  try {
    return RegExp(source);
  } on FormatException {
    return null;
  }
}
