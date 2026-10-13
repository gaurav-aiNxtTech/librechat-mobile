import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/attachment.dart';
import '../../../core/models/content_part.dart';
import '../../../core/ui/platform_actions.dart';
import '../run/run_state.dart';
import 'attachment_card.dart';
import 'markdown_text.dart';
import 'thinking_block.dart';

// ─── Pure helpers ────────────────────────────────────────────────────

/// The Server's answer when the user skips an `ask_user_question`
/// (upstream `ASK_USER_DECLINED_ANSWER`).
const askUserDeclinedAnswer = 'The user chose not to answer this question.';

const _transferPrefix = 'lc_transfer_to_';

/// How a tool call renders (Req 23.3, 23.13). Picked by the tool name in
/// the KMP `ToolCallDispatcher` order.
enum ToolVariant {
  handoff,
  askUser,
  subagent,
  webSearch,
  fileSearch,
  memory,
  imageGen,
  generic,
}

const _imageGenNames = {'image_gen_oai', 'image_edit_oai', 'gemini_image_gen'};
const _imageGenFragments = ['dall', 'image_gen', 'stable-diffusion', 'flux'];

ToolVariant toolVariant(String? name) {
  final n = (name ?? '').toLowerCase();
  if (n.startsWith(_transferPrefix)) return ToolVariant.handoff;
  if (n == 'ask_user_question') return ToolVariant.askUser;
  if (n == 'subagent') return ToolVariant.subagent;
  if (n == 'file_search' || n == 'retrieval') return ToolVariant.fileSearch;
  if (n.contains('search')) return ToolVariant.webSearch;
  if (n.contains('memory')) return ToolVariant.memory;
  if (_imageGenNames.contains(n) || _imageGenFragments.any(n.contains)) {
    return ToolVariant.imageGen;
  }
  return ToolVariant.generic;
}

/// The arguments as a map: a map mid-stream, a JSON string once saved.
/// Null for anything else. `jsonDecode` keeps the key order.
Map<String, Object?>? toolArgs(Object? args) {
  var value = args;
  if (value is String) {
    if (value.trim().isEmpty) return null;
    try {
      value = jsonDecode(value);
    } on FormatException {
      return null;
    }
  }
  return value is Map ? value.cast<String, Object?>() : null;
}

/// The `intent` argument when it is the first key and a non-blank string
/// (Req 23.2). Only the first key counts, because the Server injects it at
/// position zero and a tool may legitimately take its own `intent`.
String? toolIntent(Object? args) {
  final map = toolArgs(args);
  if (map == null || map.isEmpty || map.keys.first != 'intent') return null;
  final intent = map['intent'];
  if (intent is! String) return null;
  final trimmed = intent.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The card title: the intent, otherwise the tool name (Req 23.2).
String toolTitle(ToolCall? call) {
  final intent = toolIntent(call?.args);
  if (intent != null) return intent;
  final name = call?.name;
  return name == null || name.isEmpty ? 'Tool Call' : name; // KMP fallback
}

/// The arguments as pretty JSON, without an intent already shown as the
/// title. Null when there is nothing to show; raw text when not JSON.
String? displayArgs(Object? args) {
  if (args == null) return null;
  final map = toolArgs(args);
  if (map == null) {
    final text = args is String ? args.trim() : jsonEncode(args);
    return text.isEmpty ? null : text;
  }
  final shown = toolIntent(args) == null
      ? map
      : (Map.of(map)..remove('intent'));
  if (shown.isEmpty) return null;
  return const JsonEncoder.withIndent('  ').convert(shown);
}

/// The attachments of [type] that belong to [callId]: those with its id or
/// no id at all, or every one when the call has no id (KMP
/// `collectWebSearchSources` scoping).
List<Attachment> _scoped(
  List<Attachment> attachments,
  String type,
  String? callId,
) => [
  for (final a in attachments)
    if (a.type == type &&
        (callId == null || a.toolCallId == null || a.toolCallId == callId))
      a,
];

List<Map<String, Object?>> _maps(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is Map) item.cast<String, Object?>(),
];

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// The bare host of [url], without `www.`.
String hostOf(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  final bare = host.startsWith('www.') ? host.substring(4) : host;
  return bare.isEmpty ? url : bare;
}

