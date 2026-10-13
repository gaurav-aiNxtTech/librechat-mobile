import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../core/images/app_image.dart';
import '../../../core/models/attachment.dart';
import '../../../core/ui/platform_actions.dart';
import '../artifacts/web_host.dart';
import 'code_block.dart';
import 'math.dart';

/// The link [url] as an external target, or null when the App must not
/// open it: only `http`/`https` URLs with a host, `mailto:` and `tel:` open,
/// so `javascript:`, `intent:`, `file:` and relative links are ignored.
Uri? externalLinkTarget(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  return switch (uri.scheme.toLowerCase()) {
    'http' || 'https' when uri.host.isNotEmpty => uri,
    'mailto' || 'tel' when uri.path.isNotEmpty => uri,
    _ => null,
  };
}

/// One source a citation marker can point at: a web search result or a
/// file search passage.
typedef CitationSource = ({String title, String? url, String? snippet});

/// The sources of a message's web_search and file_search attachments, in
/// order, so marker `n` is entry `n - 1` (Req 22.6). Web results list the
/// organic results and then the top stories.
List<CitationSource> citationSources(List<Attachment> attachments) {
  final sources = <CitationSource>[];
  for (final attachment in attachments) {
    final web = attachment.webSearch;
    if (web != null) {
      for (final key in const ['organic', 'topStories']) {
        for (final result in _maps(web[key])) {
          final link = _string(result['link']);
          final title = _string(result['title']) ?? link;
          if (title == null) continue;
          sources.add((
            title: title,
            url: link,
            snippet: _string(result['snippet']),
          ));
        }
      }
    }
    final files = attachment.fileSearch;
    if (files != null) {
      for (final source in _maps(files['sources'])) {
        sources.add((
          title: _string(source['fileName']) ?? 'File', // KMP file_fallback
          url: null,
          snippet: _string(source['content']),
        ));
      }
    }
  }
  return sources;
}

Iterable<Map<String, Object?>> _maps(Object? value) =>
    value is List ? value.whereType<Map<String, Object?>>() : const [];

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

const _citationScheme = 'citation:';
final _bracketMarker = RegExp(r'\[(\d+)\]');
final _lenticularMarker = RegExp('\u3010(\\d+)\u2020[^\u3011\n]*\u3011');

/// Rewrites citation markers `[n]` and `【n†…】` into `citation:n` links
/// for the [count] sources a message carries (Req 22.6), so a tap can open
/// the source. Markers outside `1..count`, escaped markers, markers that
/// are part of a link (`[1](…)`, `[a][1]`, a `[1]:` definition), code spans
/// and fenced code are left as they are.
String linkCitations(String text, int count) {
  if (count == 0 || !(text.contains('[') || text.contains('\u3010'))) {
    return text;
  }
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final lineStart = i == 0 || text[i - 1] == '\n';
    if (lineStart) {
      final fenceEnd = fencedCodeEnd(text, i);
      if (fenceEnd != null) {
        out.write(text.substring(i, fenceEnd));
        i = fenceEnd;
        continue;
      }
    }
    final char = text[i];
    if (char == '`') {
      final end = codeSpanEnd(text, i);
      out.write(text.substring(i, end));
      i = end;
      continue;
    }
    if (char == r'\') {
      final end = i + 2 > text.length ? text.length : i + 2;
      out.write(text.substring(i, end));
      i = end;
      continue;
    }
    final match = switch (char) {
      '[' => _bracketMarker.matchAsPrefix(text, i),
      '\u3010' => _lenticularMarker.matchAsPrefix(text, i),
      _ => null,
    };
    final n = match == null ? null : int.tryParse(match[1]!);
    if (match != null &&
        n != null &&
        n >= 1 &&
        n <= count &&
        (char != '[' || _isBareBracket(text, match, lineStart: lineStart))) {
      out.write('[$n]($_citationScheme$n)');
      i = match.end;
      continue;
    }
    out.write(char);
    i++;
  }
  return out.toString();
}

