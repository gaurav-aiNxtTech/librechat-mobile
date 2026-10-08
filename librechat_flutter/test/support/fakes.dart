/// Hand-written fakes for widget and notifier tests.
///
/// Each fake `implements` the production class it stands in for and is
/// injected through a ProviderScope override. There is no mocking package.
/// A fake is added here by the task that first needs it, and only for a class
/// that exists:
///
/// ```dart
/// class FakeConversationsApi implements ConversationsApi {
///   final calls = <String>[];
///   ...
/// }
/// ```
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/tag.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';

/// Records [probe] and [save] calls. [probe] answers with [probeResult], or
/// throws [probeError], after [probeGate] completes when one is set. Other
/// members are not used by the Server_URL_Screen and throw.
class FakeConfigRepository implements ConfigRepository {
  final probes = <(String, Map<String, String>)>[];
  final savedConfigs = <StartupConfig>[];
  StartupConfig probeResult = const StartupConfig(appTitle: 'Probed');
  Object? probeError;
  Completer<void>? probeGate;

  @override
  Future<StartupConfig> probe(String url, Map<String, String> headers) async {
    probes.add((url, headers));
    await probeGate?.future;
    if (probeError case final error?) throw error;
    return probeResult;
  }

  @override
  Future<void> save({
    StartupConfig? config,
    Object? endpoints,
    Object? models,
    Object? role,
  }) async {
    if (config != null) savedConfigs.add(config);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers [login] with [loginResult], or throws [loginError], and
/// [verifyTwoFactor] with [verifyError] when set. Each call is recorded,
/// and [acknowledgeExpiry] counts in [expiryAcknowledgements]. Other members
/// are not used by the sign-in screens and throw.
class FakeAuthService extends ChangeNotifier implements AuthService {
  final logins = <(String, String)>[];
  final verifications = <(String, String, bool)>[];
  LoginResult loginResult = const SignedIn();
  Object? loginError;
  Object? verifyError;
  final savedServers = <(String, Map<String, String>)>[];
  int signOuts = 0;

  @override
  bool openIdAutoRedirected = false;

  String? _serverUrl;
  Session? _session;
  bool _expired = false;

  @override
  String? get serverUrl => _serverUrl;

  @override
  Session? get session => _session;

  @override
  bool get expired => _expired;

  /// Sets what the redirect reads, then notifies like the real service.
  void emit({String? serverUrl, Session? session, bool expired = false}) {
    _serverUrl = serverUrl;
    _session = session;
    _expired = expired;
    notifyListeners();
  }

  @override
  Future<void> saveServer(String url, Map<String, String> headers) async {
    savedServers.add((url, headers));
    _serverUrl = url;
    notifyListeners();
  }

  /// What the account screens reach through [api].
  final authApi = FakeAuthApi();

  @override
  AuthApi get api => authApi;

  @override
  Future<LoginResult> login(String identifier, String password) async {
    logins.add((identifier, password));
    if (loginError case final error?) throw error;
    return loginResult;
  }

  @override
  Future<void> verifyTwoFactor(
    String tempToken,
    String code, {
    required bool backupCode,
  }) async {
    verifications.add((tempToken, code, backupCode));
    if (verifyError case final error?) throw error;
  }

  @override
  Future<void> signOut() async => signOuts++;

  /// How often the session-expired dialog acknowledged the expiry.
  int expiryAcknowledgements = 0;

  @override
  void acknowledgeExpiry() {
    expiryAcknowledgements++;
    _expired = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the account routes the Register, Forgot_Password,
/// Reset_Password, Verify_Email and Terms screens and the AppShell's terms
/// check call, and answers the login, refresh and logout a real
/// [AuthService] makes. Each answers with its reply field, or throws
/// [error], after [gate] completes when one is set. Other members throw.
class FakeAuthApi implements AuthApi {
  final registrations = <Map<String, String>>[];
  final resetRequests = <String>[];
  final resets = <Map<String, String>>[];
  final resends = <String>[];
  int termsAccepts = 0;
  int termsChecks = 0;
  bool termsAcceptedReply = true;
  String? registerMessage = 'Registered.';
  ({String? message, String? link}) resetRequestReply = (
    message: 'Check your inbox.',
    link: null,
  );
  String? resetMessage = 'Password reset.';
  String? resendMessage = 'Sent again.';
  Object? error;
  Completer<void>? gate;

  Future<T> _answer<T>(T reply) async {
    await gate?.future;
    if (error case final error?) throw error;
    return reply;
  }

  @override
  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    registrations.add({
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return _answer(registerMessage);
  }

  @override
  Future<({String? message, String? link})> requestPasswordReset(String email) {
    resetRequests.add(email);
    return _answer(resetRequestReply);
  }

  @override
  Future<String?> resetPassword({
    required String userId,
    required String token,
    required String password,
    required String confirmPassword,
  }) {
    resets.add({
      'userId': userId,
      'token': token,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return _answer(resetMessage);
  }

  @override
  Future<String?> resendVerification(String email) {
    resends.add(email);
    return _answer(resendMessage);
  }

  @override
  Future<void> acceptTerms() {
    termsAccepts++;
    return _answer(null);
  }

  @override
  Future<bool> termsAccepted() {
    termsChecks++;
    return _answer(termsAcceptedReply);
  }

  /// What [login] answers, for a real [AuthService] on this fake.
  TokenReply loginReply = (
    token: 'a',
    user: const User(id: 'u1'),
    twoFAPending: false,
    tempToken: null,
    refreshToken: 'r',
  );
  RefreshResult refreshReply = const RefreshRejected(401);
  int logouts = 0;

  @override
  Future<TokenReply> login(String email, String password) =>
      _answer(loginReply);

  @override
  Future<RefreshResult> refresh(String refreshToken) => _answer(refreshReply);

  @override
  Future<void> logout() {
    logouts++;
    return _answer(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [CacheDb] that holds nothing, for a real [AuthService] in widget tests.
/// [clearAll] calls are counted. Other members throw.
class FakeCacheDb implements CacheDb {
  int clears = 0;

  @override
  Future<void> clearAll() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [serverConfigProvider] that loads [info] and never fetches.
class FakeServerConfig extends ServerConfigNotifier {
  FakeServerConfig(this.info);

  final ServerInfo info;

  @override
  Future<ServerInfo> build() async => info;
}

/// A [settingsProvider] held in memory, starting from [initial]. Each [save]
/// is recorded.
class FakeSettingsStore extends Notifier<AppSettings> implements SettingsStore {
  FakeSettingsStore([this.initial = const AppSettings()]);

  final AppSettings initial;
  final saved = <AppSettings>[];

  @override
  AppSettings build() => initial;

  @override
  Future<void> save(AppSettings next) async {
    saved.add(next);
    state = next;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every call in [calls] as `(method, args)` and answers from the
/// reply fields, or throws [error], after [gate] completes when one is set.
/// [list] answers [pages] in order, then an empty last page. [rename],
/// [archive] and [pin] answer their reply (null is a body that is not a
/// conversation); [setConversationTags] echoes its tags unless
/// [setTagsReply] is set.
class FakeConversationsApi implements ConversationsApi {
  final calls = <(String, List<Object?>)>[];
  final pages = <ConversationPage>[];
  final conversations = <String, Conversation>{};
  Conversation? renameReply;
  Conversation? archiveReply;
  Conversation? pinReply;
  Conversation duplicateReply = const Conversation(conversationId: 'copy');
  List<Tag> tagsReply = const [];
  List<String>? setTagsReply;
  String? sharedLinkReply;
  String createShareReply = 'share-1';
  Object? error;
  Completer<void>? gate;

  /// The calls to [method], as their args.
  List<List<Object?>> callsTo(String method) => [
    for (final (m, args) in calls)
      if (m == method) args,
  ];

  Future<T> _answer<T>(
    String method,
    List<Object?> args,
    T Function() reply,
  ) async {
    calls.add((method, args));
    await gate?.future;
    if (error case final error?) throw error;
    return reply();
  }

  @override
  Future<ConversationPage> list({
    String? cursor,
    int limit = 25,
    bool isArchived = false,
    String? search,
    List<String> tags = const [],
  }) => _answer(
    'list',
    [cursor, limit, isArchived, search, tags],
    () => pages.isEmpty
        ? (conversations: const <Conversation>[], nextCursor: null)
        : pages.removeAt(0),
  );

  @override
  Future<Conversation> get(String id) =>
      _answer('get', [id], () => conversations[id]!);

  @override
  Future<Conversation?> rename(String id, String title) =>
      _answer('rename', [id, title], () => renameReply);

  @override
  Future<Conversation?> archive(String id, bool isArchived) =>
      _answer('archive', [id, isArchived], () => archiveReply);

  @override
  Future<Conversation?> pin(String id, bool pinned) =>
      _answer('pin', [id, pinned], () => pinReply);

  @override
  Future<void> delete(String id) => _answer('delete', [id], () {});

  @override
  Future<Conversation> duplicate(String id, String title) =>
      _answer('duplicate', [id, title], () => duplicateReply);

  @override
  Future<void> importFile(Uint8List bytes, String fileName) =>
      _answer('importFile', [bytes, fileName], () {});

  @override
  Future<List<Tag>> tags() => _answer('tags', const [], () => tagsReply);

  @override
  Future<Tag> createTag(String tag) =>
      _answer('createTag', [tag], () => Tag(tag: tag));

  @override
  Future<Tag> renameTag(String tag, String newName) =>
      _answer('renameTag', [tag, newName], () => Tag(tag: newName));

  @override
  Future<void> deleteTag(String tag) => _answer('deleteTag', [tag], () {});

  @override
  Future<List<String>> setConversationTags(String id, List<String> tags) =>
      _answer('setConversationTags', [id, tags], () => setTagsReply ?? tags);

  @override
  Future<String?> sharedLinkId(String id) =>
      _answer('sharedLinkId', [id], () => sharedLinkReply);

  @override
  Future<String> createShareLink(String id) =>
      _answer('createShareLink', [id], () => createShareReply);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
