import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../log/diagnostic_log.dart';
import '../models/attachment.dart';
import '../models/content_part.dart';
import '../models/context_usage.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/pending_action.dart';
import '../models/pending_steer.dart';
import '../models/token_usage.dart';
import 'sse_parser.dart';
import 'stream_events.dart';

/// Turns the Server's SSE frames into [StreamEvent]s (Req 18.3, 18.4, 18.6).
///
/// Use one instance per Run and keep it across reconnects: the step
/// attribution state (which agent and tool call each run step belongs to)
/// must survive a resume, because the deltas after it name only their step.
///
/// A frame that is not a JSON object, or whose payload fails to decode, is
/// logged as `stream bad_frame` (the SSE event name and the data length,
/// never the data) and yields nothing, so one bad frame never ends a Run.
class EventMapper {
  EventMapper({this._log});

  final DiagnosticLog? _log;

  /// Run step id → the agent that announced it.
  final Map<String, String> _stepAgent = {};

  /// Run step id → the tool call it announced, for `on_run_step_closed`,
  /// which names only the step.
  final Map<String, String> _stepToolCall = {};

  /// The agent of the last `on_run_step` that named one, for events whose
  /// step was never announced.
  String? _lastAgentId;

  /// The events [event] carries, in order. Most frames carry one; a
  /// Sync_Frame expands into its snapshot and buffered events.
  List<StreamEvent> map(SseEvent event) {
    final data = event.data.trim();
    if (data.isEmpty || data == '[DONE]') return const [];
    return _guard(event, () {
      final root = _obj(jsonDecode(data));
      if (root == null) {
        _badFrame(event);
        return const [];
      }
      // Row 1: the attachment rides as the raw data of a named SSE event.
      if (event.event == 'attachment' ||
          event.event == 'librechat:attachment') {
        return _attachment(event, root);
      }
      // Row 2.
      if (root['sync'] == true) return _sync(event, root);
      return _mapObject(event, root);
    });
  }

  /// Runs [body], turning a decode failure into a logged, empty result.
  List<StreamEvent> _guard(SseEvent event, List<StreamEvent> Function() body) {
    try {
      return body();
    } catch (error) {
      if (!_isDecodeError(error)) rethrow;
      _badFrame(event);
    }
    return const [];
  }

  void _badFrame(SseEvent event, [String? field]) {
    _log?.info('stream', 'bad_frame', {
      'event': event.event,
      'length': event.data.length,
      'field': ?field,
    });
  }

  /// Decodes [json] with [fromJson], or logs [field] and returns null when it
  /// is not an object or does not decode. Null stays null without a log.
  T? _decode<T>(
    SseEvent event,
    String field,
    Object? json,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (json == null) return null;
    final map = _obj(json);
    if (map != null) {
      try {
        return fromJson(map);
      } catch (error) {
        if (!_isDecodeError(error)) rethrow;
        // Logged below.
      }
    }
    _badFrame(event, field);
    return null;
  }

  /// Rows 3–7, shared by live frames and a Sync_Frame's `pendingEvents`.
  List<StreamEvent> _mapObject(SseEvent event, Map<String, Object?> root) {
    if (root['final'] == true) return [_final(event, root)];
    if (root.containsKey('created')) return [_created(root)];
    final error = root['error'];
    if (error != null) return [StreamEvent.streamError(_errorText(error))];
    final name = root['event'];
    final data = _obj(root['data']);
    if (name is String && data != null) return _langGraph(event, name, data);
    return _legacy(root);
  }

  List<StreamEvent> _sync(SseEvent event, Map<String, Object?> root) {
    final resume = _obj(root['resumeState']);
    final out = <StreamEvent>[];
    final content = _list(resume?['aggregatedContent']);
    if (content != null) {
      out.add(
        StreamEvent.syncSnapshot([
          for (final part in content)
            ?_decode(event, 'aggregatedContent', part, ContentPart.fromJson),
        ]),
      );
    }
    final action = _pendingAction(event, resume?['pendingAction']);
    if (action != null) out.add(action);
    // The Server omits an empty queue, so absent means none: always emit,
    // so steers injected while the App was away are dropped.
    out.add(StreamEvent.steersSynced(_steers(event, resume?['pendingSteers'])));
    for (final pending in _list(root['pendingEvents']) ?? const <Object?>[]) {
      final obj = _obj(pending);
      if (obj == null) continue;
      out.addAll(_guard(event, () => _mapObject(event, obj)));
    }
    return out;
  }

