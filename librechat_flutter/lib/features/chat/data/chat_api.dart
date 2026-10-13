import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pending_action.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';

/// The [ChatApi] on the app's [ApiClient]. Tests override it.
final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.read(apiClientProvider)),
);

/// What the start request answers: the id to open the Stream with and the
/// Run's generation epoch, when the Server sends one.
typedef ChatStart = ({String streamId, int? generationCreatedAt});

/// What the status route answers about a conversation's Run: whether it is
/// still [active] (running, or paused on a live [pendingAction]), the
/// [streamId] to resume and the Run's generation epoch [createdAt].
typedef RunStatus = ({
  bool active,
  String? streamId,
  int? createdAt,
  PendingAction? pendingAction,
});

/// The chat routes RunService calls.
class ChatApi {
  ChatApi(this._api, {this.statusRetryDelay = const Duration(seconds: 1)});

  final ApiClient _api;

  /// The wait before a status request is retried after a 503 (see
  /// [status]). Tests shorten it.
  final Duration statusRetryDelay;

  /// How many times [status] retries a 503.
  static const statusRetries = 3;

  /// `POST /api/agents/chat/{endpoint}` with [body] from `buildChatPayload`
  /// (Req 18.2), for every endpoint. The Stream id is `streamId`, else the
  /// `conversationId`, which older Servers use as the Stream id. A reply
  /// with neither is malformed.
  Future<ChatStart> start(String endpoint, Map<String, Object?> body) =>
      _api.json('POST', '/api/agents/chat/${Uri.encodeComponent(endpoint)}', (
        json,
      ) {
        final reply = json! as Map;
        return (
          streamId: (reply['streamId'] ?? reply['conversationId']) as String,
          generationCreatedAt: (reply['generationCreatedAt'] as num?)?.toInt(),
        );
      }, data: body);

  /// `POST /api/agents/chat/abort` for the Run on [streamId] (Req 20.2).
  ///
  /// The reply is only an ack: the Server ends the Run with an aborted
  /// Final_Frame on the open Stream. An unknown [streamId] omits `abortKey`
  /// (the route rejects an empty one) and sends `conversationId: "new"`,
  /// which lets the route find the user's job before `created`.
  /// [generationCreatedAt] fences the abort to that Run, so a newer Run on
  /// the same Stream id is never stopped.
  Future<void> abort({
    required String? streamId,
    required bool isTemporary,
    int? generationCreatedAt,
  }) {
    final id = streamId == null || streamId.isEmpty ? null : streamId;
    return _api.json<void>(
      'POST',
      '/api/agents/chat/abort',
      (_) {},
      data: {
        'abortKey': ?id,
        'conversationId': id ?? 'new',
        'endpoint': 'agents',
        'isTemporary': isTemporary,
        'generationCreatedAt': ?generationCreatedAt,
      },
    );
  }

  /// `GET /api/agents/chat/status/{conversationId}` (Req 19.6, 19.8, 19.9).
  ///
  /// A 503 means the Server's generation state is still settling, not that
  /// the Run ended, so it is retried [statusRetries] times,
  /// [statusRetryDelay] apart, before it is thrown.
  Future<RunStatus> status(String conversationId) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _api.json(
          'GET',
          '/api/agents/chat/status/${Uri.encodeComponent(conversationId)}',
          _decodeStatus,
        );
      } on AppException catch (e) {
        if (e.status != 503 || attempt >= statusRetries) rethrow;
      }
      await Future<void>.delayed(statusRetryDelay);
    }
  }

  static RunStatus _decodeStatus(Object? json) {
    final reply = json! as Map;
    final action = reply['pendingAction'];
    return (
      active: reply['active'] == true,
      streamId: reply['streamId'] as String?,
      createdAt: (reply['createdAt'] as num?)?.toInt(),
      pendingAction: action is Map && action['actionId'] != null
          ? PendingAction.fromJson(action.cast<String, Object?>())
          : null,
    );
  }

  /// `GET /api/convos/gen_title/{conversationId}`: the title the Server
  /// generated for a new conversation's first turn (Req 21.10), or null when
  /// the body has none. The Server waits up to about 15 s for the title and
  /// answers 404 when none came.
  Future<String?> generateTitle(String conversationId) => _api.json(
    'GET',
    '/api/convos/gen_title/${Uri.encodeComponent(conversationId)}',
    (json) => json is Map ? json['title'] as String? : null,
  );
}
