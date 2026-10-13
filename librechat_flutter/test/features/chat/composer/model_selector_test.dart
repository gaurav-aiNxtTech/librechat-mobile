import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/features/agents/agents_api.dart';
import 'package:librechat_flutter/features/chat/composer/model_selector.dart';
import 'package:librechat_flutter/features/chat/send/chat_turn.dart';

void main() {
  const endpoints = {
    'openAI': EndpointConfig(modelDisplayLabel: 'OpenAI'),
    'anthropic': EndpointConfig(),
    'agents': EndpointConfig(),
  };
  const models = {
    'openAI': ['gpt-4o', 'gpt-4o-mini'],
    'anthropic': ['claude-sonnet'],
    'agents': ['gpt-4o'],
    'google': ['gemini'],
  };
  const agents = [
    Agent(id: 'a1', name: 'Researcher', isPublic: true),
    Agent(id: 'a2', name: 'Writer'),
  ];
  final specs = parseModelSpecs({
    'list': [
      {
        'name': 'fast',
        'label': 'Fast chat',
        'iconURL': 'openAI',
        'preset': {'endpoint': 'openAI', 'model': 'gpt-4o-mini'},
      },
      {
        'name': 'deep',
        'default': true,
        'iconURL': 'https://x.test/deep.png',
        'preset': {'endpoint': 'anthropic', 'model': 'claude-sonnet'},
      },
      {'name': 'no preset'},
      {
        'label': 'no name',
        'preset': {'endpoint': 'openAI'},
      },
    ],
  }, endpoints);
  final data = SelectorData(
    endpoints: endpoints,
    models: models,
    specs: specs,
    agents: agents,
  );

  List<String> keys(List<SelectorGroup> groups) => [
    for (final g in groups) g.key,
  ];
  List<String> labels(SelectorGroup g) => [for (final i in g.items) i.label];

  group('parseModelSpecs', () {
    test('keeps named specs with a preset endpoint', () {
      expect([for (final s in specs) s.name], ['fast', 'deep']);
      expect(specs[0].selection.spec, 'fast');
      expect(specs[0].selection.model, 'gpt-4o-mini');
      expect(specs[0].selection.modelLabel, 'Fast chat');
      expect(specs[1].isDefault, isTrue);
    });

    test('an iconURL naming an endpoint is not an image', () {
      expect(specs[0].iconUrl, isNull);
      expect(specs[1].iconUrl, 'https://x.test/deep.png');
    });
  });

  group('filterSelector', () {
    test('lists specs, agents, then configured endpoints', () {
      final groups = filterSelector(data, '');
      // `agents` is only an agent list, and `google` is not configured.
      expect(keys(groups), ['specs', 'agents', 'openAI', 'anthropic']);
      expect(groups[1].label, 'My Agents');
      expect(groups[2].label, 'OpenAI');
      expect(labels(groups[0]), ['Fast chat', 'deep']);
      expect(groups[1].items.first.selection.agentId, 'a1');
      expect(groups[1].items.first.isPublic, isTrue);
    });

    test('matches labels, models and agent names, ignoring case', () {
      final groups = filterSelector(data, '  MINI ');
      expect(keys(groups), ['specs', 'openAI']);
      expect(labels(groups[1]), ['gpt-4o-mini']);

      expect(labels(filterSelector(data, 'writ').single), ['Writer']);
    });

    test('a section label match keeps the whole section', () {
      final groups = filterSelector(data, 'openai');
      expect(keys(groups), ['openAI']);
      expect(labels(groups.single), ['gpt-4o', 'gpt-4o-mini']);
    });

    test('no match lists nothing', () {
      expect(filterSelector(data, 'zzz'), isEmpty);
    });

    test('favorites come first within their section', () {
      final withFavorites = SelectorData(
        endpoints: endpoints,
        models: models,
        agents: agents,
        favorites: {
          favoriteKey(
            const ChatSelection(endpoint: 'openAI', model: 'gpt-4o-mini'),
          ),
          favoriteKey(const ChatSelection(endpoint: 'agents', agentId: 'a2')),
        },
      );
      final groups = filterSelector(withFavorites, '');
      expect(labels(groups[0]), ['Writer', 'Researcher']);
      expect(labels(groups[1]), ['gpt-4o-mini', 'gpt-4o']);
    });

    test('hides endpoint and model rows when the Server disables them', () {
      final hidden = SelectorData(
        endpoints: endpoints,
        models: models,
        specs: specs,
        agents: agents,
        showEndpoints: false,
      );
      expect(keys(filterSelector(hidden, '')), ['specs', 'agents']);
    });
  });

  group('defaultSelection', () {
    test('prefers the last used spec', () {
      final s = defaultSelection(
        data,
        lastEndpoint: 'openAI',
        lastModel: 'gpt-4o',
        lastSpec: 'fast',
      );
      expect(s?.spec, 'fast');
    });

    test('then the last used endpoint and model', () {
      final s = defaultSelection(
        data,
        lastEndpoint: 'openAI',
        lastModel: 'gpt-4o',
      );
      expect(s, const ChatSelection(endpoint: 'openAI', model: 'gpt-4o'));
    });

    test('the agent id is the last used model on the agents endpoint', () {
      final s = defaultSelection(data, lastEndpoint: 'agents', lastModel: 'a2');
      expect(s?.agentId, 'a2');
      expect(s?.modelLabel, 'Writer');
    });

    test('a removed last choice falls back to the default spec', () {
      final s = defaultSelection(
        data,
        lastEndpoint: 'openAI',
        lastModel: 'gone',
      );
      expect(s?.spec, 'deep');
    });

    test('without a default spec, the first listed choice', () {
      final plain = SelectorData(endpoints: endpoints, models: models);
      expect(
        defaultSelection(plain),
        const ChatSelection(endpoint: 'openAI', model: 'gpt-4o'),
      );
      expect(defaultSelection(const SelectorData()), isNull);
    });

    test('keeps the last choice while its list is still loading', () {
      expect(
        defaultSelection(
          const SelectorData(),
          lastEndpoint: 'anthropic',
          lastModel: 'claude-sonnet',
        ),
        const ChatSelection(endpoint: 'anthropic', model: 'claude-sonnet'),
      );
      expect(
        defaultSelection(
          const SelectorData(agentsLoaded: false),
          lastEndpoint: 'agents',
          lastModel: 'a9',
        ),
        const ChatSelection(endpoint: 'agents', agentId: 'a9'),
      );
    });
  });

  test('selectionLabel names the spec, agent or model', () {
    expect(selectionLabel(specs[0].selection, data), 'Fast chat');
    expect(
      selectionLabel(
        const ChatSelection(endpoint: 'agents', agentId: 'a1'),
        data,
      ),
      'Researcher',
    );
    expect(
      selectionLabel(const ChatSelection(endpoint: 'openAI'), data),
      'OpenAI',
    );
  });
}
