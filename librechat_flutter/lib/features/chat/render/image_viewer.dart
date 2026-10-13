import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../core/images/app_image.dart';
import '../../../core/images/image_loader.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/ui/platform_actions.dart';
import '../data/file_downloads.dart';

/// The file name an image saves and shares as: [name] when it has one, else
/// the URL's last segment when that has an extension, else `image` with the
/// extension of the bytes' type.
String imageFileName(String url, String? name, Uint8List bytes) {
  final given = name?.trim();
  if (given != null && given.isNotEmpty) return safeFileName(given);
  if (!url.startsWith('data:')) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final last = segments.isEmpty ? '' : segments.last;
    if (last.contains('.')) return safeFileName(last);
  }
  final mime = lookupMimeType('', headerBytes: bytes);
  final ext = mime == null ? null : extensionFromMime(mime);
  return 'image.${ext ?? (ImageLoader.isSvgBytes(bytes) ? 'svg' : 'png')}';
}

/// The MIME type of image [bytes] saved as [fileName].
String imageMimeType(String fileName, Uint8List bytes) =>
    lookupMimeType(fileName, headerBytes: bytes) ??
    (ImageLoader.isSvgBytes(bytes) ? 'image/svg+xml' : 'image/png');

/// Opens [url] in the fullscreen [ImageViewer] (Req 23.5).
Future<void> openImageViewer(
  BuildContext context,
  String url, {
  String? name,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => ImageViewer(url: url, name: name),
  ),
);

/// An image inline in a message (Req 23.4): at most 300 dp tall, with
/// rounded corners. A tap opens the [ImageViewer].
class InlineImage extends StatelessWidget {
  const InlineImage(
    this.url, {
    super.key,
    this.name,
    this.semanticLabel,
    this.width,
    this.height,
  });

  /// A Server-relative path, an absolute URL or a `data:` URI (AppImage).
  final String url;

  /// The file name the viewer saves and shares the image as.
  final String? name;

  /// Read by TalkBack; defaults to [name], then "Image" (KMP cd_image).
  final String? semanticLabel;

  /// The pixel size the Server reported, which reserves the image's space
  /// before it loads.
  final int? width;
  final int? height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = semanticLabel ?? name ?? 'Image'; // KMP cd_image
    Widget box(Widget child) => SizedBox(
      height: 120,
      width: double.infinity,
      child: ColoredBox(
        color: colors.surfaceContainerHigh,
        child: Center(child: child),
      ),
    );
    final w = width, h = height;
    Widget image = AppImage(
      url,
      fit: w != null && h != null ? BoxFit.cover : null,
      placeholder: box(
        const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: box(
        Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: colors.onSurfaceVariant,
          semanticLabel: 'Failed to load image', // KMP cd_failed_to_load_image
        ),
      ),
    );
    if (w != null && h != null && w > 0 && h > 0) {
      image = AspectRatio(aspectRatio: w / h, child: image);
    }
    return Semantics(
      button: true,
      image: true,
      label: label,
      excludeSemantics: true,
      // At least a 48 dp tap target, also while the bytes decode (Req 47.2).
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
          maxHeight: 300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => openImageViewer(context, url, name: name),
              child: image,
            ),
          ),
        ),
      ),
    );
  }
}

/// The fullscreen image viewer (Req 23.5): pinch zoom and pan through
/// InteractiveViewer, with Save (the document picker) and Share.
class ImageViewer extends ConsumerStatefulWidget {
  const ImageViewer({super.key, required this.url, this.name});

  final String url;
  final String? name;

  @override
  ConsumerState<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends ConsumerState<ImageViewer> {
  var _busy = false;

  Future<void> _run(
    Future<void> Function(String fileName, Uint8List bytes, String mime) act,
  ) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      // The loader's caches already hold the bytes the viewer shows.
      final image = await ref.read(imageLoaderProvider).load(widget.url);
      final name = imageFileName(widget.url, widget.name, image.bytes);
      await act(name, image.bytes, imageMimeType(name, image.bytes));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = ref.read(platformActionsProvider);
    final label = widget.name ?? 'Image'; // KMP cd_image
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close', // KMP cd_close
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: widget.name == null
              ? null
              : Text(
                  widget.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Save to device', // KMP cd_save_to_device
              onPressed: _busy
                  ? null
                  : () => _run(
                      (name, bytes, mime) => platform
                          .saveFile(
                            fileName: name,
                            bytes: bytes,
                            mimeType: mime,
                          )
                          .then((_) {}),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share image', // KMP cd_share_image
              onPressed: _busy
                  ? null
                  : () => _run(
                      (name, bytes, mime) => platform.shareFile(
                        fileName: name,
                        bytes: bytes,
                        mimeType: mime,
                      ),
                    ),
            ),
          ],
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Center(
              child: AppImage(
                widget.url,
                fit: BoxFit.contain,
                semanticLabel: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
