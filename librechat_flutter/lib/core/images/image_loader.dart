import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../network/api_client.dart';
import '../network/server_url.dart';

/// The app's [ImageLoader]. `main()` builds it after the ApiClient and
/// overrides this provider.
final imageLoaderProvider = Provider<ImageLoader>(
  (ref) => throw UnimplementedError('imageLoaderProvider is not overridden'),
);

/// An image's bytes, and whether they are SVG rather than a raster format.
typedef LoadedImage = ({Uint8List bytes, bool svg});

/// Loads image bytes for AppImage: memory LRU, then a file in [_dir], then
/// one GET through [ApiClient.send], so image requests get the same per-hop
/// headers, redirect rules and gateway check as REST (Req 4.2–4.4).
///
/// Files are named by the SHA-256 of the absolute URL, with `.svg` added when
/// the bytes are SVG so the type survives a restart. Nothing expires on its
/// own; [clear] serves "Clear cache" (Req 41.4).
class ImageLoader {
  ImageLoader(this._api, this._dir, {this.maxMemoryBytes = 64 * 1024 * 1024});

  final ApiClient _api;
  final Directory _dir;

  /// The memory LRU's cap on the total bytes it holds.
  final int maxMemoryBytes;

  // Insertion-ordered, so the first key is the least recently used.
  final _memory = <String, LoadedImage>{};
  var _memoryBytes = 0;
  final _inFlight = <String, Future<LoadedImage>>{};

  // Bumped by [clear], so a load that was in flight doesn't refill the caches.
  var _generation = 0;

  /// The image at [url]: a Server-relative path such as
  /// `/images/u1/avatar.png`, an absolute URL, or a `data:` URI, which is
  /// decoded in place and not cached. Concurrent loads of one URL share one
  /// Future. Request failures throw AppException.
  Future<LoadedImage> load(String url) {
    if (url.startsWith(_dataScheme)) return Future.sync(() => _decode(url));
    final absolute = serverUri(_api.serverUrl ?? '', url).toString();
    final cached = _memory.remove(absolute);
    if (cached != null) {
      _memory[absolute] = cached;
      return Future.value(cached);
    }
    return _inFlight[absolute] ??= _fetch(absolute).whenComplete(() {
      // A block body: returning the removed Future would make this one wait
      // on itself.
      _inFlight.remove(absolute);
    });
  }

  /// Empties the memory cache and deletes every cached file.
  Future<void> clear() async {
    _generation++;
    _memory.clear();
    _memoryBytes = 0;
    try {
      await _dir.delete(recursive: true);
    } on PathNotFoundException {
      // Nothing was cached on disk yet.
    }
  }

  /// Whether [bytes] start with `<svg` or `<?xml`, after an optional UTF-8
  /// byte order mark and whitespace.
  static bool isSvgBytes(Uint8List bytes) {
    var i = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      i = 3;
    }
    while (i < bytes.length &&
        const [0x20, 0x09, 0x0A, 0x0D].contains(bytes[i])) {
      i++;
    }
    final head = String.fromCharCodes(
      bytes,
      i,
      min(i + 5, bytes.length),
    ).toLowerCase();
    return head.startsWith('<svg') || head.startsWith('<?xml');
  }

  Future<LoadedImage> _fetch(String url) async {
    final generation = _generation;
    final name = sha256.convert(utf8.encode(url)).toString();
    final rasterFile = File(p.join(_dir.path, name));
    final svgFile = File(p.join(_dir.path, '$name.svg'));

    LoadedImage? image;
    final raster = await _read(rasterFile);
    if (raster != null) {
      image = (bytes: raster, svg: false);
    } else {
      final svg = await _read(svgFile);
      if (svg != null) image = (bytes: svg, svg: true);
    }

    if (image == null) {
      final response = await _api.send(
        'GET',
        url,
        type: ResponseType.bytes,
        transfer: true,
      );
      final data = response.data;
      final bytes = data is Uint8List
          ? data
          : Uint8List.fromList(data as List<int>? ?? const []);
      final svg =
          _isSvgType(response.headers.value('content-type')) ||
          isSvgBytes(bytes);
      image = (bytes: bytes, svg: svg);
      if (generation == _generation) {
        await _write(svg ? svgFile : rasterFile, bytes);
      }
    }

    if (generation == _generation) _remember(url, image);
    return image;
  }

  void _remember(String url, LoadedImage image) {
    final size = image.bytes.length;
    if (size > maxMemoryBytes) return;
    final old = _memory.remove(url);
    if (old != null) _memoryBytes -= old.bytes.length;
    _memory[url] = image;
    _memoryBytes += size;
    while (_memoryBytes > maxMemoryBytes) {
      final oldest = _memory.keys.first;
      _memoryBytes -= _memory.remove(oldest)!.bytes.length;
    }
  }

  static Future<Uint8List?> _read(File file) async {
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Writes through a temporary file and a rename, so a reader never sees a
  /// partial file. A failed write only costs the disk copy.
  Future<void> _write(File file, Uint8List bytes) async {
    try {
      await _dir.create(recursive: true);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } on FileSystemException {
      // The image still loads; it is fetched again next time.
    }
  }

  static LoadedImage _decode(String url) {
    final data = UriData.parse(url);
    final bytes = data.contentAsBytes();
    return (bytes: bytes, svg: _isSvgType(data.mimeType) || isSvgBytes(bytes));
  }

  static bool _isSvgType(String? type) =>
      type != null && type.toLowerCase().startsWith('image/svg');

  static final _dataScheme = RegExp('data:', caseSensitive: false);
}
