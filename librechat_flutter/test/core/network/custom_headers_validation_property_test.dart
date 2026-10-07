import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';

import '../../support/property.dart';

// The reference model of Req 5.2, written from the requirement text rather
// than from `custom_headers.dart`, so the reserved list and the character
// classes are checked too.

/// RFC 7230 tchar.
const _tchar = "$alphanumeric!#\$%&'*+-.^_`|~";

/// Reserved_Header_Names as the requirements glossary lists them.
const _reserved = [
  'host',
  'content-length',
  'transfer-encoding',
  'connection',
  'upgrade',
  'te',
  'authorization',
  'user-agent',
  'accept',
  'accept-encoding',
  'content-type',
  'expect',
  'proxy-authorization',
];

HeaderProblem? _model(String name, String value) {
  final n = name.trim();
  if (n.isEmpty || n.runes.any((c) => !_tchar.runes.contains(c))) {
    return HeaderProblem.name;
  }
  if (_reserved.contains(n.toLowerCase())) return HeaderProblem.reserved;
  final v = value.trim();
  if (v.runes.any((c) => c != 0x09 && (c < 0x20 || c > 0x7E))) {
    return HeaderProblem.value;
  }
  return null;
}

// Generators, kept local to this file.

/// RFC 7230 separators: printable ASCII that is neither tchar nor a letter.
const _separators = '"(),/:;<=>?@[\\]{} ';

/// Spaces and control characters, including tab, CR, LF, NUL, US and DEL.
const _controls = ' \t\r\n\x00\x0b\x0c\x1f\x7f';

/// Non-ASCII: no-break space, smart quotes, letters, an emoji outside the BMP,
/// zero-width space and the byte-order mark.
const _nonAscii = '\u00a0\u2018\u2019\u201c\u201déß中😀\u200b\ufeff';

/// Surrounding whitespace that trimming removes, empty about a quarter of the
/// time.
final Gen<String> _padding = stringOf(' \t\r\n\u00a0\u3000', max: 3);

/// A string that is mostly from [good] with some separators, controls and
/// non-ASCII mixed in.
Gen<String> _mixed(String good, {int max = 12}) => listOf(
  frequency([
    (8, charOf(good)),
    (1, charOf(_separators)),
    (1, charOf(_controls)),
    (1, charOf(_nonAscii)),
  ]),
  max: max,
).map((chars) => chars.join());

/// [s] with each letter's case flipped at random.
Gen<String> _randomCase(String s) => Gen(
  (r) => s.split('').map((c) => r.nextBool() ? c.toUpperCase() : c).join(),
);

final Gen<String> _reservedName = elementOf(_reserved).flatMap(_randomCase);

final Gen<String> _name = zip3(
  _padding,
  frequency([
    (3, stringOf(_tchar, min: 1, max: 12)),
    (3, _reservedName),
    // Near misses of reserved names: a token suffix or an inner bad char.
    (
      1,
      zip2(
        _reservedName,
        stringOf(_tchar, min: 1, max: 3),
      ).map((p) => '${p.$1}${p.$2}'),
    ),
    (3, _mixed(_tchar)),
    (1, stringOf(' \t', max: 3)),
  ]),
  _padding,
).map((t) => '${t.$1}${t.$2}${t.$3}');

final Gen<String> _value = zip3(
  _padding,
  frequency([
    (3, stringOf('$asciiPrintable\t', max: 20)),
    (3, _mixed('$asciiPrintable\t', max: 20)),
    (1, stringOf(' \t', max: 3)),
  ]),
  _padding,
).map((t) => '${t.$1}${t.$2}${t.$3}');

void main() {
  // Feature: flutter-android-rewrite, Property 2: For any name and value strings, the Header_Validator returns the same result as a reference model that checks invalid name, then reserved name, then invalid value, exactly as Requirement 5.2 words them.
  // Validates: Requirements 5.2
  test('Property 2: Header validation matches its model', () async {
    await forAll(zip2(_name, _value), (pair) {
      final (name, value) = pair;
      expect(
        validateHeader(name, value),
        _model(name, value),
        reason: 'name ${describeCase(name)}, value ${describeCase(value)}',
      );
    }, runs: 300);
  });
}
