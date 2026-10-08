import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/feature_gate.dart';
import '../../core/config/server_config.dart';
import '../../core/models/conversation.dart';
import '../../core/models/tag.dart';
import '../../core/network/app_exception.dart';
import '../../core/ui/platform_actions.dart';
import '../chat/data/messages_api.dart';
import 'conversation_export.dart';
import 'conversations_api.dart';
import 'conversations_repository.dart';

/// The row actions, in the KMP `ConversationActionsMenu` order.
enum ConversationAction {
  rename,
  pin,
  tags,
  share,
  duplicate,
  export,
  archive,
  delete,
}

/// The title a row shows: the conversation's, or "New Chat".
String conversationTitle(Conversation conversation) {
  final title = conversation.title;
  return title == null || title.trim().isEmpty
      ? 'New Chat' // KMP feature/conversations new_chat
      : title;
}

void _toast(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Opens the actions sheet for [conversation] and runs the chosen action
/// (Req 16). [onOpen] navigates (closing a modal drawer). [onChanged] gets
/// the Server's row after rename, pin or tags, or null after archive or
/// delete, for lists that are not the Cache. [onTagsChanged] runs after a
/// tag is created, renamed, deleted or saved.
///
/// Every dependency is read before the first await, so a flow outlives
/// the widget that started it. A failure shows its message in a SnackBar.
Future<void> showConversationActions(
  BuildContext context,
  WidgetRef ref,
  Conversation conversation, {
  required void Function(String route) onOpen,
  required void Function(Conversation? updated) onChanged,
  VoidCallback? onTagsChanged,
}) async {
  final id = conversation.conversationId;
  if (id == null) return;
  final gates = ref.read(featureGatesProvider);
  final repository = ref.read(conversationsRepositoryProvider);
  final platform = ref.read(platformActionsProvider);
  final messagesApi = ref.read(messagesApiProvider);
  final serverUrl = ref.read(authServiceProvider).serverUrl ?? '';
  final messenger = ScaffoldMessenger.of(context);
  final openPath = GoRouterState.of(context).uri.path;
  final pinned = conversation.pinned ?? false;

  final action = await showModalBottomSheet<ConversationAction>(
    context: context,
    // Taller than the default 9/16 cap, so all eight actions fit without
    // scrolling on a phone.
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ActionsSheet(
      title: conversationTitle(conversation),
      pinned: pinned,
      showPin: gates.has(Feature.pin),
      showTags: gates.has(Feature.bookmarks),
      showShare: gates.has(Feature.sharedLinks),
    ),
  );
  if (action == null || !context.mounted) return;

  try {
    switch (action) {
      case ConversationAction.rename:
        final renamed = await showDialog<Conversation>(
          context: context,
          builder: (context) => _TextInputDialog(
            title: 'Rename conversation', // KMP rename_conversation
            message:
                'Enter a new title for this conversation.', // KMP rename_dialog_message
            label: 'Title', // KMP title_label
            initial: conversation.title ?? '',
            onSave: (title) => repository.rename(conversation, title),
            onError: (e) => _toast(messenger, userMessage(e)),
          ),
        );
        if (renamed != null) onChanged(renamed);
      case ConversationAction.pin:
        onChanged(await repository.setPinned(conversation, !pinned));
      case ConversationAction.tags:
        final saved = await showModalBottomSheet<Conversation>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => _TagsSheet(
            api: repository.api,
            conversation: conversation,
            save: (tags) => repository.setTags(conversation, tags),
            onError: (e) => _toast(messenger, userMessage(e)),
            onTagsChanged: onTagsChanged ?? () {},
          ),
        );
        if (saved != null) {
          onChanged(saved);
          onTagsChanged?.call();
        }
      case ConversationAction.share:
        final shareId =
            await repository.api.sharedLinkId(id) ??
            await repository.api.createShareLink(id);
        final base = serverUrl.replaceFirst(RegExp(r'/+$'), '');
        final url = '$base/share/$shareId';
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => _ShareSheet(
            url: url,
            onCopy: () async {
              await platform.copy(url);
              _toast(messenger, 'Link copied!'); // KMP link_copied
            },
            onShare: () => platform.share(url),
          ),
        );
      case ConversationAction.duplicate:
        final copy = await repository.duplicate(conversation);
        if (copy.conversationId case final copyId?) {
          onOpen(Routes.chat(copyId));
        }
      case ConversationAction.export:
        final markdown = await showDialog<bool>(
          context: context,
          builder: (context) => const _ExportFormatDialog(),
        );
        if (markdown == null) return;
        final messages = await messagesApi.list(id);
        final text = markdown
            ? exportConversationMarkdown(conversation, messages, DateTime.now())
            : exportConversationJson(conversation, messages);
        final saved = await platform.saveFile(
          fileName: exportFileName(conversation.title, markdown: markdown),
          bytes: Uint8List.fromList(utf8.encode(text)),
          mimeType: markdown ? 'text/markdown' : 'application/json',
        );
        // A cancelled save shows nothing.
        if (saved) {
          _toast(
            messenger,
            'Conversation exported',
          ); // KMP conversation_exported
        }
      case ConversationAction.archive:
        await repository.setArchived(conversation, true);
        onChanged(null);
      case ConversationAction.delete:
        if (!await confirmDeleteConversation(context, conversation)) return;
        await repository.delete(id);
        onChanged(null);
        // Stand-in until Task 11.4 declares the conversation view: the
        // open conversation's path is Routes.chat(id).
        if (openPath == Routes.chat(id)) onOpen(Routes.newChat);
    }
  } catch (e) {
    _toast(messenger, userMessage(e));
  }
}

