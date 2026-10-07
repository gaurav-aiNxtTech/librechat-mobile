import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';

void main() {
  group('validateHeader', () {
    test('accepts a usable pair after trimming', () {
      expect(validateHeader(' CF-Access-Client-Id ', ' abc.123 '), isNull);
      expect(validateHeader("x!#\$%&'*+-.^_`|~9", ''), isNull);
    });

    test('rejects an empty or malformed name', () {
      for (final name in ['', '   ', 'X Header', 'X:Y', 'X(1)', 'Ä', 'a/b']) {
        expect(validateHeader(name, 'v'), HeaderProblem.name, reason: name);
      }
    });

    test('rejects reserved names in any letter case', () {
      for (final name in [
        'Host',
        'AUTHORIZATION',
        'User-Agent',
        'content-TYPE',
        ' Te ',
        'Proxy-Authorization',
      ]) {
        expect(validateHeader(name, 'v'), HeaderProblem.reserved, reason: name);
      }
      expect(validateHeader('Cookie', 'a=b'), isNull);
    });

    test('rejects a value with a control or non-ASCII character', () {
      for (final value in [
        'a\nb',
        'a\rb',
        'a\u0000b',
        'a\u007Fb',
        'smart\u201C',
        'nb\u00A0sp',
      ]) {
        expect(
          validateHeader('X-Key', value),
          HeaderProblem.value,
          reason: value,
        );
      }
    });

    test('allows tab and space inside a value', () {
      expect(validateHeader('X-Key', 'a b\tc ~'), isNull);
    });

    test('reports name problems before value problems', () {
      expect(validateHeader('bad name', 'a\nb'), HeaderProblem.name);
      expect(validateHeader('Host', 'a\nb'), HeaderProblem.reserved);
    });

    test('carries the KMP reason copy', () {
      expect(HeaderProblem.name.message, 'Not a valid header name.');
      expect(
        HeaderProblem.reserved.message,
        "This header is set by the app and can't be overridden.",
      );
      expect(
        HeaderProblem.value.message,
        "This value contains characters that can't be sent.",
      );
    });
  });

  group('buildCustomHeaders', () {
    test('trims fields and skips rows blank on both sides', () {
      expect(
        buildCustomHeaders([
          (' X-A ', ' 1 '),
          ('', ''),
          ('  ', '\t'),
          ('X-Empty', ''),
        ]),
        {'X-A': '1', 'X-Empty': ''},
      );
    });

    test('keeps the last row for a name compared case-insensitively', () {
      expect(
        buildCustomHeaders([
          ('X-Token', 'old'),
          ('X-Other', 'o'),
          ('x-token', 'new'),
        ]),
        {'x-token': 'new', 'X-Other': 'o'},
      );
    });
  });

  group('mergeCookieHeader', () {
    test('drops a stale refreshToken segment', () {
      expect(
        mergeCookieHeader('CF_Authorization=jwt; refreshToken=stale; a=1', 'T'),
        'refreshToken=T; CF_Authorization=jwt; a=1',
      );
    });

    test('keeps a refreshtoken segment in another letter case', () {
      expect(
        mergeCookieHeader('refreshtoken=x', 'T'),
        'refreshToken=T; refreshtoken=x',
      );
    });

    test('gives only the Refresh_Token for a null or empty value', () {
      expect(mergeCookieHeader(null, 'T'), 'refreshToken=T');
      expect(mergeCookieHeader('', 'T'), 'refreshToken=T');
      expect(mergeCookieHeader(' ; ', 'T'), 'refreshToken=T');
    });

    test('ignores stray separators and trims segments', () {
      expect(
        mergeCookieHeader(';a=1;; ; b=2 ;refreshToken ;', 'T'),
        'refreshToken=T; a=1; b=2',
      );
    });
  });
}
