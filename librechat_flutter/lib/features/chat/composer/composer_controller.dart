import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/server_config.dart';
import '../../../core/log/diagnostic_log.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/file_config.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/ui/platform_actions.dart';
import '../../conversations/conversations_repository.dart';
import '../../files/files_api.dart';
import '../data/conversation_messages.dart';
import '../data/messages_repository.dart';
import '../run/run_service.dart';
import '../send/chat_turn.dart';
import 'attachments.dart';
import 'model_selector.dart';

part 'composer_controller.freezed.dart';

const _uuid = Uuid();

/// The Composer key of the landing state; a conversation's is its id.
const newChatKey = 'new';

/// What the Composer holds for one chat.
///
/// [selection] is the user's own pick in this Composer; until there is one,
/// [composerSelectionProvider] falls back to the conversation's or the
/// default. [quotes] are the excerpts staged by "Add to chat" (Req 25.10).
/// [files] are the attachments, uploading or uploaded (Req 26.6).
/// [temporary] is the temporary chat toggle (Req 21.5). [error] says why
/// the last send or pick was refused, until the text or selection changes.
///
/// Tools and parameters (Task 21.6) join here.
@freezed
abstract class ComposerState with _$ComposerState {
  const factory ComposerState({
    @Default('') String text,
    ChatSelection? selection,
    @Default(<String>[]) List<String> quotes,
    @Default(<StagedAttachment>[]) List<StagedAttachment> files,
    @Default(false) bool temporary,
    String? error,
  }) = _ComposerState;

  const ComposerState._();

  /// Whether an upload is still running, which holds back Send (Req 26.7).
  bool get isUploading => files.any((f) => f.isUploading);

  /// The attachments a send carries: the ones the Server now holds
  /// (Req 26.6). A failed upload is left out rather than sent as an id the
  /// Server never stored.
  List<Attachment> get uploaded => [for (final f in files) ?f.uploaded];
}

/// Files the user picked, read and checked, with the ones that have a
/// delivery choice marked (Req 26.5). See [ComposerController.stageFiles].
typedef StagedBatch = ({List<StagedAttachment> files, List<bool> choosable});

/// The Composer of one chat, by [newChatKey] or conversation id. See
/// [ComposerController].
final composerProvider = NotifierProvider.autoDispose
    .family<ComposerController, ComposerState, String>(ComposerController.new);

/// The selection a send from [chatKey]'s Composer uses: the Composer's own
/// pick, else [baseSelectionProvider]. Null when nothing can be selected.
final composerSelectionProvider = Provider.autoDispose
    .family<ChatSelection?, String>(
      (ref, chatKey) =>
          ref.watch(composerProvider(chatKey).select((s) => s.selection)) ??
          ref.watch(baseSelectionProvider(chatKey)),
    );

/// [chatKey]'s selection before the user picks one in its Composer: the
/// conversation's endpoint, model, agent and spec (from its cached row,
/// else its Run), else, in the landing state and for a conversation not
/// known yet, the [defaultSelection] from the last used choice (Req 21.1).
final baseSelectionProvider = Provider.autoDispose
    .family<ChatSelection?, String>((ref, chatKey) {
      if (chatKey != newChatKey) {
        final row = ref.watch(conversationRowProvider(chatKey)).value;
        if (row?.endpoint case final endpoint?) {
          return ChatSelection(
            endpoint: endpoint,
            endpointType: row!.endpointType,
            model: row.model,
            agentId: row.agentId,
            spec: row.spec,
            modelLabel: row.modelLabel,
          );
        }
        final run = ref.watch(
          runServiceProvider.select((s) => s.runs[chatKey]?.selection),
        );
        if (run != null) return run;
      }
      final last = ref.watch(
        settingsProvider.select(
          (s) => (s.lastEndpoint, s.lastModel, s.lastSpec),
        ),
      );
      return defaultSelection(
        ref.watch(selectorDataProvider),
        lastEndpoint: last.$1,
        lastModel: last.$2,
        lastSpec: last.$3,
      );
    });

