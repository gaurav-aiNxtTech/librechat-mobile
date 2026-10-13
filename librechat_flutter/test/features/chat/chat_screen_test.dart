import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/features/chat/chat_screen.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/render/endpoint_icon.dart';

import '../../support/fakes.dart';

/// What the landing's Composer reads besides the settings and config.
List<Override> composerOverrides() => [
  messagesRepositoryProvider.overrideWithValue(FakeMessagesRepository()),
  authServiceProvider.overrideWith((ref) => FakeAuthService()),
  onlineProvider.overrideWith((ref) => Stream.value(true)),
  missingFeaturesProvider.overrideWithValue(ValueNotifier(const {})),
];

void main() {
  group('timeGreeting', () {
    test('weekday boundaries', () {
      final wednesday = DateTime(2026, 10, 7);
      expect(wednesday.weekday, DateTime.wednesday);
      String at(int hour, int minute) =>
          timeGreeting(wednesday.add(Duration(hours: hour, minutes: minute)));
      expect(at(0, 0), 'Happy late night');
      expect(at(4, 59), 'Happy late night');
      expect(at(5, 0), 'Good early morning');
      expect(at(8, 59), 'Good early morning');
      expect(at(9, 0), 'Good morning');
      expect(at(11, 59), 'Good morning');
      expect(at(12, 0), 'Good afternoon');
      expect(at(16, 59), 'Good afternoon');
      expect(at(17, 0), 'Good evening');
      expect(at(23, 0), 'Good evening');
    });

    test('weekend boundaries on Saturday and Sunday', () {
      for (final day in [DateTime(2026, 10, 10), DateTime(2026, 10, 11)]) {
        expect(day.weekday, anyOf(DateTime.saturday, DateTime.sunday));
        String at(int hour, int minute) =>
            timeGreeting(day.add(Duration(hours: hour, minutes: minute)));
        expect(at(4, 59), 'Happy late night');
        expect(at(5, 0), 'Happy weekend morning');
        expect(at(11, 59), 'Happy weekend morning');
        expect(at(12, 0), 'Happy weekend afternoon');
        expect(at(16, 59), 'Happy weekend afternoon');
        expect(at(17, 0), 'Happy weekend evening');
        expect(at(23, 0), 'Happy weekend evening');
      }
    });
  });

  Future<void> pump(WidgetTester tester, {String? customWelcome}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...composerOverrides(),
          settingsProvider.overrideWith(FakeSettingsStore.new),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(
              ServerInfo(
                config: StartupConfig(
                  interfaceConfig: InterfaceConfig(
                    customWelcome: customWelcome,
                  ),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the custom welcome when the Server sets one', (
    tester,
  ) async {
    await pump(tester, customWelcome: '  Welcome to Acme  ');
    expect(find.text('Welcome to Acme'), findsOneWidget);
    expect(find.text('How can I help you today?'), findsNothing);
  });

  for (final (name, welcome) in [('unset', null), ('blank', '   ')]) {
    testWidgets('falls back to the default prompt when $name', (tester) async {
      await pump(tester, customWelcome: welcome);
      expect(find.text('How can I help you today?'), findsOneWidget);
    });
  }

  testWidgets('the greeting is a header and the icon is labeled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    final greeting = find.text(timeGreeting(DateTime.now()));
    expect(greeting, findsOneWidget);
    expect(
      tester.getSemantics(greeting).getSemanticsData().flagsCollection.isHeader,
      isTrue,
    );
    expect(find.bySemanticsLabel('Switchboard'), findsOneWidget);
    handle.dispose();
  });

  landingIconTests();
}

void landingIconTests() {
  testWidgets('the landing shows the last endpoint\'s icon and model', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...composerOverrides(),
          serverConfigProvider.overrideWith(
            () => FakeServerConfig(const ServerInfo(config: StartupConfig())),
          ),
          settingsProvider.overrideWith(
            () => FakeSettingsStore(
              const AppSettings(
                lastEndpoint: 'anthropic',
                lastModel: 'claude-sonnet',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    // Under the greeting and on the Composer's model chip.
    expect(find.text('claude-sonnet'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Switchboard'), findsNothing);
  });

  test('endpointIconAsset maps the bundled brands only', () {
    expect(endpointIconAsset('openAI'), 'assets/icons/providers/openai.svg');
    expect(
      endpointIconAsset('azureAssistants'),
      'assets/icons/providers/azure.svg',
    );
    expect(endpointIconAsset('Ollama'), isNull);
    expect(endpointIconAsset(null), isNull);
  });
}