  StreamEvent _final(SseEvent event, Map<String, Object?> root) {
    return StreamEvent.finalFrame(
      conversation: _decode(
        event,
        'conversation',
        root['conversation'],
        Conversation.fromJson,
      ),
      requestMessage: _decode(
        event,
        'requestMessage',
        root['requestMessage'],
        Message.fromJson,
      ),
      responseMessage:
          _decode(
            event,
            'responseMessage',
            root['responseMessage'],
            Message.fromJson,
          ) ??
          _decode(event, 'message', root['message'], Message.fromJson),
      aborted: root['aborted'] == true,
      earlyAbort: root['earlyAbort'] == true,
      pendingSteers: _steers(event, root['pendingSteers']),
    );
  }

  StreamEvent _created(Map<String, Object?> root) {
    final created = root['created'];
    // `{created: {message}}`, or `{created: true, message}`.
    final message = created is Map
        ? _obj(created['message'])
        : _obj(root['message']);
    return StreamEvent.created(
      conversationId: _str(message?['conversationId']),
      messageId: _str(message?['messageId']),
      parentMessageId: _str(message?['parentMessageId']),
    );
  }

  String _errorText(Object error) => switch (error) {
    String() => error,
    {'message': final String message} => message,
    _ => jsonEncode(error),
  };

  List<PendingSteer> _steers(SseEvent event, Object? json) => [
    for (final steer in _list(json) ?? const <Object?>[])
      ?_decode(event, 'pendingSteers', steer, PendingSteer.fromJson),
  ];

  /// A [PendingActionEvent], or null without a non-blank `actionId`: the
  /// resume route rejects an action it cannot name.
  StreamEvent? _pendingAction(SseEvent event, Object? json) {
    final action = _decode(
      event,
      'pendingAction',
      json,
      PendingAction.fromJson,
    );
    final id = action?.actionId;
    if (action == null || id == null || id.trim().isEmpty) return null;
    return StreamEvent.pendingAction(action);
  }

  List<StreamEvent> _attachment(SseEvent event, Map<String, Object?> data) {
    final attachment = _decode(event, 'attachment', data, Attachment.fromJson);
    if (attachment == null) return const [];
    return [
      StreamEvent.attachment(
        attachment,
        text: _str(data['text']),
        textFormat: _str(data['textFormat']),
      ),
    ];
  }

  List<StreamEvent> _langGraph(
    SseEvent event,
    String name,
    Map<String, Object?> data,
  ) {
    final own =
        _str(data['agentId']) ?? _str(_obj(data['metadata'])?['agentId']);
    final stepId = _str(data['id']);
    if (name == 'on_run_step' && own != null) {
      if (stepId != null) _stepAgent[stepId] = own;
      _lastAgentId = own;
    }
    String? agentId() =>
        own ??
        _stepAgent[stepId] ??
        _stepAgent[_str(_obj(data['result'])?['id'])] ??
        _lastAgentId;

    switch (name) {
      case 'on_message_delta':
        final text = _joined(_deltaParts(data), 'text', 'text');
        if (text.isEmpty) return const [];
        return [StreamEvent.textDelta(text, agentId: agentId())];
      case 'on_reasoning_delta':
        final think = _joined(_deltaParts(data), 'think', 'think');
        if (think.isEmpty) return const [];
        return [StreamEvent.thinkDelta(think, agentId: agentId())];
      case 'on_run_step':
        final calls = _list(_obj(data['stepDetails'])?['tool_calls']);
        final call = calls == null || calls.isEmpty ? null : _obj(calls.first);
        final id = _str(call?['id']);
        if (call == null || id == null) return const [];
        if (stepId != null) _stepToolCall[stepId] = id;
        return [
          StreamEvent.toolCallStarted(
            id: id,
            name: _str(call['name']),
            args: call['args'],
            agentId: agentId(),
          ),
        ];
      case 'on_run_step_completed':
        final call = _obj(_obj(data['result'])?['tool_call']);
        final id = _str(call?['id']);
        if (call == null || id == null) return const [];
        return [
          StreamEvent.toolCallCompleted(
            toolCallId: id,
            output: _stringOrJson(call['output']),
            agentId: agentId(),
          ),
        ];
      case 'on_run_step_closed':
        // A step announced before a reconnect point, or with no tool call,
        // is not in the map, and its closure has nothing to close.
        final toolCallId = _stepToolCall[stepId];
        final status = _str(data['status']);
        if (toolCallId == null || status == null) return const [];
        return [
          StreamEvent.toolCallClosed(
            toolCallId: toolCallId,
            status: status,
            agentId: agentId(),
          ),
        ];
      case 'on_summarize_complete':
        final parts = _list(_obj(data['summary'])?['content']);
        final text = _joined(parts, 'text', 'text');
        if (text.isEmpty) return const [];
        return [StreamEvent.summary(text, agentId: agentId())];
      case 'on_subagent_update':
        final phase = _str(data['phase']);
        if (phase == null) return const [];
        return [
          StreamEvent.subagentUpdate(
            phase: phase,
            parentToolCallId: _str(data['parentToolCallId']),
            subagentRunId: _str(data['subagentRunId']),
            subagentType: _str(data['subagentType']),
            label: _str(data['label']),
          ),
        ];
      case 'attachment':
        return _attachment(event, data);
      case 'title':
        final title = _str(data['title']);
        if (title == null || title.trim().isEmpty) return const [];
        return [
          StreamEvent.title(
            conversationId: _str(data['conversationId']),
            title: title,
          ),
        ];
      case 'on_token_usage':
        final usage = _decode(event, 'data', data, TokenUsage.fromJson);
        return [?_wrap(usage, StreamEvent.tokenUsage)];
      case 'on_context_usage':
        final usage = _decode(event, 'data', data, ContextUsage.fromJson);
        return [?_wrap(usage, StreamEvent.contextUsage)];
      case 'on_pending_action':
        return [?_pendingAction(event, data)];
      case 'on_steer_applied':
        final part = _obj(data['part']);
        final steerId = _str(data['steerId']) ?? _str(part?['steerId']);
        // The id is the only link to the chip this event retires.
        if (steerId == null || steerId.trim().isEmpty) return const [];
        return [
          StreamEvent.steerApplied(
            steerId: steerId,
            clientSteerId:
                _str(data['clientSteerId']) ?? _str(part?['clientSteerId']),
            index: _int(data['index']),
            part: part == null ? null : ContentPart.fromJson(part),
          ),
        ];
      // on_run_step_delta, on_chat_model_end, on_agent_update,
      // on_summarize_start, on_summarize_delta and unknown names carry
      // nothing the App renders (Req 18.6).
      default:
        return const [];
    }
  }

