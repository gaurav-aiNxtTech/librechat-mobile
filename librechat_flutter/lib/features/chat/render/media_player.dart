import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/content_part.dart';
import '../data/file_downloads.dart';

/// Where a media part's bytes come from: a [url] to download through
/// ApiClient, or inline [bytes]. [fileName] names the local file, whose
/// extension tells the player the format.
typedef MediaSource = ({String? url, Uint8List? bytes, String fileName});

/// The source of a `video_url` part, whose payload is a URL string or
/// `{url}`. A `data:` URI is decoded in place.
MediaSource? videoSource(ContentPart part) {
  final raw = part.videoUrl;
  final url = raw is Map ? raw['url'] : raw;
  if (url is! String || url.trim().isEmpty) return null;
  if (url.startsWith('data:')) {
    try {
      final data = UriData.parse(url);
      final ext = extensionFromMime(data.mimeType) ?? 'mp4';
      return (bytes: data.contentAsBytes(), url: null, fileName: 'video.$ext');
    } on FormatException {
      return null;
    }
  }
  final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
  final last = segments.isEmpty ? '' : segments.last;
  return (
    url: url,
    bytes: null,
    fileName: last.contains('.') ? last : 'video.mp4',
  );
}

/// The source of an `input_audio` part, `{data, format}` with base64
/// [data], or null when the data is missing or not base64.
MediaSource? audioSource(ContentPart part) {
  final data = part.inputAudio?['data'];
  if (data is! String || data.isEmpty) return null;
  final format = part.inputAudio?['format'];
  try {
    return (
      url: null,
      bytes: base64Decode(data),
      fileName:
          'audio.${format is String && format.isNotEmpty ? format : 'wav'}',
    );
  } on FormatException {
    return null;
  }
}

/// [d] as `m:ss`, or `h:mm:ss` from an hour up (KMP formatDuration).
String formatMediaDuration(Duration d) {
  final s = d.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  if (s >= 3600) return '${s ~/ 3600}:${two(s ~/ 60 % 60)}:${two(s % 60)}';
  return '${s ~/ 60}:${two(s % 60)}';
}

/// The local file for [source]: downloaded through [downloads], or the
/// inline bytes written out. The players read only local files, so auth
/// headers never leave ApiClient (Req 23.8).
Future<File> mediaFile(FileDownloads downloads, MediaSource source) {
  final bytes = source.bytes;
  if (bytes != null) return downloads.save(bytes, source.fileName);
  return downloads.download(source.url!, source.fileName);
}

