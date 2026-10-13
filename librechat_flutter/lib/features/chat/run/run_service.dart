import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/log/diagnostic_log.dart';
import '../../../core/models/content_part.dart';
import '../../../core/models/conversation.dart';
import '../../../core/models/message.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/stream/event_mapper.dart';
import '../../../core/stream/stream_client.dart';
import '../../../core/stream/stream_events.dart';
import '../../conversations/conversations_repository.dart';
import '../data/chat_api.dart';
import '../data/conversation_messages.dart';
import '../composer/composer_controller.dart';
import '../data/messages_repository.dart';
import '../send/chat_turn.dart';
import '../send/payload_builder.dart';
import '../tree/message_tree.dart';
import 'final_merge.dart';
import 'run_reducer.dart';
import 'run_state.dart';

const _uuid = Uuid();

/// The prefix of a landing visit's Run key, `new:<uuid>`.
const newChatPrefix = 'new:';

/// A fresh Run key for one landing visit (see [ConversationRuns.movedTo]).
String newChatRunKey() => '$newChatPrefix${_uuid.v4()}';

/// The device's IANA time zone id, read once per app run and sent with each
/// start request; null when the platform can't tell. Tests override it.
final deviceTimeZoneProvider = FutureProvider<String?>((ref) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Exception {
    return null;
  }
});

/// The app's [RunService]. It holds per-user state, so a user change
/// rebuilds it and cancels every Run.
final runServiceProvider = NotifierProvider<RunService, ConversationRuns>(
  RunService.new,
);

/// How long a Stop waits for the aborted Final_Frame after the abort ack
/// before it closes the Stream and keeps the partial reply (Req 20.4).
/// Tests shorten it.
final stopWatchdogProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
);

/// Why a Run ended. [RunService] decides what stays on screen per reason:
///
/// - [finalized]: the Final_Frame's turn, applied by the final handling.
/// - [error]: the Optimistic_Message and the partial reply with an `error`
///   part stay as local messages (Req 18.14). Before a Stream exists, or
///   before a new chat's `created`, the Run is un-sent instead.
/// - [abortFallback]: as for [error], without the `error` part (Req 20.4).
/// - [resumeExpired], [reloadNeeded]: the reply is dropped and the
///   conversation reloads from the Server (Req 19.5, 19.6). Before a new
///   chat's `created` there is nothing to reload, so the Run is un-sent.
enum RunEnd { finalized, error, abortFallback, resumeExpired, reloadNeeded }

/// A Run's private plumbing, which never goes into the state: its Stream
/// subscription, timers and pending deltas. [key] follows the Run when it
/// moves to its conversation id. [replyParentId] is the parent of a partial
/// reply kept after an error.
class _Live {
  _Live(this.key, this.epoch, this.replyParentId, this.mapper);

  String key;
  final int epoch;
  final String? replyParentId;
  final EventMapper mapper;
  StreamSubscription<StreamEvent>? subscription;
  Timer? flushTimer;

  /// The Stop watchdog (Req 20.4).
  Timer? watchdog;

  /// Whether a status request for this Run is in flight.
  bool checking = false;

  /// Text and reasoning deltas waiting for the next flush.
  final buffer = <StreamEvent>[];

  void cancel() {
    unawaited(subscription?.cancel());
    flushTimer?.cancel();
    watchdog?.cancel();
    subscription = null;
    flushTimer = null;
    watchdog = null;
    buffer.clear();
  }
}