/// The "Delete conversation" confirmation. True when the user confirms.
Future<bool> confirmDeleteConversation(
  BuildContext context,
  Conversation conversation,
) async {
  final title = conversation.title;
  final name = title == null || title.trim().isEmpty
      ? 'this conversation' // KMP this_conversation
      : title;
  return await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmDialog(
          title: 'Delete conversation', // KMP delete_conversation
          // KMP delete_confirmation_message
          message:
              'Are you sure you want to delete "$name"? This action cannot be '
              'undone.',
          confirm: 'Delete', // KMP delete
        ),
      ) ??
      false;
}

/// Picks a `.json` export and uploads it (Req 16.12, 16.13). A file over
/// the Server's `conversationImportMaxFileSize` is refused before upload.
/// On success [onImported] gets the refreshed list's cursor and
/// "Imported: {title}" shows; a rejection shows the Server's message and the
/// list stays as it was.
Future<void> importConversations(
  BuildContext context,
  WidgetRef ref, {
  required void Function(String? cursor) onImported,
}) async {
  final repository = ref.read(conversationsRepositoryProvider);
  final platform = ref.read(platformActionsProvider);
  final limit = ref
      .read(serverConfigProvider)
      .value
      ?.config
      .conversationImportMaxFileSize;
  final messenger = ScaffoldMessenger.of(context);
  // Design copy: the KMP_App has none.
  const tooLarge = "This file is larger than the server's import limit.";
  try {
    final file = await platform.pickJsonFile();
    if (file == null) return;
    if (limit != null && (file.size ?? 0) > limit) {
      _toast(messenger, tooLarge);
      return;
    }
    final bytes = await file.read();
    if (limit != null && bytes.length > limit) {
      _toast(messenger, tooLarge);
      return;
    }
    final cursor = await repository.importFile(bytes, file.name);
    onImported(cursor);
    _toast(
      messenger,
      'Imported: ${_importTitle(bytes, file.name)}',
    ); // KMP imported_title
  } catch (e) {
    _toast(messenger, userMessage(e));
  }
}

