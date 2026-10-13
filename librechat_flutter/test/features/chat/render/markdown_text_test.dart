// MarkdownText links (Req 22.7) and MessageView sizing (Req 22.9).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/render/markdown_text.dart';
import 'package:librechat_flutter/features/chat/render/message_view.dart';

import '../../../support/fakes.dart';

void main() {
  group('externalLinkTarget', () {
    test('opens web links with a host, mailto and tel', () {
      for (final url in [
        'https://example.com/a?b=1',
        'http://example.com',
        'mailto:someone@example.com',
        'tel:+15550100',
      ]) {
        expect(externalLinkTarget(url), Uri.parse(url), reason: url);
      }
    });

    test('ignores other schemes and relative links', () {
      for (final url in [
        'javascript:alert(1)',
        'intent://x#Intent;end',
        'file:///etc/hosts',
        'data:text/html,hi',
        '/relative/path',
        'https://',
        '',
      ]) {
        expect(externalLinkTarget(url), isNull, reason: url);
      }
    });
  });

  test('chatFontScale follows the KMP multipliers', () {
    expect(chatFontScale(ChatFontSize.small), 0.85);
    expect(chatFontScale(ChatFontSize.medium), 1.0);
    expect(chatFontScale(ChatFontSize.large), 1.2);
  });

  test('displayParts falls back to the text as one part', () {
    const plain = Message(messageId: 'a', conversationId: 'c', text: 'hi');
    expect(displayParts(plain).single.text, 'hi');
    const parts = [ContentPart(type: 'text', text: 'from parts')];
    expect(displayParts(plain.copyWith(content: parts)), parts);
  });

  testWidgets('a link tap opens the external browser', (tester) async {
    final platform = FakePlatformActions();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformActionsProvider.overrideWithValue(platform)],
        child: const MaterialApp(
          home: Scaffold(
            body: MarkdownText(
              'See [the docs](https://example.com/docs) and '
              '[this](javascript:alert(1)).',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('the docs', findRichText: true));
    await tester.tap(find.text('this', findRichText: true));
    await tester.pumpAndSettle();
    expect(platform.opened, [Uri.parse('https://example.com/docs')]);
  });

  testWidgets('MessageView sizes text by chatFontSize', (tester) async {
    Future<double> size(ChatFontSize fontSize) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            settingsProvider.overrideWith(
              () => FakeSettingsStore(AppSettings(chatFontSize: fontSize)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MessageView(
                Message(messageId: 'a', conversationId: 'c', text: 'Hello'),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.text('Hello', findRichText: true)).height;
    }

    final small = await size(ChatFontSize.small);
    final large = await size(ChatFontSize.large);
    expect(large, greaterThan(small));
  });
}
