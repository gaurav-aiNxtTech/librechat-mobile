/// Property testing without a package: `forAll` plus shared generators.
///
/// Every property test calls [forAll] with at least 100 runs. The seed comes
/// from `--dart-define=PROPERTY_SEED=<n>` (fixed by `scripts/ci.sh`) and is
/// random when unset. A failure prints the seed and the failing case, without
/// shrinking, so `flutter test --dart-define=PROPERTY_SEED=<n> <file>` replays
/// it.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/stream/sse_parser.dart';

import 'sse_formatter.dart';

/// The seed from `--dart-define=PROPERTY_SEED`, or a random one when unset.
final int propertySeed = const bool.hasEnvironment('PROPERTY_SEED')
    ? const int.fromEnvironment('PROPERTY_SEED')
    : Random().nextInt(1 << 32);

/// Runs [body] on [runs] values drawn from [gen].
///
/// Each call starts a fresh `Random(seed)`, so a test replays the same cases
/// whatever other tests share the seed. [seed] overrides [propertySeed].
Future<void> forAll<T>(
  Gen<T> gen,
  FutureOr<void> Function(T value) body, {
  int runs = 100,
  int? seed,
}) async {
  assert(runs > 0, 'runs must be positive');
  final usedSeed = seed ?? propertySeed;
  final random = Random(usedSeed);
  for (var run = 1; run <= runs; run++) {
    final value = gen(random);
    try {
      await body(value);
    } catch (error, stackTrace) {
      final message = [
        'Property failed on run $run of $runs with seed $usedSeed.',
        'Failing case: ${describeCase(value)}',
        'Replay: flutter test --dart-define=PROPERTY_SEED=$usedSeed <file>',
        'Error: $error',
      ].join('\n');
      // ignore: avoid_print
      print(message);
      Error.throwWithStackTrace(TestFailure(message), stackTrace);
    }
  }
}

/// Renders a generated case so whitespace and control characters stay visible.
String describeCase(Object? value) => switch (value) {
  String() => jsonEncode(value),
  List() => '[${value.map(describeCase).join(', ')}]',
  Map() =>
    '{${value.entries.map((e) => '${describeCase(e.key)}: ${describeCase(e.value)}').join(', ')}}',
  _ => '$value',
};

/// A generator: a function from a [Random] to a value.
class Gen<T> {
  const Gen(this._generate);

  final T Function(Random random) _generate;

  T call(Random random) => _generate(random);

  Gen<R> map<R>(R Function(T value) f) => Gen((r) => f(_generate(r)));

  Gen<R> flatMap<R>(Gen<R> Function(T value) f) =>
      Gen((r) => f(_generate(r))(r));

  /// Keeps drawing until [test] holds. Prefer constructing valid values.
  Gen<T> where(bool Function(T value) test, {int maxTries = 1000}) => Gen((r) {
    for (var i = 0; i < maxTries; i++) {
      final value = _generate(r);
      if (test(value)) return value;
    }
    throw StateError('Gen.where found no value in $maxTries tries');
  });
}

/// Always [value].
Gen<T> constant<T>(T value) => Gen((_) => value);

/// An int in `[min, max]`, both inclusive.
Gen<int> intRange(int min, int max) {
  assert(min <= max, 'min must not exceed max');
  return Gen((r) => min + _below(r, max - min + 1));
}

/// `true` or `false`, equally likely.
final Gen<bool> boolean = Gen((r) => r.nextBool());

/// One of [values], equally likely.
Gen<T> elementOf<T>(List<T> values) {
  assert(values.isNotEmpty, 'values must not be empty');
  return Gen((r) => values[r.nextInt(values.length)]);
}

/// A value from one of [gens], each equally likely.
Gen<T> oneOf<T>(List<Gen<T>> gens) {
  assert(gens.isNotEmpty, 'gens must not be empty');
  return Gen((r) => gens[r.nextInt(gens.length)](r));
}

