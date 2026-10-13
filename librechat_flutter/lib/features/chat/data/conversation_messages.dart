import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/message.dart';
import '../tree/message_tree.dart';
import 'messages_repository.dart';

part 'conversation_messages.freezed.dart';

/// What the Chat_Screen renders for one conversation.
///
/// [messages] holds the Server's messages plus the local ones named by
/// [localIds], each id once. [selection] is the Message_Tree's Sibling
/// choice per level (see [activePath]). [justSettledId] is the reply the
/// last Final_Frame settled, which still renders as live. [refreshing] is a
/// Server fetch running behind the shown messages, and [refreshError] the
/// last failed one, shown as a banner over the kept messages (Req 45.3).
@freezed
abstract class ConversationMessages with _$ConversationMessages {
  const ConversationMessages._();

  const factory ConversationMessages({
    @Default(<Message>[]) List<Message> messages,
    @Default(<String, String>{}) Map<String, String> selection,
    @Default(<String>{}) Set<String> localIds,
    String? justSettledId,
    @Default(false) bool refreshing,
    Object? refreshError,
  }) = _ConversationMessages;

  /// The Active_Path for [selection], without a Run's anchor.
  List<Message> get path => activePath(messages, selection);

  /// The parent of the next sent message: the last [path] message the
  /// Server confirmed, or the Root_Parent_Id.
  String get nextParentId {
    for (final m in path.reversed) {
      if (!localIds.contains(m.messageId)) return m.messageId;
    }
    return rootParentId;
  }
}

/// What a Final_Frame settles, as `finalTurn` in `run/final_merge.dart`
/// builds it and [ConversationMessagesNotifier.applyFinal] applies it.
///
/// [messages] are the Server's copies. [local] are messages the Server did
/// not return, such as an Optimistic_Message without a request message.
/// [selection] holds the Sibling choices that show the new turn.
@immutable
class FinalTurn {
  const FinalTurn({
    required this.messages,
    this.local = const [],
    this.selection = const {},
    this.justSettledId,
  });

  final List<Message> messages;
  final List<Message> local;
  final Map<String, String> selection;
  final String? justSettledId;
}

/// The ids of this app run's temporary chats (Req 21.6). RunService adds a
/// chat once its Run knows the conversation id; `RunService.isTemporary`
/// reads it. It lives apart from RunService because RunService reads
/// [conversationMessagesProvider], which depends on it.
final temporaryChatsProvider = NotifierProvider<TemporaryChats, Set<String>>(
  TemporaryChats.new,
);

/// See [temporaryChatsProvider].
class TemporaryChats extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String conversationId) {
    if (state.contains(conversationId)) return;
    state = Set.unmodifiable({...state, conversationId});
  }
}

/// Whether a conversation is a temporary chat, whose messages live only in
/// memory.
final isTemporaryChatProvider = Provider.autoDispose.family<bool, String>(
  (ref, conversationId) => ref.watch(
    temporaryChatsProvider.select((ids) => ids.contains(conversationId)),
  ),
);

/// The messages of one conversation. See [ConversationMessagesNotifier].
final conversationMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<ConversationMessagesNotifier, ConversationMessages, String>(
      ConversationMessagesNotifier.new,
    );

/// Shows the cached messages first, then the Server's (Req 17.1, 45.2).
///
/// `build` listens to [MessagesRepository.watch]. A non-empty first
/// emission becomes data at once with `refreshing: true`, then
/// [MessagesRepository.fetch] runs and replaces the rows. With nothing
/// cached the state stays loading until the fetch ends (Req 17.2): its
/// result becomes data even when empty, and its failure is the error state,
/// which [reload] retries. A failed fetch over shown messages keeps them and
/// sets [ConversationMessages.refreshError] (Req 45.3). Later emissions
/// replace the Server's messages.
///
/// Messages applied in memory ([applyFinal], [upsertMessage]) show over the
/// Cache until an emission or fetch carries them, so a Cache write still on
/// its way never hides them. Local messages ([addLocal]) are never cached
/// and stay until the Server returns the same id. A temporary chat skips
/// the Cache entirely.
class ConversationMessagesNotifier extends AsyncNotifier<ConversationMessages> {
  ConversationMessagesNotifier(this.conversationId);

  final String conversationId;

  late MessagesRepository _repository;
  bool _temporary = false;

  /// The latest Cache emission or fetch result.
  List<Message> _stored = const [];

  /// Messages applied in memory and not yet seen in [_stored], local ones
  /// included, by id in the order they arrived.
  final _overlay = <String, Message>{};
  final _localIds = <String>{};
  Map<String, String> _selection = const {};
  String? _justSettledId;
  bool _refreshing = false;
  Object? _refreshError;

  /// Bumped by each build, so work started by an older build is dropped.
  int _generation = 0;

  /// Whether this build's value was handed to Riverpod. Until then changes
  /// only update the fields, which the build's value picks up.
  bool _returned = false;

  /// Bumped by each change, so a change made while Riverpod applies the
  /// build's value is published again.
  int _version = 0;