typedef WebSource = ({String title, String url});

/// The web search sources of [call]: the `web_search` attachments'
/// `organic` and `topStories`, deduplicated by link, falling back to a
/// `results` list in the output.
List<WebSource> webSources(List<Attachment> attachments, ToolCall call) {
  final seen = <String>{};
  final out = <WebSource>[];
  void add(String? title, String? url) {
    if (url == null || !seen.add(url)) return;
    out.add((title: title ?? hostOf(url), url: url));
  }

  for (final a in _scoped(attachments, 'web_search', call.id)) {
    final data = a.webSearch;
    if (data == null) continue;
    for (final s in [..._maps(data['organic']), ..._maps(data['topStories'])]) {
      add(_string(s['title']), _string(s['link']));
    }
  }
  if (out.isNotEmpty) return out;
  final output = call.output;
  if (output == null || output.trim().isEmpty) return out;
  try {
    final decoded = jsonDecode(output);
    final results = decoded is Map ? decoded['results'] : decoded;
    for (final r in _maps(results)) {
      add(_string(r['title']), _string(r['url']) ?? _string(r['link']));
    }
  } on FormatException {
    // A plain-text output has no sources.
  }
  return out;
}

typedef FileCitation = ({String name, int relevance, List<int> pages});

/// The files a file search matched, merged by file id, most relevant first
/// (KMP `collectFileSearchSources`).
List<FileCitation> fileCitations(List<Attachment> attachments, ToolCall call) {
  final merged = <String, ({String name, double relevance, List<int> pages})>{};
  for (final a in _scoped(attachments, 'file_search', call.id)) {
    for (final s in _maps(a.fileSearch?['sources'])) {
      final id = _string(s['fileId']) ?? _string(s['fileName']);
      if (id == null) continue;
      final relevance = (s['relevance'] as num?)?.toDouble() ?? 0;
      final pages = [
        for (final p in (s['pages'] as List?) ?? const [])
          if (p is int) p,
      ];
      final old = merged[id];
      merged[id] = old == null
          ? (
              name: _string(s['fileName']) ?? id,
              relevance: relevance,
              pages: pages,
            )
          : (
              name: old.name,
              relevance: relevance > old.relevance ? relevance : old.relevance,
              pages: {...old.pages, ...pages}.toList(),
            );
    }
  }
  final list = merged.values.toList()
    ..sort((a, b) => b.relevance.compareTo(a.relevance));
  return [
    for (final c in list)
      (name: c.name, relevance: (c.relevance * 100).round(), pages: c.pages),
  ];
}

enum MemoryChangeKind { update, delete, error }

typedef MemoryChange = ({MemoryChangeKind kind, String? key, String? text});

/// The memories [call] changed, from its `memory` attachments, or one
/// change read from the output on a Server without them.
List<MemoryChange> memoryChanges(List<Attachment> attachments, ToolCall call) {
  final out = <MemoryChange>[
    for (final a in _scoped(attachments, 'memory', call.id))
      if (a.memory case final m?) _memoryChange(m),
  ];
  if (out.isNotEmpty) return out;
  final output = call.output;
  if (output == null || output.trim().isEmpty) return out;
  try {
    final decoded = jsonDecode(output);
    if (decoded is Map) {
      final key = _string(decoded['title']) ?? _string(decoded['key']);
      final text =
          _string(decoded['content']) ??
          _string(decoded['value']) ??
          _string(decoded['text']);
      return [(kind: MemoryChangeKind.update, key: key, text: text)];
    }
  } on FormatException {
    // set_memory answers with a sentence.
  }
  return [(kind: MemoryChangeKind.update, key: null, text: output)];
}

