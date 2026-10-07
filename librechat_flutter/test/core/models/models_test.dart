import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/role_permissions.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';

Map<String, Object?> _decode(String json) => jsonDecode(json) as Map<String, Object?>;

const _configJson = '''
{
  "appTitle": "Acme Chat",
  "socialLogins": ["openid", "github"],
  "openidLoginEnabled": true,
  "openidLabel": "Acme SSO",
  "githubLoginEnabled": true,
  "emailLoginEnabled": true,
  "registrationEnabled": false,
  "passwordResetEnabled": true,
  "serverDomain": "https://chat.example.com",
  "ldap": {"enabled": true, "username": true},
  "minPasswordLength": 10,
  "sharedLinksEnabled": true,
  "balance": {"enabled": true, "startBalance": 20000},
  "conversationImportMaxFileSize": 262144000,
  "modelSpecs": {"enforce": false, "list": [{"name": "gpt", "label": "GPT"}]},
  "buildInfo": {"commit": "abc1234def", "branch": "main"},
  "compactionEnabled": true,
  "someFutureField": {"nested": [1, 2]},
  "interface": {
    "customWelcome": "Hi",
    "termsOfService": {"modalAcceptance": true, "modalTitle": "Terms", "modalContent": ["a", "b"]},
    "presets": false,
    "prompts": {"use": false},
    "agents": true,
    "schedules": {},
    "traceViewer": {"enabled": true},
    "unknownFlag": true
  }
}
''';

const _messageJson = '''
{
  "messageId": "m2",
  "conversationId": "c1",
  "parentMessageId": "m1",
  "sender": "Agent",
  "text": "",
  "isCreatedByUser": false,
  "unfinished": false,
  "createdAt": "2025-03-01T10:20:30.123Z",
  "futureField": 7,
  "feedback": {"rating": "thumbsSideways", "tag": {"key": "accurate"}, "text": "ok"},
  "attachments": [{"file_id": "f1", "filename": "a.png", "type": "image/png", "toolCallId": "t1",
                   "web_search": {"organic": []}, "unknownKey": 1}],
  "content": [
    {"type": "think", "think": "Let me check."},
    {"type": "tool_call", "tool_call": {"id": "t1", "name": "web_search", "type": "tool_call",
      "args": "{\\"query\\":\\"x\\"}", "output": "done", "progress": 1, "extra": true}},
    {"type": "text", "text": "Answer"},
    {"type": "text", "text": {"value": "Edited", "annotations": []}},
    {"type": "brand_new_part", "whatever": [1]}
  ]
}
''';

