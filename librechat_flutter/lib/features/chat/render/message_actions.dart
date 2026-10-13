import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/config/feature_gate.dart';
import '../../../core/models/content_part.dart';
import '../../../core/models/message.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/ui/platform_actions.dart';
import '../../conversations/conversations_repository.dart';
import '../artifacts/artifact_parser.dart';
import '../composer/composer_controller.dart';
import '../composer/quotes.dart';
import '../data/conversation_messages.dart';
import '../data/messages_api.dart';
import '../data/messages_repository.dart';
import '../run/run_service.dart';
import '../send/chat_turn.dart';
import '../sibling_navigator.dart';
import 'message_view.dart';

/// The clipboard text of [message] (Req 25.8): the message's own `text`,
/// or its text parts joined when `text` is blank, as a content message's
/// text always is.
String messageCopyText(Message message) {
  if (message.text.trim().isNotEmpty) return message.text;
  final texts = [
    for (final part in message.content ?? const <ContentPart>[])
      if (part.type == ContentPartType.text ||
          part.type == ContentPartType.textDelta)
        if (part.text?.trim().isNotEmpty ?? false) part.text!,
  ];
  return texts.join('\n\n');
}

/// What the inline editor edits and where a Save writes it (Req 25.1,
/// 25.3): the last `text` part of a content message, with its index, else
/// the message's own `text` with no index.
///
/// The last part is the reply's answer; a content message's own `text` is
/// blank, so editing it would save nothing the Server shows.
({String text, int? index}) messageEditTarget(Message message) {
  final content = message.content ?? const <ContentPart>[];
  for (var i = content.length - 1; i >= 0; i--) {
    final part = content[i];
    if (part.type == ContentPartType.text && part.text != null) {
      return (text: part.text!, index: i);
    }
  }
  return (text: message.text, index: null);
}

/// The `option` value of [mode] on `POST /api/convos/fork` (KMP
/// `ForkOption`).
String forkOptionValue(ForkMode mode) => switch (mode) {
  ForkMode.directPath => 'directPath',
  ForkMode.includeBranches => 'includeBranches',
  ForkMode.targetLevel => 'targetLevel',
};

/// "Mar 29, 2026 3:45 PM" in the device's locale and time zone (KMP
/// `formatAbsoluteTimestamp`).
String absoluteTime(DateTime when) =>
    DateFormat('MMM d, y h:mm a').format(when.toLocal());

/// "now", "5m ago", "3h ago", "2d ago" or "3w ago", and [absoluteTime]
/// from 30 days on (KMP `formatRelativeTimestamp`). A time in the future
/// reads as "now".
String relativeTime(DateTime when, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.isNegative || diff.inSeconds < 60) return 'now'; // KMP "now"
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
  return absoluteTime(when);
}

/// The reason keys `/feedback` accepts, each belonging to one rating
/// (KMP `FeedbackTag`, upstream `FEEDBACK_TAGS`). The Server re-checks the
/// pairing, so the sheet only offers the chosen rating's tags.
enum FeedbackTag {
  // Thumbs down, in upstream's order.
  notMatched('not_matched', false, "Didn't match my request"),
  inaccurate('inaccurate', false, 'Inaccurate or incorrect answer'),
  badStyle('bad_style', false, 'Poor style or tone'),
  missingImage('missing_image', false, 'Expected an image'),
  unjustifiedRefusal('unjustified_refusal', false, 'Refused without reason'),
  notHelpful('not_helpful', false, 'Lacked useful information'),
  other('other', false, 'Other issue'),
  // Thumbs up.
  accurateReliable('accurate_reliable', true, 'Accurate and reliable'),
  creativeSolution('creative_solution', true, 'Creative solution'),
  clearWellWritten('clear_well_written', true, 'Clear and well-written'),
  attentionToDetail('attention_to_detail', true, 'Attention to detail');

  const FeedbackTag(this.key, this.up, this.label);

  /// The wire value the Server stores.
  final String key;

  /// Whether the tag belongs to thumbs-up.
  final bool up;

  /// The KMP_App's `feedback_tag_*` label.
  final String label;

  /// The tags offered for a thumbs-[up] rating, in upstream's order.
  static List<FeedbackTag> forRating({required bool up}) => [
    for (final tag in values)
      if (tag.up == up) tag,
  ];
}

/// The `rating` wire value of a thumbs-[up] rating.
String feedbackRatingValue({required bool up}) =>
    up ? 'thumbsUp' : 'thumbsDown';

/// The longest comment the Server stores with a rating.
const maxFeedbackComment = 1024;