MemoryChange _memoryChange(Map<String, Object?> m) {
  final kind = switch (m['type']) {
    'delete' => MemoryChangeKind.delete,
    'error' => MemoryChangeKind.error,
    _ => MemoryChangeKind.update,
  };
  final key = _string(m['key']);
  final value = _string(m['value']);
  return switch (kind) {
    MemoryChangeKind.update => (kind: kind, key: key, text: value),
    MemoryChangeKind.delete => (
      kind: kind,
      key: key,
      text: value ?? 'Memory deleted', // KMP memory_deleted
    ),
    MemoryChangeKind.error => (kind: kind, key: key, text: _memoryError(value)),
  };
}

/// The sentence for a refused memory write (KMP `memoryErrorMessage`).
String _memoryError(String? value) {
  const generic = 'Memory Error'; // KMP memory_error
  if (value == null) return generic;
  try {
    final blob = jsonDecode(value);
    if (blob is! Map) return generic;
    final tokens = blob['tokenCount'];
    if (tokens is! int) return generic;
    return switch (blob['errorType']) {
      // KMP memory_already_exceeded
      'already_exceeded' =>
        'Memory storage already full — exceeded by $tokens tokens. '
            'Delete existing memories before adding new ones.',
      // KMP memory_would_exceed
      'would_exceed' =>
        'Cannot save — would exceed limit by $tokens tokens. '
            'Delete existing memories to make space.',
      _ => generic,
    };
  } on FormatException {
    return generic;
  }
}

typedef AskOption = ({String label, String value});
typedef AskQuestion = ({
  String question,
  String? header,
  List<AskOption> options,
  bool multiSelect,
});
typedef AskRecord = ({AskQuestion? question, String answer});

AskQuestion? _askQuestion(Map<String, Object?> m) {
  final question = m['question'];
  if (question is! String) return null;
  return (
    question: question,
    header: _string(m['header']),
    options: [
      for (final o in _maps(m['options']))
        if (o['label'] case final String label)
          if (o['value'] case final String value) (label: label, value: value),
    ],
    multiSelect: m['multiSelect'] == true,
  );
}

/// The questions of an `ask_user_question` call with their answers
/// (Req 23.13). A batch carries `questions[]` with ids and answers
/// `{"answers": {id: text}}`; a single question takes the whole output.
List<AskRecord> askRecords(ToolCall call) {
  final args = toolArgs(call.args) ?? const {};
  final output = call.output ?? '';
  final batch = [
    for (final q in _maps(args['questions']))
      if (_string(q['id']) case final id?)
        if (_askQuestion(q) case final question?) (id: id, question: question),
  ];
  if (batch.isEmpty) return [(question: _askQuestion(args), answer: output)];
  var answers = const <String, Object?>{};
  try {
    final decoded = jsonDecode(output);
    if (decoded is Map && decoded['answers'] is Map) {
      answers = (decoded['answers'] as Map).cast<String, Object?>();
    }
  } on FormatException {
    // Unanswered: nothing is stamped until the pause resolves.
  }
  return [
    for (final e in batch)
      (question: e.question, answer: (answers[e.id] as String?) ?? ''),
  ];
}

/// How an answer reads: the picked options' labels, or the raw answer.
/// Multi-select answers are values joined by ", " and map to labels only
/// when every segment matches an option (KMP `askAnswerDisplay`).
({String label, bool declined}) askAnswerLabel(
  AskQuestion? question,
  String answer,
) {
  if (answer == askUserDeclinedAnswer) return (label: answer, declined: true);
  final options = question?.options ?? const <AskOption>[];
  String labelOf(AskOption o) => o.label.trim().isEmpty ? o.value : o.label;
  for (final o in options) {
    if (o.value == answer) return (label: labelOf(o), declined: false);
  }
  if (question?.multiSelect == true && options.isNotEmpty) {
    final picked = [
      for (final segment in answer.split(', '))
        options.where((o) => o.value == segment).firstOrNull,
    ];
    if (picked.every((o) => o != null)) {
      return (
        label: picked.map((o) => labelOf(o!)).join(', '),
        declined: false,
      );
    }
  }
  return (label: answer, declined: false);
}

