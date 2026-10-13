import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/models/attachment.dart';
import '../../../core/network/api_client.dart';

/// The app's [FileDownloads]. `main()` builds it after the ApiClient and
/// overrides this provider.
final fileDownloadsProvider = Provider<FileDownloads>(
  (ref) => throw UnimplementedError('fileDownloadsProvider is not overridden'),
);

/// The Server path that serves [attachment]'s bytes, or null when it has
/// none: `GET /api/files/download/{userId}/{file_id}` when both ids are
/// known, otherwise an absolute `filepath`.
String? attachmentDownloadPath(Attachment attachment, String? userId) {
  final fileId = attachment.fileId;
  if (fileId != null && fileId.isNotEmpty && userId != null) {
    return '/api/files/download/${Uri.encodeComponent(userId)}/'
        '${Uri.encodeComponent(fileId)}';
  }
  final path = attachment.filepath;
  if (path != null && path.startsWith(RegExp('https?://'))) return path;
  return null;
}

/// [name] without directories or characters a file system rejects, so a
/// Server-sent filename can't leave the download directory.
String safeFileName(String name) {
  final base = name.split(RegExp(r'[/\\]')).last.trim();
  final clean = base.replaceAll(RegExp(r'[\x00-\x1f:*?"<>|]'), '_');
  return clean.isEmpty || clean == '.' || clean == '..' ? 'file' : clean;
}

/// Downloads files through [ApiClient], so auth and Custom_Headers stay in
/// the one transport, and writes them under [_dir] (`<app cache>/downloads`)
/// for open_filex and the media players (Req 23.6, 23.8).
///
/// Each file goes in a folder named by the SHA-256 of its source, so its
/// own name survives for the app that opens it and two files with one name
/// don't collide.
class FileDownloads {
  FileDownloads(this._api, this._dir, {required this._currentUser});

  final ApiClient _api;
  final Directory _dir;
  final String? Function() _currentUser;

  /// The bytes at [url], a Server-relative path or an absolute URL, with no
  /// request timeout. Request failures throw AppException.
  Future<Uint8List> bytes(String url) async {
    final response = await _api.send(
      'GET',
      url,
      type: ResponseType.bytes,
      transfer: true,
    );
    final data = response.data;
    return data is Uint8List
        ? data
        : Uint8List.fromList(data as List<int>? ?? const []);
  }

  /// Writes [bytes] as [fileName] in the folder for [key], by default the
  /// bytes themselves, so the same inline media maps to one file.
  Future<File> save(Uint8List bytes, String fileName, {String? key}) async {
    final digest = key == null
        ? sha256.convert(bytes)
        : sha256.convert(utf8.encode(key));
    final folder = digest.toString().substring(0, 16);
    final file = File(p.join(_dir.path, folder, safeFileName(fileName)));
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Downloads [url] to a local file named [fileName].
  Future<File> download(String url, String fileName) async =>
      save(await bytes(url), fileName, key: url);

  /// The bytes of [attachment]. Throws [StateError] when it has no download
  /// path, which the cards rule out before offering the action.
  Future<Uint8List> attachmentBytes(Attachment attachment) =>
      bytes(_pathOf(attachment));

  /// [attachment] downloaded to a local file under its own name.
  Future<File> attachmentFile(Attachment attachment, String fileName) =>
      download(_pathOf(attachment), fileName);

  /// Whether [attachment] can be downloaded for the signed-in user.
  bool canDownload(Attachment attachment) =>
      attachmentDownloadPath(attachment, _currentUser()) != null;

  String _pathOf(Attachment attachment) =>
      attachmentDownloadPath(attachment, _currentUser()) ??
      (throw StateError('No download path for ${attachment.fileId}'));
}