/// A value from one of [weighted] gens, picked in proportion to its weight.
Gen<T> frequency<T>(List<(int, Gen<T>)> weighted) {
  final total = weighted.fold(0, (sum, entry) => sum + entry.$1);
  assert(total > 0, 'weights must sum to a positive number');
  return Gen((r) {
    var pick = r.nextInt(total);
    for (final (weight, gen) in weighted) {
      if (pick < weight) return gen(r);
      pick -= weight;
    }
    throw StateError('unreachable');
  });
}

/// A list of [min] to [max] values from [gen].
Gen<List<T>> listOf<T>(Gen<T> gen, {int min = 0, int max = 10}) {
  final length = intRange(min, max);
  return Gen((r) => List.generate(length(r), (_) => gen(r)));
}

/// `null` about one time in [oneIn], otherwise a value from [gen].
Gen<T?> nullable<T>(Gen<T> gen, {int oneIn = 4}) =>
    Gen((r) => r.nextInt(oneIn) == 0 ? null : gen(r));

/// One character (one code point) of [alphabet].
Gen<String> charOf(String alphabet) =>
    elementOf(alphabet.runes.map(String.fromCharCode).toList());

/// A string of [min] to [max] characters drawn from [alphabet].
Gen<String> stringOf(String alphabet, {int min = 0, int max = 20}) =>
    listOf(charOf(alphabet), min: min, max: max).map((chars) => chars.join());

/// A pair of values.
Gen<(A, B)> zip2<A, B>(Gen<A> a, Gen<B> b) => Gen((r) => (a(r), b(r)));

/// A triple of values.
Gen<(A, B, C)> zip3<A, B, C>(Gen<A> a, Gen<B> b, Gen<C> c) =>
    Gen((r) => (a(r), b(r), c(r)));

/// Alphabets for [stringOf] and [charOf].
const lowercase = 'abcdefghijklmnopqrstuvwxyz';
const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const digits = '0123456789';
const alphanumeric = '$lowercase$uppercase$digits';

/// Printable ASCII, space through tilde.
final String asciiPrintable = String.fromCharCodes(
  List.generate(0x7f - 0x20, (i) => 0x20 + i),
);

/// Characters that tend to break parsers: whitespace, line breaks, quotes,
/// non-ASCII letters, an emoji outside the BMP and a zero-width joiner.
const tricky = ' \t\r\n"\'\\:;=,/?#&%éßж中😀\u200d';

/// `Random.nextInt` takes at most 2^32, so wider ranges draw two halves.
int _below(Random r, int bound) {
  if (bound <= 1 << 32) return r.nextInt(bound);
  final wide = (r.nextInt(1 << 32) << 32) | r.nextInt(1 << 32);
  return wide.abs() % bound;
}

// Model generators
//
// The Message, Conversation and Attachment generators feed Property 1 (model
// JSON round trip) and Property 6 (conversation export round trip).
//
// What the generators leave out on purpose, because the wire normalizes it:
// - ContentPart `text` is always a plain string. FlexibleTextConverter reads
//   the `{value, annotations}` object form but always writes a string, so an
//   object can't come back as itself (models_test.dart covers that read).
// - Every DateTime is UTC. UtcDateTimeConverter decodes to UTC, so a local
//   time would come back as the same instant with `isUtc` flipped, which
//   DateTime `==` treats as different.
// - FeedbackRating.unknown is the decode fallback for a rating the App
//   doesn't know, not a value it sends, so it is never generated.
// - Doubles are finite: jsonEncode rejects NaN and the infinities.
// - Typed `double?` fields only get doubles and typed `int?` fields only get
//   ints. Inside `Object?` and raw maps and lists, ints stay ints and doubles
//   stay doubles, because the VM's jsonEncode writes a double with a `.` or an
//   exponent, so jsonDecode reads it back as a double.

/// Short identifier-like strings, never empty.
final Gen<String> idGen = stringOf('$alphanumeric-_', min: 1, max: 24);