/// The Composer's text, draft, selection and send (Req 17.9, 20.5,
/// 21.1, 21.5-21.9).
///
/// - **Drafts (Req 21.7, 21.8).** `build` restores the chat's draft unless
///   the user typed first. Each text change saves the draft after
///   [draftDelay], and disposal saves a pending change. A temporary chat
///   keeps no draft (Req 21.6).
/// - **Send.** [submit] ignores blank text and does nothing while the chat
///   has a Run (sending during a Run is Task 23.2's). It hands RunService a
///   send turn with the [composerSelectionProvider] selection and clears
///   the text; RunService deletes the draft (Req 21.9). The Composer bar
///   closes the keyboard when AppSettings `dismissKeyboardOnSend` is on
///   (Req 40.6).
/// - **Selection (Req 21.1).** [select] picks a model, agent or spec and
///   stores it as the last used choice.
/// - **Quotes (Req 25.10).** [addQuote] stages an excerpt a reply's "Add to
///   chat" captured, [removeQuote] drops one, and a send carries them and
///   clears them. The payload builder drops them on an Assistants
///   endpoint, which takes none.
/// - **Attachments (Req 26.3, 26.5-26.8).** [stageFiles] reads what the
///   user picked and checks the set against the Server's limits, naming
///   the first one it breaks; [attach] then starts one upload per file,
///   which [cancelUpload], [retryUpload] and [removeFile] manage.
///   [attachServerFiles] takes files the Server already holds. A send
///   carries the uploaded ones and clears the list, and does nothing while
///   an upload runs.
/// - **Temporary chat (Req 21.5, 21.6).** The landing state's toggle;
///   a temporary conversation's Composer starts on and cannot turn it off.
class ComposerController extends Notifier<ComposerState> {
  ComposerController(this.chatKey);

  final String chatKey;

  /// How long a text change waits before it is saved as the draft.
  static const draftDelay = Duration(milliseconds: 500);

  late MessagesRepository _repository;
  late ProviderContainer _container;
  Timer? _draftTimer;

  /// The cancel token of each upload still running, by `file_id`
  /// (Req 26.6).
  final _tokens = <String, CancelToken>{};

  /// The text the user changed and the draft does not hold yet.
  String? _unsaved;

  /// Whether the user typed or text came back, so a late draft load must
  /// not overwrite it.
  bool _touched = false;

  bool get _isLanding => chatKey == newChatKey;

  @override
  ComposerState build() {
    _repository = ref.read(messagesRepositoryProvider);
    _container = ref.container;
    final temporary = !_isLanding && ref.read(isTemporaryChatProvider(chatKey));
    ref.onDispose(() {
      _draftTimer?.cancel();
      if (_unsaved case final text?) _saveDraft(text);
      for (final token in _tokens.values) {
        token.cancel();
      }
      _tokens.clear();
    });
    if (!temporary) unawaited(_restoreDraft());
    return ComposerState(temporary: temporary);
  }

  Future<void> _restoreDraft() async {
    final String? draft;
    try {
      draft = await _repository.draft(chatKey);
    } on Object catch (e, st) {
      _log('draft_read_failed', e, st);
      return;
    }
    if (!ref.mounted || _touched || draft == null || draft.isEmpty) return;
    state = state.copyWith(text: draft);
  }

  /// The user changed the text field to [text].
  void setText(String text) {
    if (text == state.text) return;
    _touched = true;
    state = state.copyWith(text: text, error: null);
    _scheduleDraft(text);
  }

  /// Puts back [text] that was not sent: after an earlyAbort or a failed
  /// start (Req 20.5). Text typed since goes after it.
  void restoreText(String text) {
    if (text.trim().isEmpty) return;
    final current = state.text;
    setText(current.trim().isEmpty ? text : '$text\n$current');
  }

  /// Picks [selection] for this chat and stores it as the last used choice
  /// (Req 21.1). On the agents endpoint the agent id is the stored model.
  void select(ChatSelection selection) {
    state = state.copyWith(selection: selection, error: null);
    final settings = ref.read(settingsProvider.notifier);
    unawaited(
      settings.save(
        ref
            .read(settingsProvider)
            .copyWith(
              lastEndpoint: selection.endpoint,
              lastModel: selection.agentId ?? selection.model,
              lastSpec: selection.spec,
            ),
      ),
    );
  }