/// The live progress of a `subagent` call, matched by the parent tool call
/// id. [subagents] is keyed by `subagentRunId ?? parentToolCallId`.
SubagentProgress? subagentFor(
  Map<String, SubagentProgress> subagents,
  String? callId,
) {
  if (callId == null) return null;
  return subagents[callId] ??
      subagents.values.where((s) => s.parentToolCallId == callId).firstOrNull;
}

// ─── Widgets ─────────────────────────────────────────────────────────

/// A `tool_call` part (Req 23.1–23.3, 23.13): an expandable card titled by
/// the intent or tool name, with the arguments and the output inside, or
/// the variant for web search, file search, memory, image generation,
/// subagents, handoffs and answered questions.
///
/// [streaming] is true in the live reply: a spinner shows until the output
/// or the call's terminal `ToolCallClosed` status arrives. A saved call has
/// no running state.
///
/// Files the call produced ([toolCallAttachments]) render under the card,
/// as the web client passes each call its attachments; the image
/// generation card draws its image inside.
class ToolCallCard extends ConsumerWidget {
  const ToolCallCard({
    super.key,
    required this.part,
    required this.storageKey,
    this.attachments = const [],
    this.streaming = false,
    this.subagents = const {},
  });

  final ContentPart part;
  final String storageKey;

  /// The message's attachments; the variants read their payloads.
  final List<Attachment> attachments;
  final bool streaming;
  final Map<String, SubagentProgress> subagents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = part.toolCall ?? const ToolCall();
    final files = toolCallAttachments(attachments, call.id);
    // The image generation card draws its image itself.
    if (toolVariant(call.name) == ToolVariant.imageGen) {
      return _ImageGenStatus(
        generating: _imageGenerating(call),
        progress: call.progress,
        files: files,
        storagePrefix: '$storageKey/files',
      );
    }
    final card = _variant(ref, call);
    if (files.isEmpty) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        card,
        AttachmentList(files, storagePrefix: '$storageKey/files'),
      ],
    );
  }

  Widget _variant(WidgetRef ref, ToolCall call) {
    final generic = _GenericToolCard(
      call: call,
      storageKey: storageKey,
      running: _running(call),
      closedStatus: part.status,
    );
    switch (toolVariant(call.name)) {
      case ToolVariant.handoff:
        final target = call.name!.substring(_transferPrefix.length);
        return HandoffMarker(to: target.isEmpty ? call.name : target);
      case ToolVariant.askUser:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            for (final r in askRecords(call))
              _AskRecordCard(question: r.question, answer: r.answer),
          ],
        );
      case ToolVariant.subagent:
        final progress = subagentFor(subagents, call.id);
        return _GenericToolCard(
          call: call,
          storageKey: storageKey,
          title: _nonBlank(progress?.type) ?? _nonBlank(progress?.label),
          fallbackTitle: 'Subagent', // KMP label_subagent
          running: progress == null
              ? _running(call)
              : progress.status == SubagentStatus.running,
          closedStatus: progress?.status == SubagentStatus.failed
              ? 'failed'
              : part.status,
        );
      case ToolVariant.webSearch:
        final sources = webSources(attachments, call);
        if (sources.isEmpty) return generic;
        return _SourcesCard(
          storageKey: storageKey,
          icon: Icons.language,
          title: 'Searched the web', // KMP web_searched
          rows: [
            for (final s in sources)
              _SourceRow(
                title: s.title,
                trailing: hostOf(s.url),
                semanticLabel: 'Search result: ${s.title}', // KMP
                onTap: () {
                  final target = externalLinkTarget(s.url);
                  if (target == null) return;
                  unawaited(
                    ref.read(platformActionsProvider).openExternal(target),
                  );
                },
              ),
          ],
        );
      case ToolVariant.fileSearch:
        final files = fileCitations(attachments, call);
        if (files.isEmpty) return generic;
        return _SourcesCard(
          storageKey: storageKey,
          icon: Icons.description_outlined,
          title: 'Searched your files', // KMP files_searched
          rows: [
            for (final f in files)
              _SourceRow(
                title: f.name,
                subtitle: f.pages.isEmpty
                    ? null
                    : 'Pages: ${f.pages.join(', ')}', // KMP file_search_pages
                trailing: '${f.relevance}%', // KMP file_search_relevance
                semanticLabel: 'File search source: ${f.name}', // KMP
              ),
          ],
        );
      case ToolVariant.memory:
        final changes = memoryChanges(attachments, call);
        if (changes.isEmpty) return generic;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [for (final c in changes) _MemoryCard(change: c)],
        );
      case ToolVariant.imageGen:
      case ToolVariant.generic:
        return generic;
    }
  }

  bool _running(ToolCall call) =>
      streaming && (call.output?.isEmpty ?? true) && part.status == null;

  /// Until the call's image attachment arrives (Req 23.3). A saved call
  /// with a legacy output and no attachment counts as done.
  bool _imageGenerating(ToolCall call) {
    final hasImage = attachments.any(
      (a) => a.toolCallId != null && a.toolCallId == call.id,
    );
    if (hasImage) return false;
    return streaming || (call.output?.isEmpty ?? true);
  }
}

