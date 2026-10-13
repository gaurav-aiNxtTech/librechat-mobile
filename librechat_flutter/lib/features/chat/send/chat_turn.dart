import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/attachment.dart';
import '../../../core/models/message.dart';

part 'chat_turn.freezed.dart';

/// What a Run does. `attach` joins a Run that is already active and sends
/// no start request.
enum TurnKind { send, edit, regenerate, editAi, continued, compact, attach }

/// A Composer tool toggle (Req 27.1), sent in `ephemeralAgent`.
enum ChatTool { webSearch, fileSearch, executeCode, artifacts, memory }

/// The endpoint and model, agent or model spec a turn runs on.
@freezed
abstract class ChatSelection with _$ChatSelection {
  const ChatSelection._();

  const factory ChatSelection({
    required String endpoint,
    String? endpointType,
    String? model,
    String? agentId,
    String? spec,
    String? modelLabel,
  }) = _ChatSelection;

  /// A saved agent runs with its own tools, so no `ephemeralAgent` is sent.
  bool get isSavedAgent => agentId != null && agentId!.isNotEmpty;

  /// Assistants endpoints take no quotes (Req 25.10).
  bool get isAssistants => endpoint.toLowerCase().endsWith('assistants');
}

/// One turn as the Composer or a message action builds it, and RunService
/// runs it. `buildChatPayload` turns it into the start request body.
///
/// The fields that name the message the turn acts on depend on [kind]:
/// - send: [parentMessageId] is the parent (null for the Root_Parent_Id).
/// - edit: [userMessage] is the edited user message.
/// - regenerate, editAi: [userMessage] is the reply's parent user message.
/// - continued: [userMessage] is the reply's parent user message and
///   [responseMessageId] the reply being extended.
/// - compact: [parentMessageId] is the Active_Path leaf.
///
/// [params] holds only the model parameters the user changed.
@freezed
abstract class ChatTurn with _$ChatTurn {
  const factory ChatTurn({
    required TurnKind kind,
    required ChatSelection selection,
    @Default('') String text,
    @Default(<Attachment>[]) List<Attachment> files,
    @Default(<String>[]) List<String> quotes,
    ChatSelection? addedSelection,
    @Default(<ChatTool>{}) Set<ChatTool> tools,
    @Default(<String>[]) List<String> mcpServers,
    @Default(<String, Object?>{}) Map<String, Object?> params,
    @Default(false) bool isTemporary,
    String? parentMessageId,
    Message? userMessage,
    String? responseMessageId,
  }) = _ChatTurn;
}
