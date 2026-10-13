import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart'
    show CheckedFromJsonException;

import '../../../core/auth/auth_service.dart';
import '../../../core/models/message.dart';
import '../../../core/storage/cache_db.dart';
import 'messages_api.dart';

/// The [MessagesRepository] for the signed-in user. Tests override it.
final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(
    ref.read(messagesApiProvider),
    ref.read(cacheDbProvider),
    currentUser: () => ref.read(authServiceProvider).session?.user.id,
  ),
);

/// The cached messages of opened conversations and the Composer drafts
/// (Req 17.1, 45.1-45.3).
///
/// Only messages and drafts live here; conversation rows are written
/// through `ConversationsRepository.upsert`. A Cache write that follows a
/// request is skipped when [currentUser] changed while the request was out,
/// so a signed-out user's data never lands in the Cache again.
class MessagesRepository {
  MessagesRepository(this.api, this._db, {required this._currentUser});

  final MessagesApi api;
  final CacheDb _db;
  final String? Function() _currentUser;

  /// The cached messages of [conversationId], oldest first. Rows that no
  /// longer decode are skipped.
  Stream<List<Message>> watch(String conversationId) {
    final query = _db.select(_db.messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map(
      (rows) => [for (final row in rows) ?_decode(row.json)],
    );
  }

  /// `GET /api/messages/{conversationId}`, then replaces the conversation's
  /// cached rows with the result in one transaction (Req 45.2). A failure
  /// writes nothing and rethrows (Req 45.3).
  Future<List<Message>> fetch(String conversationId) async {
    final user = _currentUser();
    final messages = await api.list(conversationId);
    if (_currentUser() == user) {
      await _db.transaction(() async {
        await (_db.delete(
          _db.messages,
        )..where((t) => t.conversationId.equals(conversationId))).go();
        await _db.batch(
          (b) => b.insertAllOnConflictUpdate(
            _db.messages,
            _rows(conversationId, messages),
          ),
        );
      });
    }
    return messages;
  }

  /// Adds or replaces [messages] in [conversationId]'s cached rows.
  Future<void> upsert(String conversationId, List<Message> messages) {
    final rows = _rows(conversationId, messages);
    if (rows.isEmpty) return Future.value();
    return _db.batch((b) => b.insertAllOnConflictUpdate(_db.messages, rows));
  }

  /// The saved Composer draft for [key] (a conversation id, or `new` for
  /// the landing state), or null.
  Future<String?> draft(String key) async {
    final row = await (_db.select(
      _db.drafts,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.content;
  }

  /// Saves [text] as [key]'s draft. Blank text deletes the draft.
  Future<void> saveDraft(String key, String text) {
    if (text.trim().isEmpty) return deleteDraft(key);
    return _db
        .into(_db.drafts)
        .insertOnConflictUpdate(
          DraftsCompanion.insert(
            key: key,
            content: text,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  /// Deletes [key]'s draft, if any.
  Future<void> deleteDraft(String key) =>
      (_db.delete(_db.drafts)..where((t) => t.key.equals(key))).go();

  static List<MessagesCompanion> _rows(
    String conversationId,
    List<Message> messages,
  ) => [
    for (final m in messages)
      MessagesCompanion.insert(
        id: m.messageId,
        conversationId: conversationId,
        json: jsonEncode(m.toJson()),
        createdAt: (m.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      ),
  ];

  static Message? _decode(String json) {
    try {
      return Message.fromJson(
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
