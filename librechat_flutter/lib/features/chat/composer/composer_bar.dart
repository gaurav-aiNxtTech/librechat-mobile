import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_gate.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/ui/platform_actions.dart';
import '../../files/files_api.dart';
import '../data/conversation_messages.dart';
import '../run/run_service.dart';
import '../run/run_state.dart';
import '../send/chat_turn.dart';
import 'attachments.dart';
import 'composer_controller.dart';
import 'model_selector.dart';

/// The Composer at the bottom of the Chat_Screen: the model chip, the
/// temporary chat toggle, the text field and Send or Stop
/// (KMP CommonChatInputCore.kt).
///
/// [chatKey] is [newChatKey] or the conversation id, and [runKey] the key
/// its Runs go under: the landing visit's `new:<uuid>`, or the conversation
/// id.
///
/// - **Stop (Req 20.1, 20.8).** While the chat has a Run, in every phase,
///   Stop replaces Send; it is disabled while a Stop is pending.
/// - **Send.** Disabled for blank text with no attachment, and while an
///   upload runs (Req 26.7). A conversation sends once its messages are
///   loaded, as a reply to the last confirmed message. After a send the
///   keyboard closes when AppSettings `dismissKeyboardOnSend` is on
///   (Req 40.6).
/// - **Attachments (Req 26.1, 26.6-26.8).** The attach button picks files,
///   photos or a photo from the camera, [ComposerController.stageFiles]
///   checks them against the Server's limits, a delivery choice is asked
///   for when a file has one (Req 26.5), and the chips above the field show
///   each upload's progress, cancel, retry and remove.
/// - **Temporary chat (Req 21.5).** With `Feature.temporaryChat`, the
///   landing state shows the toggle and a temporary conversation shows it
///   on, as a fixed indicator (as in the KMP_App).
/// - **Errors.** A Run that ended with no reply to show its error in, such
///   as a failed start, shows the error in a SnackBar (`errors[runKey]`).
class ComposerBar extends ConsumerStatefulWidget {
  const ComposerBar({super.key, required this.chatKey, required this.runKey});

  final String chatKey;
  final String runKey;

  @override
  ConsumerState<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends ConsumerState<ComposerBar> {
  late final TextEditingController _text;

  NotifierProvider<ComposerController, ComposerState> get _provider =>
      composerProvider(widget.chatKey);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(_provider).text);
    // Text set by the controller, such as a restored draft, reaches the
    // field; the field's own edits already match.
    ref.listenManual(_provider.select((s) => s.text), (_, text) {
      if (text == _text.text) return;
      _text.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
    ref.listenManual(
      runServiceProvider.select((s) => s.errors[_key(s)]),
      (_, error) => _showError(error),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _key(ConversationRuns s) => s.movedTo[widget.runKey] ?? widget.runKey;

  void _showError(String? error) {
    if (error == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(error)));
      final runs = ref.read(runServiceProvider.notifier);
      runs.dismissError(_key(ref.read(runServiceProvider)));
    });
  }