  /// Row 7: the legacy flat `{type, …}` frames.
  List<StreamEvent> _legacy(Map<String, Object?> root) {
    final agentId = _str(_obj(root['metadata'])?['agentId']) ?? _lastAgentId;
    switch (_str(root['type'])) {
      case 'content' || 'text':
        final text = _str(root['text']);
        if (text == null || text.isEmpty) return const [];
        return [StreamEvent.textDelta(text, agentId: agentId)];
      case 'thinking' || 'think':
        final think = _str(root['text']);
        if (think == null || think.isEmpty) return const [];
        return [StreamEvent.thinkDelta(think, agentId: agentId)];
      case 'tool_call_start':
        final id = _str(root['toolCallId']);
        if (id == null) return const [];
        return [
          StreamEvent.toolCallStarted(
            id: id,
            name: _str(root['toolName']),
            args: root['input'],
            agentId: agentId,
          ),
        ];
      case 'tool_call_complete':
        final id = _str(root['toolCallId']);
        if (id == null) return const [];
        return [
          StreamEvent.toolCallCompleted(
            toolCallId: id,
            output: _stringOrJson(root['output']),
            agentId: agentId,
          ),
        ];
      default:
        final text = _str(root['text']) ?? _str(root['response']);
        if (text == null || text.isEmpty) return const [];
        return [StreamEvent.textDelta(text, agentId: agentId)];
    }
  }
}

/// Whether [error] is a frame's JSON failing to decode: a wrong shape or
/// type, or a number a model field cannot hold (`1e400` decodes to Infinity,
/// whose `toInt()` throws [UnsupportedError]).
bool _isDecodeError(Object error) =>
    error is FormatException ||
    error is TypeError ||
    error is CheckedFromJsonException ||
    error is UnsupportedError ||
    error is ArgumentError;

StreamEvent? _wrap<T>(T? value, StreamEvent Function(T value) wrap) =>
    value == null ? null : wrap(value);

List<Object?>? _deltaParts(Map<String, Object?> data) =>
    _list(_obj(data['delta'])?['content']);

/// Joins the string [field] of each part in [parts] whose `type` is [type].
String _joined(List<Object?>? parts, String type, String field) {
  final out = StringBuffer();
  for (final part in parts ?? const <Object?>[]) {
    final map = _obj(part);
    final value = map?[field];
    if (map?['type'] == type && value is String) out.write(value);
  }
  return out.toString();
}

/// A tool output as text: a string as is, anything else JSON-encoded.
String? _stringOrJson(Object? value) => switch (value) {
  null => null,
  String() => value,
  _ => jsonEncode(value),
};

// Readers that return null for a wrong type, so a malformed field never
// throws past its frame.
String? _str(Object? value) => value is String ? value : null;

int? _int(Object? value) => value is int ? value : null;

Map<String, Object?>? _obj(Object? value) =>
    value is Map<String, Object?> ? value : null;

List<Object?>? _list(Object? value) => value is List ? value : null;