  /// Stages [quote] as a quote chip, which goes out with the next message
  /// (Req 25.10). A blank excerpt and one already staged are ignored, so a
  /// second "Add to chat" on the same selection adds nothing.
  void addQuote(String quote) {
    final text = quote.trim();
    if (text.isEmpty || state.quotes.contains(text)) return;
    state = state.copyWith(quotes: [...state.quotes, text], error: null);
  }

  /// Drops the quote chip at [index] (Req 25.10).
  void removeQuote(int index) {
    if (index < 0 || index >= state.quotes.length) return;
    state = state.copyWith(
      quotes: [...state.quotes]..removeAt(index),
      error: null,
    );
  }

  /// Shows [message] in the Composer, for a pick the platform refused,
  /// such as a denied camera permission (Req 44.11).
  void showError(String message) => state = state.copyWith(error: message);

  /// Turns the landing state's temporary chat toggle on or off (Req 21.5).
  /// A conversation's mode is fixed.
  void toggleTemporary() {
    if (!_isLanding) return;
    state = state.copyWith(temporary: !state.temporary);
  }

  /// Reads [picked] and checks the whole set against the Server's limits
  /// (Req 26.2, 26.3). Null when the set is refused, with the Composer's
  /// error naming the first limit it breaks, or when a file cannot be
  /// read; nothing is attached either way.
  ///
  /// The bytes are read here, before the check, so the size and the mime
  /// type are the file's own rather than the picker's guess, and are kept
  /// for the upload and for a retry. The files already staged count
  /// towards the limits, since they go out in the same message.
  ///
  /// `choosable` marks the files the user is asked about (Req 26.5). The
  /// caller shows [showDeliverySheet] when any is set and hands the routes
  /// back to [attach].
  Future<StagedBatch?> stageFiles(List<PickedFile> picked) async {
    if (picked.isEmpty) {
      return (files: const <StagedAttachment>[], choosable: const <bool>[]);
    }
    final config = await _fileConfig();
    if (!ref.mounted) return null;
    final staged = <StagedAttachment>[];
    for (final file in picked) {
      final Uint8List bytes;
      try {
        bytes = await file.read();
      } on Object catch (e, st) {
        _log('attachment_read_failed', e, st);
        if (ref.mounted) {
          state = state.copyWith(error: 'Could not read ${file.name}.');
        }
        return null;
      }
      staged.add(
        StagedAttachment(
          fileId: _uuid.v4(),
          info: FileInfo.detect(
            name: file.name,
            size: bytes.length,
            headerBytes: bytes,
          ),
          bytes: bytes,
        ),
      );
    }
    if (!ref.mounted) return null;

    final selection = _selection;
    final endpoint = selection?.endpoint ?? '';
    final verdict = checkAttachments(
      [
        for (final f in [...state.files, ...staged]) f.info,
      ],
      config,
      endpoint,
      endpointType: selection?.endpointType,
    );
    if (verdict case final AttachmentRejected rejected) {
      state = state.copyWith(
        error: attachmentLimitMessage(
          rejected,
          config,
          endpoint,
          endpointType: selection?.endpointType,
        ),
      );
      return null;
    }
    final context = _contextAvailable(selection);
    return (
      files: staged,
      choosable: [
        for (final f in staged) context && canDeliverAsText(f.info, config),
      ],
    );
  }

  /// Attaches [staged] on [routes], one route per file in the same order,
  /// and starts an upload for each (Req 26.6).
  void attach(List<StagedAttachment> staged, List<UploadRoute> routes) {
    final files = [
      for (final (index, file) in staged.indexed)
        file.copyWith(
          // An image always goes to the provider: the text path stamps
          // `source: text`, which the Server's attachment pass stops at
          // before its image branch, so the model would see no image.
          route: file.isImage
              ? UploadRoute.provider
              : routes.elementAtOrNull(index) ?? UploadRoute.provider,
        ),
    ];
    if (files.isEmpty) return;
    state = state.copyWith(files: [...state.files, ...files], error: null);
    for (final file in files) {
      unawaited(_upload(file));
    }
  }

