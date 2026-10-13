import '../../../core/models/attachment.dart';
import '../../../core/models/message.dart';
import '../tree/message_tree.dart';
import 'chat_turn.dart';

/// The `POST /api/agents/chat/{endpoint}` body for [t] (Req 18.2).
///
/// [conversationId] is omitted in a new chat. [messageId] is the
/// Optimistic_Message id, sent for send and edit only. [clientRequestId] is
/// a fresh uuid per send, and [timeZone] the device's IANA id. Null, false
/// and empty optional fields are left out. The changed model parameters in
/// `t.params` are spread last and override base keys.
Map<String, Object?> buildChatPayload(
  ChatTurn t, {
  required String clientRequestId,
  String? conversationId,
  String? messageId,
  String? timeZone,
}) {
  final s = t.selection;
  final user = t.userMessage;
  final body = <String, Object?>{};

  void put(String key, Object? value) {
    if (value == null || value == false) return;
    if (value is String && key != 'text' && value.isEmpty) return;
    if (value is Iterable && value.isEmpty) return;
    if (value is Map && value.isEmpty) return;
    body[key] = value;
  }

  String parentOf(Message? m) {
    final id = m?.parentMessageId;
    return id == null || id.isEmpty ? rootParentId : id;
  }

  // The per-kind table: text, parent, message id, files, quotes and flags.
  switch (t.kind) {
    case TurnKind.send:
      final parent = t.parentMessageId;
      put('text', t.text);
      put(
        'parentMessageId',
        parent == null || parent.isEmpty ? rootParentId : parent,
      );
      put('messageId', messageId);
      put('files', t.files);
      put('quotes', t.quotes);
    case TurnKind.edit:
      put('text', t.text);
      put('parentMessageId', parentOf(user));
      put('messageId', messageId);
      put('isEdited', true);
      put('files', user?.files);
    case TurnKind.regenerate:
    case TurnKind.editAi:
      put('text', user?.text ?? '');
      put('parentMessageId', parentOf(user));
      put('overrideParentMessageId', user?.messageId);
      put('isRegenerate', true);
      put('isEdited', t.kind == TurnKind.editAi);
      put('files', user?.files);
      put('quotes', user?.quotes);
    case TurnKind.continued:
      put('text', user?.text ?? '');
      put('parentMessageId', parentOf(user));
      put('overrideParentMessageId', user?.messageId);
      put('responseMessageId', t.responseMessageId);
      put('isContinued', true);
      put('isEdited', true);
      put('isRegenerate', true);
      // As in the KMP_App, a continue reuses the user message's files.
      put('files', user?.files);
    case TurnKind.compact:
      // The Server rejects `compact` beside isRegenerate, isContinued,
      // editedContent or responseMessageId, so none of them is set.
      put('text', '');
      put('parentMessageId', t.parentMessageId);
      put('messageId', t.parentMessageId);
      put('compact', true);
    case TurnKind.attach:
      throw ArgumentError.value(
        t.kind,
        'kind',
        'an attached Run sends no start request',
      );
  }

  if (s.isAssistants) body.remove('quotes');
  if (body['files'] case final List<Attachment> files) {
    body['files'] = [for (final f in files) _file(f)];
  }

  put('conversationId', conversationId);
  put('endpoint', s.endpoint);
  put('endpointType', s.endpointType);
  put('model', s.model);
  put('agent_id', s.agentId);
  put('spec', s.spec);
  put('clientRequestId', clientRequestId);
  put('isTemporary', t.isTemporary);
  if (t.addedSelection case final added?) put('addedConvo', _selection(added));
  if (!s.isSavedAgent) {
    put('ephemeralAgent', _ephemeralAgent(t.tools, t.mcpServers));
  }
  put('timezone', timeZone);

  for (final MapEntry(:key, :value) in t.params.entries) {
    if (value != null) body[key] = value;
  }
  return body;
}

Map<String, Object?> _file(Attachment f) => {
  'file_id': ?f.fileId,
  'filepath': ?f.filepath,
  'type': ?f.type,
  'width': ?f.width,
  'height': ?f.height,
};

Map<String, Object?> _selection(ChatSelection s) => {
  'endpoint': s.endpoint,
  'endpointType': ?s.endpointType,
  'model': ?s.model,
  'agent_id': ?s.agentId,
  'spec': ?s.spec,
  'modelLabel': ?s.modelLabel,
};

Map<String, Object?> _ephemeralAgent(Set<ChatTool> tools, List<String> mcp) => {
  if (mcp.isNotEmpty) 'mcp': mcp,
  if (tools.contains(ChatTool.webSearch)) 'web_search': true,
  if (tools.contains(ChatTool.fileSearch)) 'file_search': true,
  if (tools.contains(ChatTool.executeCode)) 'execute_code': true,
  if (tools.contains(ChatTool.artifacts)) 'artifacts': 'default',
  if (tools.contains(ChatTool.memory)) 'memory': true,
};
