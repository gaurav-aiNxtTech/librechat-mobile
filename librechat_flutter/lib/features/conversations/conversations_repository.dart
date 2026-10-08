import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../../core/auth/auth_service.dart';
import '../../core/models/conversation.dart';
import '../../core/storage/cache_db.dart';
import 'conversations_api.dart';

/// The [ConversationsRepository] for the signed-in user. Tests override it.
final conversationsRepositoryProvider = Provider<ConversationsRepository>(
  (ref) => ConversationsRepository(
    ref.read(conversationsApiProvider),
    ref.read(cacheDbProvider),
    currentUser: () => ref.read(authServiceProvider).session?.user.id,
  ),
);

/// The Conversation_List's data: the cached rows and every mutation that
/// changes them (Req 15, 16, 45.1-45.3).
///
/// The Cache is written only after the Server accepts a request, from the
/// Server's returned row when it has one. A failed request writes nothing and
/// rethrows. A write is skipped when [currentUser] changed while the request
/// was out, so a signed-out user's data never lands in the Cache again.
class ConversationsRepository {
  ConversationsRepository(this.api, this._db, {required this._currentUser});

  final ConversationsApi api;
  final CacheDb _db;
  final String? Function() _currentUser;

  /// The cached non-archived conversations, most recently updated first.
  /// Rows that no longer decode are skipped.
  Stream<List<Conversation>> watchList() {
    final query = _db.select(_db.conversations)
      ..where((t) => t.isArchived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().map(
      (rows) => [for (final row in rows) ?_decode(row.json)],
    );
  }

  /// Fetches page 1 and replaces every cached row with it in one
  /// transaction. Returns the next page's cursor.
  Future<String?> refresh() async {
    final user = _currentUser();
    final page = await api.list();
    if (_currentUser() == user) {
      await _db.transaction(() async {
        await _db.delete(_db.conversations).go();
        await _db.batch(
          (b) => b.insertAll(_db.conversations, _rows(page.conversations)),
        );
      });
    }
    return page.nextCursor;
  }

  /// Fetches the page at [cursor] and adds it to the Cache. Returns the next
  /// page's cursor.
  Future<String?> loadMore(String cursor) async {
    final user = _currentUser();
    final page = await api.list(cursor: cursor);
    if (_currentUser() == user) await _upsertAll(page.conversations);
    return page.nextCursor;
  }

  /// Writes [conversation] to the Cache. A conversation without an id is
  /// not cached.
  Future<void> upsert(Conversation conversation) => _upsertAll([conversation]);

  /// `POST /api/convos/update`, then caches the renamed row.
  Future<Conversation> rename(Conversation conversation, String title) =>
      _mutate(
        conversation,
        (id) => api.rename(id, title),
        (c) => c.copyWith(title: title),
      );

  /// `POST /api/convos/archive`. An archived row stays cached, hidden from
  /// [watchList]; unarchiving shows it again.
  Future<Conversation> setArchived(Conversation conversation, bool archived) =>
      _mutate(
        conversation,
        (id) => api.archive(id, archived),
        (c) => c.copyWith(isArchived: archived),
        force: true,
      );

  /// `POST /api/convos/pin`.
  Future<Conversation> setPinned(Conversation conversation, bool pinned) =>
      _mutate(
        conversation,
        (id) => api.pin(id, pinned),
        (c) => c.copyWith(pinned: pinned),
        force: true,
      );

  /// `PUT /api/tags/convo/{id}`, then caches the Server's tag list.
  Future<Conversation> setTags(
    Conversation conversation,
    List<String> tags,
  ) async {
    final user = _currentUser();
    final saved = await api.setConversationTags(
      conversation.conversationId!,
      tags,
    );
    final next = conversation.copyWith(tags: saved);
    if (_currentUser() == user) await upsert(next);
    return next;
  }

  /// `DELETE /api/convos`, then removes the row and its cached messages.
  Future<void> delete(String id) async {
    final user = _currentUser();
    await api.delete(id);
    if (_currentUser() != user) return;
    await _db.transaction(() async {
      await (_db.delete(_db.conversations)..where((t) => t.id.equals(id))).go();
      await (_db.delete(
        _db.messages,
      )..where((t) => t.conversationId.equals(id))).go();
    });
  }

  /// `POST /api/convos/duplicate` titled "Copy of {title}", then caches and
  /// returns the copy.
  Future<Conversation> duplicate(Conversation conversation) async {
    final user = _currentUser();
    final copy = await api.duplicate(
      conversation.conversationId!,
      'Copy of ${conversation.title ?? 'New Chat'}',
    );
    if (_currentUser() == user) await upsert(copy);
    return copy;
  }

  /// Uploads an export. The caller [refresh]es after, so a failed refresh
  /// does not read as a failed import.
  Future<void> importFile(Uint8List bytes, String fileName) =>
      api.importFile(bytes, fileName);

  /// Sends [request], then caches the Server's row when it is the same
  /// conversation, else [local] applied to [conversation]. With [force],
  /// [local] is applied to the Server's row too, so the field the request
  /// set holds even when the response leaves it out.
  Future<Conversation> _mutate(
    Conversation conversation,
    Future<Conversation?> Function(String id) request,
    Conversation Function(Conversation c) local, {
    bool force = false,
  }) async {
    final id = conversation.conversationId!;
    final user = _currentUser();
    final server = await request(id);
    final next = server != null && server.conversationId == id
        ? (force ? local(server) : server)
        : local(conversation);
    if (_currentUser() == user) await upsert(next);
    return next;
  }

  Future<void> _upsertAll(List<Conversation> conversations) {
    final rows = _rows(conversations);
    if (rows.isEmpty) return Future.value();
    return _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.conversations, rows),
    );
  }

  static List<ConversationsCompanion> _rows(List<Conversation> conversations) =>
      [
        for (final c in conversations)
          if (c.conversationId case final id?)
            ConversationsCompanion.insert(
              id: id,
              json: jsonEncode(c.toJson()),
              updatedAt: (c.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
              isArchived: Value(c.isArchived),
            ),
      ];

  static Conversation? _decode(String json) {
    try {
      return Conversation.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on CheckedFromJsonException {
      return null;
    }
  }
}
