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
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/images/image_loader.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/tag.dart';
import 'package:librechat_flutter/core/models/user.dart';
import 'package:librechat_flutter/core/storage/cache_db.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/stream/event_mapper.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/stream/stream_events.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/file_downloads.dart';
import 'package:librechat_flutter/features/chat/data/messages_api.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/conversations/conversations_api.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';
import 'package:librechat_flutter/features/files/files_api.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

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

  /// What [fork] answers (Req 25.9).
  ForkedConversation forkReply = (
    conversation: const Conversation(conversationId: 'fork-1'),
    messages: const <Message>[],
  );
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
  Future<ForkedConversation> fork({
    required String conversationId,
    required String messageId,
    required String option,
    required bool splitAtTarget,
    String? latestMessageId,
  }) => _answer('fork', [
    conversationId,
    messageId,
    option,
    splitAtTarget,
    latestMessageId,
  ], () => forkReply);

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

/// A [ConversationsRepository] over an in-memory Cache, for widget tests
/// (drift's stream timers leak in `testWidgets`).
///
/// [watchList] streams [rows] (the cached list, already in display order)
/// and every [emit]. Each call is recorded in [calls] as `(method, args)`;
/// a method throws `errors[method]`, else [error], after `gates[method]`,
/// else [gate], completes when one is set. [refresh] answers
/// [refreshCursor] and, when
/// [refreshRows] is set, emits it; [loadMore] answers [loadMoreCursors] in
/// order, then null. Mutations apply to [rows] the way the real Cache
/// write would. [api] is a [FakeConversationsApi].
class FakeConversationsRepository implements ConversationsRepository {
  FakeConversationsRepository({List<Conversation> rows = const []})
    : rows = [...rows];

  List<Conversation> rows;
  final fakeApi = FakeConversationsApi();
  final calls = <(String, List<Object?>)>[];
  final errors = <String, Object>{};
  Object? error;
  Completer<void>? gate;
  final gates = <String, Completer<void>>{};
  String? refreshCursor;
  List<Conversation>? refreshRows;
  final loadMoreCursors = <String?>[];
  Conversation duplicateReply = const Conversation(conversationId: 'copy');
  final _changes = StreamController<List<Conversation>>.broadcast();

  @override
  ConversationsApi get api => fakeApi;

  /// The calls to [method], as their args.
  List<List<Object?>> callsTo(String method) => [
    for (final (m, args) in calls)
      if (m == method) args,
  ];

  /// Replaces the cached rows and notifies [watchList].
  void emit(List<Conversation> next) {
    rows = [...next];
    _changes.add(rows);
  }

  Future<T> _answer<T>(
    String method,
    List<Object?> args,
    T Function() reply,
  ) async {
    calls.add((method, args));
    await (gates[method] ?? gate)?.future;
    if (errors[method] ?? error case final error?) throw error;
    return reply();
  }

  void _replace(Conversation next) => emit([
    for (final c in rows) c.conversationId == next.conversationId ? next : c,
  ]);

  void _remove(String? id) => emit([
    for (final c in rows)
      if (c.conversationId != id) c,
  ]);

  @override
  Stream<List<Conversation>> watchList() async* {
    yield rows;
    yield* _changes.stream;
  }

  @override
  Future<String?> refresh() => _answer('refresh', const [], () {
    if (refreshRows case final next?) emit(next);
    return refreshCursor;
  });

  @override
  Future<String?> loadMore(String cursor) => _answer('loadMore', [
    cursor,
  ], () => loadMoreCursors.isEmpty ? null : loadMoreCursors.removeAt(0));

  @override
  Future<void> upsert(Conversation conversation) =>
      _answer('upsert', [conversation], () => _replace(conversation));

  @override
  Future<Conversation> rename(Conversation conversation, String title) =>
      _answer('rename', [conversation, title], () {
        final next = conversation.copyWith(title: title);
        _replace(next);
        return next;
      });

  @override
  Future<Conversation> setArchived(Conversation conversation, bool archived) =>
      _answer('setArchived', [conversation, archived], () {
        final next = conversation.copyWith(isArchived: archived);
        if (archived) {
          _remove(next.conversationId);
        } else {
          emit([next, ...rows]);
        }
        return next;
      });

  @override
  Future<Conversation> setPinned(Conversation conversation, bool pinned) =>
      _answer('setPinned', [conversation, pinned], () {
        final next = conversation.copyWith(pinned: pinned);
        _replace(next);
        return next;
      });

