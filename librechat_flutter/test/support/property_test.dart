import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'property.dart';

void main() {
  group('forAll', () {
    test('runs the body once per run', () async {
      var count = 0;
      await forAll(constant(1), (_) => count++, runs: 37, seed: 1);
      expect(count, 37);
    });

    test('defaults to 100 runs', () async {
      var count = 0;
      await forAll(constant(1), (_) => count++);
      expect(count, 100);
    });

    test('the same seed draws the same cases', () async {
      final gen = listOf(intRange(-1000, 1000));
      final first = <List<int>>[];
      final second = <List<int>>[];
      await forAll(gen, first.add, seed: 42);
      await forAll(gen, second.add, seed: 42);
      expect(second, first);
    });

    test('awaits an async body', () async {
      final seen = <int>[];
      await forAll(
        intRange(0, 9),
        (value) async {
          await Future<void>.delayed(Duration.zero);
          seen.add(value);
        },
        runs: 5,
        seed: 3,
      );
      expect(seen, hasLength(5));
    });

    test('a failure reports the seed and the failing case', () async {
      Object? caught;
      try {
        await forAll(stringOf('ab\n', min: 1), (s) {
          if (s.contains('\n')) throw StateError('newline');
        }, seed: 7);
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<TestFailure>());
      final message = (caught! as TestFailure).message!;
      expect(message, contains('seed 7'));
      expect(message, contains('--dart-define=PROPERTY_SEED=7'));
      expect(message, contains(r'Failing case: "'));
      expect(message, contains(r'\n'));
      expect(message, contains('Bad state: newline'));
    });
  });

  group('generators', () {
    final random = Random(5);

    test('intRange stays inside its inclusive bounds and reaches both', () {
      final values = List.generate(500, (_) => intRange(-2, 2)(random));
      expect(values.toSet(), {-2, -1, 0, 1, 2});
    });

    test('intRange handles ranges wider than 2^32', () {
      const max = 1 << 40;
      final values = List.generate(200, (_) => intRange(0, max)(random));
      expect(values.every((v) => v >= 0 && v <= max), isTrue);
      expect(values.any((v) => v > 1 << 32), isTrue);
    });

    test('listOf and stringOf respect length bounds and the alphabet', () {
      for (var i = 0; i < 200; i++) {
        expect(
          listOf(boolean, min: 2, max: 4)(random).length,
          inInclusiveRange(2, 4),
        );
        final s = stringOf('é😀x', min: 1, max: 3)(random);
        expect(s.runes.length, inInclusiveRange(1, 3));
        expect(s.runes.every('é😀x'.runes.contains), isTrue);
      }
    });

    test('elementOf, oneOf and frequency pick only from their inputs', () {
      final picks = List.generate(300, (_) => elementOf(['a', 'b'])(random));
      expect(picks.toSet(), {'a', 'b'});
      final gens = List.generate(
        300,
        (_) => oneOf([constant(1), constant(2)])(random),
      );
      expect(gens.toSet(), {1, 2});
      final weighted = List.generate(
        300,
        (_) => frequency([(1, constant('x')), (0, constant('never'))])(random),
      );
      expect(weighted.toSet(), {'x'});
    });

    test('nullable mixes nulls and values', () {
      final values = List.generate(300, (_) => nullable(constant(1))(random));
      expect(values.toSet(), {null, 1});
    });

    test('map, flatMap, where and zip compose', () {
      final gen = zip2(
        intRange(1, 5).flatMap((n) => listOf(constant(n), min: n, max: n)),
        intRange(0, 100).where((n) => n.isEven).map((n) => '$n'),
      );
      for (var i = 0; i < 100; i++) {
        final (list, even) = gen(random);
        expect(list, hasLength(list.first));
        expect(int.parse(even).isEven, isTrue);
      }
      final (a, b, c) = zip3(constant(1), constant('b'), constant(true))(
        random,
      );
      expect((a, b, c), (1, 'b', true));
    });

    test('where gives up when nothing matches', () {
      expect(
        () => constant(1).where((n) => n == 2, maxTries: 10)(random),
        throwsStateError,
      );
    });
  });

  test('describeCase quotes strings inside collections', () {
    expect(describeCase(['a\tb', 1, null]), r'["a\tb", 1, null]');
    expect(describeCase({'k': ' '}), '{"k": " "}');
  });
}