String? _nonBlank(String? s) => s == null || s.trim().isEmpty ? null : s;

/// The default card: the title, a running spinner or a failure badge, and
/// the "Input:" and "Output:" sections when expanded (KMP
/// GenericToolCallCard).
class _GenericToolCard extends StatelessWidget {
  const _GenericToolCard({
    required this.call,
    required this.storageKey,
    required this.running,
    this.closedStatus,
    this.title,
    this.fallbackTitle,
  });

  final ToolCall call;
  final String storageKey;
  final bool running;
  final String? closedStatus;
  final String? title;
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final args = displayArgs(call.args);
    final output = call.output;
    final intent = toolIntent(call.args);
    final name = title ?? intent ?? fallbackTitle ?? toolTitle(call);
    final Widget? status = running
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : switch (closedStatus) {
            'cancelled' => Icon(
              Icons.block,
              size: 16,
              color: colors.onSurfaceVariant,
              semanticLabel: 'Stopped', // KMP cd_tool_cancelled
            ),
            'failed' => Icon(
              Icons.error_outline,
              size: 16,
              color: colors.error,
              semanticLabel: 'Failed', // KMP cd_tool_failed
            ),
            _ => null,
          };
    return CollapsibleCard(
      storageKey: storageKey,
      icon: Icon(
        Icons.build_outlined,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
      title: Text(name, style: theme.textTheme.titleSmall),
      status: status,
      children: [
        if (args != null) ...[
          _SectionLabel('Input:'), // KMP label_input
          _Mono(args),
        ],
        if (output != null && output.trim().isNotEmpty) ...[
          _SectionLabel('Output:'), // KMP label_output
          _Mono(output),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Arguments or output in a scrollable monospace box.
class _Mono extends StatelessWidget {
  const _Mono(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: SelectableText(
          text,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}

/// "Searched the web" or "Searched your files", expanding to the sources.
class _SourcesCard extends StatelessWidget {
  const _SourcesCard({
    required this.storageKey,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final String storageKey;
  final IconData icon;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CollapsibleCard(
      storageKey: storageKey,
      icon: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleSmall),
      children: rows,
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.title,
    required this.trailing,
    required this.semanticLabel,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String trailing;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (subtitle case final subtitle?)
                      Text(subtitle, style: muted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(trailing, style: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One memory write (KMP MemoryArtifactCard): a "Memory" or "Memory Error"
/// badge, the key and the remembered text.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.change});

  final MemoryChange change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final error = change.kind == MemoryChangeKind.error;
    final fg = error ? colors.onErrorContainer : colors.onTertiaryContainer;
    final key = change.key;
    final text = change.text;
    return Semantics(
      container: true,
      // KMP cd_memory_artifact, memory_artifact_untitled
      label: 'Memory artifact: ${key ?? 'Untitled'}',
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: error ? colors.errorContainer : colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                spacing: 8,
                children: [
                  Text(
                    error
                        ? 'Memory Error'
                        : 'Memory', // KMP memory_error, label_memory
                    style: theme.textTheme.labelSmall?.copyWith(color: fg),
                  ),
                  if (key != null)
                    Expanded(
                      child: Text(
                        key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (text != null && text.trim().isNotEmpty)
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An image generation call's state: a progress indicator until the image
/// arrives (Req 23.3), then the generated image ([files]) in the card.
class _ImageGenStatus extends StatelessWidget {
  const _ImageGenStatus({
    required this.generating,
    required this.files,
    required this.storagePrefix,
    this.progress,
  });

  final bool generating;
  final double? progress;
  final List<Attachment> files;
  final String storagePrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      generating
                          ? 'Generating image…' // KMP generating_image
                          : 'Image generated', // KMP image_generated
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
            if (generating) LinearProgressIndicator(value: progress),
            if (files.isNotEmpty)
              AttachmentList(files, storagePrefix: storagePrefix),
          ],
        ),
      ),
    );
  }
}

/// An answered (or pending) `ask_user_question`: the question and the
/// answer (KMP AskUserQuestionRecordCard).
class _AskRecordCard extends StatelessWidget {
  const _AskRecordCard({required this.question, required this.answer});

  final AskQuestion? question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final answered = answer.trim().isNotEmpty;
    final display = askAnswerLabel(question, answer);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final questionText = question?.question.trim();
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(Icons.help_outline, size: 18, color: colors.onSurfaceVariant),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    answered
                        ? 'Asked'
                        : 'Asking', // KMP ask_user_question_record_*
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (question?.header case final header?)
                    Text(
                      header,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (questionText != null && questionText.isNotEmpty)
                    Text(questionText, style: theme.textTheme.bodyMedium),
                  if (!answered || display.declined)
                    Text(
                      display.declined
                          ? 'You skipped this question' // KMP ask_user_question_record_skipped
                          : 'No answer was given', // KMP ask_user_question_record_unanswered
                      style: muted?.copyWith(fontStyle: FontStyle.italic),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          // KMP ask_user_question_record_answer_label
                          TextSpan(text: 'You answered: ', style: muted),
                          TextSpan(
                            text: display.label,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An agent handoff (KMP AgentHandoffCard): from one agent to the next.
/// Used by `agent_update` parts and `lc_transfer_to_*` calls.
class HandoffMarker extends StatelessWidget {
  const HandoffMarker({super.key, this.from, this.to});

  final String? from;
  final String? to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSecondaryContainer;
    Widget agent(String name) => Expanded(
      child: Row(
        spacing: 4,
        children: [
          Icon(Icons.smart_toy_outlined, size: 16, color: fg),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      // KMP cd_agent_handoff with agent_unknown
      label: 'Agent handoff from ${from ?? 'unknown'} to ${to ?? 'unknown'}',
      excludeSemantics: true,
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              agent(from ?? 'Previous Agent'), // KMP agent_previous
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: fg),
              ),
              agent(to ?? 'Next Agent'), // KMP agent_next
            ],
          ),
        ),
      ),
    );
  }
}
