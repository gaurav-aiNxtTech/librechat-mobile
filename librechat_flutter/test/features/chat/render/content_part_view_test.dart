// The part table and activity groups as MessageView renders them
// (Req 23.1, 23.9-23.12, 23.14).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/render/content_part_view.dart';
import 'package:librechat_flutter/features/chat/render/message_view.dart';

import '../../../support/fakes.dart';

ContentPart _tool(String id, {String? output = 'ok'}) => ContentPart(
  type: ContentPartType.toolCall,
  toolCall: ToolCall(id: id, name: 'tool_$id', output: output),
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<ContentPart> parts, {
    bool justSettled = false,
    bool grouping = true,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformActionsProvider.overrideWithValue(FakePlatformActions()),
        settingsProvider.overrideWith(FakeSettingsStore.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MessageView(
              Message(messageId: 'm', conversationId: 'c', content: parts),
              justSettled: justSettled,
              grouping: grouping,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('each part type renders its widget (Req 23.9)', (tester) async {
    await pump(tester, [
      const ContentPart(type: ContentPartType.text, text: 'Plain answer'),
      const ContentPart(type: ContentPartType.think, think: 'Pondering'),
      const ContentPart(type: ContentPartType.error, error: 'It broke'),
      const ContentPart(type: ContentPartType.summary, content: 'Earlier'),
      const ContentPart(
        type: ContentPartType.agentUpdate,
        agentId: '2',
        agentUpdate: {'agentId': 'planner'},
      ),
      const ContentPart(type: ContentPartType.steer, steer: 'Shorter please'),
      _tool('1'),
    ]);
    expect(find.text('Plain answer', findRichText: true), findsOneWidget);
    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('Pondering', findRichText: true), findsNothing);
    expect(find.text('It broke'), findsOneWidget);
    expect(find.text('Summarized earlier messages'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Agent handoff from planner to Agent 2'),
      findsOneWidget,
    );
    expect(find.text('sent while replying'), findsOneWidget);
    expect(find.text('Shorter please', findRichText: true), findsOneWidget);
    expect(find.text('tool_1'), findsOneWidget);

    await tester.tap(find.text('Thinking'));
    await tester.pumpAndSettle();
    expect(find.text('Pondering', findRichText: true), findsOneWidget);
  });

  testWidgets('an unknown part type is skipped (Req 23.14)', (tester) async {
    await pump(tester, [
      const ContentPart(type: 'text', text: 'Before'),
      const ContentPart(type: 'hologram', text: 'Not shown'),
      const ContentPart(type: 'text', text: 'After'),
    ]);
    expect(find.text('Before', findRichText: true), findsOneWidget);
    expect(find.text('After', findRichText: true), findsOneWidget);
    expect(find.text('Not shown', findRichText: true), findsNothing);
  });

  testWidgets('consecutive tool calls fold into a collapsed group', (
    tester,
  ) async {
    await pump(tester, [_tool('a'), _tool('b')]);
    expect(find.byType(ActivityGroupView), findsOneWidget);
    expect(find.text('Used 2 tools'), findsOneWidget);
    expect(find.text('tool_a'), findsNothing);

    await tester.tap(find.text('Used 2 tools'));
    await tester.pumpAndSettle();
    expect(find.text('tool_a'), findsOneWidget);
    expect(find.text('tool_b'), findsOneWidget);
  });

  testWidgets('the reply that just settled keeps its group open', (
    tester,
  ) async {
    await pump(tester, [_tool('a'), _tool('b')], justSettled: true);
    expect(find.text('tool_a'), findsOneWidget);
  });

  testWidgets('a filled activity label titles its group', (tester) async {
    await pump(tester, [
      const ContentPart(type: ContentPartType.think, think: 'Plan'),
      _tool('a'),
      const ContentPart(
        type: ContentPartType.activityLabel,
        activityLabel: 'Checked the weather',
      ),
      const ContentPart(type: ContentPartType.text, text: 'Sunny'),
    ]);
    expect(find.text('Checked the weather'), findsOneWidget);
    expect(find.text('Thinking'), findsNothing);
    expect(find.text('Sunny', findRichText: true), findsOneWidget);
  });

  testWidgets('with grouping off every part renders on its own', (
    tester,
  ) async {
    await pump(tester, [_tool('a'), _tool('b')], grouping: false);
    expect(find.byType(ActivityGroupView), findsNothing);
    expect(find.text('tool_a'), findsOneWidget);
    expect(find.text('tool_b'), findsOneWidget);
  });

  test('summaryText reads a string or the text blocks', () {
    expect(
      summaryText(const ContentPart(type: 'summary', content: 'Plain')),
      'Plain',
    );
    expect(
      summaryText(
        const ContentPart(
          type: 'summary',
          content: [
            {'type': 'text', 'text': 'A'},
            {'type': 'image', 'text': 'skip'},
            {'type': 'text', 'text': 'B'},
          ],
        ),
      ),
      'AB',
    );
    expect(summaryText(const ContentPart(type: 'summary', text: 'T')), 'T');
  });
}
