import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_gate.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/models/tag.dart';
import '../../core/network/api_client.dart';

/// One page of `GET /api/convos`. [nextCursor] is null on the last page.
typedef ConversationPage = ({
  List<Conversation> conversations,
  String? nextCursor,
});

/// `POST /api/convos/fork`: the new conversation and the messages the
/// Server copied into it (Req 25.9).
typedef ForkedConversation = ({
  Conversation conversation,
  List<Message> messages,
});

/// The [ConversationsApi] on the app's [ApiClient]. Tests override it.
final conversationsApiProvider = Provider<ConversationsApi>(
  (ref) => ConversationsApi(ref.read(apiClientProvider)),
);

/// The conversation, Bookmarks and share-link routes of the
/// Conversation_List (Req 15, 16).
///
/// Bodies are passed without the Arg_Envelope: [ApiClient] wraps them for
/// `update`, `archive`, `pin` and `DELETE /api/convos` (Req 4.5).
class ConversationsApi {
  ConversationsApi(this._api);

  final ApiClient _api;

  /// `GET /api/convos`: one page, newest first. A blank [search] is not
  /// sent; each of [tags] is a repeated `tags` parameter.
  Future<ConversationPage> list({
    String? cursor,
    int limit = 25,
    bool isArchived = false,
    String? search,
    List<String> tags = const [],
  }) {
    final query = search?.trim();
    return _api.json(
      'GET',
      '/api/convos',
      _decodePage,
      query: {
        'cursor': cursor,
        'limit': limit,
        'isArchived': isArchived,
        if (query != null && query.isNotEmpty) 'search': query,
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
  }

  /// `GET /api/convos/{id}`: the full conversation, `tags` included.
  Future<Conversation> get(String id) => _api.json(
    'GET',
    '/api/convos/${Uri.encodeComponent(id)}',
    (json) => _conversation(json)!,
  );

  /// `POST /api/convos/update`. The Server's saved row, or null when the
  /// body is not a conversation.
  Future<Conversation?> rename(String id, String title) => _api.json(
    'POST',
    '/api/convos/update',
    _conversation,
    data: {'conversationId': id, 'title': title},
  );

  /// `POST /api/convos/archive`.
  Future<Conversation?> archive(String id, bool isArchived) => _api.json(
    'POST',
    '/api/convos/archive',
    _conversation,
    data: {'conversationId': id, 'isArchived': isArchived},
  );

  /// `POST /api/convos/pin`.
  Future<Conversation?> pin(String id, bool pinned) => _api.json(
    'POST',
    '/api/convos/pin',
    _conversation,
    data: {'conversationId': id, 'pinned': pinned},
    feature: Feature.pin,
  );

  /// `DELETE /api/convos`. The Server's result is ignored.
  Future<void> delete(String id) =>
      _api.send('DELETE', '/api/convos', data: {'conversationId': id});

  /// `POST /api/convos/duplicate` (no Arg_Envelope). The copy is the
  /// response's `conversation`, or the whole body when that key is absent.
  Future<Conversation> duplicate(String id, String title) =>
      _api.json('POST', '/api/convos/duplicate', (json) {
        final body = json! as Map;
        return _conversation(body['conversation'] ?? body)!;
      }, data: {'conversationId': id, 'title': title});

  /// `POST /api/convos/fork` (no Arg_Envelope): forks [conversationId] at
  /// [messageId] (Req 25.9).
  ///
  /// [option] is one of the KMP_App's fork modes (`directPath`,
  /// `includeBranches`, `targetLevel`), [splitAtTarget] starts the fork at
  /// the target instead of the root, and [latestMessageId] is the open
  /// conversation's leaf, which the Server uses to resolve the branch.
  Future<ForkedConversation> fork({
    required String conversationId,
    required String messageId,
    required String option,
    required bool splitAtTarget,
    String? latestMessageId,
  }) => _api.json(
    'POST',
    '/api/convos/fork',
    (json) {
      final body = json! as Map;
      return (
        conversation: _conversation(body['conversation'])!,
        messages: [
          for (final item in (body['messages'] as List?) ?? const [])
            Message.fromJson((item as Map).cast<String, Object?>()),
        ],
      );
    },
    data: {
      'conversationId': conversationId,
      'messageId': messageId,
      'option': option,
      'splitAtTarget': splitAtTarget,
      'latestMessageId': ?latestMessageId,
    },
  );

  /// `POST /api/convos/import`: uploads [bytes] as the multipart `file`
  /// field, named [fileName].
  Future<void> importFile(Uint8List bytes, String fileName) => _api.send(
    'POST',
    '/api/convos/import',
    data: FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType('application', 'json'),
      ),
    }),
    transfer: true,
  );

  /// `GET /api/tags`: the user's Bookmarks tags.
  Future<List<Tag>> tags() => _api.json(
    'GET',
    '/api/tags',
    (json) => [
      for (final item in json! as List)
        Tag.fromJson((item as Map).cast<String, Object?>()),
    ],
    feature: Feature.bookmarks,
  );

  /// `POST /api/tags`.
  Future<Tag> createTag(String tag) => _api.json(
    'POST',
    '/api/tags',
    _tag,
    data: {'tag': tag},
    feature: Feature.bookmarks,
  );

  /// `PUT /api/tags/{tag}`.
  Future<Tag> renameTag(String tag, String newName) => _api.json(
    'PUT',
    '/api/tags/${Uri.encodeComponent(tag)}',
    _tag,
    data: {'tag': newName},
    feature: Feature.bookmarks,
  );

  /// `DELETE /api/tags/{tag}`.
  Future<void> deleteTag(String tag) => _api.send(
    'DELETE',
    '/api/tags/${Uri.encodeComponent(tag)}',
    feature: Feature.bookmarks,
  );

  /// `PUT /api/tags/convo/{id}`: replaces the conversation's tags and
  /// returns the Server's list. String items and `{tag}` objects both read
  /// as names; a body that is not a list reads as [tags].
  Future<List<String>> setConversationTags(String id, List<String> tags) =>
      _api.json(
        'PUT',
        '/api/tags/convo/${Uri.encodeComponent(id)}',
        (json) => json is List
            ? [
                for (final item in json)
                  if (item is String)
                    item
                  else if (item is Map && item['tag'] is String)
                    item['tag'] as String,
              ]
            : tags,
        data: {'tags': tags},
        feature: Feature.bookmarks,
      );

  /// `GET /api/share/link/{id}`: the existing link's `shareId`, or null
  /// unless the Server answers `success: true`.
  Future<String?> sharedLinkId(String id) => _api.json(
    'GET',
    '/api/share/link/${Uri.encodeComponent(id)}',
    (json) => json is Map && json['success'] == true
        ? json['shareId'] as String?
        : null,
    feature: Feature.sharedLinks,
  );

  /// `POST /api/share/{id}`: creates a link and returns its `shareId`.
  Future<String> createShareLink(String id) => _api.json(
    'POST',
    '/api/share/${Uri.encodeComponent(id)}',
    (json) => (json! as Map)['shareId'] as String,
    data: const <String, Object?>{},
    feature: Feature.sharedLinks,
  );

  static ConversationPage _decodePage(Object? json) {
    final body = json! as Map;
    return (
      conversations: [
        for (final item in (body['conversations'] as List?) ?? const [])
          _conversation(item)!,
      ],
      nextCursor: body['nextCursor'] as String?,
    );
  }

  static Conversation? _conversation(Object? json) =>
      json is Map ? Conversation.fromJson(json.cast<String, Object?>()) : null;

  static Tag _tag(Object? json) =>
      Tag.fromJson((json! as Map).cast<String, Object?>());
}