/// One stored message of the Active_Path with its actions (Req 25).
///
/// The row under the message holds the SiblingNavigator (Req 17.6), the
/// [MessageTimestamp] and the action buttons: feedback and regenerate on a
/// reply, copy, edit and fork on either. Edit opens the inline editor,
/// whose Save writes the text through `PUT /api/messages/…` (Req 25.3) and
/// whose Submit starts a turn (Req 25.1, 25.4).
///
/// A reply sits in a [QuotableText], so selecting its text offers "Add to
/// chat", which stages the selection as a quote chip (Req 25.10).
///
/// While the conversation has a Run, edit, regenerate, continue, feedback
/// and Sibling switching are disabled, not hidden (Req 25.14). This is the
/// only Run state the row reads, so a streamed event never rebuilds it
/// (Req 18.8).
class MessageActions extends ConsumerStatefulWidget {
  const MessageActions({
    super.key,
    required this.conversationId,
    required this.message,
    required this.parent,
    required this.siblings,
    required this.latestMessageId,
    required this.onSelectSibling,
    this.justSettled = false,
    this.artifactVersions = const {},
  });

  final String conversationId;
  final Message message;

  /// The reply's parent user message, which regenerate, continue and an
  /// assistant edit resubmit. Null on a user message, and on a reply whose
  /// parent is not a user message.
  final Message? parent;

  /// The message's Siblings, oldest first (Req 17.6).
  final List<Message> siblings;

  /// The Active_Path's leaf, sent as the fork's `latestMessageId`.
  final String? latestMessageId;

  /// Shows the Sibling with this id.
  final ValueChanged<String> onSelectSibling;

  /// Whether this is the reply that has just finished streaming.
  final bool justSettled;

  /// The Active_Path's artifacts by identifier (Req 24.12).
  final Map<String, List<Artifact>> artifactVersions;