bool _isBareBracket(String text, Match match, {required bool lineStart}) {
  if (match.start > 0 && text[match.start - 1] == ']') return false;
  if (match.end < text.length) {
    final next = text[match.end];
    if (next == '(' || next == '[') return false;
    if (lineStart && next == ':') return false;
  }
  return true;
}

/// The source number of a `citation:n` link, or null for any other link.
int? citationNumber(String url) => url.startsWith(_citationScheme)
    ? int.tryParse(url.substring(_citationScheme.length))
    : null;

/// GitHub-flavored Markdown rendered natively through gpt_markdown
/// (Req 22.1): headings, emphasis, lists, task lists, blockquotes, links,
/// tables, inline code and rules.
///
/// Fenced code renders as a [CodeBlock] (Req 22.2). Math goes through
/// [prepareMath] and renders as a [MathView] (Req 22.3–22.5). When
/// [attachments] carry web or file search sources, citation markers become
/// links that open a [CitationSheet] (Req 22.6). Any other link opens the
/// external browser through [PlatformActions.openExternal] (Req 22.7).
/// Images load through [AppImage], so Server images carry the App's auth
/// headers (Req 4.2).
class MarkdownText extends ConsumerWidget {
  const MarkdownText(
    this.text, {
    super.key,
    this.style,
    this.attachments = const [],
    this.streaming = false,
  });

  final String text;

  /// The body style, sized from AppSettings `chatFontSize` (Req 22.9).
  final TextStyle? style;

  /// The message's attachments, whose search sources citations point at.
  final List<Attachment> attachments;

  /// True in the live reply, where a `mermaid` fence stays a code block
  /// until the reply settles (Req 24.6).
  final bool streaming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = citationSources(attachments);
    return GptMarkdown(
      linkCitations(prepareMath(text), sources.length),
      style: style,
      onLinkTap: (url, _) {
        if (citationNumber(url) case final n?) {
          if (n >= 1 && n <= sources.length) {
            unawaited(CitationSheet.show(context, n, sources[n - 1]));
          }
          return;
        }
        final target = externalLinkTarget(url);
        if (target == null) return;
        unawaited(ref.read(platformActionsProvider).openExternal(target));
      },
      latexBuilder: (context, tex, textStyle, inline) =>
          MathView(tex, style: textStyle, inline: inline),
      codeBuilder: (context, name, code, closed) {
        final source = code.endsWith('\n')
            ? code.substring(0, code.length - 1)
            : code;
        // A closed `mermaid` fence renders as a diagram once the reply
        // settles (Req 24.6); while it streams it stays a code block.
        if (closed && !streaming && fenceLanguage(name) == 'mermaid') {
          return MermaidView(source);
        }
        return CodeBlock(language: name, code: source, closed: closed);
      },
      imageBuilder: (context, url, width, height) => AppImage(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'Image', // New copy: KMP images have no label here
      ),
    );
  }
}

/// The bottom sheet for citation [number] (Req 22.6): the source's title,
/// its snippet, and for a web source its URL with an Open action that
/// opens the external browser.
class CitationSheet extends ConsumerWidget {
  const CitationSheet({super.key, required this.number, required this.source});

  final int number;
  final CitationSource source;

  static Future<void> show(
    BuildContext context,
    int number,
    CitationSource source,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => CitationSheet(number: number, source: source),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final url = source.url;
    final target = url == null ? null : externalLinkTarget(url);
    final snippet = source.snippet;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Citation $number', // KMP citation_number
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (snippet != null) ...[
              const SizedBox(height: 4),
              Text(
                snippet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (url != null) ...[
              const SizedBox(height: 8),
              Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (target != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Tooltip(
                  message: 'Open citation URL', // KMP cd_open_citation_url
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(
                        ref.read(platformActionsProvider).openExternal(target),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'), // KMP action_open
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
