import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/images/app_image.dart';
import '../../core/models/attachment.dart';
import '../../core/models/content_part.dart';
import '../../core/models/message.dart';
import '../../core/network/app_exception.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/platform_actions.dart';
import 'data/conversation_messages.dart';
import 'data/file_downloads.dart';
import 'render/attachment_card.dart';
import 'render/content_part_view.dart';
import 'render/image_viewer.dart';

// ─── Pure helpers ────────────────────────────────────────────────────

/// One tile of the Media_Screen's grid (Req 25.12).
sealed class MediaItem {
  const MediaItem();
}

/// An image the conversation holds: an `image_url` or `image_file` part, or
/// an image attachment. [url] is what [AppImage] loads, [name] what the
/// image viewer saves and shares it as.
final class MediaImage extends MediaItem {
  const MediaImage({required this.url, this.name, this.width, this.height});

  final String url;
  final String? name;

  /// The pixel size the Server reported, which reserves the tile's space.
  final int? width;
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is MediaImage &&
      other.url == url &&
      other.name == name &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(url, name, width, height);

  @override
  String toString() => 'MediaImage($url)';
}

/// A non-image file the conversation holds, uploaded or generated.
final class MediaFile extends MediaItem {
  const MediaFile(this.attachment);

  final Attachment attachment;

  @override
  bool operator ==(Object other) =>
      other is MediaFile && other.attachment == attachment;

  @override
  int get hashCode => attachment.hashCode;

  @override
  String toString() => 'MediaFile(${attachment.fileId})';
}

/// Everything the Media_Screen shows for [messages] (Req 25.12): the image
/// parts and image attachments first, then the files, each in the order the
/// conversation holds them.
///
/// Images are deduped by URL and files by `file_id`, else by name, so a
/// file a reply returned and the next turn re-sent appears once. Payload
/// attachments (search sources, memory writes) and the sandbox's
/// empty-folder markers are left out, as in the messages themselves.
List<MediaItem> conversationMedia(List<Message> messages) {
  final images = <String, MediaImage>{};
  final files = <String, MediaFile>{};

  void addFile(Attachment a) {
    if (isImageAttachment(a)) {
      if (attachmentImageUrl(a) case final url?) {
        images.putIfAbsent(
          url,
          () => MediaImage(
            url: url,
            name: switch (attachmentName(a)) {
              final name? => displayFilename(name),
              null => null,
            },
            width: a.width,
            height: a.height,
          ),
        );
      }
      return;
    }
    final key = a.fileId ?? attachmentName(a);
    if (key == null) return;
    files.putIfAbsent(key, () => MediaFile(a));
  }

  for (final message in messages) {
    for (final part in message.content ?? const <ContentPart>[]) {
      if (part.type != ContentPartType.imageUrl &&
          part.type != ContentPartType.imageFile) {
        continue;
      }
      if (imagePartUrl(part) case final url?) {
        images.putIfAbsent(url, () => MediaImage(url: url));
      }
    }
    for (final a in message.files ?? const <Attachment>[]) {
      addFile(a);
    }
    // The same filter the bubble's attachment row uses, so the grid holds
    // exactly the files the conversation showed.
    for (final a in messageAttachments(
      message.attachments ?? const [],
      const {},
    )) {
      addFile(a);
    }
  }
  return [...images.values, ...files.values];
}

// ─── Screen ──────────────────────────────────────────────────────────

/// The Media_Screen at `/chat/c/:conversationId/media` (Req 25.12): the
/// conversation's images and files in a grid, where a tap opens the image
/// viewer or the file (KMP ConversationMediaScreen.kt).
///
/// The items come from [conversationMessagesProvider], so the screen shows
/// the cached messages at once and no request of its own.
class MediaScreen extends ConsumerWidget {
  const MediaScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = conversationMessagesProvider(conversationId);
    final state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'), // KMP media_gallery_title
      ),
      body: switch (state) {
        AsyncValue(:final value?) => _Grid(conversationMedia(value.messages)),
        AsyncError(:final error) => ErrorView(
          title: 'Could not load messages', // As on the Chat_Screen
          message: userMessage(error),
          onRetry: () => unawaited(ref.read(provider.notifier).reload()),
        ),
        _ => Center(
          child: Semantics(
            liveRegion: true,
            child: const CircularProgressIndicator(
              semanticsLabel: 'Loading messages', // As on the Chat_Screen
            ),
          ),
        ),
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid(this.items);

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No media in this conversation', // KMP media_empty_media
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      // A maximum tile width, so a phone shows three columns and a tablet
      // or a landscape phone adds columns instead of stretching them.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        final MediaImage image => _ImageTile(image),
        final MediaFile file => _FileTile(file.attachment),
      },
    );
  }
}

/// One image tile: the thumbnail, which opens the fullscreen viewer
/// (Req 23.5, 25.12).
class _ImageTile extends StatelessWidget {
  const _ImageTile(this.image);

  final MediaImage image;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = image.name ?? 'Image'; // KMP cd_image
    return Semantics(
      button: true,
      image: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () =>
              unawaited(openImageViewer(context, image.url, name: image.name)),
          child: AppImage(
            image.url,
            fit: BoxFit.cover,
            error: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: colors.onSurfaceVariant,
                // KMP cd_failed_to_load_image
                semanticLabel: 'Failed to load image',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One file tile: its type icon and name. A tap downloads the file and
/// opens it with the device's app, as the message's own card does
/// (Req 23.6, 25.12).
class _FileTile extends ConsumerStatefulWidget {
  const _FileTile(this.attachment);

  final Attachment attachment;

  @override
  ConsumerState<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends ConsumerState<_FileTile> {
  var _busy = false;

  String get _name {
    final name = attachmentName(widget.attachment);
    return name == null ? 'Attachment' : displayFilename(name); // KMP
  }

  Future<void> _open() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final a = widget.attachment;
      final file = await ref
          .read(fileDownloadsProvider)
          .attachmentFile(a, _name);
      final result = await ref
          .read(platformActionsProvider)
          .openFile(file.path, mimeType: attachmentMimeType(a, _name));
      if (result == OpenFileResult.noApp) {
        messenger.showSnackBar(
          // As on the message's own card.
          const SnackBar(content: Text('No app can open this file')),
        );
      } else if (result == OpenFileResult.failed) {
        // Shown with the unknown-error copy by the catch below.
        throw StateError('Opening $_name failed');
      }
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final downloadable = ref
        .read(fileDownloadsProvider)
        .canDownload(widget.attachment);
    return Semantics(
      button: downloadable,
      label: 'Attached file: $_name', // KMP cd_attached_file
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: downloadable && !_busy ? () => unawaited(_open()) : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                if (_busy)
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    fileTypeIcon(widget.attachment.type),
                    size: 28,
                    color: colors.onSurfaceVariant,
                  ),
                Text(
                  _name,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
