// Fixture round trips for the core models (Req 4.7). Each fixture in `fixtures/` follows a
// LibreChat v0.8.8 response and carries unknown fields and, where the model has an enum, an
// unknown enum value. To cover another model, add a `_Fixture` to `_fixtures`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/role_permissions.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/models/user.dart';

/// One fixture file and how to decode, encode and check it.
class _Fixture<T> {
  const _Fixture(
    this.file, {
    required this.decode,
    required this.encode,
    required this.unknownKeys,
    required this.check,
    this.unknownEnums,
  });

  /// File name under `test/core/models/fixtures/`.
  final String file;
  final T Function(Object? json) decode;
  final Object? Function(T value) encode;

  /// Keys the model does not know. Each must appear in the fixture and nowhere in the encoding,
  /// so they must not collide with a modeled key or a key inside a raw (`Object?`) payload.
  final List<String> unknownKeys;

  /// Enum values that the fixture sets to a value the App does not know.
  final List<Enum?> Function(T value)? unknownEnums;

  /// Key field expectations.
  final void Function(T value) check;

  void register() {
    group(file, () {
      late Object? raw;
      late T decoded;

      setUpAll(() {
        raw = jsonDecode(
          File('test/core/models/fixtures/$file').readAsStringSync(),
        );
        decoded = decode(raw);
      });

      test('decodes key fields', () => check(decoded));

      test('ignores unknown fields', () {
        final encoded = _wire(encode(decoded));
        for (final key in unknownKeys) {
          expect(
            _hasKey(raw, key),
            isTrue,
            reason: 'the fixture should carry "$key"',
          );
          expect(
            _hasKey(encoded, key),
            isFalse,
            reason: '"$key" should not be modeled',
          );
        }
      });

      if (unknownEnums != null) {
        test('decodes unknown enum values to unknown', () {
          final values = unknownEnums!(decoded);
          expect(values, isNotEmpty);
          for (final value in values) {
            expect(value?.name, 'unknown');
          }
        });
      }

      test('fromJson(toJson(decoded)) == decoded', () {
        final encoded = _wire(encode(decoded));
        final again = decode(encoded);
        expect(again, decoded);
        expect(
          _wire(encode(again)),
          encoded,
          reason: 're-encoding should be stable',
        );
      });
    });
  }
}

/// Sends a value through JSON text, as the wire and the Cache do.
Object? _wire(Object? json) => jsonDecode(jsonEncode(json));

bool _hasKey(Object? json, String key) => switch (json) {
  Map() => json.containsKey(key) || json.values.any((v) => _hasKey(v, key)),
  List() => json.any((v) => _hasKey(v, key)),
  _ => false,
};

Map<String, Object?> _map(Object? json) => json as Map<String, Object?>;