  @override
  Future<Conversation> setTags(Conversation conversation, List<String> tags) =>
      _answer('setTags', [conversation, tags], () {
        final next = conversation.copyWith(tags: tags);
        _replace(next);
        return next;
      });

  @override
  Future<void> delete(String id) => _answer('delete', [id], () => _remove(id));

  @override
  Future<Conversation> duplicate(Conversation conversation) =>
      _answer('duplicate', [conversation], () {
        emit([duplicateReply, ...rows]);
        return duplicateReply;
      });

  @override
  Future<void> importFile(Uint8List bytes, String fileName) =>
      _answer('importFile', [bytes, fileName], () {});

  /// The row of [id] in [rows], then after every [emit].
  @override
  Stream<Conversation?> watchOne(String id) async* {
    Conversation? find(List<Conversation> list) =>
        list.where((c) => c.conversationId == id).firstOrNull;
    yield find(rows);
    yield* _changes.stream.map(find);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers [list] from [messages] (empty for an unknown id), or throws
/// [error], after [gate] completes when one is set. Each requested id is
/// recorded in [requests].
///
/// The message actions' routes record their arguments and answer the
/// Server's reply (Req 25.3, 25.6, 25.7): [update] echoes the saved text
/// into the matching [messages] row, or into a bare message when the id is
/// unknown, and the feedback routes answer what they stored.
class FakeMessagesApi implements MessagesApi {
  final messages = <String, List<Message>>{};
  final requests = <String>[];
  Object? error;
  Completer<void>? gate;

  /// Each [update] call, in order.
  final updates =
      <({String conversationId, String messageId, String text, int? index})>[];

  /// Each [setFeedback] call, in order.
  final feedbackSets =
      <
        ({
          String conversationId,
          String messageId,
          String rating,
          String tag,
          String? text,
        })
      >[];

  /// Each [clearFeedback] call, in order.
  final feedbackClears = <(String, String)>[];

  @override
  Future<List<Message>> list(String conversationId) async {
    requests.add(conversationId);
    await gate?.future;
    if (error case final error?) throw error;
    return messages[conversationId] ?? const [];
  }

  @override
  Future<Message> update(
    String conversationId,
    String messageId, {
    required String text,
    int? index,
  }) async {
    updates.add((
      conversationId: conversationId,
      messageId: messageId,
      text: text,
      index: index,
    ));
    await gate?.future;
    if (error case final error?) throw error;
    final stored = (messages[conversationId] ?? const <Message>[]).firstWhere(
      (m) => m.messageId == messageId,
      orElse: () =>
          Message(messageId: messageId, conversationId: conversationId),
    );
    // The Server writes the part's text when an index is given, and the
    // message's own text otherwise.
    final content = stored.content;
    if (index != null && content != null && index < content.length) {
      return stored.copyWith(
        content: [
          ...content.sublist(0, index),
          content[index].copyWith(text: text),
          ...content.sublist(index + 1),
        ],
      );
    }
    return stored.copyWith(text: text);
  }

  @override
  Future<MessageFeedback?> setFeedback(
    String conversationId,
    String messageId, {
    required String rating,
    required String tag,
    String? text,
  }) async {
    feedbackSets.add((
      conversationId: conversationId,
      messageId: messageId,
      rating: rating,
      tag: tag,
      text: text,
    ));
    await gate?.future;
    if (error case final error?) throw error;
    return MessageFeedback(
      rating: rating == 'thumbsUp'
          ? FeedbackRating.thumbsUp
          : FeedbackRating.thumbsDown,
      tag: tag,
      text: text,
    );
  }

  @override
  Future<MessageFeedback?> clearFeedback(
    String conversationId,
    String messageId,
  ) async {
    feedbackClears.add((conversationId, messageId));
    await gate?.future;
    if (error case final error?) throw error;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records saves, shares and copies. [saveFile] answers [saveResult]
/// (false is a cancelled save); [pickJsonFile] answers [picked] (null is a
/// cancelled pick) and counts in [picks].
///
/// The attachment pickers answer [pickedFiles] (empty is a cancelled pick)
/// and record which source was used in [pickedSources]; [pickError] makes
/// one throw, as a denied camera permission does (Req 44.11).
class FakePlatformActions implements PlatformActions {
  final saves = <({String fileName, Uint8List bytes, String mimeType})>[];
  final shares = <String>[];
  final copies = <String>[];
  bool saveResult = true;
  PickedFile? picked;
  int picks = 0;
  List<PickedFile> pickedFiles = const [];
  final pickedSources = <String>[];
  Object? pickError;

  @override
  Future<List<PickedFile>> pickFiles() async => _pick('files');

  @override
  Future<List<PickedFile>> pickImages() async => _pick('photos');

  @override
  Future<PickedFile?> takePhoto() async => _pick('camera').firstOrNull;

  List<PickedFile> _pick(String source) {
    pickedSources.add(source);
    if (pickError case final error?) throw error;
    return pickedFiles;
  }

  @override
  Future<bool> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    saves.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
    return saveResult;
  }

  @override
  Future<PickedFile?> pickJsonFile() async {
    picks++;
    return picked;
  }

  @override
  Future<void> share(String text) async => shares.add(text);

  @override
  Future<void> copy(String text) async => copies.add(text);

  /// Each opened link, in order.
  final opened = <Uri>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }

  /// Each shared file, in order.
  final sharedFiles = <({String fileName, Uint8List bytes, String mimeType})>[];

  @override
  Future<void> shareFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async =>
      sharedFiles.add((fileName: fileName, bytes: bytes, mimeType: mimeType));

  /// Each opened file as `(path, mimeType)`, answered with [openResult].
  final openedFiles = <(String, String?)>[];
  OpenFileResult openResult = OpenFileResult.opened;

  @override
  Future<OpenFileResult> openFile(String path, {String? mimeType}) async {
    openedFiles.add((path, mimeType));
    return openResult;
  }
}

/// An [ImageLoader] that answers every URL with a 1×1 PNG and records it
/// in [loads]. Other members throw.
class FakeImageLoader implements ImageLoader {
  final loads = <String>[];

  static final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<LoadedImage> load(String url) async {
    loads.add(url);
    return (bytes: png, svg: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [FileDownloads] that never touches the network or the disk. Every
/// request is recorded in [requests] (the attachment's `file_id` or the
/// URL) and answers [bytesReply], or throws [error] when set. Files are
/// fake paths under `/fake/downloads/`.
class FakeFileDownloads implements FileDownloads {
  final requests = <String>[];
  Uint8List bytesReply = Uint8List.fromList(const [1, 2, 3]);
  Object? error;

  Future<T> _answer<T>(String request, T Function() reply) async {
    requests.add(request);
    if (error case final error?) throw error;
    return reply();
  }

  @override
  Future<Uint8List> bytes(String url) => _answer(url, () => bytesReply);

  @override
  Future<File> save(Uint8List bytes, String fileName, {String? key}) async =>
      File('/fake/downloads/$fileName');

  @override
  Future<File> download(String url, String fileName) =>
      _answer(url, () => File('/fake/downloads/$fileName'));

  @override
  Future<Uint8List> attachmentBytes(Attachment attachment) =>
      _answer(attachment.fileId ?? '', () => bytesReply);

  @override
  Future<File> attachmentFile(Attachment attachment, String fileName) =>
      _answer(attachment.fileId ?? '', () => File('/fake/downloads/$fileName'));

  @override
  bool canDownload(Attachment attachment) => true;
}

/// A [MessagesRepository] held in memory, for widget tests (drift's stream
/// timers leak in `testWidgets`). [watch] streams `cached[id]` (empty when
/// unset) and every [emit]; [fetch] reads [api] and, like the real one,
/// replaces the cached rows with its result.
class FakeMessagesRepository implements MessagesRepository {
  final cached = <String, List<Message>>{};
  final fakeApi = FakeMessagesApi();
  final _changes = StreamController<(String, List<Message>)>.broadcast();

  @override
  MessagesApi get api => fakeApi;

  /// Replaces the cached rows of [conversationId] and notifies [watch].
  void emit(String conversationId, List<Message> rows) {
    cached[conversationId] = rows;
    _changes.add((conversationId, rows));
  }

  @override
  Stream<List<Message>> watch(String conversationId) async* {
    yield cached[conversationId] ?? const [];
    yield* _changes.stream
        .where((change) => change.$1 == conversationId)
        .map((change) => change.$2);
  }

  @override
  Future<List<Message>> fetch(String conversationId) async {
    final messages = await fakeApi.list(conversationId);
    emit(conversationId, messages);
    return messages;
  }

  /// The saved drafts, by key.
  final drafts = <String, String>{};

  @override
  Future<String?> draft(String key) async => drafts[key];

  @override
  Future<void> saveDraft(String key, String text) async {
    if (text.trim().isEmpty) return deleteDraft(key);
    drafts[key] = text;
  }

  @override
  Future<void> deleteDraft(String key) async => drafts.remove(key);

  @override
  Future<void> upsert(String conversationId, List<Message> messages) async {
    final ids = {for (final m in messages) m.messageId};
    emit(conversationId, [
      for (final m in cached[conversationId] ?? const <Message>[])
        if (!ids.contains(m.messageId)) m,
      ...messages,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records each [start] as `(endpoint, body)` in [starts] and answers
/// [startReply], or throws [startError], after [startGate] completes when
/// one is set. [generateTitle] records its id in [titleRequests] and
/// answers [titleReply], or throws [titleError]. [abort] records
/// `(streamId, isTemporary, generationCreatedAt)` in [aborts] and [status]
/// its id in [statusRequests]; each throws its error when set, after its
/// gate completes when one is set. [statusReply] defaults to no active Run.
class FakeChatApi implements ChatApi {
  final starts = <(String, Map<String, Object?>)>[];
  ChatStart startReply = (streamId: 's1', generationCreatedAt: 7);
  Object? startError;
  Completer<void>? startGate;
  final titleRequests = <String>[];
  String? titleReply = 'Generated';
  Object? titleError;
  final aborts = <(String?, bool, int?)>[];
  Object? abortError;
  Completer<void>? abortGate;
  final statusRequests = <String>[];
  RunStatus statusReply = (
    active: false,
    streamId: null,
    createdAt: null,
    pendingAction: null,
  );
  Object? statusError;
  Completer<void>? statusGate;

  @override
  Future<void> abort({
    required String? streamId,
    required bool isTemporary,
    int? generationCreatedAt,
  }) async {
    aborts.add((streamId, isTemporary, generationCreatedAt));
    await abortGate?.future;
    if (abortError case final error?) throw error;
  }

  @override
  Future<RunStatus> status(String conversationId) async {
    statusRequests.add(conversationId);
    await statusGate?.future;
    if (statusError case final error?) throw error;
    return statusReply;
  }

  @override
  Future<ChatStart> start(String endpoint, Map<String, Object?> body) async {
    starts.add((endpoint, body));
    await startGate?.future;
    if (startError case final error?) throw error;
    return startReply;
  }

  @override
  Future<String?> generateTitle(String conversationId) async {
    titleRequests.add(conversationId);
    if (titleError case final error?) throw error;
    return titleReply;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Hands each [open] a Stream the test drives through [emit]. Each open is
/// recorded in [opens] as `(streamId, resume)`, and [cancels] counts the
/// cancelled subscriptions.
class FakeStreamClient implements StreamClient {
  final opens = <(String, bool)>[];
  final _controllers = <StreamController<StreamEvent>>[];
  int cancels = 0;

  @override
  Stream<StreamEvent> open(
    String streamId,
    EventMapper mapper, {
    bool resume = false,
  }) {
    opens.add((streamId, resume));
    final controller = StreamController<StreamEvent>(onCancel: () => cancels++);
    _controllers.add(controller);
    return controller.stream;
  }

  /// Delivers [events] on the last opened Stream, then lets them arrive.
  Future<void> emit(List<StreamEvent> events) async {
    for (final e in events) {
      _controllers.last.add(e);
    }
    await Future<void>.delayed(Duration.zero);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A WebView platform that renders nothing, so a widget test can mount
/// `WebContentView` and drive the pieces the App owns: the `Host` channel,
/// the NavigationDelegate and the load calls.
///
/// The platform interface classes verify their own token, so these fakes
/// `extend` them rather than `implements`; every other member keeps the
/// base class's `UnimplementedError`, which is what a call the App should
/// not make looks like.
///
/// Install it once per test, before the first `WebContentView` mounts:
///
/// ```dart
/// late FakeWebViewPlatform webView;
/// setUp(() => webView = FakeWebViewPlatform.install());
/// ```
class FakeWebViewPlatform extends WebViewPlatform {
  /// Replaces `WebViewPlatform.instance` with a fresh fake. The instance
  /// cannot be set back to null, so each test installs its own.
  static FakeWebViewPlatform install() {
    final platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    return platform;
  }

  /// Every controller created since [install], in order.
  final controllers = <FakeWebViewController>[];

  /// The controller of the most recently created WebView.
  FakeWebViewController get controller => controllers.last;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = FakeWebViewController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => FakeWebViewWidget(params);
}

/// Records the controller calls `WebContentView` makes and replays the
/// callbacks it registers.
class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  /// Each `loadHtmlString` as `(html, baseUrl)`, in order.
  final loads = <(String, String?)>[];
  JavaScriptMode? javaScriptMode;
  Color? backgroundColor;

  /// The channels the view added, by name.
  final channels = <String, JavaScriptChannelParams>{};
  FakeNavigationDelegate? navigationDelegate;

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async =>
      loads.add((html, baseUrl));

  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async =>
      javaScriptMode = mode;

  @override
  Future<void> setBackgroundColor(Color color) async => backgroundColor = color;

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      channels[params.name] = params;

  @override
  Future<void> removeJavaScriptChannel(String name) async =>
      channels.remove(name);

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate delegate,
  ) async => navigationDelegate = delegate as FakeNavigationDelegate;

  /// Delivers [message] on the `Host` channel, as a page's
  /// `Host.postMessage` would.
  void postHostMessage(String message) =>
      channels['Host']!.onMessageReceived(JavaScriptMessage(message: message));

  /// Asks the navigation delegate about [url], as a tapped link would.
  Future<NavigationDecision> navigate(
    String url, {
    bool isMainFrame = true,
  }) async => navigationDelegate!.onNavigationRequest!(
    NavigationRequest(url: url, isMainFrame: isMainFrame),
  );

  /// Reports a load failure, as the platform would.
  void failLoad(String description, {bool isForMainFrame = true}) =>
      navigationDelegate!.onWebResourceError!(
        WebResourceError(
          errorCode: -2,
          description: description,
          errorType: WebResourceErrorType.hostLookup,
          isForMainFrame: isForMainFrame,
        ),
      );
}

/// Keeps the callbacks the App registers, so a test can fire them.
class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  WebResourceErrorCallback? onWebResourceError;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback callback,
  ) async => onNavigationRequest = callback;

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async =>
      onWebResourceError = callback;
}

/// The placeholder in place of the native view, so the surrounding layout
/// is the real one.
class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: Key('FakeWebView'));
}

/// A [FilesApi] that never touches the network.
///
/// [config] answers [configReply] or throws [configError]. Each [upload]
/// is recorded in [uploads] and its progress callback kept in [progress],
/// keyed by `file_id`, so a test can report progress itself. [uploadGate]
/// holds every upload open while a test looks at the chips, and
/// [uploadError] makes them fail. A cancelled upload throws the cancel
/// error, as dio does.
class FakeFilesApi implements FilesApi {
  final uploads = <RecordedUpload>[];
  final progress = <String, dio.ProgressCallback>{};
  FileConfig configReply = builtInFileConfig;
  Object? configError;
  Object? uploadError;
  Completer<void>? uploadGate;

  @override
  Future<FileConfig> config() async {
    if (configError case final error?) throw error;
    return configReply;
  }

  @override
  Future<FileObject> upload({
    required Uint8List bytes,
    required String filename,
    required String type,
    required String fileId,
    String? endpoint,
    String? model,
    String? agentId,
    String? toolResource,
    bool messageFile = true,
    int? width,
    int? height,
    dio.ProgressCallback? onProgress,
    dio.CancelToken? cancelToken,
  }) async {
    uploads.add((
      filename: filename,
      type: type,
      fileId: fileId,
      size: bytes.length,
      endpoint: endpoint,
      model: model,
      agentId: agentId,
      toolResource: toolResource,
      width: width,
      height: height,
    ));
    if (onProgress != null) progress[fileId] = onProgress;
    final gate = uploadGate?.future ?? Future<void>.value();
    if (cancelToken == null) {
      await gate;
    } else {
      await Future.any([gate, cancelToken.whenCancel]);
      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
    }
    if (uploadError case final error?) throw error;
    return FileObject(
      fileId: fileId,
      filename: filename,
      filepath: '/uploads/$fileId',
      type: type,
      bytes: bytes.length,
      width: width,
      height: height,
    );
  }
}

/// One [FakeFilesApi.upload] call.
typedef RecordedUpload = ({
  String filename,
  String type,
  String fileId,
  int size,
  String? endpoint,
  String? model,
  String? agentId,
  String? toolResource,
  int? width,
  int? height,
});