  @override
  Future<ConversationMessages> build() async {
    final generation = ++_generation;
    _repository = ref.watch(messagesRepositoryProvider);
    _temporary = ref.watch(isTemporaryChatProvider(conversationId));
    _stored = const [];
    _overlay.clear();
    _localIds.clear();
    _selection = const {};
    _justSettledId = null;
    _refreshing = false;
    _refreshError = null;
    _returned = false;

    final firstEmission = Completer<void>();
    if (_temporary) {
      firstEmission.complete();
    } else {
      final subscription = _repository
          .watch(conversationId)
          .listen(
            (rows) {
              if (generation != _generation) return;
              _store(rows);
              if (!firstEmission.isCompleted) {
                firstEmission.complete();
              } else {
                _changed();
              }
            },
            // A failed Cache read counts as an empty Cache; the fetch runs.
            onError: (Object _) {
              if (!firstEmission.isCompleted) firstEmission.complete();
            },
          );
      ref.onDispose(() => unawaited(subscription.cancel()));
    }
    await firstEmission.future;
    // A newer build owns the fields; Riverpod ignores this one's value.
    if (generation != _generation) return _compose();

    if (_stored.isNotEmpty) {
      _refreshing = true;
      unawaited(_refresh(generation));
      return _settle(generation);
    }
    try {
      final fetched = await _fetch();
      if (generation != _generation) return _compose();
      _store(fetched);
    } catch (e) {
      if (generation != _generation) rethrow;
      // Messages applied while the fetch was out, such as a just-created
      // chat's first turn, still show.
      if (_compose().messages.isEmpty) {
        _settle(generation);
        rethrow;
      }
      _refreshError = e;
    }
    return _settle(generation);
  }

  /// Applies a Final_Frame's turn in one state change, so the Run's live
  /// reply swaps for the Server's copy in one frame (Req 18.11). The Cache
  /// write is RunService's.
  void applyFinal(FinalTurn turn) {
    for (final m in turn.messages) {
      _localIds.remove(m.messageId);
      _overlay[m.messageId] = m;
    }
    _addLocal(turn.local);
    _selection = {..._selection, ...turn.selection};
    _justSettledId = turn.justSettledId;
    _changed();
  }

  /// Keeps [messages] that the Server never confirmed, such as an
  /// Optimistic_Message and partial reply after an error. They are never
  /// cached and are not the next send's parent.
  void addLocal(List<Message> messages) {
    _addLocal(messages);
    _changed();
  }

  /// Shows the Server's [message] at once and caches it, after an edit,
  /// branch or feedback.
  Future<void> upsertMessage(Message message) async {
    _localIds.remove(message.messageId);
    _overlay[message.messageId] = message;
    _changed();
    if (!_temporary) await _repository.upsert(conversationId, [message]);
  }

  /// Replaces the Sibling choices, for example with a `selectSibling`
  /// result (Req 17.7).
  void select(Map<String, String> selection) {
    _selection = Map.unmodifiable(selection);
    _changed();
  }

  /// Fetches the Server's copy again. Shown messages stay while it runs;
  /// from the error state it shows loading, then the result or the error.
  Future<void> reload() async {
    final generation = _generation;
    // The build's own fetch is still running.
    if (!_returned) return;
    if (state.hasValue) {
      _refreshing = true;
      _changed();
      return _refresh(generation);
    }
    state = const AsyncLoading();
    try {
      final fetched = await _fetch();
      if (generation != _generation || !ref.mounted) return;
      _refreshError = null;
      _store(fetched);
      state = AsyncData(_compose());
    } catch (e, st) {
      if (generation != _generation || !ref.mounted) return;
      if (_compose().messages.isEmpty) {
        state = AsyncError(e, st);
      } else {
        _refreshError = e;
        state = AsyncData(_compose());
      }
    }
  }

  /// A temporary chat's messages are never cached (Req 21.6).
  Future<List<Message>> _fetch() => _temporary
      ? _repository.api.list(conversationId)
      : _repository.fetch(conversationId);

  Future<void> _refresh(int generation) async {
    try {
      final fetched = await _fetch();
      if (generation != _generation) return;
      _refreshError = null;
      _store(fetched);
    } catch (e) {
      if (generation != _generation) return;
      _refreshError = e;
    }
    _refreshing = false;
    _changed();
  }

  /// Takes [rows] as the Server's messages. The Server's copy of an id
  /// replaces the in-memory one, and a local id it returns is confirmed.
  void _store(List<Message> rows) {
    _stored = rows;
    for (final m in rows) {
      _overlay.remove(m.messageId);
      _localIds.remove(m.messageId);
    }
  }

  void _addLocal(List<Message> messages) {
    for (final m in messages) {
      _overlay[m.messageId] = m;
      _localIds.add(m.messageId);
    }
  }

  ConversationMessages _compose() {
    final stored = {for (final m in _stored) m.messageId};
    return ConversationMessages(
      messages: List.unmodifiable([
        for (final m in _stored) _overlay[m.messageId] ?? m,
        for (final m in _overlay.values)
          if (!stored.contains(m.messageId)) m,
      ]),
      selection: _selection,
      localIds: Set.unmodifiable(_localIds),
      justSettledId: _justSettledId,
      refreshing: _refreshing,
      refreshError: _refreshError,
    );
  }

  /// Publishes the fields once the build's value was handed over.
  void _changed() {
    _version++;
    if (_returned && ref.mounted) state = AsyncData(_compose());
  }

  /// Marks the build's value as handed over and returns it. Riverpod
  /// applies it a microtask later, so a change made in between is
  /// published again on the next event-loop turn.
  ConversationMessages _settle(int generation) {
    _returned = true;
    final version = _version;
    Future(() {
      if (generation != _generation || !ref.mounted) return;
      if (_version != version) state = AsyncData(_compose());
    });
    return _compose();
  }
}
