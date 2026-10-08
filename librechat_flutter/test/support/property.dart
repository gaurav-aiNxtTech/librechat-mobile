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