/// Runs chat turns and owns all live state (Req 18, 21.6, 21.9–21.11).
///
/// - **Start.** [send] shows the Optimistic_Message and the waiting
///   indicator at once (Req 18.1, 18.9), deletes the draft (Req 21.9),
///   sends the start request (Req 18.2) and opens the Stream (Req 18.3).
/// - **Events.** Deltas wait in a per-Run buffer that a [flushInterval]
///   timer applies, so listeners see at most 20 delta updates per second
///   (Req 18.8). Any other event flushes the buffer first, so order holds.
///   `created` moves a `new:` Run to its conversation id (Req 18.10).
/// - **Final.** The Final_Frame swaps the live reply for the Server's turn
///   in one synchronous block (Req 18.11). The Cache write, the
///   conversation row and the title follow (Req 18.13, 21.10, 21.11),
///   except in a temporary chat (Req 21.6).
/// - **Stop.** [stop] sends the abort and keeps reading the Stream, whose
///   aborted Final_Frame ends the Run (Req 20.2, 20.3). Without a Final
///   within [stopWatchdogProvider] of the ack, or when the abort fails, the
///   Run ends keeping its partial reply (Req 20.4).
/// - **Recovery.** When the reconnect ladder is used up, the status route
///   decides: an active Run is resumed once more, an ended one reloads, and
///   otherwise the Run is `detached` with a network error, keeping its
///   partial reply (Req 19.6, 19.7). [onOpen] and the network coming back
///   check a detached Run again, and [onOpen] attaches to a Run the Server
///   has for a conversation with none here (Req 19.8, 19.9).
/// - **End.** [_end] is the only exit of a Run. Each Run carries an epoch,
///   and timers and Stream callbacks of a stale Run are ignored, so a Run
///   ends exactly once.
///
/// Sending during a Run is Task 23.2's.
class RunService extends Notifier<ConversationRuns> {
  /// How long deltas wait before they are applied (Req 18.8).
  static const flushInterval = Duration(milliseconds: 50);

  final _live = <String, _Live>{};
  int _epochs = 0;

  /// Conversations whose [onOpen] status request, for a Run this service
  /// does not hold, is in flight.
  final _attaching = <String>{};

  /// Bumped by each build, so follow-ups of a previous user's Run stop.
  int _generation = 0;

  @override
  ConversationRuns build() {
    ref.watch(authServiceProvider.select((a) => a.session?.user.id));
    _generation++;
    ref.onDispose(_cancelAll);
    // The network coming back retries every detached Run (Req 19.8). A
    // container listener, unlike `ref.listen`, isn't paused while nothing
    // watches this service, as on the conversation list.
    final online = ref.container.listen(onlineProvider, (previous, next) {
      if (next.value == true && previous?.value == false) _recoverDetached();
    });
    ref.onDispose(online.close);
    return const ConversationRuns();
  }

  /// Whether [conversationId] is a temporary chat of this app run, whose
  /// messages are never cached (Req 21.6).
  bool isTemporary(String conversationId) =>
      ref.read(temporaryChatsProvider).contains(conversationId);

  /// Clears the banner error of [key] (see [ConversationRuns.errors]).
  void dismissError(String key) {
    if (!state.errors.containsKey(key)) return;
    state = state.copyWith(errors: {...state.errors}..remove(key));
  }