final _fixtures = <_Fixture<dynamic>>[
  _Fixture<StartupConfig>(
    'startup_config.json',
    decode: (json) => StartupConfig.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const [
      'serverDomain',
      'showBirthdayIcon',
      'instanceProjectId',
      'bundlerURL',
      'startBalance',
      'branch',
      'externalUrl',
      'sidePanel',
      'autoSubmitFromUrl',
    ],
    check: (config) {
      expect(config.appTitle, 'Acme Chat');
      expect(config.socialLogins, ['openid', 'github', 'google']);
      expect(config.openidLoginEnabled, isTrue);
      expect(config.openidLabel, 'Acme SSO');
      expect(config.githubLoginEnabled, isTrue);
      expect(config.registrationEnabled, isTrue);
      expect(config.minPasswordLength, 8);
      expect(config.ldap?.enabled, isFalse);
      expect(config.balance?.enabled, isTrue);
      expect(config.conversationImportMaxFileSize, 262144000);
      expect(config.modelSpecs?['enforce'], isFalse);
      expect(
        config.buildInfo?.commit,
        '361553f3322d7b9bb547d0a9c2c5aaefc2934901',
      );
      expect(config.compactionEnabled, isTrue);
      expect(config.version, isNull);

      final ui = config.interfaceConfig;
      expect(ui.customWelcome, 'Welcome to Acme Chat');
      expect(ui.termsOfService?.modalAcceptance, isTrue);
      expect(ui.termsOfService?.modalContent, [
        'Be kind.',
        'Do not share secrets.',
      ]);
      expect(ui.presets, isFalse);
      expect(ui.multiConvo, isFalse);
      expect(ui.contextUsage, isTrue, reason: 'an absent flag is on');
      expect(ui.prompts, {
        'use': true,
        'create': true,
        'share': false,
        'public': false,
      });
      expect(ui.sharedLinks, isTrue);
      expect(ui.traceViewer, {'enabled': false});
      expect(ui.marketplace, {'use': false});
    },
  ),
  _Fixture<Map<String, EndpointConfig>>(
    'endpoints.json',
    decode: (json) => _map(
      json,
    ).map((name, e) => MapEntry(name, EndpointConfig.fromJson(_map(e)))),
    encode: (value) => value.map((name, e) => MapEntry(name, e.toJson())),
    unknownKeys: const ['disableBuilder', 'customParams'],
    check: (endpoints) {
      expect(endpoints.keys.toList(), [
        'openAI',
        'anthropic',
        'agents',
        'OpenRouter',
      ]);
      expect(endpoints['openAI']?.modelDisplayLabel, 'ChatGPT');
      expect(endpoints['anthropic']?.userProvide, isTrue);
      expect(endpoints['agents']?.order, 1);
      expect(endpoints['agents']?.capabilities, contains('execute_code'));
      expect(endpoints['OpenRouter']?.type, 'custom');
      expect(endpoints['OpenRouter']?.iconURL, 'openrouter');
      expect(endpoints['OpenRouter']?.capabilities, isNull);
    },
  ),
  _Fixture<RolePermissions>(
    'role_permissions.json',
    decode: (json) => RolePermissions.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const ['_id', '__v', 'description'],
    check: (role) {
      expect(role.name, 'USER');
      expect(role.permissions?['AGENTS'], {
        'USE': true,
        'CREATE': false,
        'SHARE': false,
        'SHARE_PUBLIC': false,
      });
      expect(role.permissions?['MARKETPLACE']?['USE'], isFalse);
      expect(role.permissions?['SCHEDULES']?['CREATE'], isTrue);
      expect(role.permissions?['FUTURE_FEATURE'], {
        'USE': true,
      }, reason: 'types are open keys');
    },
  ),
  _Fixture<User>(
    'user.json',
    decode: (json) => User.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const [
      'emailVerified',
      'plugins',
      'favorites',
      'createdAt',
      '__v',
    ],
    check: (user) {
      expect(user.id, '6650f1c2a8b3c4d5e6f70001');
      expect(user.name, 'Ada Lovelace');
      expect(user.username, 'ada');
      expect(user.email, 'ada@example.com');
      expect(user.role, 'USER');
      expect(user.provider, 'local');
      expect(user.twoFactorEnabled, isTrue);
      expect(user.termsAccepted, isTrue);
      expect(user.personalization?.memories, isFalse);
    },
  ),
  _Fixture<Conversation>(
    'conversation.json',
    decode: (json) => Conversation.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const [
      '_id',
      'user',
      '__v',
      'expiredAt',
      'files',
      'imageDetail',
      'messages',
      'resendFiles',
    ],
    check: (convo) {
      expect(convo.conversationId, '3f1c9a52-6a7e-4c1b-9d8e-2b4f6a8c0d1e');
      expect(convo.title, 'Planning a trip to Lisbon');
      expect(convo.endpoint, 'agents');
      expect(convo.agentId, 'agent_Xk3mPq9rT2vW');
      expect(convo.spec, 'fast-chat');
      expect(convo.iconURL, isNull);
      expect(convo.tags, ['work', 'research']);
      expect(convo.isArchived, isFalse);
      expect(convo.pinned, isNull);
      expect(convo.temperature, 1.0);
      expect(convo.topP, 0.95);
      expect(convo.topK, 40);
      expect(convo.presencePenalty, 0.5);
      expect(convo.maxContextTokens, 200000);
      expect(convo.reasoningEffort, 'high');
      expect(convo.stop, ['\n\nHuman:']);
      expect(convo.webSearch, isTrue);
      expect(convo.createdAt, DateTime.utc(2026, 9, 20, 14, 3, 10, 4));
      expect(convo.updatedAt?.isUtc, isTrue);
    },
  ),
  _Fixture<Message>(
    'message.json',
    decode: (json) => Message.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const [
      '_id',
      '__v',
      'user',
      'tokenCount',
      'iconURL',
      'expiredAt',
      'stepId',
      'annotations',
      'payloadFromTheFuture',
      'embedded',
    ],
    unknownEnums: (message) => [message.feedback?.rating],
    check: (message) {
      expect(message.messageId, '8e9f0a1b-2c3d-4e5f-9a0b-1c2d3e4f5a6b');
      expect(message.parentMessageId, '5b7d1e2a-0c3f-4e5a-8b9c-1d2e3f4a5b6c');
      expect(message.sender, 'Research helper');
      expect(message.text, '');
      expect(message.isCreatedByUser, isFalse);
      expect(message.createdAt, DateTime.utc(2026, 9, 20, 14, 3, 11, 482));
      expect(message.feedback?.tag, {
        'key': 'accurate_reliable',
        'label': 'Accurate and reliable',
      });
      expect(message.feedback?.text, 'Good sources.');

      final parts = message.content!;
      expect(parts.map((p) => p.type), [
        ContentPartType.think,
        ContentPartType.text,
        ContentPartType.toolCall,
        ContentPartType.text,
        'brand_new_part',
      ]);
      expect(
        parts[0].think,
        'The user wants walking routes. I should search first.',
      );
      expect(parts[1].text, 'Let me look that up.');
      expect(parts[1].toolCallIds, ['toolu_01AbCdEfGhIjKlMn']);
      final call = parts[2].toolCall!;
      expect(call.id, 'toolu_01AbCdEfGhIjKlMn');
      expect(call.name, 'web_search');
      expect(call.args, '{"query":"best walking routes Lisbon"}');
      expect(call.output, 'Found 5 results.');
      expect(call.progress, 1.0);
      expect(parts[2].agentId, 'agent_Xk3mPq9rT2vW');
      expect(parts[2].stepIndex, 2);
      expect(
        parts[3].text,
        'Alfama and Belém are the two classic walks.',
        reason: 'the {value, annotations} form reads as its value',
      );
      expect(parts[4].text, isNull);

      final attachment = message.attachments!.single;
      expect(attachment.type, 'web_search');
      expect(attachment.toolCallId, 'toolu_01AbCdEfGhIjKlMn');
      expect(
        (attachment.webSearch?['organic'] as List).single,
        containsPair('title', 'Walking in Lisbon'),
      );
      expect(
        message.files!.single.fileId,
        'a7c3e9f1-2b4d-4f6a-8c0e-1d3f5a7b9c2e',
      );
      expect(message.files!.single.width, 1600);
    },
  ),
  _Fixture<Attachment>(
    'attachment.json',
    decode: (json) => Attachment.fromJson(_map(json)),
    encode: (value) => value.toJson(),
    unknownKeys: const [
      '_id',
      'user',
      'conversationId',
      'embedded',
      'object',
      'usage',
      'context',
      'source',
      '__v',
    ],
    check: (file) {
      expect(file.fileId, 'a7c3e9f1-2b4d-4f6a-8c0e-1d3f5a7b9c2e');
      expect(file.filename, 'lisbon-map.png');
      expect(file.filepath, endsWith('__lisbon-map.png'));
      expect(file.type, 'image/png');
      expect(file.bytes, 482113);
      expect(file.width, 1600);
      expect(file.height, 1200);
      expect(file.messageId, '5b7d1e2a-0c3f-4e5a-8b9c-1d2e3f4a5b6c');
      expect(file.toolCallId, isNull);
    },
  ),
];

void main() {
  for (final fixture in _fixtures) {
    fixture.register();
  }
}