/// The export's title when it parses and has one, else [fileName] without
/// its extension (design Import).
String _importTitle(Uint8List bytes, String fileName) {
  try {
    final title = parseConversationExport(
      utf8.decode(bytes, allowMalformed: true),
    ).conversation.title?.trim();
    if (title != null && title.isNotEmpty) return title;
  } on FormatException {
    // Not this App's export format; the Server may still import it.
  }
  return p.basenameWithoutExtension(fileName);
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({
    required this.title,
    required this.pinned,
    required this.showPin,
    required this.showTags,
    required this.showShare,
  });

  final String title;
  final bool pinned;
  final bool showPin;
  final bool showTags;
  final bool showShare;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    Widget tile(
      ConversationAction action,
      IconData icon,
      String label, {
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () => Navigator.pop(context, action),
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            tile(ConversationAction.rename, Icons.edit, 'Rename'), // KMP rename
            if (showPin)
              tile(
                ConversationAction.pin,
                pinned ? Icons.push_pin : Icons.push_pin_outlined,
                pinned ? 'Unpin' : 'Pin', // KMP unpin, pin
              ),
            if (showTags)
              tile(
                ConversationAction.tags,
                Icons.label_outline,
                'Tags',
              ), // KMP tags
            if (showShare)
              tile(ConversationAction.share, Icons.share, 'Share'), // KMP share
            tile(
              ConversationAction.duplicate,
              Icons.content_copy,
              'Duplicate', // KMP duplicate
            ),
            tile(
              ConversationAction.export,
              Icons.file_download,
              'Export',
            ), // KMP export
            tile(
              ConversationAction.archive,
              Icons.archive,
              'Archive',
            ), // KMP archive
            tile(
              ConversationAction.delete,
              Icons.delete,
              'Delete', // KMP delete
              color: error,
            ),
          ],
        ),
      ),
    );
  }
}

/// A one-field dialog that saves through [onSave] and stays open, with the
/// text, when it fails. Save is off while the field is blank.
class _TextInputDialog<T> extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    this.message,
    required this.label,
    required this.initial,
    required this.onSave,
    required this.onError,
  });

  final String title;
  final String? message;
  final String label;
  final String initial;
  final Future<T> Function(String text) onSave;
  final void Function(Object error) onError;

  @override
  State<_TextInputDialog<T>> createState() => _TextInputDialogState<T>();
}

class _TextInputDialogState<T> extends State<_TextInputDialog<T>> {
  late final _controller = TextEditingController(text: widget.initial);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await widget.onSave(_controller.text.trim());
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      widget.onError(e);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blank = _controller.text.trim().isEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message case final message?) ...[
            Text(message),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(labelText: widget.label),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (!blank && !_saving) unawaited(_save());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'), // KMP cancel
        ),
        TextButton(
          onPressed: blank || _saving ? null : () => unawaited(_save()),
          child: const Text('Save'), // KMP save
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'), // KMP cancel
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(confirm),
        ),
      ],
    );
  }
}

/// "Export format": pops true for Markdown, false for JSON.
class _ExportFormatDialog extends StatelessWidget {
  const _ExportFormatDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export format'), // KMP export_format
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('JSON'), // KMP format_json
            // KMP format_json_description
            subtitle: const Text('Full data export, can be imported back'),
            onTap: () => Navigator.pop(context, false),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Markdown'), // KMP format_markdown
            // KMP format_markdown_description
            subtitle: const Text('Readable text format'),
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'), // KMP cancel
        ),
      ],
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.url,
    required this.onCopy,
    required this.onShare,
  });

  final String url;
  final Future<void> Function() onCopy;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: SelectableText(url),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy link'), // New copy: the KMP_App has none
            onTap: () {
              Navigator.pop(context);
              unawaited(onCopy());
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'), // KMP share
            onTap: () {
              Navigator.pop(context);
              unawaited(onShare());
            },
          ),
        ],
      ),
    );
  }
}

/// The tag picker (Req 16): the user's tags as checkboxes, the
/// conversation's current tags checked (read with `GET /api/convos/{id}`,
/// since the list rows carry none), plus add, rename and delete. Save pops
/// with the saved conversation.
class _TagsSheet extends StatefulWidget {
  const _TagsSheet({
    required this.api,
    required this.conversation,
    required this.save,
    required this.onError,
    required this.onTagsChanged,
  });

