import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;

part 'cache_db.g.dart';

/// The open Cache. `main()` overrides this with `overrideWithValue`.
final cacheDbProvider = Provider<CacheDb>(
  (ref) => throw UnimplementedError('cacheDbProvider is not overridden'),
);

// Rows hold the Server's JSON as text; the other columns exist only for queries.
// Times are epoch milliseconds.

/// Conversation_List and Archived_Screen rows.
@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Messages of opened conversations.
@DataClassName('MessageRow')
@TableIndex(name: 'messages_conversation_id', columns: {#conversationId})
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get json => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Composer drafts, keyed by conversation id (`new` for the landing state).
@DataClassName('DraftRow')
class Drafts extends Table {
  TextColumn get key => text()();
  // A getter named `text` would clash with `Table.text()`; the SQL column is still `text`.
  TextColumn get content => text().named('text')();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Server_Config style blobs: `config`, `endpoints`, `models`, `role`, `tags`.
@DataClassName('CacheEntryRow')
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The offline Cache (Req 45.1).
///
/// Opened with `driftDatabase(name: 'cache')`; tests pass their own executor,
/// for example `NativeDatabase.memory()`.
@DriftDatabase(tables: [Conversations, Messages, Drafts, CacheEntries])
class CacheDb extends _$CacheDb {
  CacheDb([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cache'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Any version change (up or down) rebuilds the Cache, keeping only the
    // drafts (Req 45.4). There is deliberately no step-by-step migration.
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        if (table.actualTableName == drafts.actualTableName) continue;
        await m.deleteTable(table.actualTableName);
      }
      // Dropping a table drops its indexes, so every remaining entity can be
      // created again; `drafts` uses CREATE TABLE IF NOT EXISTS and keeps its rows.
      for (final entity in allSchemaEntities) {
        await m.create(entity);
      }
    },
  );

  /// Empties every table, drafts included. Runs when the session is cleared
  /// (Req 12.11).
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });

  /// Empties the Server's data and keeps the drafts. "Clear cache" runs this
  /// together with `ImageLoader.clear()` (Req 41.4).
  Future<void> clearServerData() => transaction(() async {
    for (final table in allTables) {
      if (table.actualTableName == drafts.actualTableName) continue;
      await delete(table).go();
    }
  });
}