  /// Attaches files the Server already holds, from the Files_Manager's
  /// picker mode or a share (Req 26.1). They need no upload, so their
  /// chips start done.
  void attachServerFiles(List<FileObject> files) {
    final staged = [
      for (final file in files)
        if (file.fileId case final id?)
          if (!state.files.any((f) => f.fileId == id))
            StagedAttachment(
              fileId: id,
              info: FileInfo(
                name: file.filename ?? id,
                size: file.bytes ?? 0,
                mimeType: file.type ?? 'application/octet-stream',
              ),
              uploaded: Attachment(
                fileId: id,
                filename: file.filename,
                filepath: file.filepath,
                type: file.type,
                bytes: file.bytes,
                width: file.width,
                height: file.height,
              ),
            ),
    ];
    if (staged.isEmpty) return;
    state = state.copyWith(files: [...state.files, ...staged], error: null);
  }

  /// Drops [file] from the message (Req 26.8). An upload still running is
  /// cancelled with it.
  void removeFile(StagedAttachment file) {
    _tokens.remove(file.fileId)?.cancel();
    state = state.copyWith(
      files: [
        for (final f in state.files)
          if (f.fileId != file.fileId) f,
      ],
      error: null,
    );
  }

  /// Cancels [file]'s upload and drops its chip (Req 26.6).
  void cancelUpload(StagedAttachment file) => removeFile(file);

  /// Uploads [file] again after a failure (Req 26.6). The route is kept:
  /// the user chose it for this file.
  void retryUpload(StagedAttachment file) {
    final current = _file(file.fileId);
    if (current == null || current.bytes == null) return;
    final retried = current.copyWith(clearError: true, clearProgress: true);
    state = state.copyWith(files: _replaced(retried), error: null);
    unawaited(_upload(retried));
  }

  /// The upload limits, or the Server's built-in defaults when the config
  /// cannot be loaded, as the web client falls back (Req 26.2).
  Future<FileConfig> _fileConfig() async {
    try {
      return await ref.read(fileConfigProvider.future);
    } on Object catch (e, st) {
      _log('file_config_failed', e, st);
      return builtInFileConfig;
    }
  }

  /// Whether this chat can deliver a file as extracted text: the agents
  /// endpoint with the Server's `context` capability (Req 26.5).
  bool _contextAvailable(ChatSelection? selection) {
    if (selection?.endpoint != agentsEndpoint) return false;
    final info = ref.read(serverConfigProvider).value;
    final capabilities = info?.endpoints[agentsEndpoint]?.capabilities;
    return capabilities?.contains('context') ?? false;
  }

  Future<void> _upload(StagedAttachment file) async {
    final bytes = file.bytes;
    if (bytes == null) return;
    final selection = _selection;
    final token = CancelToken();
    _tokens[file.fileId] = token;
    final (width, height) = file.isImage
        ? await _imageSize(bytes)
        : (null, null);
    try {
      final object = await ref
          .read(filesApiProvider)
          .upload(
            bytes: bytes,
            filename: file.name,
            type: file.info.mimeType,
            fileId: file.fileId,
            endpoint: selection?.endpoint,
            model: selection?.agentId == null ? selection?.model : null,
            agentId: selection?.agentId,
            toolResource: file.route.toolResource,
            width: width,
            height: height,
            onProgress: (sent, total) {
              if (total <= 0) return;
              _patch(file.fileId, (f) => f.copyWith(progress: sent / total));
            },
            cancelToken: token,
          );
      _patch(
        file.fileId,
        (f) => f.copyWith(
          progress: 1,
          uploaded: Attachment(
            fileId: object.fileId ?? file.fileId,
            filename: object.filename ?? f.name,
            filepath: object.filepath,
            type: object.type ?? f.info.mimeType,
            bytes: object.bytes ?? f.info.size,
            width: object.width ?? width,
            height: object.height ?? height,
          ),
        ),
      );
    } on Object catch (e, st) {
      // A cancel already dropped the chip, and the upload the user ended
      // is not a failure.
      if (e is DioException && CancelToken.isCancel(e)) return;
      _log('upload_failed', e, st);
      _patch(
        file.fileId,
        (f) => f.copyWith(error: userMessage(e), clearProgress: true),
      );
    } finally {
      _tokens.remove(file.fileId);
    }
  }

