/// What a Final_Frame settles (Req 18.11, 18.12, 20.5, 20.6). Pure.
library;

import '../../../core/models/message.dart';
import '../../../core/stream/stream_events.dart';
import '../data/conversation_messages.dart';
import '../tree/message_tree.dart';

/// The turn [frame] settles for a Run whose Optimistic_Message is
/// [optimistic] (null for regenerate, continue and attached Runs).
///
/// - **Abort contract (Req 20.6).** An aborted frame's response is dropped
///   when the frame has `earlyAbort`, no request message, empty response
///   `content`, or a response id equal to the request id plus `_`: the
///   Server saved no reply.
/// - **Early abort (Req 20.5).** Nothing is stored. RunService un-sends the
///   Optimistic_Message and puts its text back into the Composer.
/// - **Matching (Req 18.12).** The Optimistic_Message matches the request
///   message by id, else by equal parent and text, and only the Server's
///   copy is kept, with `files` taken from the Optimistic_Message when the
///   Server's copy has none.
/// - **No request message.** The Optimistic_Message stays as a local
///   message.
///
/// The selection shows the new request and reply, and `justSettledId` is
/// the kept reply.
FinalTurn finalTurn(FinalEvent frame, Message? optimistic) {
  if (frame.earlyAbort) return const FinalTurn(messages: []);

  final request = frame.requestMessage;
  var response = frame.responseMessage;
  if (frame.aborted && response != null && _savedNoReply(request, response)) {
    response = null;
  }

  final messages = <Message>[];
  final selection = <String, String>{};
  if (request != null) {
    final matched =
        optimistic != null &&
        (optimistic.messageId == request.messageId ||
            (optimistic.parentMessageId == request.parentMessageId &&
                optimistic.text == request.text));
    final files = request.files;
    messages.add(
      matched && (files == null || files.isEmpty)
          ? request.copyWith(files: optimistic.files)
          : request,
    );
    selection[_keyOf(request.parentMessageId)] = request.messageId;
  }
  if (response != null) {
    messages.add(response);
    selection[_keyOf(response.parentMessageId ?? request?.messageId)] =
        response.messageId;
  }
  return FinalTurn(
    messages: List.unmodifiable(messages),
    local: request == null && optimistic != null ? [optimistic] : const [],
    selection: Map.unmodifiable(selection),
    justSettledId: response?.messageId,
  );
}

/// [request] is null or [response] has no content or the placeholder id.
bool _savedNoReply(Message? request, Message response) =>
    request == null ||
    (response.content?.isEmpty ?? true) ||
    response.messageId == '${request.messageId}_';

/// The Sibling key of a message with [parentId] (see `activePath`).
String _keyOf(String? parentId) =>
    parentId == null || parentId.isEmpty ? rootParentId : parentId;