  /// Runs [turn] under [key]: a conversation id, or a landing visit's
  /// `new:<uuid>` key (a moved one resolves to its conversation id).
  ///
  /// Does nothing while [key] has a Run; `sendDuringRun` (Task 23.2) takes
  /// those turns. A failed start un-sends the turn: the Run goes, its text
  /// goes back to the Composer and the error goes to
  /// [ConversationRuns.errors]. The returned future completes once the
  /// Stream is open or the start failed.
  Future<void> send(String key, ChatTurn turn) async {
    if (turn.kind == TurnKind.attach) {
      throw ArgumentError.value(turn.kind, 'turn.kind', 'attach sends no turn');
    }
    key = state.movedTo[key] ?? key;
    if (state.runs.containsKey(key)) return;
    final isNew = key.startsWith(newChatPrefix);
    final conversationId = isNew ? null : key;
    final optimistic = _optimistic(turn, conversationId);
    final user = turn.userMessage?.messageId;
    // The message the live reply renders under, and the parent of a
    // partial reply kept after an error (see `activePath`).
    final (anchorId, replyParentId) = switch (turn.kind) {
      TurnKind.send ||
      TurnKind.edit => (optimistic?.messageId, optimistic?.messageId),
      TurnKind.regenerate || TurnKind.editAi => (user, user),
      TurnKind.continued => (turn.responseMessageId, user),
      TurnKind.compact ||
      TurnKind.attach => (turn.parentMessageId, turn.parentMessageId),
    };

    final l = _Live(
      key,
      ++_epochs,
      replyParentId,
      EventMapper(log: ref.read(diagnosticLogProvider)),
    );
    _live[key] = l;
    state = state.copyWith(
      runs: {
        ...state.runs,
        key: RunState(
          key: key,
          kind: turn.kind,
          selection: turn.selection,
          conversationId: conversationId,
          isTemporary: turn.isTemporary,
          isComparison: turn.addedSelection != null,
          firstRunOfNewChat: isNew,
          optimistic: optimistic,
          anchorId: anchorId,
          epoch: l.epoch,
        ),
      },
      errors: {...state.errors}..remove(key),
    );
    if (turn.isTemporary && conversationId != null) {
      ref.read(temporaryChatsProvider.notifier).add(conversationId);
    }
    if (turn.kind == TurnKind.send) {
      final repository = ref.read(messagesRepositoryProvider);
      _background('delete_draft', () => repository.deleteDraft(_draftKey(key)));
    }

    final ChatStart start;
    try {
      final timeZone = await ref.read(deviceTimeZoneProvider.future);
      if (!_isCurrent(l)) return;
      start = await ref
          .read(chatApiProvider)
          .start(
            turn.selection.endpoint,
            buildChatPayload(
              turn,
              clientRequestId: _uuid.v4(),
              conversationId: conversationId,
              messageId: optimistic?.messageId,
              timeZone: timeZone,
            ),
          );
    } on Object catch (e, st) {
      if (!_isCurrent(l)) return;
      ref.read(diagnosticLogProvider).error('run', 'start_failed', e, st);
      _end(l, RunEnd.error, error: e);
      return;
    }
    if (!_isCurrent(l)) return;
    _setRun(
      _run(l).copyWith(
        streamId: start.streamId,
        generationCreatedAt: start.generationCreatedAt,
        phase: RunPhase.streaming,
      ),
    );
    _open(l, start.streamId);
    // A Stop tapped while starting waited for the Stream id.
    if (_run(l).stopping) unawaited(_abort(l));
  }

  /// The Optimistic_Message of a send or edit; an edit's is a new Sibling
  /// of the edited message. Other kinds have none.
  static Message? _optimistic(ChatTurn t, String? conversationId) {
    if (t.kind != TurnKind.send && t.kind != TurnKind.edit) return null;
    final isEdit = t.kind == TurnKind.edit;
    final parent = isEdit ? t.userMessage?.parentMessageId : t.parentMessageId;
    return Message(
      messageId: _uuid.v4(),
      conversationId: conversationId ?? '',
      parentMessageId: parent == null || parent.isEmpty ? rootParentId : parent,
      sender: 'User',
      text: t.text,
      isCreatedByUser: true,
      files: isEdit ? t.userMessage?.files : (t.files.isEmpty ? null : t.files),
      quotes: !isEdit && t.quotes.isNotEmpty ? t.quotes : null,
      createdAt: DateTime.now(),
    );
  }

  /// Opens [l]'s Stream. Recovery and attaching reopen with [resume], and
  /// the Sync_Frame rebuilds the reply (Req 19.4).
  void _open(_Live l, String streamId, {bool resume = false}) {
    unawaited(l.subscription?.cancel());
    l.subscription = ref
        .read(streamClientProvider)
        .open(streamId, l.mapper, resume: resume)
        .listen(
          (e) => _onEvent(l, e),
          // StreamClient ends every Stream with an event of its own, so
          // only an error, such as a missing Server_URL, needs handling.
          onError: (Object e, StackTrace st) {
            if (!_isCurrent(l)) return;
            ref
                .read(diagnosticLogProvider)
                .error('run', 'stream_failed', e, st);
            _flush(l);
            _end(l, RunEnd.error, error: e);
          },
        );
  }