  @override
  ConsumerState<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends ConsumerState<MessageActions> {
  final _editor = TextEditingController();

  /// Whether the inline editor is open.
  bool _editing = false;

  /// Whether a request of this message's is in flight, which disables the
  /// editor's buttons.
  bool _busy = false;

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  Message get _message => widget.message;

  bool get _isUser => _message.isCreatedByUser;

  /// The parent user message regenerate, continue and an assistant edit
  /// resubmit; null when there is none to resubmit.
  Message? get _userParent {
    final parent = widget.parent;
    return parent != null && parent.isCreatedByUser ? parent : null;
  }

  @override
  Widget build(BuildContext context) {
    // The only Run state the row reads (Req 18.8, 25.14).
    final live = ref.watch(
      runServiceProvider.select(
        (s) => s.runs.containsKey(widget.conversationId),
      ),
    );
    final Widget view = MessageView(
      _message,
      justSettled: widget.justSettled,
      artifactVersions: widget.artifactVersions,
      editor: _editing
          ? InlineMessageEditor(
              controller: _editor,
              enabled: !_busy,
              onCancel: _cancelEdit,
              onSave: () => unawaited(_saveEdit()),
              // A reply with no parent user message has nothing to
              // resubmit, so only Save is offered.
              onSaveAndSubmit: !_isUser && _userParent == null
                  ? null
                  : _submitEdit,
            )
          : null,
      actions: _editing ? null : _bar(live),
    );
    // A reply's text is selectable, and its selection toolbar offers "Add
    // to chat" (Req 25.10). A user message has nothing to quote: it is the
    // user's own words already.
    if (_isUser || _editing) return view;
    return QuotableText(chatKey: widget.conversationId, child: view);
  }

  Widget _bar(bool live) {
    final index = widget.siblings.indexWhere(
      (m) => m.messageId == _message.messageId,
    );
    final feedback = ref.watch(
      featureGatesProvider.select((g) => g.has(Feature.feedback)),
    );
    final rating = _message.feedback?.rating;
    final buttons = <Widget>[
      if (!_isUser && feedback) ...[
        _ActionButton(
          icon: rating == FeedbackRating.thumbsUp
              ? Icons.thumb_up
              : Icons.thumb_up_outlined,
          // KMP cd_thumbs_up
          label: 'Thumbs up',
          selected: rating == FeedbackRating.thumbsUp,
          // KMP cd_feedback_unavailable
          disabledReason: 'Unavailable while a reply is generating',
          onPressed: live ? null : () => unawaited(_feedback(up: true)),
        ),
        _ActionButton(
          icon: rating == FeedbackRating.thumbsDown
              ? Icons.thumb_down
              : Icons.thumb_down_outlined,
          // KMP cd_thumbs_down
          label: 'Thumbs down',
          selected: rating == FeedbackRating.thumbsDown,
          disabledReason: 'Unavailable while a reply is generating',
          onPressed: live ? null : () => unawaited(_feedback(up: false)),
        ),
      ],
      _ActionButton(
        icon: Icons.content_copy,
        label: 'Copy message', // KMP cd_copy_message
        onPressed: () => unawaited(_copy()),
      ),
      _ActionButton(
        icon: Icons.edit,
        label: 'Edit message', // KMP cd_edit_message
        onPressed: live ? null : _startEdit,
      ),
      if (!_isUser) ...[
        _ActionButton(
          icon: Icons.refresh,
          label: 'Regenerate response', // KMP cd_regenerate_response
          onPressed: live || _userParent == null ? null : _regenerate,
        ),
        _ActionButton(
          icon: Icons.play_arrow_outlined,
          // New copy: the KMP_App has none
          label: 'Continue generating',
          onPressed: live || _userParent == null ? null : _continue,
        ),
      ],
      _ActionButton(
        icon: Icons.call_split,
        label: 'Fork conversation from here', // KMP cd_fork_conversation
        onPressed: () => unawaited(_fork()),
      ),
    ];
    return Row(
      children: [
        if (widget.siblings.length > 1 && index >= 0)
          SiblingNavigator(
            index: index,
            count: widget.siblings.length,
            onSelect: live
                ? null
                : (i) => widget.onSelectSibling(widget.siblings[i].messageId),
          ),
        if (_message.createdAt case final createdAt?)
          MessageTimestamp(createdAt),
        // Wraps instead of overflowing when the buttons, the navigator and
        // a large text scale together need more than one line.
        Expanded(
          child: Wrap(alignment: WrapAlignment.end, children: buttons),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Req 25.8.
  Future<void> _copy() async {
    final text = messageCopyText(_message);
    if (text.isEmpty) return;
    await ref.read(platformActionsProvider).copy(text);
    if (mounted) _toast('Copied'); // KMP cd_copied
  }

  void _startEdit() {
    _editor.text = messageEditTarget(_message).text;
    setState(() => _editing = true);
  }

  void _cancelEdit() => setState(() => _editing = false);

  /// Saves the edited text without a new Run (Req 25.3): the Server's
  /// saved message replaces the shown one. The editor stays open with the
  /// text when the request fails.
  Future<void> _saveEdit() async {
    final text = _editor.text.trim();
    if (text.isEmpty) return;
    final target = messageEditTarget(_message);
    setState(() => _busy = true);
    try {
      final saved = await ref
          .read(messagesApiProvider)
          .update(
            widget.conversationId,
            _message.messageId,
            text: text,
            index: target.index,
          );
      await ref
          .read(conversationMessagesProvider(widget.conversationId).notifier)
          .upsertMessage(saved);
      if (mounted) setState(() => _editing = false);
    } on Object catch (e) {
      if (mounted) _toast(userMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A user message's edit goes out as a new Sibling with the new text
  /// (Req 25.1). A reply's regenerates the reply from its parent user
  /// message with `isEdited` (Req 25.4), and does not carry the edited
  /// text: the Server's new reply replaces it, as in the KMP_App and the
  /// web client. Save, next to it, is what stores the text.
  void _submitEdit() {
    final text = _editor.text.trim();
    if (text.isEmpty) return;
    final sent = _isUser
        ? _send(TurnKind.edit, userMessage: _message, text: text)
        : _send(TurnKind.editAi, userMessage: _userParent);
    if (sent) setState(() => _editing = false);
  }

  /// Req 25.2.
  void _regenerate() => _send(TurnKind.regenerate, userMessage: _userParent);

  /// Req 25.5.
  void _continue() => _send(
    TurnKind.continued,
    userMessage: _userParent,
    responseMessageId: _message.messageId,
  );

  /// Hands RunService the turn, with the Composer's selection. Returns
  /// whether it went out; without a selection nothing is sent and the
  /// Composer's refusal shows.
  bool _send(
    TurnKind kind, {
    Message? userMessage,
    String text = '',
    String? responseMessageId,
  }) {
    if (userMessage == null) return false;
    final selection = ref.read(
      composerSelectionProvider(widget.conversationId),
    );
    if (selection == null) {
      // KMP: the Composer's own refusal.
      _toast('Select a model before sending your message.');
      return false;
    }
    unawaited(
      ref
          .read(runServiceProvider.notifier)
          .send(
            widget.conversationId,
            ChatTurn(
              kind: kind,
              selection: selection,
              text: text,
              userMessage: userMessage,
              responseMessageId: responseMessageId,
              isTemporary: ref
                  .read(temporaryChatsProvider)
                  .contains(widget.conversationId),
            ),
          ),
    );
    return true;
  }

  /// A thumb that is already selected clears the feedback (Req 25.7);
  /// either other thumb asks for a reason and an optional comment first,
  /// because the Server rejects a rating without a tag (Req 25.6).
  Future<void> _feedback({required bool up}) async {
    final current = _message.feedback?.rating;
    final selected =
        current == (up ? FeedbackRating.thumbsUp : FeedbackRating.thumbsDown);
    final api = ref.read(messagesApiProvider);
    ({FeedbackTag tag, String? comment})? reason;
    if (!selected) {
      reason = await showModalBottomSheet<({FeedbackTag tag, String? comment})>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _FeedbackSheet(up: up),
      );
      if (reason == null) return;
    }
    try {
      final saved = selected
          ? await api.clearFeedback(widget.conversationId, _message.messageId)
          : await api.setFeedback(
              widget.conversationId,
              _message.messageId,
              rating: feedbackRatingValue(up: up),
              tag: reason!.tag.key,
              text: reason.comment,
            );
      if (!mounted) return;
      await ref
          .read(conversationMessagesProvider(widget.conversationId).notifier)
          .upsertMessage(_message.copyWith(feedback: saved));
    } on Object catch (e) {
      if (mounted) _toast(userMessage(e));
    }
  }

  /// Forks the conversation from this message (Req 25.9): the dialog's
  /// mode and split-at-target go to `POST /api/convos/fork`, the returned
  /// conversation and messages are cached, and the new conversation opens.
  Future<void> _fork() async {
    final settings = ref.read(settingsProvider);
    final conversations = ref.read(conversationsRepositoryProvider);
    final messages = ref.read(messagesRepositoryProvider);
    final choice = await showModalBottomSheet<({ForkMode mode, bool split})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ForkSheet(
        mode: settings.forkMode,
        split: settings.forkSplitAtTarget,
      ),
    );
    if (choice == null || !mounted) return;
    try {
      final forked = await conversations.api.fork(
        conversationId: widget.conversationId,
        messageId: _message.messageId,
        option: forkOptionValue(choice.mode),
        splitAtTarget: choice.split,
        latestMessageId: widget.latestMessageId,
      );
      final newId = forked.conversation.conversationId;
      if (newId == null) return;
      await conversations.upsert(forked.conversation);
      await messages.upsert(newId, forked.messages);
      if (mounted) context.go(Routes.chat(newId));
    } on Object catch (e) {
      if (mounted) _toast(userMessage(e));
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// One action button: an 18 dp icon, as in the KMP_App, in the default
/// 48 dp tap target. A [disabledReason] is read after the label while the
/// button is off, so TalkBack says why (KMP `cd_feedback_unavailable`).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.disabledReason,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final off = onPressed == null;
    final reason = disabledReason;
    return IconButton(
      onPressed: onPressed,
      // The tooltip is what TalkBack reads, so the reason goes here.
      tooltip: off && reason != null ? '$label, $reason' : label,
      iconSize: 18,
      icon: Icon(
        icon,
        color: switch ((off, selected)) {
          // Set explicitly, so a disabled button greys its icon and not
          // just its ripple (KMP ActionButtons).
          (true, _) => colors.onSurfaceVariant.withValues(alpha: 0.38),
          (false, true) => colors.primary,
          (false, false) => colors.onSurfaceVariant,
        },
      ),
    );
  }
}

/// A message timestamp that switches between relative and absolute time on
/// tap (Req 25.13, KMP `MessageTimestamp.kt`).
class MessageTimestamp extends StatefulWidget {
  const MessageTimestamp(this.createdAt, {super.key});

  final DateTime createdAt;

  @override
  State<MessageTimestamp> createState() => _MessageTimestampState();
}

class _MessageTimestampState extends State<MessageTimestamp> {
  bool _absolute = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _absolute
        ? absoluteTime(widget.createdAt)
        : relativeTime(widget.createdAt);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => setState(() => _absolute = !_absolute),
        borderRadius: BorderRadius.circular(8),
        // The label is small; the tap target is not.
        child: SizedBox(
          height: kMinInteractiveDimension,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The inline edit field with Cancel, Save and Save & Submit (KMP
/// `InlineEditInput.kt`). Save and Save & Submit are off while the text is
/// blank and while a save is in flight; a null [onSaveAndSubmit] leaves
/// that button out, for a message with nothing to resubmit.
class InlineMessageEditor extends StatelessWidget {
  const InlineMessageEditor({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onCancel,
    required this.onSave,
    required this.onSaveAndSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback? onSaveAndSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          autofocus: true,
          maxLines: 10,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Edit message', // KMP cd_edit_message
          ),
        ),
        const SizedBox(height: 8),
        // Each button takes a third of the width with an ellipsis, as in
        // the KMP_App, so "Save & Submit" never overflows a phone.
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final ready = enabled && controller.text.trim().isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: enabled ? onCancel : null,
                    child: const _ButtonLabel('Cancel'), // KMP cancel
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: ready ? onSave : null,
                    child: const _ButtonLabel('Save'), // KMP save
                  ),
                ),
                if (onSaveAndSubmit case final submit?) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: ready ? submit : null,
                      // KMP save_and_submit
                      child: const _ButtonLabel('Save & Submit'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// An editor button's label: one line, ellipsised when its third of the
/// row is too narrow for it.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
}

/// The reason picker a thumb opens (Req 25.6, KMP `FeedbackTagSheet.kt`).
/// Submit is off until a reason is picked, because the Server rejects a
/// rating without a tag. Pops `(tag, comment)`, or nothing when dismissed.
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.up});

  final bool up;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _comment = TextEditingController();
  FeedbackTag? _tag;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = FeedbackTag.forRating(up: widget.up);
    // The reasons scroll; the header and Submit stay put, so a short
    // screen or an open keyboard never puts Submit out of reach.
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
                  widget.up
                      // KMP feedback_question_positive
                      ? 'What was good about this response?'
                      // KMP feedback_question
                      : 'What was the issue with this response?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioGroup<FeedbackTag>(
                      groupValue: _tag,
                      onChanged: (next) => setState(() => _tag = next),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final tag in tags)
                            RadioListTile<FeedbackTag>(
                              value: tag,
                              title: Text(tag.label),
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: TextField(
                        controller: _comment,
                        maxLength: maxFeedbackComment,
                        maxLines: 5,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          // KMP hint_optional_comment
                          hintText: 'Optional comment…',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'), // KMP cancel
                  ),
                  TextButton(
                    // The Server rejects a rating with no tag, so an
                    // enabled Submit would only produce a 400.
                    onPressed: _tag == null
                        ? null
                        : () => Navigator.pop(context, (
                            tag: _tag!,
                            comment: _comment.text.trim().isEmpty
                                ? null
                                : _comment.text.trim(),
                          )),
                    child: const Text('Submit'), // KMP action_submit
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

/// The fork options (Req 25.9, KMP `ForkOptionsBottomSheet.kt`), starting
/// from the Settings_Screen's fork defaults. Pops `(mode, split)`.
class _ForkSheet extends StatefulWidget {
  const _ForkSheet({required this.mode, required this.split});

  final ForkMode mode;
  final bool split;

  @override
  State<_ForkSheet> createState() => _ForkSheetState();
}

class _ForkSheetState extends State<_ForkSheet> {
  late ForkMode _mode = widget.mode;
  late bool _split = widget.split;

  static const _rows = <(ForkMode, IconData, String, String)>[
    (
      ForkMode.directPath,
      Icons.linear_scale,
      'Visible messages', // KMP fork_visible_messages
      'Only the direct path of messages', // KMP fork_visible_messages_desc
    ),
    (
      ForkMode.includeBranches,
      Icons.call_split,
      'Include branches', // KMP fork_include_branches
      'Direct path plus sibling messages', // KMP fork_include_branches_desc
    ),
    (
      ForkMode.targetLevel,
      Icons.account_tree,
      'All to target level', // KMP fork_all_to_target
      // KMP fork_all_to_target_desc
      'All messages and branches up to this level',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The modes scroll; the header and Fork stay put, so a short screen
    // never puts Fork out of reach.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Semantics(
              header: true,
              child: Text(
                'Fork Conversation', // KMP fork_conversation
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioGroup<ForkMode>(
                    groupValue: _mode,
                    onChanged: (next) => setState(() => _mode = next ?? _mode),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (mode, icon, label, description) in _rows)
                          RadioListTile<ForkMode>(
                            value: mode,
                            secondary: Icon(icon),
                            title: Text(label),
                            subtitle: Text(description),
                          ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    value: _split,
                    onChanged: (on) => setState(() => _split = on ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      // KMP fork_start_new
                      'Start new conversation from target',
                    ),
                    subtitle: const Text(
                      // KMP fork_start_new_desc
                      'Begin the fork from the selected message instead of '
                      'the root',
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  onPressed: () =>
                      Navigator.pop(context, (mode: _mode, split: _split)),
                  // New copy: the KMP_App forks on a row tap, which has no
                  // room for the Settings_Screen's default.
                  child: const Text('Fork'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
