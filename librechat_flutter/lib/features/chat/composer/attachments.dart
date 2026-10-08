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