  void _onEvent(_Live l, StreamEvent e) {
    if (!_isCurrent(l)) return;
    if (e is TextDelta || e is ThinkDelta) {
      l.buffer.add(e);
      l.flushTimer ??= Timer(flushInterval, () => _flush(l));
      return;
    }
    _flush(l);
    switch (e) {
      case FinalEvent():
        _final(l, e);
      case StreamError(:final text):
        _end(l, RunEnd.error, error: text);
      case StreamFailed(:final error):
        _end(l, RunEnd.error, error: error);
      case StreamExpired():
        _end(l, RunEnd.resumeExpired);
      case StreamRetryExhausted():
        _onRetryExhausted(l);
      case CreatedEvent():
        _setRun(reduce(_run(l), e));
        _moveToConversation(l);
      default:
        _setRun(reduce(_run(l), e));
    }
  }

  /// Applies the buffered deltas in one state change.
  void _flush(_Live l) {
    l.flushTimer?.cancel();
    l.flushTimer = null;
    if (l.buffer.isEmpty || !_isCurrent(l)) return l.buffer.clear();
    var run = _run(l);
    for (final e in l.buffer) {
      run = reduce(run, e);
    }
    l.buffer.clear();
    _setRun(run);
  }

  /// Moves a `new:` Run to its conversation id ([id], else the one
  /// `created` set) and records the move in [ConversationRuns.movedTo], so
  /// the new-chat screen goes to the conversation's route (Req 18.10).
  void _moveToConversation(_Live l, [String? id]) {
    final run = _run(l);
    final conversationId = run.conversationId ?? id;
    final from = l.key;
    if (!from.startsWith(newChatPrefix) || conversationId == null) return;
    _live.remove(from);
    l.key = conversationId;
    _live[conversationId] = l;
    // Before the move is published, so the conversation's screen never
    // reads the Cache (Req 21.6).
    if (run.isTemporary) {
      ref.read(temporaryChatsProvider.notifier).add(conversationId);
    }
    state = state.copyWith(
      runs: {
        for (final MapEntry(:key, :value) in state.runs.entries)
          if (key != from) key: value,
        conversationId: run.copyWith(
          key: conversationId,
          conversationId: conversationId,
          optimistic: run.optimistic?.copyWith(conversationId: conversationId),
        ),
      },
      movedTo: {...state.movedTo, from: conversationId},
    );
  }

  /// The final handling, in one synchronous block so the swap paints in
  /// one frame (Req 18.11).
  void _final(_Live l, FinalEvent frame) {
    // Task 23.2 claims and re-homes `frame.pendingSteers` here, first.
    _moveToConversation(
      l,
      frame.conversation?.conversationId ??
          frame.requestMessage?.conversationId,
    );
    final run = _run(l);
    final turn = finalTurn(frame, run.optimistic);
    if (frame.earlyAbort) {
      // Un-send: nothing is stored and the text goes back (Req 20.5).
      _restoreText(l.key, run);
      _end(l, RunEnd.finalized);
      return;
    }
    final id = run.conversationId;
    if (id != null) {
      final messages = conversationMessagesProvider(id);
      if (ref.exists(messages)) ref.read(messages.notifier).applyFinal(turn);
    }
    _end(l, RunEnd.finalized);
    if (id != null && !run.isTemporary) {
      unawaited(_afterFinal(run, id, frame, turn));
    }
  }

  /// Caches the turn and the conversation row (Req 18.13), with the title
  /// event's title (Req 21.11) or, after the first non-aborted Run of a new
  /// chat, the generated one (Req 21.10). The row is the frame's, or the
  /// Server's for an aborted new chat, whose frame carries a stub.
  /// Read-aloud and the queue drain (later tasks) follow here.
  Future<void> _afterFinal(
    RunState run,
    String id,
    FinalEvent frame,
    FinalTurn turn,
  ) async {
    final messages = ref.read(messagesRepositoryProvider);
    final conversations = ref.read(conversationsRepositoryProvider);
    final chatApi = ref.read(chatApiProvider);
    final log = ref.read(diagnosticLogProvider);
    final alive = _aliveCheck();
    try {
      await messages.upsert(id, turn.messages);
      var row = frame.conversation;
      if (row == null || (frame.aborted && run.firstRunOfNewChat)) {
        row = await conversations.api.get(id);
      }
      if (run.title case final title?) row = row.copyWith(title: title);
      if (!alive()) return;
      await conversations.upsert(row);
      if (frame.aborted || !run.firstRunOfNewChat || run.title != null) return;
      final title = await chatApi.generateTitle(id);
      if (title == null || title.trim().isEmpty || !alive()) return;
      await conversations.upsert(row.copyWith(title: title));
    } on Object catch (e, st) {
      log.error('run', 'final_followup_failed', e, st);
    }
  }

