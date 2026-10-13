import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/auth/auth_service.dart';
import '../../core/models/file_config.dart';
import '../../core/network/api_client.dart';

part 'files_api.freezed.dart';
part 'files_api.g.dart';

/// A file on the Server, as `GET /api/files` lists it and `POST /api/files`
/// answers one upload (Req 26.6, 37.1).
@freezed
abstract class FileObject with _$FileObject {
  const factory FileObject({
    @JsonKey(name: 'file_id') String? fileId,
    String? filename,
    String? filepath,
    String? type,
    int? bytes,
    int? width,
    int? height,
    String? source,
    String? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FileObject;

  factory FileObject.fromJson(Map<String, Object?> json) =>
      _$FileObjectFromJson(json);
}

/// The [FilesApi] on the app's [ApiClient]. Tests override it.
final filesApiProvider = Provider<FilesApi>(
  (ref) => FilesApi(ref.read(apiClientProvider)),
);

/// The Server's upload limits, loaded once per session (Req 26.2).
///
/// Kept for the session and reloaded when the user or the Server_URL
/// changes. The value is already merged: megabytes converted to bytes and
/// the Server's built-in entries filled in (see [mergeFileConfig]).
///
/// A failed load leaves readers on [builtInFileConfig], as the web client's
/// `useGetFileConfig` does, so a Server that cannot answer does not block
/// attaching.
final fileConfigProvider = FutureProvider<FileConfig>((ref) {
  ref.watch(authServiceProvider.select((a) => a.session?.user.id));
  ref.watch(authServiceProvider.select((a) => a.serverUrl));
  return ref.read(filesApiProvider).config();
});

/// The file routes: the upload limits, and one upload per file.
class FilesApi {
  FilesApi(this._api);

  final ApiClient _api;

  /// `GET /api/files/config`, merged by [mergeFileConfig] (Req 26.2).
  ///
  /// The Server answers with the administrator's `fileConfig` block as it
  /// is, and with nothing at all when there is none.
  Future<FileConfig> config() => _api.json(
    'GET',
    '/api/files/config',
    (json) => mergeFileConfig(
      json is Map ? FileConfig.fromJson(json.cast<String, Object?>()) : null,
    ),
  );

  /// `POST /api/files`: one file as multipart (Req 26.6).
  ///
  /// [fileId] is the uuid the App mints, which the Server stores and the
  /// message then references. [toolResource] is `context` for a file the
  /// user chose to deliver as extracted text (Req 26.5) and null for the
  /// provider's own path, where upstream sends no such field.
  /// [width] and [height] go with an image.
  ///
  /// [onProgress] reports sent and total bytes for the chip's progress, and
  /// [cancelToken] backs its cancel action. Like the web client's uploads
  /// this one has no request timeout; only a stalled connection or the
  /// user's cancel ends it early.
  Future<FileObject> upload({
    required Uint8List bytes,
    required String filename,
    required String type,
    required String fileId,
    String? endpoint,
    String? model,
    String? agentId,
    String? toolResource,
    bool messageFile = true,
    int? width,
    int? height,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(uploadMimeType(type)),
      ),
      'file_id': fileId,
      'endpoint': ?endpoint,
      'model': ?model,
      'agent_id': ?agentId,
      'tool_resource': ?toolResource,
      'message_file': '$messageFile',
      if (width != null) 'width': '$width',
      if (height != null) 'height': '$height',
    });
    return _api.json(
      'POST',
      '/api/files',
      (json) => FileObject.fromJson((json! as Map).cast<String, Object?>()),
      data: form,
      transfer: true,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}

/// Platform mime spellings the Server has never heard of, rewritten for the
/// multipart part's `Content-Type` (KMP `uploadMimeType`).
///
/// Only these: the Server normalizes its own aliases on receipt, and every
/// one of them already clears its upload filter, so rewriting those would
/// change what it records for no reason.
const _platformMimeTypes = {
  // Android's DocumentsProvider for `.sh`, which the Server answers 415 for.
  'text/x-sh': 'application/x-sh',
};

/// The mime type an upload of a file the platform reported as [type] sends.
/// Mime parameters are kept: this rewrites a type, it does not sanitize a
/// header.
String uploadMimeType(String type) {
  final raw = type.trim();
  if (raw.isEmpty) return 'application/octet-stream';
  final semicolon = raw.indexOf(';');
  final bare = (semicolon < 0 ? raw : raw.substring(0, semicolon)).trim();
  final replacement = _platformMimeTypes[bare];
  if (replacement == null) return raw;
  return semicolon < 0
      ? replacement
      : '$replacement${raw.substring(semicolon)}';
}

/// One megabyte, the unit the Server's `fileConfig` block is written in.
const megabyte = 1024 * 1024;

/// The Server's built-in `supportedMimeTypes`, the regex sources of
/// `file-config.ts` `supportedMimeTypes` in order.
///
/// The Server applies these to every endpoint that configures none of its
/// own, so the App carries them to reject a type the Server would reject
/// (Req 26.3) instead of failing the upload.
const builtInSupportedMimeTypes = <String>[
  // textMimeTypes
  r'^(text/(x-c|x-csharp|tab-separated-values|x-c\+\+|x-h|x-java|html|'
      r'markdown|x-php|x-python|x-script\.python|x-ruby|x-tex|plain|css|vtt|'
      r'javascript|csv|xml|calendar))$',
  // excelMimeTypes
  r'^application/(vnd\.ms-excel|msexcel|x-msexcel|x-ms-excel|x-excel|'
      r'x-dos_ms_excel|xls|x-xls|'
      r'vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet)$',
  // applicationMimeTypes
  r'^(application/(epub\+zip|csv|json|msword|pdf|x-tar|x-sh|'
      r'x-zip-compressed|typescript|sql|yaml|x-parquet|vnd\.apache\.parquet|'
      r'vnd\.coffeescript|vnd\.openxmlformats-officedocument\.'
      r'(wordprocessingml\.document|presentationml\.(presentation|template)|'
      r'spreadsheetml\.sheet)|'
      r'vnd\.oasis\.opendocument\.(text|spreadsheet|presentation|graphics)|'
      r'xml|zip))$',
  // imageMimeTypes
  r'^image/(jpeg|gif|png|webp|heic|heif)$',
  // videoMimeTypes
  r'^video/(mp4|avi|mov|wmv|flv|webm|mkv|m4v|3gp|ogv)$',
  // audioMimeTypes
  r'^audio/(mp3|mpeg|mpeg3|wav|wave|x-wav|ogg|vorbis|mp4|m4a|x-m4a|flac|'
      r'x-flac|webm|aac|wma|opus)$',
  // Supported by the LibreChat Code Interpreter API.
  r'^image/(svg|svg\+xml)$',
  // .eml email files.
  r'^message/rfc822$',
];

/// The Server's built-in `text.supportedMimeTypes` (`defaultTextMimeTypes`):
/// any well-formed mime type, so text delivery is open unless an
/// administrator narrows it.
const builtInTextMimeTypes = <String>[r'^[\w.-]+/[\w.-]+$'];

const _defaultSizeLimit = 512 * megabyte;

const _builtInEntry = EndpointFileConfig(
  fileLimit: 10,
  fileSizeLimit: _defaultSizeLimit,
  totalSizeLimit: _defaultSizeLimit,
  supportedMimeTypes: builtInSupportedMimeTypes,
  disabled: false,
);

/// The Server's own defaults, which apply when it serves no `fileConfig`
/// (`file-config.ts` `fileConfig`). Sizes are bytes.
const builtInFileConfig = FileConfig(
  endpoints: {
    'default': _builtInEntry,
    'agents': _builtInEntry,
    'assistants': _builtInEntry,
    'azureAssistants': _builtInEntry,
    'anthropic': _builtInEntry,
  },
  serverFileSizeLimit: _defaultSizeLimit,
  text: MimeTypesConfig(supportedMimeTypes: builtInTextMimeTypes),
);

/// [served] over [builtInFileConfig], the way the web client's
/// `mergeFileConfig` does before anything reads the limits (Req 26.2).
///
/// `GET /api/files/config` answers with the administrator's `librechat.yaml`
/// `fileConfig` block unchanged, so its `fileSizeLimit`, `totalSizeLimit`
/// and `serverFileSizeLimit` are **megabytes** and are converted here;
/// `fileLimit` is a count and is not. Null [served] (no `fileConfig` at all)
/// leaves the built-in config.
///
/// Each served entry overrides the built-in entry of the same name field by
/// field, and an entry the Server has no built-in for starts empty — not
/// from `default`, which is what `checkAttachments` resolves against at
/// check time. `disabled: true` zeroes the limits and empties the pattern
/// list, as the Server does, which `checkAttachments` then reports as the
/// disabled limit.
FileConfig mergeFileConfig(FileConfig? served) {
  if (served == null) return builtInFileConfig;
  final endpoints = {...builtInFileConfig.endpoints};
  for (final MapEntry(:key, value: entry) in served.endpoints.entries) {
    final base = endpoints[key] ?? const EndpointFileConfig();
    if (entry.disabled ?? false) {
      endpoints[key] = const EndpointFileConfig(
        disabled: true,
        fileLimit: 0,
        fileSizeLimit: 0,
        totalSizeLimit: 0,
      );
      continue;
    }
    endpoints[key] = EndpointFileConfig(
      disabled: entry.disabled ?? base.disabled,
      fileLimit: entry.fileLimit ?? base.fileLimit,
      fileSizeLimit: _bytes(entry.fileSizeLimit) ?? base.fileSizeLimit,
      totalSizeLimit: _bytes(entry.totalSizeLimit) ?? base.totalSizeLimit,
      supportedMimeTypes: entry.supportedMimeTypes.isNotEmpty
          ? entry.supportedMimeTypes
          : base.supportedMimeTypes,
    );
  }
  final text = served.text?.supportedMimeTypes;
  return FileConfig(
    endpoints: endpoints,
    serverFileSizeLimit:
        _bytes(served.serverFileSizeLimit) ??
        builtInFileConfig.serverFileSizeLimit,
    text: text == null || text.isEmpty
        ? builtInFileConfig.text
        : MimeTypesConfig(supportedMimeTypes: text),
  );
}

int? _bytes(int? megabytes) => megabytes == null ? null : megabytes * megabyte;
