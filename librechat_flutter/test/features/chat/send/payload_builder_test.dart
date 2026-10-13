// Payload builder examples (Task 15.1).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/features/chat/send/chat_turn.dart';
import 'package:librechat_flutter/features/chat/send/payload_builder.dart';
import 'package:librechat_flutter/features/chat/tree/message_tree.dart';

const openAi = ChatSelection(endpoint: 'openAI', model: 'gpt-4o');
const image = Attachment(
  fileId: 'f1',
  filename: 'a.png',
  filepath: '/i/a.png',
  type: 'image/png',
  width: 4,
  height: 3,
);
const user = Message(
  messageId: 'u1',
  conversationId: 'c',
  parentMessageId: 'a0',
  text: 'hello',
  isCreatedByUser: true,
  files: [image],
  quotes: ['q'],
);

Map<String, Object?> build(
  ChatTurn t, {
  String? conversationId = 'c',
  String? messageId = 'm1',
}) => buildChatPayload(
  t,
  clientRequestId: 'req',
  conversationId: conversationId,
  messageId: messageId,
  timeZone: 'Europe/Berlin',
);

void main() {
  test('send in a new chat carries the base fields and the Root_Parent_Id', () {
    final body = build(
      const ChatTurn(kind: TurnKind.send, selection: openAi, text: 'hi'),
      conversationId: null,
    );
    expect(body, {
      'text': 'hi',
      'parentMessageId': rootParentId,
      'messageId': 'm1',
      'endpoint': 'openAI',
      'model': 'gpt-4o',
      'clientRequestId': 'req',
      'timezone': 'Europe/Berlin',
    });
  });

  test(
    'send carries files, quotes, temporary, addedConvo, tools and params',
    () {
      final body = build(
        const ChatTurn(
          kind: TurnKind.send,
          selection: openAi,
          text: 'hi',
          parentMessageId: 'a1',
          files: [image],
          quotes: ['q'],
          isTemporary: true,
          addedSelection: ChatSelection(
            endpoint: 'agents',
            agentId: 'agent_x',
            modelLabel: 'X',
          ),
          tools: {ChatTool.webSearch, ChatTool.artifacts},
          mcpServers: ['srv'],
          params: {'temperature': 0.2, 'model': 'gpt-4.1', 'top_p': null},
        ),
      );
      expect(body['conversationId'], 'c');
      expect(body['parentMessageId'], 'a1');
      expect(body['files'], [
        {
          'file_id': 'f1',
          'filepath': '/i/a.png',
          'type': 'image/png',
          'width': 4,
          'height': 3,
        },
      ]);
      expect(body['quotes'], ['q']);
      expect(body['isTemporary'], true);
      expect(body['addedConvo'], {
        'endpoint': 'agents',
        'agent_id': 'agent_x',
        'modelLabel': 'X',
      });
      expect(body['ephemeralAgent'], {
        'mcp': ['srv'],
        'web_search': true,
        'artifacts': 'default',
      });
      expect(body['temperature'], 0.2);
      expect(body['model'], 'gpt-4.1', reason: 'params override base keys');
      expect(body.containsKey('top_p'), isFalse);
    },
  );

  test('a saved agent sends no ephemeralAgent, and Assistants no quotes', () {
    final agent = build(
      const ChatTurn(
        kind: TurnKind.send,
        selection: ChatSelection(endpoint: 'agents', agentId: 'agent_1'),
        tools: {ChatTool.webSearch},
      ),
    );
    expect(agent['agent_id'], 'agent_1');
    expect(agent.containsKey('ephemeralAgent'), isFalse);
    final assistants = build(
      const ChatTurn(
        kind: TurnKind.send,
        selection: ChatSelection(endpoint: 'azureAssistants'),
        quotes: ['q'],
      ),
    );
    expect(assistants.containsKey('quotes'), isFalse);
  });

  test(
    'edit sends the edited text under the original parent with its files',
    () {
      final body = build(
        const ChatTurn(
          kind: TurnKind.edit,
          selection: openAi,
          text: 'new',
          userMessage: user,
        ),
      );
      expect(body['text'], 'new');
      expect(body['parentMessageId'], 'a0');
      expect(body['messageId'], 'm1');
      expect(body['isEdited'], true);
      expect(body['files'], hasLength(1));
      expect(body.containsKey('quotes'), isFalse);
    },
  );

  test('regenerate and editAi replay the user message', () {
    final regen = build(
      const ChatTurn(
        kind: TurnKind.regenerate,
        selection: openAi,
        userMessage: user,
      ),
    );
    expect(regen['text'], 'hello');
    expect(regen['parentMessageId'], 'a0');
    expect(regen['overrideParentMessageId'], 'u1');
    expect(regen['isRegenerate'], true);
    expect(regen['quotes'], ['q']);
    expect(regen['files'], hasLength(1));
    expect(regen.containsKey('messageId'), isFalse);
    expect(regen.containsKey('isEdited'), isFalse);
    final editAi = build(
      const ChatTurn(
        kind: TurnKind.editAi,
        selection: openAi,
        userMessage: user,
      ),
    );
    expect(editAi['isEdited'], true);
    expect(editAi['isRegenerate'], true);
  });

  test('continued extends the reply', () {
    final body = build(
      const ChatTurn(
        kind: TurnKind.continued,
        selection: openAi,
        userMessage: user,
        responseMessageId: 'a1',
      ),
    );
    expect(body['text'], 'hello');
    expect(body['overrideParentMessageId'], 'u1');
    expect(body['responseMessageId'], 'a1');
    expect(body['isContinued'], true);
    expect(body['isEdited'], true);
    expect(body['isRegenerate'], true);
    expect(body.containsKey('messageId'), isFalse);
  });

  test('compact sends the leaf and never the regenerate flags', () {
    final body = build(
      const ChatTurn(
        kind: TurnKind.compact,
        selection: openAi,
        parentMessageId: 'leaf',
      ),
    );
    expect(body['text'], '');
    expect(body['parentMessageId'], 'leaf');
    expect(body['messageId'], 'leaf');
    expect(body['compact'], true);
    for (final key in [
      'isRegenerate',
      'isContinued',
      'responseMessageId',
      'overrideParentMessageId',
    ]) {
      expect(body.containsKey(key), isFalse, reason: key);
    }
  });

  test('attach has no start request', () {
    expect(
      () => build(const ChatTurn(kind: TurnKind.attach, selection: openAi)),
      throwsArgumentError,
    );
  });
}