/// Unicode text: plain words, printable ASCII, whitespace, quotes, escapes,
/// non-Latin letters, an emoji outside the BMP and a zero-width joiner.
final Gen<String> textGen = frequency([
  (2, stringOf('$alphanumeric ', max: 16)),
  (3, stringOf('$asciiPrintable$tricky', max: 24)),
  (1, constant('')),
]);

/// Ints across the range a JSON number carries exactly in JavaScript too.
final Gen<int> intGen = oneOf([
  intRange(-1000, 1000),
  intRange(0, 1 << 31),
  intRange(-(1 << 53), 1 << 53),
]);

/// A finite double from a random bit pattern, subnormals included.
final Gen<double> _bitsDouble = Gen((r) {
  final bytes = ByteData(8)
    ..setUint32(0, r.nextInt(1 << 32))
    ..setUint32(4, r.nextInt(1 << 32));
  return bytes.getFloat64(0);
}).where((d) => d.isFinite);

/// Finite doubles: fractions, integral values, edge values and random bits.
final Gen<double> doubleGen = oneOf([
  Gen((r) => r.nextDouble()),
  Gen((r) => (r.nextDouble() - 0.5) * 4000),
  intRange(-1000, 1000).map((n) => n.toDouble()),
  elementOf(const [
    0.0,
    -0.0,
    0.1,
    1e21,
    1e-7,
    double.minPositive,
    double.maxFinite,
    -double.maxFinite,
  ]),
  _bitsDouble,
]);

