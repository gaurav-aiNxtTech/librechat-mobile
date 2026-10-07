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

import 'package:flutter_test/flutter_test.dart';

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
