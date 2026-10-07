import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';

import '../../support/property.dart';

/// One generated custom `Cookie` segment: the raw text placed between `;`
/// separators, and the trimmed text the merge must keep, or null when the
/// merge must drop it (empty, or named exactly `refreshToken`).
typedef _Segment = ({String raw, String? kept});

/// Spaces and tabs around a segment or its name.
final Gen<String> _pad = stringOf(' \t', max: 3);

/// A cookie name of at most 8 characters, so it can never be `refreshToken`.
final Gen<String> _name = stringOf('$alphanumeric-_', min: 1, max: 8);

/// A cookie value: anything printable but `;`, with `=` and inner spaces.
final Gen<String> _value = stringOf(
  asciiPrintable.replaceAll(';', ''),
  max: 12,
);

/// Pads [core] on both sides; the merge must keep [core] trimmed.
Gen<_Segment> _keptSegment(Gen<String> core) => zip3(_pad, core, _pad).map(
  (p) => (raw: '${p.$1}${p.$2}${p.$3}', kept: p.$2.trim()),
);

/// `name=value`, which is kept unless the value trims the whole thing empty.
final Gen<_Segment> _pair = _keptSegment(
  zip2(_name, _value).map((p) => '${p.$1}=${p.$2}'),
);

/// A bare name with no `=`.
final Gen<_Segment> _bare = _keptSegment(_name);

/// An empty or whitespace-only segment, which is dropped.
final Gen<_Segment> _empty = _pad.map((p) => (raw: p, kept: null));

/// A stale `refreshToken` segment, with or without a value and with stray
/// whitespace around the name. Its cookie name is exactly `refreshToken`.
final Gen<_Segment> _stale = zip3(_pad, _pad, nullable(_value, oneIn: 3)).map(
  (p) => (
    raw: '${p.$1}refreshToken${p.$2}${p.$3 == null ? '' : '=${p.$3}'}',
    kept: null,
  ),
);

/// Names that look like `refreshToken` but are a different cookie.
final Gen<_Segment> _nearMiss = _keptSegment(
  zip2(
    elementOf([
      'refreshtoken',
      'RefreshToken',
      'REFRESHTOKEN',
      'refreshToken_',
      'xrefreshToken',
      'refreshTokens',
      'refresh Token',
      'refresh_token',
    ]),
    nullable(_value, oneIn: 3),
  ).map((p) => p.$2 == null ? p.$1 : '${p.$1}=${p.$2}'),
);

final Gen<_Segment> _segment = frequency([
  (4, _pair),
  (1, _bare),
  (2, _empty),
  (2, _stale),
  (2, _nearMiss),
]);

/// The custom `Cookie` value as segments, or null for a missing value.
/// An empty list renders as `''`.
final Gen<List<_Segment>?> _custom = frequency([
  (1, constant<List<_Segment>?>(null)),
  (1, constant<List<_Segment>?>(const [])),
  (8, listOf(_segment, min: 1, max: 8)),
]);

/// A Refresh_Token: cookie-value characters, with `=` for base64 padding.
final Gen<String> _token = stringOf('$alphanumeric-_.=', min: 1, max: 40);

String _cookieName(String segment) {
  final eq = segment.indexOf('=');
  return (eq == -1 ? segment : segment.substring(0, eq)).trim();
}

void main() {
  // Feature: flutter-android-rewrite, Property 3: For any custom Cookie value
  // and Refresh_Token, the merged Cookie header holds exactly one segment
  // named exactly refreshToken, carrying the Refresh_Token, plus every other
  // non-empty custom segment in its original order.
  // Validates: Requirements 5.8
  test('Property 3: The Cookie merge keeps exactly one refreshToken', () async {
    await forAll(
      zip2(_custom, _token).map(
        (p) => (
          custom: p.$1?.map((s) => s.raw).join(';'),
          expectedKept: [
            for (final s in p.$1 ?? const <_Segment>[])
              if (s.kept != null && s.kept!.isNotEmpty) s.kept!,
          ],
          token: p.$2,
        ),
      ),
      (c) {
        final merged = mergeCookieHeader(c.custom, c.token);
        final segments = merged.split('; ');

        final refresh = [
          for (final s in segments)
            if (_cookieName(s) == 'refreshToken') s,
        ];
        expect(
          refresh,
          hasLength(1),
          reason: 'one refreshToken segment in ${describeCase(merged)}',
        );
        expect(
          refresh.single.substring(refresh.single.indexOf('=') + 1),
          c.token,
          reason: 'refreshToken carries the Refresh_Token',
        );

        final others = [
          for (final s in segments)
            if (_cookieName(s) != 'refreshToken') s,
        ];
        expect(
          others,
          c.expectedKept,
          reason:
              'custom ${describeCase(c.custom)} keeps its other segments, '
              'trimmed and in order',
        );
      },
      runs: 200,
    );
  });
}