  void _send() {
    String? parent;
    if (widget.chatKey != newChatKey) {
      final messages = ref.read(conversationMessagesProvider(widget.chatKey));
      // Until the messages load, the parent of the next message is unknown.
      final data = messages.value;
      if (data == null) return;
      parent = data.nextParentId;
    }
    final sent = ref
        .read(_provider.notifier)
        .submit(widget.runKey, parentMessageId: parent);
    if (sent && ref.read(settingsProvider).dismissKeyboardOnSend) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _pickModel(ChatSelection? current) async {
    final picked = await showModelSelector(context, selected: current);
    if (picked != null && mounted) ref.read(_provider.notifier).select(picked);
  }

  /// Picks from [source], checks the set and starts the uploads, asking
  /// about delivery first when a file has a choice (Req 26.1, 26.5, 26.6).
  Future<void> _attach(AttachSource source) async {
    final controller = ref.read(_provider.notifier);
    final actions = ref.read(platformActionsProvider);
    final List<PickedFile> picked;
    try {
      picked = switch (source) {
        AttachSource.files => await actions.pickFiles(),
        AttachSource.photos => await actions.pickImages(),
        AttachSource.camera => [?await actions.takePhoto()],
      };
    } on PlatformException {
      // A refused permission names the feature and leaves the rest of the
      // Composer working (Req 44.11).
      controller.showError(switch (source) {
        AttachSource.camera =>
          'Camera access is off, so no photo can be taken. '
              'Files and photos still attach.',
        AttachSource.photos => 'Photo access is off, so no photo can be read.',
        AttachSource.files => 'The file picker could not be opened.',
      });
      return;
    }
    if (picked.isEmpty) return;

    final batch = await controller.stageFiles(picked);
    if (batch == null || batch.files.isEmpty || !mounted) return;
    var routes = [for (final _ in batch.files) UploadRoute.provider];
    if (batch.choosable.contains(true)) {
      final chosen = await showDeliverySheet(
        context,
        files: [for (final file in batch.files) file.info],
        choosable: batch.choosable,
      );
      // Backing out of the choice attaches nothing (Req 26.5).
      if (chosen == null || !mounted) return;
      routes = chosen;
    }
    controller.attach(batch.files, routes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final selection = ref.watch(composerSelectionProvider(widget.chatKey));
    final data = ref.watch(selectorDataProvider);
    final label = selection == null ? null : selectionLabel(selection, data);
    // Null without a Run, else whether Stop is enabled.
    final run = ref.watch(
      runServiceProvider.select((s) => s.runs[_key(s)]?.canStop),
    );
    // Watching the limits loads them before the first pick. An empty set
    // is refused only when the endpoint takes no uploads at all, which
    // turns the attach button off (Req 26.2).
    final fileConfig = ref.watch(fileConfigProvider).value;
    final uploadsOff =
        fileConfig != null &&
        selection != null &&
        checkAttachments(
              const [],
              fileConfig,
              selection.endpoint,
              endpointType: selection.endpointType,
            )
            is AttachmentRejected;
    final landing = widget.chatKey == newChatKey;
    final showTemporary =
        ref.watch(
          featureGatesProvider.select((g) => g.has(Feature.temporaryChat)),
        ) &&
        (landing || state.temporary);
    final error = state.error;

    final Widget action;
    if (run != null) {
      action = IconButton.filledTonal(
        tooltip: 'Stop generation', // KMP cd_stop_generation
        onPressed: run ? () => unawaited(_stop()) : null,
        icon: const Icon(Icons.stop),
      );
    } else {
      // A file on its own is a message; an upload still running is not
      // (Req 26.7).
      final canSend =
          !state.isUploading &&
          (state.text.trim().isNotEmpty || state.uploaded.isNotEmpty);
      action = IconButton.filled(
        tooltip: 'Send message', // KMP cd_send_message
        onPressed: canSend ? _send : null,
        icon: const Icon(Icons.arrow_upward),
      );
    }

    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ModelSelectorButton(
                        label: label,
                        onPressed: () => unawaited(_pickModel(selection)),
                      ),
                    ),
                  ),
                  if (showTemporary)
                    _TemporaryToggle(
                      on: state.temporary,
                      onToggle: landing ? controller.toggleTemporary : null,
                    ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              AttachmentChips(
                files: state.files,
                onRemove: controller.removeFile,
                onCancel: controller.cancelUpload,
                onRetry: controller.retryUpload,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AttachButton(
                    enabled: !uploadsOff,
                    onSource: (source) => unawaited(_attach(source)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      onChanged: controller.setText,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: label == null
                            ? 'Message…' // KMP hint_message
                            : 'Message $label', // KMP hint_message_model
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  action,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _stop() =>
      ref.read(runServiceProvider.notifier).stop(widget.runKey);
}

/// The temporary chat toggle (KMP TempChatToggle.kt). [onToggle] is null
/// for a temporary conversation, where it only shows the mode.
class _TemporaryToggle extends StatelessWidget {
  const _TemporaryToggle({required this.on, required this.onToggle});

  final bool on;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: on,
      label: on
          ? 'Disable temporary chat' // KMP TempChatToggle
          : 'Enable temporary chat', // KMP TempChatToggle
      excludeSemantics: true,
      onTap: onToggle,
      child: IconButton(
        onPressed: onToggle,
        isSelected: on,
        icon: Icon(
          on ? Icons.visibility_off : Icons.visibility,
          color: on ? colors.primary : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