  /// Stops [key]'s Run (Req 20.2): sets `stopping`, which disables the
  /// Stop control (Req 20.8), sends the abort and keeps reading the Stream.
  /// The aborted Final_Frame ends the Run as usual (Req 20.3). A Run still
  /// starting sends its abort once the start returns its Stream id. Does
  /// nothing without a Run or while a Stop is pending.
  Future<void> stop(String key) async {
    key = state.movedTo[key] ?? key;
    final l = _live[key];
    final run = state.runs[key];
    if (l == null || run == null || run.stopping) return;
    _setRun(run.copyWith(stopping: true));
    if (run.phase != RunPhase.starting) await _abort(l);
  }

  /// Sends [l]'s abort. A failure ends the Run as `abortFallback` at once;
  /// an ack arms the watchdog (Req 20.4). A detached Run has no Stream to
  /// carry the aborted Final, so its ack reloads the messages, which then
  /// hold the turn the Server saved.
  Future<void> _abort(_Live l) async {
    final run = _run(l);
    try {
      await ref
          .read(chatApiProvider)
          .abort(
            streamId: run.streamId,
            isTemporary: run.isTemporary,
            generationCreatedAt: run.generationCreatedAt,
          );
    } on Object catch (e, st) {
      if (!_isCurrent(l)) return;
      ref.read(diagnosticLogProvider).error('run', 'abort_failed', e, st);
      _flush(l);
      _end(l, RunEnd.abortFallback);
      return;
    }
    if (!_isCurrent(l)) return;
    // Task 23.2 claims the ack's `pendingSteers` here.
    if (_run(l).phase == RunPhase.detached) {
      _end(l, RunEnd.reloadNeeded);
      return;
    }
    l.watchdog?.cancel();
    l.watchdog = Timer(ref.read(stopWatchdogProvider), () {
      if (!_isCurrent(l)) return;
      _flush(l);
      _end(l, RunEnd.abortFallback);
    });
  }

  /// The reconnect ladder is used up: the status route decides (Req 19.6).
  void _onRetryExhausted(_Live l) =>
      unawaited(_checkStatus(l, exhausted: true));

  /// Asks the Server whether [l]'s Run is still active.
  ///
  /// - Not active: the Run ended there, so the messages reload.
  /// - Active: the Stream reopens with `resume: true`. After an [exhausted]
  ///   ladder this happens once per Run (`resumedOnce`); a second
  ///   exhaustion detaches the Run.
  /// - A failed request detaches the Run after an [exhausted] ladder and
  ///   leaves a detached one as it is (Req 19.7).
  ///
  /// A `pendingAction` in the answer shows its card at once (Req 28.1).
  Future<void> _checkStatus(_Live l, {bool exhausted = false}) async {
    final run = _run(l);
    final id = run.conversationId ?? run.streamId;
    if (l.checking) return;
    if (id == null) {
      _detach(l);
      return;
    }
    l.checking = true;
    final RunStatus status;
    try {
      status = await ref.read(chatApiProvider).status(id);
    } on Object catch (e, st) {
      l.checking = false;
      if (!_isCurrent(l)) return;
      ref.read(diagnosticLogProvider).error('run', 'status_failed', e, st);
      if (exhausted) _detach(l);
      return;
    }
    l.checking = false;
    if (!_isCurrent(l)) return;
    // Task 23.2 claims the answer's `unrecoveredSteers` here.
    if (!status.active) {
      _end(l, RunEnd.reloadNeeded);
      return;
    }
    final current = _run(l);
    if (exhausted && current.resumedOnce) {
      _detach(l);
      return;
    }
    if (!exhausted && current.phase != RunPhase.detached) return;
    _setRun(
      current.copyWith(
        phase: RunPhase.streaming,
        attempt: 0,
        resumedOnce: true,
        error: null,
        generationCreatedAt: status.createdAt ?? current.generationCreatedAt,
        pendingAction: status.pendingAction ?? current.pendingAction,
      ),
    );
    _open(l, status.streamId ?? current.streamId ?? id, resume: true);
  }