void main() {
  test('decodes a representative /api/config', () {
    final config = StartupConfig.fromJson(_decode(_configJson));

    expect(config.appTitle, 'Acme Chat');
    expect(config.socialLogins, ['openid', 'github']);
    expect(config.openidLoginEnabled, isTrue);
    expect(config.openidLabel, 'Acme SSO');
    expect(config.ldap?.username, isTrue);
    expect(config.minPasswordLength, 10);
    expect(config.balance?.enabled, isTrue);
    expect(config.buildInfo?.commit, 'abc1234def');
    expect(config.compactionEnabled, isTrue);
    expect(config.version, isNull);
    expect(config.modelSpecs?['list'], [
      {'name': 'gpt', 'label': 'GPT'},
    ]);

    final ui = config.interfaceConfig;
    expect(ui.customWelcome, 'Hi');
    expect(ui.termsOfService?.modalAcceptance, isTrue);
    expect(ui.termsOfService?.modalContent, ['a', 'b']);
    expect(ui.presets, isFalse);
    expect(ui.bookmarks, isTrue, reason: 'an absent flag is on');
    expect(ui.prompts, {'use': false});
    expect(ui.agents, true);
    expect(ui.schedules, <String, Object?>{});
    expect(ui.traceViewer, {'enabled': true});
  });

  test('a config without interface or flags uses the Server defaults', () {
    final config = StartupConfig.fromJson({});
    expect(config.appTitle, 'LibreChat');
    expect(config.emailLoginEnabled, isTrue);
    expect(config.interfaceConfig.presets, isTrue);
    expect(config.compactionEnabled, isNull);
  });

  test('decodes a message with think, tool_call and text parts', () {
    final message = Message.fromJson(_decode(_messageJson));

    expect(message.messageId, 'm2');
    expect(message.parentMessageId, 'm1');
    expect(message.createdAt, DateTime.utc(2025, 3, 1, 10, 20, 30, 123));
    expect(message.createdAt!.isUtc, isTrue);

    final parts = message.content!;
    expect(parts.map((p) => p.type), [
      ContentPartType.think,
      ContentPartType.toolCall,
      ContentPartType.text,
      ContentPartType.text,
      'brand_new_part',
    ]);
    expect(parts[0].think, 'Let me check.');
    final call = parts[1].toolCall!;
    expect(call.id, 't1');
    expect(call.name, 'web_search');
    expect(call.args, '{"query":"x"}');
    expect(call.output, 'done');
    expect(call.progress, 1.0);
    expect(parts[2].text, 'Answer');
    expect(parts[3].text, 'Edited', reason: 'the {value, annotations} form reads as its value');

    expect(message.attachments!.single.toolCallId, 't1');
    expect(message.attachments!.single.webSearch, {'organic': <Object?>[]});
  });

  test('an unknown enum value decodes to unknown', () {
    final message = Message.fromJson(_decode(_messageJson));
    expect(message.feedback?.rating, FeedbackRating.unknown);
    expect(message.feedback?.tag, {'key': 'accurate'});
    expect(
      MessageFeedback.fromJson({'rating': 'thumbsUp'}).rating,
      FeedbackRating.thumbsUp,
    );
  });

  test('toJson omits unset fields and writes text parts as strings', () {
    const part = ContentPart(type: ContentPartType.text, text: 'Hi');
    expect(part.toJson(), {'type': 'text', 'text': 'Hi'});

    final message = Message.fromJson(_decode(_messageJson));
    final json = jsonDecode(jsonEncode(message.toJson())) as Map<String, Object?>;
    expect(json.containsKey('endpoint'), isFalse);
    expect(json['createdAt'], '2025-03-01T10:20:30.123Z');
    expect((json['content'] as List)[3], {'type': 'text', 'text': 'Edited'});
  });

  test('decodes user, conversation, endpoint and role responses', () {
    final user = User.fromJson({
      '_id': 'u1',
      'id': 'u1',
      'email': 'a@example.com',
      'role': 'ADMIN',
      'twoFactorEnabled': true,
      'personalization': {'memories': false},
      'password': 'never-modeled',
    });
    expect(user.id, 'u1');
    expect(user.twoFactorEnabled, isTrue);
    expect(user.personalization?.memories, isFalse);
    expect(User.fromJson({'id': 'u2'}).id, 'u2');
    expect(user.toJson()['_id'], 'u1');

    final convo = Conversation.fromJson({
      'conversationId': 'c1',
      'title': 'Trip',
      'agent_id': 'agent_1',
      'top_p': 1,
      'tags': ['work'],
      'updatedAt': 'not a date',
    });
    expect(convo.agentId, 'agent_1');
    expect(convo.topP, 1.0);
    expect(convo.isArchived, isFalse);
    expect(convo.updatedAt, isNull, reason: 'an unparseable timestamp does not fail decoding');

    final endpoint = EndpointConfig.fromJson({
      'type': 'custom',
      'order': 2,
      'capabilities': ['tools'],
      'disableBuilder': false,
    });
    expect(endpoint.order, 2);
    expect(endpoint.capabilities, ['tools']);

    final role = RolePermissions.fromJson({
      'name': 'USER',
      'permissions': {
        'AGENTS': {'USE': true, 'CREATE': false},
      },
    });
    expect(role.permissions?['AGENTS']?['CREATE'], isFalse);
  });
}
