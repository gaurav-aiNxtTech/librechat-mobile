import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/secure_store.dart';

void main() {
  late CacheDb db;
  late SecureStore secure;
  late AuthService auth;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStore.serverUrlKey: 'https://chat.example.com',
      SecureStore.sessionKey: jsonEncode({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': {'_id': 'u1', 'email': 'user@example.com'},
      }),
    });
    secure = SecureStore();
    await secure.load();
    db = CacheDb(NativeDatabase.memory());
    await db
        .into(db.cacheEntries)
        .insert(
          CacheEntriesCompanion.insert(key: 'config', json: '{}', updatedAt: 1),
        );
    auth = AuthService(secure: secure, cache: db);
    await auth.load();
  });

  tearDown(() => db.close());

  test('load restores the stored session', () {
    expect(auth.serverUrl, 'https://chat.example.com');
    expect(auth.session?.accessToken, 'access-1');
    expect(auth.session?.user.id, 'u1');
  });

  test('saving the same URL keeps the session and the Cache', () async {
    await auth.saveServer('https://chat.example.com', {'X-Gate': 'g'});

    expect(auth.session, isNotNull);
    expect(secure.customHeaders, {'X-Gate': 'g'});
    expect(await db.select(db.cacheEntries).get(), hasLength(1));
  });

  test('saving a new URL clears the session and the Cache', () async {
    var notified = 0;
    auth.addListener(() => notified++);

    await auth.saveServer('https://other.example.com', const {});

    expect(auth.serverUrl, 'https://other.example.com');
    expect(auth.session, isNull);
    expect(secure.session, isNull);
    expect(await db.select(db.cacheEntries).get(), isEmpty);
    expect(notified, 1);
  });

  test('Session JSON round-trips', () {
    final session = auth.session!;
    expect(Session.fromJson(session.toJson()).toJson(), session.toJson());
  });
}
