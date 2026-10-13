import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/features/chat/chat_screen.dart';
import 'package:librechat_flutter/features/chat/composer/composer_controller.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/run/run_service.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';

import '../../../support/fakes.dart';

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late FakeChatApi chatApi;
  late FakeMessagesRepository messages;
  late FakeSettingsStore settings;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('composer_bar_test');
    log = await DiagnosticLog.open(directory: logDir);
    chatApi = FakeChatApi();
    messages = FakeMessagesRepository();
    settings = FakeSettingsStore(
      const AppSettings(lastEndpoint: 'openAI', lastModel: 'gpt-4o'),
    );
  });

  tearDown(() async {
    await log.file();
    await logDir.delete(recursive: true);
  });

  /// Shows the Chat_Screen: the landing state, or [conversationId]'s
  /// conversation. A second call replaces the tree, which disposes the
  /// Composer the first one opened, as leaving the screen does.
  Future<void> pump(
    WidgetTester tester, {
    ServerInfo info = const ServerInfo(config: StartupConfig()),
    String? conversationId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authServiceProvider.overrideWith((ref) => FakeAuthService()),
          diagnosticLogProvider.overrideWithValue(log),
          chatApiProvider.overrideWithValue(chatApi),
          streamClientProvider.overrideWithValue(FakeStreamClient()),
          messagesRepositoryProvider.overrideWithValue(messages),
          conversationsRepositoryProvider.overrideWithValue(
            FakeConversationsRepository(),
          ),
          deviceTimeZoneProvider.overrideWith((ref) async => 'UTC'),
          onlineProvider.overrideWith((ref) => Stream.value(true)),
          settingsProvider.overrideWith(() => settings),
          serverConfigProvider.overrideWith(() => FakeServerConfig(info)),
          missingFeaturesProvider.overrideWithValue(ValueNotifier(const {})),
        ],
        child: MaterialApp(home: ChatScreen(conversationId: conversationId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  IconButton button(WidgetTester tester, String tooltip) => tester
      .widget<IconButton>(find.widgetWithIcon(IconButton, _icons[tooltip]!));

  bool fieldFocused(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  String text(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).controller.text;

  testWidgets('Send stays disabled for blank text', (tester) async {
    await pump(tester);
    expect(button(tester, 'Send message').onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(button(tester, 'Send message').onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Hi');
    await tester.pump();
    expect(button(tester, 'Send message').onPressed, isNotNull);
  });

  testWidgets('a send shows the message, the waiting indicator and Stop, '
      'which is disabled while the Stop is pending', (tester) async {
    chatApi.startGate = Completer<void>();
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Hello there', findRichText: true), findsOneWidget);
    expect(find.text('Waiting for response…'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsNothing);
    expect(button(tester, 'Stop generation').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Stop generation'));
    await tester.pumpAndSettle();
    expect(button(tester, 'Stop generation').onPressed, isNull);
  });

  for (final dismiss in [true, false]) {
    testWidgets('with dismiss keyboard on send ${dismiss ? 'on' : 'off'} '
        'a send ${dismiss ? 'closes' : 'keeps'} the keyboard', (tester) async {
      settings = FakeSettingsStore(
        AppSettings(
          lastEndpoint: 'openAI',
          lastModel: 'gpt-4o',
          dismissKeyboardOnSend: dismiss,
        ),
      );
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.pump();
      expect(fieldFocused(tester), isTrue);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(fieldFocused(tester), !dismiss);
    });
  }

  testWidgets('leaving a conversation with unsent text keeps it as the '
      'draft, and reopening restores it into the field', (tester) async {
    await pump(tester, conversationId: 'c1');
    await tester.enterText(find.byType(TextField), 'half a thought');
    await tester.pump(
      ComposerController.draftDelay + const Duration(milliseconds: 50),
    );
    expect(messages.drafts['c1'], 'half a thought');

    // The landing state has its own Composer, and no draft of its own.
    await pump(tester);
    expect(text(tester), isEmpty);

    await pump(tester, conversationId: 'c1');
    expect(text(tester), 'half a thought');
    expect(button(tester, 'Send message').onPressed, isNotNull);
  });

  testWidgets('the Model_Selector lists nothing when the Server disables '
      'model selection', (tester) async {
    await pump(
      tester,
      info: const ServerInfo(
        config: StartupConfig(
          interfaceConfig: InterfaceConfig(modelSelect: false),
        ),
        endpoints: {'openAI': EndpointConfig()},
        models: {
          'openAI': ['gpt-4o'],
        },
      ),
    );
    // With every choice hidden there is nothing to select.
    await tester.tap(find.widgetWithText(TextButton, 'Select model'));
    await tester.pumpAndSettle();
    expect(find.text('Select a model'), findsOneWidget);
    expect(find.text('gpt-4o'), findsNothing);
    expect(find.textContaining('openAI'), findsNothing);
  });

  testWidgets('the temporary chat toggle switches on the landing', (
    tester,
  ) async {
    await pump(tester);
    expect(find.bySemanticsLabel('Enable temporary chat'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Enable temporary chat'));
    await tester.pump();
    expect(find.bySemanticsLabel('Disable temporary chat'), findsOneWidget);
  });

  testWidgets('the Model_Selector searches and picks a model', (tester) async {
    await pump(
      tester,
      info: const ServerInfo(
        config: StartupConfig(),
        endpoints: {'openAI': EndpointConfig(), 'anthropic': EndpointConfig()},
        models: {
          'openAI': ['gpt-4o'],
          'anthropic': ['claude-sonnet', 'claude-haiku'],
        },
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, 'gpt-4o'));
    await tester.pumpAndSettle();
    expect(find.text('Select a model'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search models...'),
      'haiku',
    );
    await tester.pumpAndSettle();
    expect(find.text('claude-sonnet'), findsNothing);
    await tester.tap(find.text('claude-haiku'));
    await tester.pumpAndSettle();

    expect(find.text('Select a model'), findsNothing);
    expect(find.widgetWithText(TextButton, 'claude-haiku'), findsOneWidget);
    expect(settings.saved.last.lastModel, 'claude-haiku');
  });
}

const _icons = {
  'Send message': Icons.arrow_upward,
  'Stop generation': Icons.stop,
};
