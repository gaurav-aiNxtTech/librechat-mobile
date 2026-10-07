import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/server_config.dart';
import '../../core/log/diagnostic_log.dart';
import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/custom_headers.dart';
import '../../core/network/server_url.dart';
import '../../core/storage/cache_db.dart';
import '../../core/storage/secure_store.dart';
import '../../core/ui/headers_editor.dart';

/// The [ConfigRepository] the Server_URL_Screen probes with and caches
/// through. Tests override it.
final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) =>
      ConfigRepository(ref.read(apiClientProvider), ref.read(cacheDbProvider)),
);

/// Why a QR scan could not run (Req 44.11).
enum ScanProblem {
  // New copy: the KMP_App has no QR scan.
  cameraDenied(
    "Camera access is off, so the QR scanner can't open. Type the server URL "
    'instead, or allow camera access in Settings.',
  ),
  cameraFailed("The camera couldn't start. Type the server URL instead.");

  const ScanProblem(this.message);

  final String message;
}

/// What the Server_URL_Screen shows. Exactly one of [urlProblem] and
/// [failure] explains the last submit's failure, if any.
@immutable
class ServerUrlState {
  const ServerUrlState({
    this.url = '',
    this.rows = const [],
    this.advancedOpen = false,
    this.urlProblem,
    this.rowProblems = const {},
    this.insecureUrl,
    this.probing = false,
    this.failure,
    this.scanProblem,
    this.connected = false,
  });

  /// The URL field's text, kept as typed (Req 8.5).
  final String url;
  final List<HeaderRow> rows;
  final bool advancedOpen;

  /// The normalizer's reason, shown under the URL field (Req 8.5).
  final UrlProblem? urlProblem;

  /// The rejected header rows, by index (Req 5.3).
  final Map<int, HeaderProblem> rowProblems;

  /// The normalized `http://` URL waiting on the "Insecure connection"
  /// dialog, or null when the dialog is closed (Req 7.4).
  final String? insecureUrl;

  /// True while `GET /api/config` runs; inputs are disabled.
  final bool probing;

  /// The probe's failure text (Req 7.5).
  final String? failure;
  final ScanProblem? scanProblem;

  /// Set once the Server_URL is stored; the screen then opens `/login`.
  final bool connected;

  ServerUrlState copyWith({
    String? url,
    List<HeaderRow>? rows,
    bool? advancedOpen,
    UrlProblem? Function()? urlProblem,
    Map<int, HeaderProblem>? rowProblems,
    String? Function()? insecureUrl,
    bool? probing,
    String? Function()? failure,
    ScanProblem? Function()? scanProblem,
    bool? connected,
  }) => ServerUrlState(
    url: url ?? this.url,
    rows: rows ?? this.rows,
    advancedOpen: advancedOpen ?? this.advancedOpen,
    urlProblem: urlProblem != null ? urlProblem() : this.urlProblem,
    rowProblems: rowProblems ?? this.rowProblems,
    insecureUrl: insecureUrl != null ? insecureUrl() : this.insecureUrl,
    probing: probing ?? this.probing,
    failure: failure != null ? failure() : this.failure,
    scanProblem: scanProblem != null ? scanProblem() : this.scanProblem,
    connected: connected ?? this.connected,
  );
}

final serverUrlControllerProvider =
    NotifierProvider.autoDispose<ServerUrlController, ServerUrlState>(
      ServerUrlController.new,
    );

/// Drives the Server_URL_Screen (Req 5.1, 5.3, 5.7, 7.3–7.9, 8.5): normalize
/// the URL, validate the header rows, confirm `http://`, probe
/// `GET /api/config` with the typed values, then store the Server_URL with
/// its Custom_Headers and cache the config.
class ServerUrlController extends Notifier<ServerUrlState> {
  /// Starts from the stored Server_URL and Custom_Headers, so "Change server"
  /// shows them (Req 7.8). Advanced opens when headers are stored (Req 5.1).
  @override
  ServerUrlState build() {
    final headers = ref.read(secureStoreProvider).customHeaders;
    return ServerUrlState(
      url: ref.read(authServiceProvider).serverUrl ?? '',
      rows: [
        for (final MapEntry(:key, :value) in headers.entries) (key, value),
      ],
      advancedOpen: headers.isNotEmpty,
    );
  }

  void setUrl(String url) {
    if (state.probing || url == state.url) return;
    state = state.copyWith(
      url: url,
      urlProblem: () => null,
      failure: () => null,
    );
  }

  /// Rows are re-indexed by an edit, so their old problems are dropped.
  void setRows(List<HeaderRow> rows) {
    if (state.probing) return;
    state = state.copyWith(
      rows: rows,
      rowProblems: const {},
      failure: () => null,
    );
  }

  void toggleAdvanced() =>
      state = state.copyWith(advancedOpen: !state.advancedOpen);

  /// A scanned URL fills the field (Req 7.7).
  void scanned(String url) {
    if (state.probing) return;
    setUrl(url);
    state = state.copyWith(scanProblem: () => null);
  }

  void scanFailed(ScanProblem problem) =>
      state = state.copyWith(scanProblem: () => problem);

  /// Normalizes, validates the rows, and asks about `http://` before probing.
  /// A rejection shows its reason, keeps the input and sends nothing
  /// (Req 5.3, 8.5). Does nothing while a probe runs.
  Future<void> submit() async {
    if (state.probing) return;
    final (:url, :problem) = normalizeServerUrl(state.url);
    if (url == null) {
      state = state.copyWith(urlProblem: () => problem, failure: () => null);
      return;
    }
    final rowProblems = headerRowProblems(state.rows);
    state = state.copyWith(
      urlProblem: () => null,
      rowProblems: rowProblems,
      failure: () => null,
      advancedOpen: rowProblems.isNotEmpty ? true : null,
    );
    if (rowProblems.isNotEmpty) return;
    if (url.startsWith('http://')) {
      state = state.copyWith(insecureUrl: () => url);
      return;
    }
    await _connect(url);
  }

  /// "Connect anyway" in the "Insecure connection" dialog (Req 7.4).
  Future<void> confirmInsecure() async {
    final url = state.insecureUrl;
    state = state.copyWith(insecureUrl: () => null);
    if (url != null && !state.probing) await _connect(url);
  }

  /// "Cancel", or dismissing the dialog: nothing is sent.
  void cancelInsecure() => state = state.copyWith(insecureUrl: () => null);

  /// Probes with the typed rows (Req 5.7, 7.3). Success stores the Server_URL
  /// and Custom_Headers (Req 7.6, 7.9), then caches the config; failure
  /// shows the reason and keeps the input (Req 7.5).
  Future<void> _connect(String url) async {
    final headers = buildCustomHeaders(state.rows);
    final repository = ref.read(configRepositoryProvider);
    final auth = ref.read(authServiceProvider);
    final log = ref.read(diagnosticLogProvider);
    state = state.copyWith(probing: true, connected: false);
    try {
      final config = await repository.probe(url, headers);
      await auth.saveServer(url, headers);
      try {
        // After saveServer, which empties the Cache for a new Server_URL.
        await repository.save(config: config);
      } catch (e, st) {
        // The Server_URL is stored; serverConfigProvider fetches it again.
        log.error('auth', 'config_cache_failed', e, st);
      }
      if (ref.mounted) state = state.copyWith(probing: false, connected: true);
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(probing: false, failure: () => userMessage(e));
      }
    }
  }
}