  /// Leaves [l]'s Run without a Stream, showing a network error under the
  /// partial reply (Req 19.7). A pending Stop's watchdog keeps running.
  void _detach(_Live l) {
    unawaited(l.subscription?.cancel());
    l.subscription = null;
    _setRun(
      _run(l).copyWith(
        phase: RunPhase.detached,
        error: _errorText(AppException(FailureKind.network)),
      ),
    );
  }

  /// Checks status for every detached Run, as when the network comes back.
  void _recoverDetached() {
    for (final l in [..._live.values]) {
      if (state.runs[l.key]?.phase == RunPhase.detached) {
        unawaited(_checkStatus(l));
      }
    }
  }

  /// Called when a Chat_Screen opens [conversationId] and when the App
  /// returns to the foreground with it open (Req 19.8, 19.9).
  ///
  /// A detached Run checks status again. A conversation without a Run here
  /// asks the status route and attaches to an active Run with
  /// `resume: true`, so the Sync_Frame rebuilds the reply. A streaming Run
  /// needs nothing, and a failed request leaves things as they are.
  Future<void> onOpen(String conversationId) async {
    final l = _live[conversationId];
    final run = state.runs[conversationId];
    if (l != null && run != null) {
      if (run.phase == RunPhase.detached) await _checkStatus(l);
      return;
    }
    if (!_attaching.add(conversationId)) return;
    final alive = _aliveCheck();
    try {
      final status = await ref.read(chatApiProvider).status(conversationId);
      if (!status.active || !alive()) return;
      final row = await _cachedRow(conversationId);
      if (!alive() || state.runs.containsKey(conversationId)) return;
      _attach(conversationId, status, row);
    } on Object catch (e, st) {
      if (alive()) {
        ref.read(diagnosticLogProvider).error('run', 'status_failed', e, st);
      }
    } finally {
      _attaching.remove(conversationId);
    }
  }

  /// The cached conversation row, for an attached Run's selection; null
  /// when the Cache has none or fails.
  Future<Conversation?> _cachedRow(String id) async {
    try {
      return await ref.read(conversationsRepositoryProvider).watchOne(id).first;
    } on Object {
      return null;
    }
  }

  /// Holds the Server's active Run of [id] and opens its Stream with
  /// `resume: true`. An attached Run has no Optimistic_Message and no
  /// anchor: the Server saves the request message only with the Final, so
  /// the user message appears then.
  void _attach(String id, RunStatus status, Conversation? row) {
    final l = _Live(
      id,
      ++_epochs,
      null,
      EventMapper(log: ref.read(diagnosticLogProvider)),
    );
    _live[id] = l;
    final streamId = status.streamId ?? id;
    _setRun(
      RunState(
        key: id,
        kind: TurnKind.attach,
        selection: ChatSelection(
          endpoint: row?.endpoint ?? 'agents',
          endpointType: row?.endpointType,
          model: row?.model,
          agentId: row?.agentId,
          spec: row?.spec,
          modelLabel: row?.modelLabel,
        ),
        conversationId: id,
        streamId: streamId,
        generationCreatedAt: status.createdAt,
        isTemporary: isTemporary(id),
        phase: RunPhase.streaming,
        pendingAction: status.pendingAction,
        epoch: l.epoch,
      ),
    );
    _open(l, streamId, resume: true);
  }