  final ConversationsApi api;
  final Conversation conversation;
  final Future<Conversation> Function(List<String> tags) save;
  final void Function(Object error) onError;
  final VoidCallback onTagsChanged;

  @override
  State<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends State<_TagsSheet> {
  final _newTag = TextEditingController();
  List<String>? _tags;
  final _selected = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _newTag.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final [tags as List<Tag>, full as Conversation] = await Future.wait([
        widget.api.tags(),
        widget.api.get(widget.conversation.conversationId!),
      ]);
      if (!mounted) return;
      setState(() {
        final names = [for (final t in tags) t.tag];
        for (final t in full.tags ?? const <String>[]) {
          _selected.add(t);
          if (!names.contains(t)) names.add(t);
        }
        _tags = names;
      });
    } catch (e) {
      widget.onError(e);
      if (mounted) Navigator.pop(context);
    }
  }

  /// Runs [task] with the controls off; a failure shows its message.
  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() => _run(() async {
    final name = _newTag.text.trim();
    if (name.isEmpty) return;
    if (!_tags!.contains(name)) {
      final created = await widget.api.createTag(name);
      widget.onTagsChanged();
      if (!mounted) return;
      _tags!.add(created.tag);
    }
    setState(() {
      _selected.add(name);
      _newTag.clear();
    });
  });

  Future<void> _rename(String tag) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog<String>(
        title: 'Rename tag', // New copy: the KMP_App has none
        label: 'Tag', // New copy: the KMP_App has none
        initial: tag,
        onSave: (name) async {
          if (name != tag) await widget.api.renameTag(tag, name);
          return name;
        },
        onError: widget.onError,
      ),
    );
    if (name == null || name == tag || !mounted) return;
    widget.onTagsChanged();
    setState(() {
      final tags = _tags!;
      tags[tags.indexOf(tag)] = name;
      if (_selected.remove(tag)) _selected.add(name);
    });
  }

  Future<void> _delete(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Delete tag', // New copy: the KMP_App has none
        // New copy: the KMP_App has none
        message: 'Delete "$tag"? It is removed from every conversation.',
        confirm: 'Delete', // KMP delete
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await widget.api.deleteTag(tag);
      widget.onTagsChanged();
      if (!mounted) return;
      setState(() {
        _tags!.remove(tag);
        _selected.remove(tag);
      });
    });
  }

  Future<void> _save() => _run(() async {
    final tags = [
      for (final t in _tags!)
        if (_selected.contains(t)) t,
    ];
    final saved = await widget.save(tags);
    if (mounted) Navigator.pop(context, saved);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = _tags;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  'Tags',
                  style: theme.textTheme.titleLarge,
                ), // KMP tags
              ),
            ),
            if (tags == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Tags', // KMP tags
                  ),
                ),
              )
            else ...[
              if (tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'No tags yet. Add one below.', // KMP no_tags_yet
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in tags)
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(tag),
                              value: _selected.contains(tag),
                              onChanged: _busy
                                  ? null
                                  : (on) => setState(
                                      () => on == true
                                          ? _selected.add(tag)
                                          : _selected.remove(tag),
                                    ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip:
                                'Rename tag', // New copy: the KMP_App has none
                            onPressed: _busy
                                ? null
                                : () => unawaited(_rename(tag)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip:
                                'Delete tag', // New copy: the KMP_App has none
                            onPressed: _busy
                                ? null
                                : () => unawaited(_delete(tag)),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTag,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Add new tag', // KMP add_new_tag
                        ),
                        onSubmitted: (_) => unawaited(_add()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add tag', // KMP cd_add_tag
                      onPressed: _busy ? null : () => unawaited(_add()),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'), // KMP cancel
                  ),
                  TextButton(
                    onPressed: tags == null || _busy
                        ? null
                        : () => unawaited(_save()),
                    child: const Text('Save'), // KMP save
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