/// A UTC time at millisecond precision, from year 1 to year 9999.
final Gen<DateTime> utcTimeGen = intRange(
  DateTime.utc(1).millisecondsSinceEpoch,
  DateTime.utc(9999, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
).map((ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));

/// A JSON scalar: null, a bool, an int, a double or a string.
final Gen<Object?> jsonScalarGen = oneOf<Object?>([
  constant(null),
  boolean,
  intGen,
  doubleGen,
  textGen,
]);

/// A raw JSON value nested up to [depth] levels of lists and maps.
Gen<Object?> jsonValueGen(int depth) => depth <= 0
    ? jsonScalarGen
    : frequency<Object?>([
        (3, jsonScalarGen),
        (1, jsonListGen(depth - 1)),
        (1, jsonMapGen(depth - 1)),
      ]);

/// A raw JSON list whose items nest up to [depth] more levels.
Gen<List<Object?>> jsonListGen(int depth) =>
    listOf(jsonValueGen(depth), max: 4);

/// A raw JSON object whose values nest up to [depth] more levels.
Gen<Map<String, Object?>> jsonMapGen(int depth) => listOf(
  zip2(textGen, jsonValueGen(depth)),
  max: 4,
).map((entries) => {for (final (key, value) in entries) key: value});

/// Raw pass-through fields: objects and values nested up to 3 deep.
final Gen<Map<String, Object?>> rawMapGen = jsonMapGen(2);
final Gen<Object?> rawValueGen = jsonValueGen(3);

final Gen<List<String>> stringListGen = listOf(textGen, max: 4);

/// Each optional field is null about half the time.
Gen<T?> opt<T>(Gen<T> gen) => nullable(gen, oneIn: 2);

/// Every known ContentPart type, plus unknown ones that must still decode.
final Gen<String> partTypeGen = frequency([
  (
    6,
    elementOf(const [
      ContentPartType.text,
      ContentPartType.textDelta,
      ContentPartType.think,
      ContentPartType.toolCall,
      ContentPartType.imageUrl,
      ContentPartType.imageFile,
      ContentPartType.videoUrl,
      ContentPartType.inputAudio,
      ContentPartType.error,
      ContentPartType.agentUpdate,
      ContentPartType.summary,
      ContentPartType.steer,
      ContentPartType.activityLabel,
    ]),
  ),
  (1, stringOf('${lowercase}_', min: 1, max: 14)),
]);

/// `args` is a map mid-stream, a JSON string once saved, or anything else.
final Gen<Object?> toolArgsGen = oneOf<Object?>([
  rawMapGen,
  rawMapGen.map(jsonEncode),
  rawValueGen,
]);

final Gen<ToolCall> toolCallGen = Gen(
  (r) => ToolCall(
    id: opt(idGen)(r),
    name: opt(idGen)(r),
    type: opt(elementOf(const ['tool_call', 'function', 'code_interpreter']))(
      r,
    ),
    args: opt(toolArgsGen)(r),
    output: opt(textGen)(r),
    progress: opt(doubleGen)(r),
  ),
);

/// A part of any type with every optional field independently set or null.
/// A `tool_call` part always carries its tool call.
final Gen<ContentPart> contentPartGen = Gen((r) {
  final type = partTypeGen(r);
  return ContentPart(
    type: type,
    text: opt(textGen)(r),
    think: opt(textGen)(r),
    toolCallIds: opt(listOf(idGen, max: 3))(r),
    toolCall: type == ContentPartType.toolCall
        ? toolCallGen(r)
        : opt(toolCallGen)(r),
    imageUrl: opt(oneOf<Object?>([textGen, rawMapGen]))(r),
    imageFile: opt(rawMapGen)(r),
    videoUrl: opt(oneOf<Object?>([textGen, rawMapGen]))(r),
    inputAudio: opt(rawMapGen)(r),
    error: opt(textGen)(r),
    agentUpdate: opt(rawMapGen)(r),
    steer: opt(rawMapGen)(r),
    activityLabel: opt(textGen)(r),
    activityLabelType: opt(idGen)(r),
    activityEndIndex: opt(intGen)(r),
    pending: opt(boolean)(r),
    status: opt(elementOf(const ['failed', 'partial']))(r),
    content: opt(rawValueGen)(r),
    agentId: opt(idGen)(r),
    groupId: opt(intGen)(r),
    stepIndex: opt(intGen)(r),
  );
});

final Gen<Attachment> attachmentGen = Gen(
  (r) => Attachment(
    fileId: opt(idGen)(r),
    filename: opt(textGen)(r),
    filepath: opt(textGen)(r),
    type: opt(elementOf(const ['image/png', 'application/pdf', 'text/plain']))(
      r,
    ),
    bytes: opt(intGen)(r),
    width: opt(intGen)(r),
    height: opt(intGen)(r),
    messageId: opt(idGen)(r),
    toolCallId: opt(idGen)(r),
    status: opt(idGen)(r),
    previewError: opt(textGen)(r),
    webSearch: opt(rawMapGen)(r),
    fileSearch: opt(rawMapGen)(r),
    memory: opt(rawMapGen)(r),
  ),
);

final Gen<MessageFeedback> feedbackGen = Gen(
  (r) => MessageFeedback(
    rating: opt(
      elementOf(const [FeedbackRating.thumbsUp, FeedbackRating.thumbsDown]),
    )(r),
    tag: opt(rawValueGen)(r),
    text: opt(textGen)(r),
  ),
);

/// A Message with 0–6 ContentParts.
final Gen<Message> messageGen = Gen(
  (r) => Message(
    messageId: idGen(r),
    conversationId: idGen(r),
    parentMessageId: opt(idGen)(r),
    sender: opt(textGen)(r),
    text: textGen(r),
    isCreatedByUser: boolean(r),
    endpoint: opt(idGen)(r),
    model: opt(idGen)(r),
    error: boolean(r),
    unfinished: boolean(r),
    content: opt(listOf(contentPartGen, max: 6))(r),
    files: opt(listOf(attachmentGen, max: 3))(r),
    attachments: opt(listOf(attachmentGen, max: 3))(r),
    feedback: opt(feedbackGen)(r),
    quotes: opt(stringListGen)(r),
    createdAt: opt(utcTimeGen)(r),
    updatedAt: opt(utcTimeGen)(r),
  ),
);

final Gen<Conversation> conversationGen = Gen(
  (r) => Conversation(
    conversationId: opt(idGen)(r),
    title: opt(textGen)(r),
    endpoint: opt(idGen)(r),
    endpointType: opt(idGen)(r),
    model: opt(idGen)(r),
    agentId: opt(idGen)(r),
    spec: opt(idGen)(r),
    iconURL: opt(textGen)(r),
    tags: opt(stringListGen)(r),
    isArchived: boolean(r),
    pinned: opt(boolean)(r),
    chatProjectId: opt(idGen)(r),
    isTemporary: opt(boolean)(r),
    temperature: opt(doubleGen)(r),
    topP: opt(doubleGen)(r),
    topK: opt(intGen)(r),
    frequencyPenalty: opt(doubleGen)(r),
    presencePenalty: opt(doubleGen)(r),
    maxOutputTokens: opt(intGen)(r),
    maxContextTokens: opt(intGen)(r),
    maxTokens: opt(intGen)(r),
    system: opt(textGen)(r),
    promptPrefix: opt(textGen)(r),
    modelLabel: opt(textGen)(r),
    reasoningEffort: opt(idGen)(r),
    reasoningMode: opt(idGen)(r),
    reasoningContext: opt(idGen)(r),
    effort: opt(idGen)(r),
    thinkingLevel: opt(idGen)(r),
    thinkingDisplay: opt(idGen)(r),
    stop: opt(stringListGen)(r),
    webSearch: opt(boolean)(r),
    urlContext: opt(boolean)(r),
    promptCacheTtl: opt(idGen)(r),
    createdAt: opt(utcTimeGen)(r),
    updatedAt: opt(utcTimeGen)(r),
  ),
);

// Date group generators (Property 5)

/// A local time from 2020 to 2030 that one time in three is a local
/// midnight plus 0-120 s.
final Gen<DateTime> groupingNowGen = Gen((r) {
  final any = DateTime.fromMillisecondsSinceEpoch(
    intRange(
      DateTime(2020).millisecondsSinceEpoch,
      DateTime(2030).millisecondsSinceEpoch,
    )(r),
  );
  if (r.nextInt(3) != 0) return any;
  return DateTime(
    any.year,
    any.month,
    any.day,
  ).add(Duration(seconds: intRange(0, 120)(r)));
});

/// A UTC `updatedAt` from two years before to one day after [now], weighted
/// toward local midnights and local month starts (each plus or minus a few
/// seconds).
Gen<DateTime> groupingTimeGen(DateTime now) {
  final jitter = intRange(-5, 5).map((s) => Duration(seconds: s));
  final start = now.subtract(const Duration(days: 730));
  return frequency([
    (
      2,
      intRange(
        start.millisecondsSinceEpoch,
        now.add(const Duration(days: 1)).millisecondsSinceEpoch,
      ).map((ms) => DateTime.fromMillisecondsSinceEpoch(ms)),
    ),
    (
      2,
      Gen(
        (r) => DateTime(
          now.year,
          now.month,
          now.day - intRange(-1, 730)(r),
        ).add(jitter(r)),
      ),
    ),
    (
      1,
      Gen(
        (r) =>
            DateTime(now.year, now.month - intRange(0, 24)(r)).add(jitter(r)),
      ),
    ),
  ]).map((t) => t.toUtc());
}

/// Property 5's case: a `now` and 0-60 conversations `c0..cN` in random
/// order, `updatedAt` from [groupingTimeGen] and null about one time in six.
final Gen<({DateTime now, List<Conversation> conversations})> groupingCaseGen =
    groupingNowGen.flatMap(
      (now) => listOf(nullable(groupingTimeGen(now), oneIn: 6), max: 60).map(
        (times) => (
          now: now,
          conversations: [
            for (var i = 0; i < times.length; i++)
              Conversation(conversationId: 'c$i', updatedAt: times[i]),
          ],
        ),
      ),
    );

// SSE (Property 8) ------------------------------------------------------------

/// SSE text characters: ASCII letters, space, `:` and 2- to 4-byte UTF-8
/// characters. No CR, LF or NUL, which SSE values cannot carry.
const sseUnicode = '$lowercase$uppercase :éж中😀𝄞';

/// An [SseEvent] with an optional non-empty name, an optional (possibly
/// empty) id and 1 to 4 data lines, so empty, multi-line, leading-space and
/// non-ASCII data all occur.
final Gen<SseEvent> sseEvent = Gen(
  (r) => SseEvent(
    event: nullable(stringOf(sseUnicode, min: 1))(r),
    id: nullable(stringOf(sseUnicode))(r),
    data: listOf(
      stringOf(sseUnicode),
      min: 1,
      max: 4,
    ).map((lines) => lines.join('\n'))(r),
  ),
);

/// One of LF, CR and CRLF.
final Gen<SseLineEnding> sseLineEnding = elementOf(SseLineEnding.values);

/// An event as written on the wire: its line ending and the comment lines
/// before it.
typedef SseFrame = ({
  SseEvent event,
  SseLineEnding ending,
  List<String> comments,
});

/// A Property 8 case: the frames, whether a BOM leads the bytes, and seeds
/// the test turns into cut offsets once the byte length is known.
typedef SseCase = ({List<SseFrame> frames, bool bom, List<int> cutSeeds});

/// 0 to 20 frames with 0 to 2 comments each, an optional BOM and 1 to 10 cut
/// seeds.
final Gen<SseCase> sseCase = Gen(
  (r) => (
    frames: listOf(
      Gen<SseFrame>(
        (r) => (
          event: sseEvent(r),
          ending: sseLineEnding(r),
          comments: listOf(stringOf(sseUnicode), max: 2)(r),
        ),
      ),
      max: 20,
    )(r),
    bom: boolean(r),
    cutSeeds: listOf(intRange(0, 1 << 20), min: 1, max: 10)(r),
  ),
);

// OpenAPI specs (Property 13, Req 34.11).

/// A valid OpenAPI 3 spec: a `servers[0].url` (https, optional port, path and
/// trailing `/`) and 1–5 paths with 1–3 operations each. Values are only
/// strings, ints, bools, lists and maps, so JSON and YAML read them alike.
final Gen<Map<String, Object?>> openApiSpec = Gen((r) {
  final paths = <String, Object?>{};
  for (var count = intRange(1, 5)(r); count > 0; count--) {
    final segments = listOf(_openApiSegment, min: 1, max: 3)(r);
    final path = '/${segments.join('/')}';
    // A repeated path collapses; the first draw always lands.
    if (!paths.containsKey(path)) paths[path] = _openApiPathItem(segments, r);
  }
  return {
    'openapi': elementOf(['3.0.0', '3.0.3', '3.1.0', '3.1.1'])(r),
    'info': {
      'title': stringOf(alphanumeric, min: 1, max: 12)(r),
      'version': '1.0.0',
    },
    'servers': [
      {'url': _openApiServerUrl(r)},
    ],
    'paths': paths,
  };
});

const _openApiMethods = [
  'get',
  'post',
  'put',
  'patch',
  'delete',
  'head',
  'options',
];

const _openApiTypes = ['string', 'integer', 'number', 'boolean'];

final Gen<String> _openApiLabel = stringOf('$lowercase$digits', min: 1, max: 8);

final Gen<String> _openApiName = stringOf(lowercase, min: 1, max: 6);

/// Free text, blank and messy ones included.
final Gen<String> _openApiText = stringOf('$asciiPrintable$tricky', max: 20);

/// A literal path segment or a `{name}` template.
final Gen<String> _openApiSegment = oneOf([
  stringOf('$alphanumeric-', min: 1, max: 8),
  _openApiName.map((name) => '{$name}'),
]);

String _openApiServerUrl(Random r) {
  final host = listOf(_openApiLabel, min: 1, max: 3)(r).join('.');
  final port = r.nextInt(3) == 0 ? ':${intRange(1, 65535)(r)}' : '';
  final path = listOf(_openApiLabel, max: 2)(r).map((s) => '/$s').join();
  final slash = r.nextInt(3) == 0 ? '/' : '';
  return 'https://$host$port$path$slash';
}

Map<String, Object?> _openApiPathItem(List<String> segments, Random r) {
  final pathNames = [
    for (final segment in segments)
      if (segment.startsWith('{')) segment.substring(1, segment.length - 1),
  ];
  final methods = [..._openApiMethods]..shuffle(r);
  return {
    if (pathNames.isNotEmpty)
      'parameters': [
        for (final name in pathNames)
          {
            'name': name,
            'in': 'path',
            'required': true,
            'schema': {'type': 'string'},
          },
      ],
    for (final method in methods.take(intRange(1, 3)(r)))
      method: _openApiOperation(pathNames, r),
  };
}

Map<String, Object?> _openApiOperation(List<String> pathNames, Random r) {
  final operationId = nullable(
    stringOf('$alphanumeric$tricky-.', min: 1, max: 16),
  )(r);
  final summary = nullable(_openApiText)(r);
  final description = nullable(_openApiText)(r);
  final parameters = [
    for (var count = intRange(0, 3)(r); count > 0; count--)
      _openApiParameter(pathNames, r),
  ];
  return {
    'operationId': ?operationId,
    'summary': ?summary,
    'description': ?description,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (r.nextBool()) 'requestBody': _openApiRequestBody(r),
  };
}

Map<String, Object?> _openApiParameter(List<String> pathNames, Random r) {
  // Reusing a path-level name, sometimes `in: path` too, exercises the
  // operation-wins override.
  final reuse = pathNames.isNotEmpty && r.nextInt(3) == 0;
  final description = nullable(_openApiText)(r);
  final required = nullable(boolean)(r);
  return {
    'name': reuse ? elementOf(pathNames)(r) : _openApiName(r),
    'in': elementOf(reuse ? ['path', 'query'] : ['query', 'header'])(r),
    'schema': {'type': elementOf(_openApiTypes)(r)},
    'description': ?description,
    'required': ?required,
  };
}

Map<String, Object?> _openApiRequestBody(Random r) {
  final properties = <String, Object?>{
    for (final name in listOf(_openApiName, min: 1, max: 3)(r))
      name: {
        'type': elementOf(_openApiTypes)(r),
        'description': ?nullable(_openApiText)(r),
        'default': ?nullable(
          oneOf<Object>([intRange(-1000, 1000), boolean]),
          oneIn: 2,
        )(r),
      },
  };
  final required = [
    for (final name in properties.keys)
      if (r.nextBool()) name,
  ];
  return {
    'content': {
      'application/json': {
        'schema': {
          'type': 'object',
          'properties': properties,
          if (required.isNotEmpty) 'required': required,
        },
      },
    },
  };
}

// Artifact generators (Property 9).

/// An artifact identifier or title: spaces, unicode, `:` and braces, but no
/// quotes, tabs or line breaks.
final Gen<String> artifactValueGen = stringOf(
  '$alphanumeric :-_./{}=#éж中😀',
  max: 16,
);

/// An artifact type: a rendered type, or another MIME-like string.
final Gen<String> artifactTypeGen = frequency([
  (
    3,
    elementOf(const [
      'text/html',
      'application/vnd.code-html',
      'image/svg+xml',
      'application/vnd.react',
      'application/vnd.mermaid',
      'text/markdown',
      'text/plain',
    ]),
  ),
  (
    1,
    zip2(
      stringOf(lowercase, min: 1, max: 8),
      stringOf('$lowercase$digits.+-', min: 1, max: 12),
    ).map((p) => '${p.$1}/${p.$2}'),
  ),
]);

/// Artifact content: 0–6 lines with backticks, tildes, mid-line `:::`,
/// tabs, unicode and blank lines. Every non-blank line holds a letter, so
/// none closes a fence or a block. With [fenceLines], bare fence and `:::`
/// lines appear too, for writers that pick a fence longer than the content's.
Gen<String> artifactContentGen({bool fenceLines = false}) {
  final token = elementOf(const [
    '`',
    '```',
    '~~~',
    '~',
    ' ::: ',
    ':::',
    '  ',
    '\t',
    'a',
    'é',
    '中',
    '😀',
  ]);
  final affix = listOf(token, max: 3).map((t) => t.join());
  final line = frequency([
    (2, elementOf(const ['', ' ', '  '])),
    (
      6,
      zip3(
        affix,
        charOf('$lowercaseéж中'),
        affix,
      ).map((p) => '${p.$1}${p.$2}${p.$3}'),
    ),
    if (fenceLines)
      (1, elementOf(const ['```', '````', '~~~', ':::', '``````````'])),
  ]);
  return listOf(line, max: 6).map((lines) => lines.join('\n'));
}

/// Text around an artifact: 0–3 lines with no `:`, backtick or tilde, so it
/// opens neither a fence nor an artifact.
final Gen<String> artifactProseGen = listOf(
  stringOf('$alphanumeric .,!?éж中😀', max: 20),
  max: 3,
).map((lines) => lines.join('\n'));

// Prompt variable generators (Property 11)

const _promptNamePool = ['name', 'topic', 'first name', 'x-y', 'a.b', 'Lang'];
const _promptServerNames = [
  'current_date',
  'current_user',
  'iso_datetime',
  'current_datetime',
];

/// [base] with each character's case picked at random.
Gen<String> _randomCase(String base) => Gen(
  (r) => [
    for (final c in base.split(''))
      r.nextBool() ? c.toUpperCase() : c.toLowerCase(),
  ].join(),
);

/// 0-2 spaces on each side of [inner].
Gen<String> _padded(Gen<String> inner) =>
    Gen((r) => '${' ' * r.nextInt(3)}${inner(r)}${' ' * r.nextInt(3)}');

/// A name from a small pool, in random case with 0-2 spaces on each side.
final Gen<String> promptNameGen = _padded(
  elementOf(_promptNamePool).flatMap(_randomCase),
);

final Gen<String> _promptServerNameGen = _padded(
  elementOf(_promptServerNames).flatMap(_randomCase),
);

/// 0-8 segments: literal text, placeholders, server-filled placeholders and
/// stray brace fragments.
final Gen<String> promptTemplateGen = listOf(
  frequency([
    (
      2,
      stringOf(
        '$alphanumeric $tricky',
        max: 12,
      ).map((s) => s.replaceAll(RegExp('[{}]'), '')),
    ),
    (3, promptNameGen.map((name) => '{{$name}}')),
    (1, _promptServerNameGen.map((name) => '{{$name}}')),
    (2, elementOf(const ['{', '}', '{{', '}}', '{{}}', '{ {', '}}{{'])),
  ]),
  max: 8,
).map((segments) => segments.join());

/// 0-6 entries keyed by pool names, unused names and server names, with
/// blank values and values holding `$1`, `\` and `{{x}}`.
final Gen<Map<String, String>> promptValuesGen = listOf(
  zip2(
    frequency([
      (4, promptNameGen),
      (1, elementOf(const ['unused', 'other key', ''])),
      (1, _promptServerNameGen),
    ]),
    oneOf([
      elementOf(const ['', '  ', '\t']),
      stringOf('$alphanumeric \$\\{}', min: 1, max: 8).map((s) => 'v$s'),
      elementOf(const [r'$1', r'\', '{{x}}', r'a\$2b']),
    ]),
  ),
  max: 6,
).map((entries) => {for (final (key, value) in entries) key: value});

/// Property 11's case: a template and a value map.
final Gen<(String, Map<String, String>)> promptFillCaseGen = zip2(
  promptTemplateGen,
  promptValuesGen,
);
