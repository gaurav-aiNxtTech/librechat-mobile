import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/server_url.dart';

import '../../support/property.dart';

/// Upper- or lowercases each character of [text] at random.
String _randomCase(Random r, String text) => text.split('').map((c) {
  return r.nextBool() ? c.toUpperCase() : c.toLowerCase();
}).join();

/// Whitespace that `String.trim` removes, ASCII and Unicode.
const _whitespace = ' \t\n\r\u00a0\u0085\u2028\ufeff';

/// A scheme in random case followed by `://`, or no scheme at all.
final Gen<String> _scheme = frequency([
  (1, constant('')),
  (3, Gen((r) => '${_randomCase(r, r.nextBool() ? 'http' : 'https')}://')),
]);

/// Optional user info, which may itself hold `:` and `@`.
final Gen<String> _userInfo = frequency([
  (2, constant('')),
  (1, stringOf('$alphanumeric:@._-%', min: 1, max: 8).map((u) => '$u@')),
]);

final Gen<String> _hostName = listOf(
  stringOf('$alphanumeric-', min: 1, max: 8),
  min: 1,
  max: 4,
).map((labels) => labels.join('.'));

final Gen<String> _ipv4 = listOf(
  intRange(0, 255),
  min: 4,
  max: 4,
).map((octets) => octets.join('.'));

final Gen<String> _ipv6 = Gen((r) {
  const literals = [
    '[::1]',
    '[fe80::1]',
    '[2001:db8::a:1]',
    '[::ffff:192.0.2.1]',
    '[2001:0db8:85a3:0000:0000:8a2e:0370:7334]',
  ];
  return _randomCase(r, literals[r.nextInt(literals.length)]);
});

/// A host in random case: a name, IPv4, `localhost` or an IPv6 literal.
final Gen<String> _host = oneOf([
  _hostName.flatMap((h) => Gen((r) => _randomCase(r, h))),
  _ipv4,
  Gen((r) => _randomCase(r, 'localhost')),
  _ipv6,
]);

/// No port, a default port (sometimes with leading zeros) or another port.
final Gen<String> _port = frequency([
  (2, constant('')),
  (2, Gen((r) => ':${'0' * r.nextInt(3)}${r.nextBool() ? 80 : 443}')),
  (2, intRange(1, 65535).map((p) => ':$p')),
]);

/// Usually nothing, sometimes whitespace typed between the host and the path.
final Gen<String> _gap = frequency([
  (6, constant('')),
  (1, stringOf(' \t', min: 1, max: 2)),
]);

/// Mixed-case segments with spaces, then a run of trailing `/` and spaces.
final Gen<String> _path = Gen((r) {
  final segments = listOf(
    stringOf("$alphanumeric -_.~%:@!\$&'()*+,;=éж", max: 6).map((s) => '/$s'),
    max: 4,
  )(r).join();
  final trailing = stringOf('/// \t', max: 5)(r);
  return '$segments$trailing';
});

/// An optional query and an optional fragment, with any printable content.
final Gen<String> _queryAndFragment = Gen((r) {
  final query = r.nextBool() ? '?${stringOf(asciiPrintable, max: 10)(r)}' : '';
  final fragment = r.nextBool()
      ? '#${stringOf(asciiPrintable, max: 10)(r)}'
      : '';
  return '$query$fragment';
});

final Gen<String> _surroundingWhitespace = stringOf(_whitespace, max: 3);

/// A messy typed Server_URL that the normalizer accepts.
final Gen<String> _acceptedInput = Gen((r) {
  return [
    _surroundingWhitespace(r),
    _scheme(r),
    _userInfo(r),
    _host(r),
    _port(r),
    _gap(r),
    _path(r),
    _queryAndFragment(r),
    _surroundingWhitespace(r),
  ].join();
}).where((input) => normalizeServerUrl(input).url != null);

void main() {
  // Feature: flutter-android-rewrite, Property 4: For any input the Server_URL_Normalizer accepts, normalizing its output again returns that output unchanged.
  // Validates: Requirements 8.6
  test('Property 4: Server URL normalization is idempotent', () async {
    await forAll(_acceptedInput, (input) {
      final once = normalizeServerUrl(input).url!;
      expect(
        normalizeServerUrl(once),
        (url: once, problem: null),
        reason: 'first output: ${describeCase(once)}',
      );
    }, runs: 100);
  });
}