/// Play or pause, a seek slider and the times: the controls both players
/// share (Req 23.8).
class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
    this.playLabel = 'Play', // KMP cd_play
  });

  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;
  final String playLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    return Row(
      children: [
        IconButton(
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          tooltip: playing ? 'Pause' : playLabel, // KMP cd_pause
          onPressed: onToggle,
        ),
        Expanded(
          child: Slider(
            value: max <= 0 ? 0 : value.toDouble(),
            max: max <= 0 ? 1 : max,
            semanticFormatterCallback: (v) =>
                formatMediaDuration(Duration(milliseconds: v.round())),
            onChanged: max <= 0
                ? null
                : (v) => onSeek(Duration(milliseconds: v.round())),
          ),
        ),
        Text(
          '${formatMediaDuration(position)} / ${formatMediaDuration(duration)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// A small notice in place of a player: loading, or why it can't play.
class _MediaNotice extends StatelessWidget {
  const _MediaNotice({required this.icon, this.text});

  final Widget icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 8,
        children: [
          icon,
          if (text case final text?)
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _card(BuildContext context, Widget child) => Card.filled(
  margin: EdgeInsets.zero,
  color: Theme.of(context).colorScheme.surfaceContainerHigh,
  clipBehavior: Clip.antiAlias,
  child: child,
);

const _spinner = SizedBox.square(
  dimension: 20,
  child: CircularProgressIndicator(strokeWidth: 2),
);

/// An `input_audio` part played inline with just_audio (Req 23.8). The
/// player is created once the local file exists and disposed with the
/// widget.
class AudioPartPlayer extends ConsumerStatefulWidget {
  const AudioPartPlayer({super.key, required this.source});

  /// Null when the part has no audio data.
  final MediaSource? source;

  @override
  ConsumerState<AudioPartPlayer> createState() => _AudioPartPlayerState();
}

class _AudioPartPlayerState extends ConsumerState<AudioPartPlayer> {
  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _failed = false;
  var _playing = false;
  var _position = Duration.zero;
  var _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.source != null) unawaited(_load(widget.source!));
  }

  Future<void> _load(MediaSource source) async {
    final player = AudioPlayer();
    try {
      final file = await mediaFile(ref.read(fileDownloadsProvider), source);
      if (!mounted) return player.dispose();
      final duration = await player.setFilePath(file.path);
      if (!mounted) return player.dispose();
      _subscriptions.addAll([
        player.positionStream.listen((p) => setState(() => _position = p)),
        player.durationStream.listen(
          (d) => setState(() => _duration = d ?? Duration.zero),
        ),
        player.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed) {
            // Back to the start, ready to play again (KMP).
            unawaited(player.pause());
            unawaited(player.seek(Duration.zero));
          }
          setState(() => _playing = s.playing);
        }),
      ]);
      setState(() {
        _player = player;
        _duration = duration ?? Duration.zero;
      });
    } on Object {
      await player.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_player?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (widget.source == null || _failed) {
      return _card(
        context,
        _MediaNotice(
          icon: Icon(Icons.music_off_outlined, color: colors.onSurfaceVariant),
          text: widget.source == null
              ? 'No audio data' // KMP audio_no_data
              : 'Failed to decode audio', // KMP audio_decode_failed
        ),
      );
    }
    final player = _player;
    if (player == null) {
      return _card(context, const _MediaNotice(icon: _spinner));
    }
    return _card(
      context,
      _Controls(
        playing: _playing,
        position: _position,
        duration: _duration,
        onToggle: () => unawaited(_playing ? player.pause() : player.play()),
        onSeek: (d) => unawaited(player.seek(d)),
      ),
    );
  }
}

/// A `video_url` part played inline with video_player (Req 23.8): the
/// video at its aspect ratio over the shared controls. The controller is
/// disposed with the widget.
class VideoPartPlayer extends ConsumerStatefulWidget {
  const VideoPartPlayer({super.key, required this.source});

  final MediaSource source;

  @override
  ConsumerState<VideoPartPlayer> createState() => _VideoPartPlayerState();
}

class _VideoPartPlayerState extends ConsumerState<VideoPartPlayer> {
  VideoPlayerController? _controller;
  var _failed = false;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    VideoPlayerController? controller;
    try {
      final file = await mediaFile(
        ref.read(fileDownloadsProvider),
        widget.source,
      );
      if (_disposed) return;
      controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (_disposed) return controller.dispose();
      controller.addListener(_onTick);
      setState(() => _controller = controller);
    } on Object {
      await controller?.dispose();
      if (!_disposed) setState(() => _failed = true);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;
    if (v.isCompleted && !v.isPlaying && v.position != Duration.zero) {
      unawaited(c.seekTo(Duration.zero));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.removeListener(_onTick);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_failed) {
      return _card(
        context,
        _MediaNotice(
          icon: Icon(
            Icons.videocam_off_outlined,
            color: colors.onSurfaceVariant,
          ),
          text: 'Video content not supported', // KMP video_not_supported
        ),
      );
    }
    final c = _controller;
    if (c == null) {
      return _card(
        context,
        const SizedBox(height: 160, child: Center(child: _spinner)),
      );
    }
    final v = c.value;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: AspectRatio(
              aspectRatio: v.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          _Controls(
            playing: v.isPlaying,
            position: v.position,
            duration: v.duration,
            playLabel: 'Play video', // KMP cd_play_video
            onToggle: () => unawaited(v.isPlaying ? c.pause() : c.play()),
            onSeek: (d) => unawaited(c.seekTo(d)),
          ),
        ],
      ),
    );
  }
}
