// splitPanes and id parsing (Task 23.6).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/features/chat/comparison/panes.dart';

ContentPart part(String text, [String? agentId]) =>
    ContentPart(type: ContentPartType.text, text: text, agentId: agentId);

List<String?> texts(List<ContentPart> parts) => [for (final p in parts) p.text];

void main() {
  group('splitPanes', () {
    test('keeps the input order in each pane', () {
      final (primary, secondary) = splitPanes([
        part('p1', 'agent_abc'),
        part('s1', 'agent_abc____1'),
        part('p2'),
        part('s2', 'openAI__gpt-4o___GPT-4o____1'),
        part('p3', 'agent_abc'),
      ]);
      expect(texts(primary), ['p1', 'p2', 'p3']);
      expect(texts(secondary), ['s1', 's2']);
    });

    test('only a ____N suffix is secondary', () {
      final (primary, secondary) = splitPanes([
        part('unattributed'),
        part('saved', 'agent_abc'),
        part('non-digit', 'agent____x'),
        part('not at the end', 'a____1b'),
        part('suffixed', 'agent_abc____1'),
      ]);
      expect(texts(primary), [
        'unattributed',
        'saved',
        'non-digit',
        'not at the end',
      ]);
      expect(texts(secondary), ['suffixed']);
    });

    test('empty input gives two empty panes', () {
      final (primary, secondary) = splitPanes(const []);
      expect(primary, isEmpty);
      expect(secondary, isEmpty);
    });
  });

  group('secondaryAgentId', () {
    test('finds the first secondary id', () {
      expect(
        secondaryAgentId([
          part('a', 'agent_abc'),
          part('b', 'agent_x____1'),
          part('c', 'agent_y____2'),
        ]),
        'agent_x____1',
      );
    });

    test('is null without one', () {
      expect(secondaryAgentId([part('a', 'agent_abc'), part('b')]), isNull);
    });
  });

  group('isSecondaryAgentId and stripPaneSuffix', () {
    test('null is not secondary', () {
      expect(isSecondaryAgentId(null), isFalse);
    });

    test('stripPaneSuffix removes only a trailing ____N', () {
      expect(stripPaneSuffix('agent_abc____12'), 'agent_abc');
      expect(stripPaneSuffix('agent_abc'), 'agent_abc');
      expect(stripPaneSuffix('a____1b'), 'a____1b');
    });
  });

  group('parsePaneAgentId', () {
    test('a saved agent is the agents endpoint', () {
      expect(parsePaneAgentId('agent_abc____1'), (
        endpoint: 'agents',
        model: 'agent_abc',
        agentId: 'agent_abc',
        sender: null,
      ));
    });

    test('an ephemeral id with a sender', () {
      expect(parsePaneAgentId('openAI__gpt-4o___GPT-4o____1'), (
        endpoint: 'openAI',
        model: 'gpt-4o',
        agentId: null,
        sender: 'GPT-4o',
      ));
    });

    test('__ in the model is a colon', () {
      final selection = parsePaneAgentId(
        'bedrock__anthropic.claude-3__v1____1',
      );
      expect(selection.endpoint, 'bedrock');
      expect(selection.model, 'anthropic.claude-3:v1');
      expect(selection.sender, isNull);
    });

    test('__ in the sender is a colon', () {
      expect(
        parsePaneAgentId('ollama__llama3___Llama__3____1').sender,
        'Llama:3',
      );
    });

    test('an ephemeral id without a sender', () {
      expect(parsePaneAgentId('ollama__llama3____2'), (
        endpoint: 'ollama',
        model: 'llama3',
        agentId: null,
        sender: null,
      ));
    });

    test('an unparseable ephemeral id falls back to agents', () {
      expect(parsePaneAgentId('weird____1'), (
        endpoint: 'agents',
        model: 'weird',
        agentId: 'weird',
        sender: null,
      ));
      expect(parsePaneAgentId('__model____1').endpoint, 'agents');
    });
  });
}