  /// The only exit of a Run: cancels its Stream and timers, keeps or drops
  /// its content by [reason] (see [RunEnd]) and removes it, in one
  /// synchronous block. [error] is the Server's error text or an exception.
  void _end(_Live l, RunEnd reason, {Object? error}) {
    if (!_isCurrent(l)) return;
    final run = _run(l);
    l.cancel();
    _live.remove(l.key);
    final id = run.conversationId;
    var errors = state.errors;
    switch (reason) {
      case RunEnd.finalized:
        break;
      case RunEnd.error || RunEnd.abortFallback:
        if (run.streamId == null || id == null) {
          // No Stream yet, or no conversation to keep the reply in: un-send.
          _restoreText(l.key, run);
          if (error != null) errors = {...errors, l.key: _errorText(error)};
        } else {
          _addLocal(id, [
            ?run.optimistic,
            if (error != null || run.hasContent) _partial(run, l, id, error),
          ]);
        }
      case RunEnd.resumeExpired || RunEnd.reloadNeeded:
        if (id != null) {
          _reload(id, temporary: run.isTemporary);
        } else {
          _restoreText(l.key, run);
        }
    }
    state = state.copyWith(
      runs: {...state.runs}..remove(l.key),
      errors: errors,
    );
  }

  /// The partial reply kept after an error or an abort fallback, with an
  /// `error` part when [error] is set (Req 18.14).
  Message _partial(RunState run, _Live l, String id, Object? error) => Message(
    messageId: _uuid.v4(),
    conversationId: id,
    parentMessageId: l.replyParentId ?? rootParentId,
    sender: run.selection.modelLabel ?? run.selection.model,
    endpoint: run.selection.endpoint,
    model: run.selection.model,
    error: error != null,
    content: [
      ...run.parts,
      if (error != null)
        ContentPart(type: ContentPartType.error, error: _errorText(error)),
    ],
    attachments: run.attachments.isEmpty ? null : run.attachments,
    createdAt: DateTime.now(),
  );

  void _addLocal(String id, List<Message> messages) {
    final provider = conversationMessagesProvider(id);
    if (messages.isEmpty || !ref.exists(provider)) return;
    ref.read(provider.notifier).addLocal(messages);
  }

  /// Reloads [id]'s messages: the open screen's, else the Cache's.
  void _reload(String id, {required bool temporary}) {
    final provider = conversationMessagesProvider(id);
    if (ref.exists(provider)) {
      unawaited(ref.read(provider.notifier).reload());
    } else if (!temporary) {
      final repository = ref.read(messagesRepositoryProvider);
      _background('reload_failed', () => repository.fetch(id));
    }
  }

  /// Puts an un-sent Optimistic_Message's text back (Req 20.5): into the
  /// chat's Composer when one is open, else into its draft. A temporary
  /// chat keeps no draft (Req 21.6).
  void _restoreText(String key, RunState run) {
    final text = run.optimistic?.text ?? '';
    if (text.trim().isEmpty) return;
    final composer = composerProvider(_draftKey(key));
    if (ref.exists(composer)) {
      ref.read(composer.notifier).restoreText(text);
      return;
    }
    if (run.isTemporary) return;
    final repository = ref.read(messagesRepositoryProvider);
    _background(
      'restore_text',
      () => repository.saveDraft(_draftKey(key), text),
    );
  }

  /// The Composer and draft key: the conversation id, or `new` on landing.
  static String _draftKey(String runKey) =>
      runKey.startsWith(newChatPrefix) ? newChatKey : runKey;

  static String _errorText(Object error) =>
      error is String ? error : userMessage(error);

  bool _isCurrent(_Live l) =>
      identical(_live[l.key], l) && state.runs[l.key]?.epoch == l.epoch;

  RunState _run(_Live l) => state.runs[l.key]!;

  void _setRun(RunState run) {
    state = state.copyWith(runs: {...state.runs, run.key: run});
  }

  /// Whether this build is still the current one, for async follow-ups.
  bool Function() _aliveCheck() {
    final generation = _generation;
    return () => ref.mounted && generation == _generation;
  }

  /// Runs [work] without waiting, logging a failure as [event].
  void _background(String event, Future<void> Function() work) {
    final log = ref.read(diagnosticLogProvider);
    unawaited(
      work().catchError(
        (Object e, StackTrace st) => log.error('run', event, e, st),
      ),
    );
  }

  void _cancelAll() {
    for (final l in _live.values) {
      l.cancel();
    }
    _live.clear();
  }
}
