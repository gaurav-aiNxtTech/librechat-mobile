import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message.dart';
import '../../../core/network/api_client.dart';

/// The [MessagesApi] on the app's [ApiClient]. Tests override it.
final messagesApiProvider = Provider<MessagesApi>(
  (ref) => MessagesApi(ref.read(apiClientProvider)),
);

/// The message routes. The conversation export reads [list]; the
/// conversation view adds its routes here.
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
}
