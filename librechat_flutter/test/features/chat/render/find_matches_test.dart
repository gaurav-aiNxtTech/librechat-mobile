// The in-conversation search's pure helpers and its state (Task 21.3,
// Req 25.11): `searchablePartText`, `matchRanges`, `findMatches` and the
// query, count and wrap of `ChatSearchController`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/features/chat/render/find_matches.dart';

ContentPart _part(String type, {String? text, String? think, Object? steer}) =>
    ContentPart(type: type, text: text, think: think, steer: steer);

ContentPart _label(String label, {String? type}) => ContentPart(
  type: ContentPartType.activityLabel,
  activityLabel: label,
  activityLabelType: type,
);

Message _message(String id, {String text = '', List<ContentPart>? content}) =>
    Message(messageId: id, conversationId: 'c1', text: text, content: content);

void main() {
  group('searchablePartText', () {
    test('reads the text, reasoning, steer and activity label', () {
      expect(
        searchablePartText(_part(ContentPartType.text, text: 'answer')),
        'answer',
      );
      expect(
        searchablePartText(_part(ContentPartType.textDelta, text: 'partial')),
        'partial',
      );
      expect(
        searchablePartText(_part(ContentPartType.think, think: 'reasoning')),
        'reasoning',
      );
      expect(
        searchablePartText(_part(ContentPartType.steer, steer: 'steered')),
        'steered',
      );
      expect(
        searchablePartText(_label('Searched the web')),
        'Searched the web',
      );
    });

    test('a steer the Server did not send as a string reads as nothing', () {
      expect(
        searchablePartText(
          _part(ContentPartType.steer, steer: const {'text': 'steered'}),
        ),
        isNull,
      );
    });

    test('tool calls, errors, summaries and media are not searched', () {
      final parts = [
        ContentPart(
          type: ContentPartType.toolCall,
          toolCall: const ToolCall(
            id: 't1',
            name: 'search',
            args: 'needle',
            output: 'needle',
          ),
        ),
        ContentPart(type: ContentPartType.error, error: 'needle'),
        ContentPart(type: ContentPartType.summary, content: 'needle'),
        ContentPart(type: ContentPartType.imageUrl, imageUrl: 'needle.png'),
        ContentPart(type: ContentPartType.videoUrl, videoUrl: 'needle.mp4'),
        const ContentPart(type: 'something_new', text: 'needle'),
      ];
      for (final part in parts) {
        expect(searchablePartText(part), isNull, reason: part.type);
      }
    });
  });

  group('matchRanges', () {
    test('finds every case-insensitive match in order', () {
      expect(matchRanges('Plan the PLAN, plan', 'plan'), [
        (start: 0, end: 4),
        (start: 9, end: 13),
        (start: 15, end: 19),
      ]);
    });

    test('the offsets address the original text', () {
      // The match is found through the original characters, so the range
      // can be cut out of the text as it stands.
      const text = 'Trip to LISBON soon';
      final range = matchRanges(text, 'lisbon').single;
      expect(text.substring(range.start, range.end), 'LISBON');
    });

    test('matches do not overlap', () {
      expect(matchRanges('aaaa', 'aa'), [
        (start: 0, end: 2),
        (start: 2, end: 4),
      ]);
    });

    test('the query is literal, not a pattern', () {
      expect(matchRanges('abc', 'a.c'), isEmpty);
      expect(matchRanges('a.c', 'a.c'), [(start: 0, end: 3)]);
      expect(matchRanges(r'cost is $5 (net)', r'$5 ('), [(start: 8, end: 12)]);
    });

    test('a blank query or text matches nothing', () {
      expect(matchRanges('plan', ''), isEmpty);
      expect(matchRanges('', 'plan'), isEmpty);
    });
  });

  group('findMatches', () {
    test('a blank query matches nothing', () {
      final path = [_message('m1', text: 'plan')];
      expect(findMatches(path, ''), isEmpty);
      expect(findMatches(path, '   '), isEmpty);
      expect(findMatches(const [], 'plan'), isEmpty);
    });

    test('the query is trimmed', () {
      final hits = findMatches([_message('m1', text: 'the plan')], '  plan ');
      expect(hits, [(messageId: 'm1', partIndex: 0, offset: 4)]);
    });

    test('a message with no content is searched through its own text, as '
        'part 0', () {
      final hits = findMatches([
        _message('u1', text: 'Plan a trip, plan it well'),
      ], 'plan');
      expect(hits, [
        (messageId: 'u1', partIndex: 0, offset: 0),
        (messageId: 'u1', partIndex: 0, offset: 13),
      ]);
    });

    test('walks the path in render order, across messages and parts', () {
      final path = [
        _message('u1', text: 'Plan a trip'),
        _message(
          'a1',
          content: [
            _part(ContentPartType.think, think: 'the plan needs flights'),
            _part(ContentPartType.text, text: 'Here is the plan'),
          ],
        ),
        _message('u2', text: 'thanks'),
      ];
      expect(findMatches(path, 'plan'), [
        (messageId: 'u1', partIndex: 0, offset: 0),
        (messageId: 'a1', partIndex: 0, offset: 4),
        (messageId: 'a1', partIndex: 1, offset: 12),
      ]);
    });

    test('a part index names a part that is on screen, so a skipped phase '
        'label does not shift it', () {
      final path = [
        _message(
          'a1',
          content: [
            _part(ContentPartType.text, text: 'plan one'),
            // Never rendered, so never searched.
            _label('plan phase', type: 'phase'),
            _part(ContentPartType.text, text: 'plan two'),
          ],
        ),
      ];
      expect(findMatches(path, 'plan'), [
        (messageId: 'a1', partIndex: 0, offset: 0),
        (messageId: 'a1', partIndex: 2, offset: 0),
      ]);
    });

    test('an activity label on screen is searched', () {
      final path = [
        _message(
          'a1',
          content: [
            _label('Searched for the plan'),
            _part(ContentPartType.text, text: 'Done'),
          ],
        ),
      ];
      expect(findMatches(path, 'plan'), [
        (messageId: 'a1', partIndex: 0, offset: 17),
      ]);
    });

    test('a message whose content holds no searchable text matches '
        'nothing', () {
      final path = [
        _message(
          'a1',
          text: 'plan',
          content: [
            ContentPart(
              type: ContentPartType.toolCall,
              toolCall: const ToolCall(id: 't1', name: 'plan', output: 'plan'),
            ),
            _part(ContentPartType.text, text: ''),
          ],
        ),
      ];
      expect(findMatches(path, 'plan'), isEmpty);
    });
  });

  group('ChatSearchController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    ChatSearchController controller() =>
        container.read(chatSearchProvider('c1').notifier);
    ChatSearch state() => container.read(chatSearchProvider('c1'));

    test('starts closed and empty', () {
      expect(state(), const ChatSearch());
      expect(state().active, isFalse);
    });

    test('open shows the field, close clears the query', () {
      controller().open();
      expect(state().active, isTrue);

      controller().setQuery('plan');
      controller().close();
      expect(state(), const ChatSearch());
    });

    test('a new query starts again at the first match', () {
      controller()
        ..setQuery('plan')
        ..next(3);
      expect(state().index, 1);

      controller().setQuery('plans');
      expect(state(), const ChatSearch(active: true, query: 'plans'));
    });

    test('next and previous wrap through the matches', () {
      final search = controller()..setQuery('plan');
      expect(state().index, 0);

      search.next(3);
      expect(state().index, 1);
      search.next(3);
      expect(state().index, 2);
      search.next(3);
      expect(state().index, 0, reason: 'wraps at the end');

      search.previous(3);
      expect(state().index, 2, reason: 'wraps at the start');
      search.previous(3);
      expect(state().index, 1);
    });

    test('with no match neither control moves', () {
      final search = controller()..setQuery('plan');
      search.next(0);
      search.previous(0);
      expect(state().index, 0);
    });
  });
}
