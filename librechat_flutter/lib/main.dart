import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/auth_service.dart';
import 'core/images/image_loader.dart';
import 'core/log/diagnostic_log.dart';
import 'core/network/api_client.dart';
import 'core/storage/cache_db.dart';
import 'core/storage/secure_store.dart';
import 'core/storage/settings_store.dart';
import 'core/stream/stream_client.dart';
import 'core/ui/theme/app_theme.dart';
import 'features/chat/data/file_downloads.dart';

/// Bootstrap: every step finishes before `runApp`, so the first frame uses the stored theme
/// (Req 3.9) and the stored session (Req 12.2).
Future<void> main() async {
  // 1. Binding and the Diagnostic_Log, which also receives uncaught errors.
  WidgetsFlutterBinding.ensureInitialized();
  final log = await DiagnosticLog.open();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log.error('app', 'flutter_error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.error('app', 'uncaught_error', error, stack);
    if (kDebugMode) debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  // 2. Settings_Store.
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  // 3. Secure_Store: one readAll() for the Server_URL, Custom_Headers and Session.
  final secureStore = SecureStore(log: log);
  await secureStore.load();

  // 4. Cache: one query so the schema check or rebuild finishes before the first frame.
  final cacheDb = CacheDb();
  await cacheDb.customSelect('SELECT 1').get();

  // 5. AuthService, then ApiClient, then `auth.api` to close the only
  // dependency cycle, then the stored session.
  final auth = AuthService(secure: secureStore, cache: cacheDb, log: log);
  final api = ApiClient(secure: secureStore, auth: auth, log: log);
  auth.api = AuthApi(api);
  await auth.load();

  // 6. StreamClient shares ApiClient's headers and AuthService's refresh.
  // ImageLoader caches files in `<app cache>/images`; the wallpaper palette
  // loads here so the first frame can use it.
  final streamClient = StreamClient(api: api, auth: auth, log: log);
  final cacheDir = await getApplicationCacheDirectory();
  final imageLoader = ImageLoader(
    api,
    Directory(p.join(cacheDir.path, 'images')),
  );
  // Attachments and media download to `<app cache>/downloads` for
  // open_filex and the players.
  final fileDownloads = FileDownloads(
    api,
    Directory(p.join(cacheDir.path, 'downloads')),
    currentUser: () => auth.session?.user.id,
  );
  final wallpaperSchemes = await loadWallpaperSchemes();

  // 7. Run with Riverpod's automatic retry off; failures surface as errors instead.
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        diagnosticLogProvider.overrideWithValue(log),
        settingsProvider.overrideWith(() => SettingsStore(prefs)),
        secureStoreProvider.overrideWithValue(secureStore),
        cacheDbProvider.overrideWithValue(cacheDb),
        authServiceProvider.overrideWith((ref) => auth),
        apiClientProvider.overrideWithValue(api),
        streamClientProvider.overrideWithValue(streamClient),
        imageLoaderProvider.overrideWithValue(imageLoader),
        fileDownloadsProvider.overrideWithValue(fileDownloads),
        wallpaperSchemesProvider.overrideWithValue(wallpaperSchemes),
      ],
      child: const SwitchboardApp(),
    ),
  );
}
