import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'image_loader.dart';

/// An image loaded through [imageLoaderProvider]: SVG renders with
/// [SvgPicture.memory] and everything else with [Image.memory].
///
/// While loading it shows [placeholder] or a neutral box; on failure it shows
/// [error] or a broken-image icon with a semantic label (Req 47.1).
class AppImage extends ConsumerStatefulWidget {
  const AppImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.semanticLabel,
    this.placeholder,
    this.error,
  });

  /// A Server-relative path, an absolute URL or a `data:` URI.
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  /// Read by TalkBack for the image and for the failure icon. Without one,
  /// the image is decorative and left out of semantics.
  final String? semanticLabel;
  final Widget? placeholder;
  final Widget? error;

  @override
  ConsumerState<AppImage> createState() => _AppImageState();
}

class _AppImageState extends ConsumerState<AppImage> {
  // One Future per URL, so a rebuild doesn't load again.
  late Future<LoadedImage> _image;

  @override
  void initState() {
    super.initState();
    _image = ref.read(imageLoaderProvider).load(widget.url);
  }

  @override
  void didUpdateWidget(AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _image = ref.read(imageLoaderProvider).load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(context);
        final image = snapshot.data;
        if (image == null) return _placeholder(context);
        final label = widget.semanticLabel;
        if (image.svg) {
          return SvgPicture.memory(
            image.bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.contain,
            semanticsLabel: label,
            excludeFromSemantics: label == null,
            placeholderBuilder: _placeholder,
            errorBuilder: (context, _, _) => _error(context),
          );
        }
        return Image.memory(
          image.bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          semanticLabel: label,
          excludeFromSemantics: label == null,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => _error(context),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) =>
      widget.placeholder ??
      SizedBox(
        width: widget.width,
        height: widget.height,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );

  Widget _error(BuildContext context) {
    if (widget.error case final error?) return error;
    // The icon never outgrows a small slot such as a 16 dp provider icon.
    final size = [widget.width, widget.height].nonNulls.fold(24.0, min);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: size,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          semanticLabel: widget.semanticLabel ?? 'Image failed to load',
        ),
      ),
    );
  }
}