  /// [bytes]'s pixel size, which an image upload sends so the Server stores
  /// it without decoding. Null for bytes no codec recognises.
  static Future<(int?, int?)> _imageSize(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } on Object {
      return (null, null);
    }
  }

  StagedAttachment? _file(String fileId) =>
      state.files.where((f) => f.fileId == fileId).firstOrNull;

  List<StagedAttachment> _replaced(StagedAttachment file) => [
    for (final f in state.files) f.fileId == file.fileId ? file : f,
  ];

  /// Applies [change] to the staged file [fileId], if it is still staged.
  void _patch(
    String fileId,
    StagedAttachment Function(StagedAttachment file) change,
  ) {
    if (!ref.mounted) return;
    final file = _file(fileId);
    if (file == null) return;
    state = state.copyWith(files: _replaced(change(file)));
  }

  ChatSelection? get _selection =>
      state.selection ?? ref.read(baseSelectionProvider(chatKey));

  /// Sends the Composer's text and attachments under [runKey] (the
  /// conversation id, or the landing visit's `new:<uuid>` key) as a reply
  /// to [parentMessageId] (null for the Root_Parent_Id). Returns whether it
  /// was sent; a chat with a Run, a missing selection, a running upload
  /// (Req 26.7) and blank text with no attachment send nothing.
  bool submit(String runKey, {String? parentMessageId}) {
    final text = state.text;
    if (!_send(runKey, text, parentMessageId)) return false;
    _draftTimer?.cancel();
    _unsaved = null;
    // The quotes and the attachments went out with the message
    // (Req 25.10, 26.6).
    state = state.copyWith(
      text: '',
      quotes: const [],
      files: const [],
      error: null,
    );
    return true;
  }

  /// Sends [text], such as a conversation starter (Req 17.9), leaving the
  /// Composer's own text as it is.
  bool submitText(String runKey, String text, {String? parentMessageId}) =>
      _send(runKey, text, parentMessageId);

  bool _send(String runKey, String text, String? parentMessageId) {
    final files = state.uploaded;
    // A file on its own is a message; text and files both empty is not.
    if (text.trim().isEmpty && files.isEmpty) return false;
    // Sending is off until every upload has finished (Req 26.7).
    if (state.isUploading) return false;
    final runs = ref.read(runServiceProvider);
    if (runs.runs.containsKey(runs.movedTo[runKey] ?? runKey)) return false;
    final selection = _selection;
    final refusal = switch (selection) {
      null => 'Select a model before sending your message.', // KMP
      ChatSelection(endpoint: agentsEndpoint, agentId: null, spec: null) =>
        'Select an agent before sending your message.', // KMP
      _ => null,
    };
    if (refusal != null) {
      state = state.copyWith(error: refusal);
      return false;
    }
    unawaited(
      ref
          .read(runServiceProvider.notifier)
          .send(
            runKey,
            ChatTurn(
              kind: TurnKind.send,
              selection: selection!,
              text: text,
              files: files,
              // `buildChatPayload` leaves them out on an Assistants
              // endpoint, which takes no quotes (Req 25.10).
              quotes: state.quotes,
              isTemporary: state.temporary,
              parentMessageId: parentMessageId,
            ),
          ),
    );
    return true;
  }

  void _scheduleDraft(String text) {
    if (state.temporary) return;
    _unsaved = text;
    _draftTimer?.cancel();
    _draftTimer = Timer(draftDelay, () {
      _unsaved = null;
      _saveDraft(text);
    });
  }

  void _saveDraft(String text) => unawaited(
    _repository
        .saveDraft(chatKey, text)
        .catchError(
          (Object e, StackTrace st) => _log('draft_save_failed', e, st),
        ),
  );

  void _log(String event, Object e, StackTrace st) =>
      _container.read(diagnosticLogProvider).error('composer', event, e, st);
}
