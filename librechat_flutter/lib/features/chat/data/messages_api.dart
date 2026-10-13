import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_gate.dart';
import '../../../core/models/message.dart';
import '../../../core/network/api_client.dart';

/// The [MessagesApi] on the app's [ApiClient]. Tests override it.
final messagesApiProvider = Provider<MessagesApi>(
  (ref) => MessagesApi(ref.read(apiClientProvider)),
);

/// The message routes. The conversation export and `MessagesRepository`
/// read [list]; the message actions read [update], [setFeedback] and
/// [clearFeedback] (Req 25.3, 25.6, 25.7).
class MessagesApi {
  MessagesApi(this._api);

  final ApiClient _api;

  /// `GET /api/messages/{conversationId}`: every message, in Server order.
  Future<List<Message>> list(String conversationId) => _api.json(
    'GET',
    '/api/messages/${Uri.encodeComponent(conversationId)}',
    (json) => [
      for (final item in json! as List)
        Message.fromJson((item as Map).cast<String, Object?>()),
    ],
  );

  /// `PUT /api/messages/{conversationId}/{messageId}`: saves [text]
  /// (Req 25.3) and returns the Server's saved message.
  ///
  /// [index] is the content part the text belongs to. Without it the
  /// Server writes the message's own `text`; with it the Server writes
  /// that part's text and leaves the rest of the content as it is.
  Future<Message> update(
    String conversationId,
    String messageId, {
    required String text,
    int? index,
  }) => _api.json(
    'PUT',
    _path(conversationId, messageId),
    (json) => Message.fromJson((json! as Map).cast<String, Object?>()),
    data: {'text': text, 'index': ?index},
  );

  /// `PUT /api/messages/{conversationId}/{messageId}/feedback` with
  /// `{feedback: {rating, tag, text}}` (Req 25.6). [rating] is `thumbsUp`
  /// or `thumbsDown` and [tag] one of the reason keys the Server accepts;
  /// it rejects a rating without a tag. [text] is the optional comment.
  Future<MessageFeedback?> setFeedback(
    String conversationId,
    String messageId, {
    required String rating,
    required String tag,
    String? text,
  }) => _feedback(conversationId, messageId, {
    'feedback': {'rating': rating, 'tag': tag, 'text': ?text},
  });

  /// The same route with an empty body, which the Server reads as a clear
  /// (Req 25.7). Answers null, the message's feedback after the clear.
  Future<MessageFeedback?> clearFeedback(
    String conversationId,
    String messageId,
  ) => _feedback(conversationId, messageId, const <String, Object?>{});

  /// The feedback route. The answer is `{messageId, conversationId,
  /// feedback}`, not a whole message, so only the feedback comes back.
  Future<MessageFeedback?> _feedback(
    String conversationId,
    String messageId,
    Map<String, Object?> body,
  ) => _api.json(
    'PUT',
    '${_path(conversationId, messageId)}/feedback',
    (json) => json is Map && json['feedback'] is Map
        ? MessageFeedback.fromJson(
            (json['feedback'] as Map).cast<String, Object?>(),
          )
        : null,
    data: body,
    feature: Feature.feedback,
  );

  static String _path(String conversationId, String messageId) =>
      '/api/messages/${Uri.encodeComponent(conversationId)}'
      '/${Uri.encodeComponent(messageId)}';
}
