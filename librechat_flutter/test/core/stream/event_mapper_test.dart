// EventMapper (Req 18.3, 18.4, 18.6): every dispatch row and LangGraph row of
// the design tables, the ignored names, bad frames and step attribution.
// Frames follow the KMP SseEventMapperTest wire shapes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/context_usage.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/pending_action.dart';
import 'package:librechat_flutter/core/models/pending_steer.dart';
import 'package:librechat_flutter/core/models/token_usage.dart';
import 'package:librechat_flutter/core/stream/event_mapper.dart';
import 'package:librechat_flutter/core/stream/sse_parser.dart';
import 'package:librechat_flutter/core/stream/stream_events.dart';

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late EventMapper mapper;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('event_mapper_test');
    log = await DiagnosticLog.open(directory: logDir);
    mapper = EventMapper(log: log);
  });

  tearDown(() async {
    await log.file();
    await logDir.delete(recursive: true);
  });

  /// Maps one frame whose data is [json] encoded.
  List<StreamEvent> map(Object? json, {String? event}) =>
      mapper.map(SseEvent(event: event, data: jsonEncode(json)));

  /// Maps a LangGraph `{event, data}` frame.
  List<StreamEvent> lg(String name, Map<String, Object?> data) =>
      map({'event': name, 'data': data});

  Map<String, Object?> runStep(String stepId, String callId, {String? agent}) =>
      {
        'id': stepId,
        'stepDetails': {
          'type': 'tool_calls',
          'tool_calls': [
            {'id': callId, 'name': 'web_search', 'args': '{"query":"kotlin"}'},
          ],
        },
        'agentId': ?agent,
      };

  Map<String, Object?> textDelta(String stepId, String text) => {
    'id': stepId,
    'delta': {
      'content': [
        {'type': 'text', 'text': text},
      ],
    },
  };

  Future<List<String>> badFrames() async =>
      (await log.file()).readAsLinesSync().where((l) {
        return l.contains(' stream bad_frame');
      }).toList();

  group('dispatch rows', () {
    test('1: attachment and librechat:attachment SSE events', () {
      final officeReady = {
        'file_id': 'f1',
        'filename': 'report.docx',
        'filepath': '/files/report.docx',
        'type': 'application/vnd.librechat.docx-preview',
        'toolCallId': 'call_1',
        'messageId': 'm1',
        'status': 'ready',
        'text': '<html><body>hi</body></html>',
        'textFormat': 'html',
      };
      expect(map(officeReady, event: 'attachment'), [
        const AttachmentEvent(
          Attachment(
            fileId: 'f1',
            filename: 'report.docx',
            filepath: '/files/report.docx',
            type: 'application/vnd.librechat.docx-preview',
            toolCallId: 'call_1',
            messageId: 'm1',
            status: 'ready',
            text: '<html><body>hi</body></html>',
            textFormat: 'html',
          ),
        ),
      ]);

      final failed = {
        'file_id': 'f1',
        'filename': 'report.docx',
        'status': 'failed',
        'previewError': 'timeout',
      };
      expect(map(failed, event: 'librechat:attachment'), [
        const AttachmentEvent(
          Attachment(
            fileId: 'f1',
            filename: 'report.docx',
            status: 'failed',
            previewError: 'timeout',
          ),
        ),
      ]);

      final webSearch = {
        'type': 'web_search',
        'toolCallId': 'call_ws',
        'web_search': {
          'turn': 0,
          'organic': [
            {'link': 'https://example.com/a', 'title': 'A'},
          ],
        },
      };
      final [event as AttachmentEvent] = map(webSearch, event: 'attachment');
      expect(event.attachment.type, 'web_search');
      expect(event.attachment.webSearch?['organic'], [
        {'link': 'https://example.com/a', 'title': 'A'},
      ]);
    });

    test('2: sync emits snapshot, pause, steers, then pendingEvents', () {
      final events = map({
        'sync': true,
        'resumeState': {
          'aggregatedContent': [
            {'type': 'text', 'text': 'Let me generate that now'},
            {
              'type': 'tool_call',
              'tool_call': {
                'type': 'tool_call',
                'id': 'call_done',
                'name': 'web_search',
                'args': '{}',
                'output': 'results',
              },
            },
            // Undecodable parts are skipped.
            {'text': 'no type'},
            'not a part',
          ],
          'pendingAction': {
            'actionId': 'act_3',
            'payload': {'type': 'ask_user_question'},
          },
          'pendingSteers': [
            {'steerId': 'st_1', 'text': 'be brief', 'createdAt': 1000},
            {'steerId': 'st_2', 'text': 'in French'},
          ],
        },
        'pendingEvents': [
          {'event': 'on_message_delta', 'data': textDelta('s', ' there')},
          {
            'event': 'on_run_step_completed',
            'data': {
              'result': {
                'id': 's',
                'tool_call': {'id': 'call_pending', 'output': 'http://img/x'},
              },
            },
          },
        ],
      });
      expect(events, [
        const SyncSnapshot([
          ContentPart(type: 'text', text: 'Let me generate that now'),
          ContentPart(
            type: 'tool_call',
            toolCall: ToolCall(
              type: 'tool_call',
              id: 'call_done',
              name: 'web_search',
              args: '{}',
              output: 'results',
            ),
          ),
        ]),
        const PendingActionEvent(
          PendingAction(
            actionId: 'act_3',
            payload: {'type': 'ask_user_question'},
          ),
        ),
        const SteersSynced([
          PendingSteer(steerId: 'st_1', text: 'be brief', createdAt: 1000),
          PendingSteer(steerId: 'st_2', text: 'in French'),
        ]),
        const TextDelta(' there'),
        const ToolCallCompleted(
          toolCallId: 'call_pending',
          output: 'http://img/x',
        ),
      ]);
    });

    test('2: sync without content or steers still emits SteersSynced([])', () {
      expect(
        map({
          'sync': true,
          'resumeState': {
            'pendingAction': {
              'actionId': 'act_4',
              'payload': {'type': 'tool_approval', 'action_requests': []},
            },
          },
        }),
        [
          const PendingActionEvent(
            PendingAction(
              actionId: 'act_4',
              payload: {'type': 'tool_approval', 'action_requests': []},
            ),
          ),
          const SteersSynced([]),
        ],
      );
      expect(map({'sync': true, 'resumeState': <String, Object?>{}}), [
        const SteersSynced([]),
      ]);
      // A blank actionId cannot be resolved, so no card.
      expect(
        map({
          'sync': true,
          'resumeState': {
            'aggregatedContent': [],
            'pendingAction': {'actionId': ' '},
            'pendingSteers': [],
          },
        }),
        [const SyncSnapshot([]), const SteersSynced([])],
      );
    });

    test('3: final with the full payload, aborted flags and steers', () {
      expect(
        map({
          'final': true,
          'conversation': {'conversationId': 'c1', 'title': 'Chat'},
          'requestMessage': {
            'messageId': 'm1',
            'conversationId': 'c1',
            'text': 'Hello',
            'isCreatedByUser': true,
          },
          'responseMessage': {
            'messageId': 'm2',
            'conversationId': 'c1',
            'text': 'Hi there',
          },
          'message': {'messageId': 'ignored', 'conversationId': 'c1'},
          'aborted': true,
          'earlyAbort': true,
          'pendingSteers': [
            {'steerId': 'st_9', 'text': 'never made it'},
          ],
        }),
        [
          const FinalEvent(
            conversation: Conversation(conversationId: 'c1', title: 'Chat'),
            requestMessage: Message(
              messageId: 'm1',
              conversationId: 'c1',
              text: 'Hello',
              isCreatedByUser: true,
            ),
            responseMessage: Message(
              messageId: 'm2',
              conversationId: 'c1',
              text: 'Hi there',
            ),
            aborted: true,
            earlyAbort: true,
            pendingSteers: [
              PendingSteer(steerId: 'st_9', text: 'never made it'),
            ],
          ),
        ],
      );
    });

    test('3: final falls back to message; bad parts become null', () async {
      expect(
        map({
          'final': true,
          'message': {
            'messageId': 'm1',
            'conversationId': 'c1',
            'text': 'Done',
          },
        }),
        [
          const FinalEvent(
            responseMessage: Message(
              messageId: 'm1',
              conversationId: 'c1',
              text: 'Done',
            ),
          ),
        ],
      );
      // Flags are read only when they are booleans; a sub-object that fails
      // to decode is dropped and logged, and the rest survives.
      expect(
        map({
          'final': true,
          'conversation': {'conversationId': 'c1'},
          'responseMessage': {'messageId': 5},
          'aborted': 'true',
          'earlyAbort': 1,
        }),
        [const FinalEvent(conversation: Conversation(conversationId: 'c1'))],
      );
      final [line] = await badFrames();
      expect(line, contains('field=responseMessage'));
    });

    test('4: created as a {message} object or true with a message', () {
      const created = CreatedEvent(
        conversationId: 'c1',
        messageId: 'm1',
        parentMessageId: 'm0',
      );
      final message = {
        'conversationId': 'c1',
        'messageId': 'm1',
        'parentMessageId': 'm0',
      };
      expect(
        map({
          'created': {'message': message},
        }),
        [created],
      );
      expect(map({'created': true, 'message': message}), [created]);
    });

    test('5: error as a string or an object', () {
      expect(map({'error': 'Rate limit exceeded'}), [
        const StreamError('Rate limit exceeded'),
      ]);
      expect(
        map({
          'error': {'message': 'Model not found', 'code': 404},
        }),
        [const StreamError('Model not found')],
      );
      expect(
        map({
          'error': {'code': 500},
        }),
        [const StreamError('{"code":500}')],
      );
    });

    test('rows are checked in design order', () {
      expect(map({'final': true, 'created': true, 'error': 'x'}), [
        const FinalEvent(),
      ]);
      expect(map({'created': true, 'error': 'x'}), [const CreatedEvent()]);
      expect(map({'error': 'x', 'event': 'title', 'data': {}}), [
        const StreamError('x'),
      ]);
    });

    test('7: legacy flat frames', () {
      expect(map({'type': 'content', 'text': 'Legacy text'}), [
        const TextDelta('Legacy text'),
      ]);
      expect(map({'type': 'text', 'text': 'more'}), [const TextDelta('more')]);
      expect(
        map({
          'type': 'thinking',
          'text': 'Hmm...',
          'metadata': {'agentId': 'a1'},
        }),
        [const ThinkDelta('Hmm...', agentId: 'a1')],
      );
      expect(map({'type': 'think', 'text': 'so'}), [const ThinkDelta('so')]);
      expect(
        map({
          'type': 'tool_call_start',
          'toolCallId': 'tc1',
          'toolName': 'calculator',
          'input': '2+2',
        }),
        [const ToolCallStarted(id: 'tc1', name: 'calculator', args: '2+2')],
      );
      expect(
        map({
          'type': 'tool_call_complete',
          'toolCallId': 'tc1',
          'output': {'value': 4},
        }),
        [const ToolCallCompleted(toolCallId: 'tc1', output: '{"value":4}')],
      );
      expect(map({'text': 'Fallback content'}), [
        const TextDelta('Fallback content'),
      ]);
      expect(map({'type': 'other', 'response': 'Response text'}), [
        const TextDelta('Response text'),
      ]);
      expect(map({'type': 'other', 'value': 1}), isEmpty);
      expect(map({'type': 'tool_call_start'}), isEmpty);
    });
  });

  group('LangGraph rows', () {
    test('on_message_delta joins the text parts', () {
      expect(
        lg('on_message_delta', {
          'id': 'step_1',
          'delta': {
            'content': [
              {'type': 'text', 'text': 'Hello '},
              {'type': 'image_url', 'url': 'http://x.com'},
              {'type': 'text', 'text': 'world'},
            ],
          },
        }),
        [const TextDelta('Hello world')],
      );
    });

    test('on_reasoning_delta joins the think parts', () {
      expect(
        lg('on_reasoning_delta', {
          'id': 'step_1',
          'delta': {
            'content': [
              {'type': 'think', 'think': 'Let me '},
              {'type': 'text', 'text': 'no'},
              {'type': 'think', 'think': 'consider...'},
            ],
          },
        }),
        [const ThinkDelta('Let me consider...')],
      );
    });

    test('on_run_step starts the first tool call', () {
      expect(lg('on_run_step', runStep('step_1', 'call_1', agent: 'agent_1')), [
        const ToolCallStarted(
          id: 'call_1',
          name: 'web_search',
          args: '{"query":"kotlin"}',
          agentId: 'agent_1',
        ),
      ]);
      // A step without a tool call starts nothing but still records the agent.
      expect(
        lg('on_run_step', {
          'id': 'step_2',
          'agentId': 'agent_2',
          'stepDetails': {'type': 'message_creation'},
        }),
        isEmpty,
      );
      expect(lg('on_message_delta', textDelta('step_2', 'hi')), [
        const TextDelta('hi', agentId: 'agent_2'),
      ]);
    });

    test('on_run_step_completed completes result.tool_call', () {
      expect(
        lg('on_run_step_completed', {
          'result': {
            'id': 'step_1',
            'tool_call': {'id': 'call_1', 'name': 'search', 'output': 'Done'},
          },
        }),
        [const ToolCallCompleted(toolCallId: 'call_1', output: 'Done')],
      );
      expect(
        lg('on_run_step_completed', {
          'result': {
            'id': 's',
            'tool_call': {
              'id': 'c1',
              'output': {'url': 'http://img.com/x.png'},
            },
          },
        }),
        [
          const ToolCallCompleted(
            toolCallId: 'c1',
            output: '{"url":"http://img.com/x.png"}',
          ),
        ],
      );
      expect(
        lg('on_run_step_completed', {
          'result': {'id': 's', 'tool_call': <String, Object?>{}},
        }),
        isEmpty,
      );
    });

    test('on_run_step_closed closes the tool call its step announced', () {
      Map<String, Object?> closed(String stepId, {Object? status}) => {
        'id': stepId,
        'index': 0,
        'type': 'tool_calls',
        'status': ?status,
      };
      // A step this mapper never saw is dropped.
      expect(lg('on_run_step_closed', closed('step_1', status: 'x')), isEmpty);
      lg('on_run_step', runStep('step_1', 'call_1', agent: 'agent_1'));
      expect(lg('on_run_step_closed', closed('step_1', status: 'cancelled')), [
        const ToolCallClosed(
          toolCallId: 'call_1',
          status: 'cancelled',
          agentId: 'agent_1',
        ),
      ]);
      expect(lg('on_run_step_closed', closed('step_1')), isEmpty);
      expect(lg('on_run_step_closed', closed('step_1', status: 2)), isEmpty);
    });

    test('on_summarize_complete takes the summary text parts', () {
      expect(
        lg('on_summarize_complete', {
          'id': 's',
          'agentId': 'agent_1',
          'summary': {
            'type': 'summary',
            'content': [
              {'type': 'text', 'text': 'Earlier, '},
              {'type': 'think', 'think': 'skip'},
              {'type': 'text', 'text': 'we planned.'},
            ],
          },
        }),
        [const SummaryEvent('Earlier, we planned.', agentId: 'agent_1')],
      );
      expect(
        lg('on_summarize_complete', {
          'summary': {'content': []},
        }),
        isEmpty,
      );
    });

    test('on_subagent_update needs a phase', () {
      expect(
        lg('on_subagent_update', {
          'runId': 'r1',
          'subagentRunId': 'sr1',
          'parentToolCallId': 'call_42',
          'subagentType': 'researcher',
          'subagentAgentId': 'agent_x',
          'phase': 'message_delta',
          'label': 'Researching',
          'data': textDelta('step_1', 'Found it'),
        }),
        [
          const SubagentUpdate(
            phase: 'message_delta',
            parentToolCallId: 'call_42',
            subagentRunId: 'sr1',
            subagentType: 'researcher',
            label: 'Researching',
          ),
        ],
      );
      expect(lg('on_subagent_update', {'subagentRunId': 'sr1'}), isEmpty);
    });

    test('attachment and title', () {
      expect(
        lg('attachment', {
          'file_id': 'f1',
          'filename': 'image.png',
          'type': 'image/png',
          'width': 800,
          'height': 600,
        }),
        [
          const AttachmentEvent(
            Attachment(
              fileId: 'f1',
              filename: 'image.png',
              type: 'image/png',
              width: 800,
              height: 600,
            ),
          ),
        ],
      );
      expect(lg('title', {'conversationId': 'c1', 'title': 'Trip plans'}), [
        const TitleEvent(conversationId: 'c1', title: 'Trip plans'),
      ]);
      expect(lg('title', {'conversationId': 'c1', 'title': '  '}), isEmpty);
      expect(lg('title', {'conversationId': 'c1'}), isEmpty);
    });

    test('on_token_usage and on_context_usage', () {
      expect(
        lg('on_token_usage', {
          'input_tokens': 30,
          'output_tokens': 8,
          'total_tokens': 38,
          'model': 'claude-haiku-4-5',
          'usage_type': 'activity-label',
        }),
        [
          const TokenUsageEvent(
            TokenUsage(
              inputTokens: 30,
              outputTokens: 8,
              totalTokens: 38,
              model: 'claude-haiku-4-5',
              usageType: 'activity-label',
            ),
          ),
        ],
      );
      expect(
        lg('on_context_usage', {
          'contextBudget': 1000,
          'remainingContextTokens': 600,
          'breakdown': {'messageTokens': 400},
          'agentId': 'agent_1',
        }),
        [
          const ContextUsageEvent(
            ContextUsage(
              contextBudget: 1000,
              remainingContextTokens: 600,
              breakdown: {'messageTokens': 400},
              agentId: 'agent_1',
            ),
          ),
        ],
      );
    });

    test('on_pending_action is dropped without an actionId', () {
      final payload = {
        'type': 'tool_approval',
        'action_requests': [
          {
            'name': 'web_search',
            'tool_call_id': 'call_1',
            'arguments': {'query': 'cats'},
          },
        ],
        'review_configs': [
          {
            'action_name': 'web_search',
            'tool_call_id': 'call_1',
            'allowed_decisions': ['approve', 'reject'],
          },
        ],
      };
      expect(
        lg('on_pending_action', {
          'actionId': 'act_1',
          'streamId': 'conv_1',
          'payload': payload,
        }),
        [
          PendingActionEvent(
            PendingAction(
              actionId: 'act_1',
              streamId: 'conv_1',
              payload: payload,
            ),
          ),
        ],
      );
      expect(lg('on_pending_action', {'payload': payload}), isEmpty);
      expect(lg('on_pending_action', {'actionId': ''}), isEmpty);
    });

    test('on_steer_applied decodes the string steer part', () {
      expect(
        lg('on_steer_applied', {
          'steerId': 'st_1',
          'clientSteerId': 'local-1',
          'index': 3,
          'responseMessageId': 'msg_1',
          'part': {
            'type': 'steer',
            'steer': 'be brief',
            'quotes': ['excerpt a'],
          },
        }),
        [
          const SteerApplied(
            steerId: 'st_1',
            clientSteerId: 'local-1',
            index: 3,
            part: ContentPart(type: 'steer', steer: 'be brief'),
          ),
        ],
      );
      // The ids may ride on the part only.
      expect(
        lg('on_steer_applied', {
          'index': 0,
          'part': {
            'type': 'steer',
            'steer': 'stop',
            'steerId': 'st_2',
            'clientSteerId': 'local-2',
          },
        }),
        [
          const SteerApplied(
            steerId: 'st_2',
            clientSteerId: 'local-2',
            index: 0,
            part: ContentPart(type: 'steer', steer: 'stop'),
          ),
        ],
      );
      expect(
        lg('on_steer_applied', {
          'index': 1,
          'part': {'type': 'steer', 'steer': 'x'},
        }),
        isEmpty,
      );
    });

    test('ignored and unknown names yield nothing', () {
      for (final name in [
        'on_run_step_delta',
        'on_chat_model_end',
        'on_agent_update',
        'on_summarize_start',
        'on_summarize_delta',
        'on_brand_new_event',
      ]) {
        expect(
          lg(name, {
            'id': 'step_1',
            'delta': {'args': 'partial'},
            'text': 'not a delta',
          }),
          isEmpty,
          reason: name,
        );
      }
    });
  });

  group('empty and bad frames', () {
    test('blank data, [DONE] and empty deltas yield nothing', () async {
      expect(mapper.map(const SseEvent(data: '')), isEmpty);
      expect(mapper.map(const SseEvent(data: '  \n ')), isEmpty);
      expect(mapper.map(const SseEvent(data: '[DONE]')), isEmpty);
      expect(lg('on_message_delta', textDelta('s', '')), isEmpty);
      expect(
        lg('on_reasoning_delta', {
          'delta': {'content': []},
        }),
        isEmpty,
      );
      expect(map({'type': 'content', 'text': ''}), isEmpty);
      expect(await badFrames(), isEmpty);
    });

    test('bad frames are logged and skipped', () async {
      final good = SseEvent(
        data: jsonEncode({
          'event': 'on_message_delta',
          'data': textDelta('s', 'ok'),
        }),
      );
      final bad = [
        const SseEvent(data: 'not json at all'),
        const SseEvent(data: '[1, 2]'),
        SseEvent(
          data: jsonEncode({
            'event': 'on_token_usage',
            'data': {'input_tokens': '12'},
          }),
        ),
        SseEvent(
          event: 'attachment',
          data: jsonEncode({'file_id': 'f1', 'filename': 42}),
        ),
      ];
      for (final frame in bad) {
        expect(mapper.map(frame), isEmpty, reason: frame.toString());
        expect(mapper.map(good), [const TextDelta('ok')]);
      }
      final lines = await badFrames();
      expect(lines, hasLength(bad.length));
      expect(lines.first, contains('event=null'));
      expect(lines.first, contains('length=15'));
      expect(lines.last, contains('event=attachment'));
      for (final line in lines) {
        expect(line, isNot(contains('not json')));
      }
    });

    test(
      'a number a model cannot hold skips the frame or sub-object',
      () async {
        // 1e400 decodes to Infinity, whose toInt() throws UnsupportedError.
        final good = SseEvent(
          data: jsonEncode({
            'event': 'on_message_delta',
            'data': textDelta('s', 'ok'),
          }),
        );
        final bad = [
          const SseEvent(
            data: '{"event":"on_token_usage","data":{"input_tokens":1e400}}',
          ),
          const SseEvent(
            data:
                '{"event":"on_context_usage","data":{"contextBudget":-1e400}}',
          ),
          // A part decoded outside _decode: the whole frame goes.
          const SseEvent(
            data:
                '{"event":"on_steer_applied","data":{"steerId":"st_1",'
                '"part":{"type":"text","text":"x","stepIndex":1e400}}}',
          ),
        ];
        for (final frame in bad) {
          expect(mapper.map(frame), isEmpty, reason: frame.data);
          expect(mapper.map(good), [const TextDelta('ok')]);
        }
        // A bad sub-object of a Final_Frame is dropped and the rest survives.
        expect(
          mapper.map(
            const SseEvent(
              data:
                  '{"final":true,"conversation":{"conversationId":"c1",'
                  '"maxTokens":1e400},"responseMessage":{"messageId":"m1",'
                  '"conversationId":"c1"}}',
            ),
          ),
          [
            const FinalEvent(
              responseMessage: Message(messageId: 'm1', conversationId: 'c1'),
            ),
          ],
        );
        final lines = await badFrames();
        expect(lines, hasLength(bad.length + 1));
        expect(lines.last, contains('field=conversation'));
        for (final line in lines) {
          expect(line, isNot(contains('1e400')));
        }
      },
    );

    test('a bad pending event does not drop the sync frame', () {
      expect(
        map({
          'sync': true,
          'resumeState': {
            'aggregatedContent': [
              {'type': 'text', 'text': 'hi'},
            ],
          },
          'pendingEvents': [
            {
              'event': 'on_steer_applied',
              'data': {
                'steerId': 'st_1',
                'part': {'steer': 'no type'},
              },
            },
            'not an event',
            {'event': 'on_message_delta', 'data': textDelta('s', '!')},
          ],
        }),
        [
          const SyncSnapshot([ContentPart(type: 'text', text: 'hi')]),
          const SteersSynced([]),
          const TextDelta('!'),
        ],
      );
    });
  });

  group('step attribution', () {
    test('interleaved steps keep their own agents', () {
      lg('on_run_step', runStep('s1', 'c1', agent: 'agentA'));
      lg('on_run_step', runStep('s2', 'c2', agent: 'agentB'));

      expect(
        [
          ...lg('on_message_delta', textDelta('s1', 'sky')),
          ...lg('on_message_delta', textDelta('s2', 'blue')),
          ...lg('on_message_delta', textDelta('s1', ' is')),
          ...lg('on_reasoning_delta', {
            'id': 's2',
            'delta': {
              'content': [
                {'type': 'think', 'think': 'hmm'},
              ],
            },
          }),
          // A completion names its step through result.id.
          ...lg('on_run_step_completed', {
            'result': {
              'id': 's1',
              'tool_call': {'id': 'c1', 'output': 'done'},
            },
          }),
          // An unknown step falls back to the last announced agent.
          ...lg('on_message_delta', textDelta('s9', 'orphan')),
          // An explicit agentId wins over the step map.
          ...lg('on_message_delta', {
            ...textDelta('s1', 'handoff'),
            'metadata': {'agentId': 'agentC'},
          }),
          // The closure resolves its tool call and agent through the step.
          ...lg('on_run_step_closed', {'id': 's1', 'status': 'completed'}),
          ...map({'type': 'content', 'text': 'legacy'}),
        ],
        [
          const TextDelta('sky', agentId: 'agentA'),
          const TextDelta('blue', agentId: 'agentB'),
          const TextDelta(' is', agentId: 'agentA'),
          const ThinkDelta('hmm', agentId: 'agentB'),
          const ToolCallCompleted(
            toolCallId: 'c1',
            output: 'done',
            agentId: 'agentA',
          ),
          const TextDelta('orphan', agentId: 'agentB'),
          const TextDelta('handoff', agentId: 'agentC'),
          const ToolCallClosed(
            toolCallId: 'c1',
            status: 'completed',
            agentId: 'agentA',
          ),
          const TextDelta('legacy', agentId: 'agentB'),
        ],
      );
    });

    test('state survives a reconnect on the same mapper', () {
      lg('on_run_step', runStep('s1', 'c1', agent: 'agentA'));
      lg('on_run_step', runStep('s2', 'c2', agent: 'agentB'));
      lg('on_message_delta', textDelta('s1', 'before'));

      // The resumed connection opens with a Sync_Frame, then live frames.
      expect(
        map({
          'sync': true,
          'resumeState': {
            'aggregatedContent': [
              {'type': 'text', 'text': 'before'},
            ],
          },
          'pendingEvents': [
            {'event': 'on_message_delta', 'data': textDelta('s1', ' after')},
          ],
        }),
        [
          const SyncSnapshot([ContentPart(type: 'text', text: 'before')]),
          const SteersSynced([]),
          const TextDelta(' after', agentId: 'agentA'),
        ],
      );
      expect(lg('on_message_delta', textDelta('s2', 'live')), [
        const TextDelta('live', agentId: 'agentB'),
      ]);
      expect(lg('on_run_step_closed', {'id': 's2', 'status': 'completed'}), [
        const ToolCallClosed(
          toolCallId: 'c2',
          status: 'completed',
          agentId: 'agentB',
        ),
      ]);
    });
  });
}
