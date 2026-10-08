import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/agents/openapi_parser.dart';

import '../../support/property.dart';

void main() {
  // Feature: flutter-android-rewrite, Property 13: For any valid OpenAPI spec, parseOpenApiSpec derives the same domain and the same function definitions, with no errors, from the spec written as YAML and from the same spec written as JSON.
  // Validates: Requirements 34.11
  test('Property 13: The OpenAPI_Parser reads YAML and JSON alike', () async {
    await forAll(openApiSpec, (spec) {
      final jsonText = jsonEncode(spec);
      final yamlText = _toYaml(spec);
      // The YAML text really takes the YAML path.
      expect(() => jsonDecode(yamlText), throwsFormatException);
      final fromJson = parseOpenApiSpec(jsonText);
      final fromYaml = parseOpenApiSpec(yamlText);
      expect(fromJson.errors, isEmpty);
      expect(fromYaml.errors, isEmpty);
      expect(fromJson.functions, isNotEmpty);
      expect(fromYaml.domain, fromJson.domain);
      expect(
        fromYaml.functions.map((f) => f.toJson()).toList(),
        fromJson.functions.map((f) => f.toJson()).toList(),
      );
      expect(
        [for (final f in fromYaml.functions) (f.method, f.path)],
        [for (final f in fromJson.functions) (f.method, f.path)],
      );
    }, runs: 100);
  });
}

/// Writes [value] as block YAML, double-quoting every string, keys included.
String _toYaml(Object? value) {
  final out = StringBuffer();
  _writeBlock(out, value, 0);
  return out.toString();
}

void _writeBlock(StringBuffer out, Object? value, int indent) {
  final pad = ' ' * indent;
  if (value is Map) {
    for (final MapEntry(:key, :value) in value.entries) {
      out.write('$pad${_quote('$key')}:');
      _writeChild(out, value, indent);
    }
  } else if (value is List) {
    for (final item in value) {
      out.write('$pad-');
      _writeChild(out, item, indent);
    }
  } else {
    out.writeln('$pad${_scalar(value)}');
  }
}

/// A non-empty collection goes on the next lines, indented; anything else
/// stays on the line.
void _writeChild(StringBuffer out, Object? value, int indent) {
  if ((value is Map && value.isNotEmpty) ||
      (value is List && value.isNotEmpty)) {
    out.writeln();
    _writeBlock(out, value, indent + 2);
  } else {
    out.writeln(' ${_scalar(value)}');
  }
}

String _scalar(Object? value) => switch (value) {
  String() => _quote(value),
  Map() => '{}',
  List() => '[]',
  _ => '$value',
};

/// A YAML double-quoted string; control, line-separator and BOM code units
/// are escaped because YAML would fold or reject them raw.
String _quote(String text) {
  final out = StringBuffer('"');
  for (final unit in text.codeUnits) {
    if (unit == 0x5C) {
      out.write(r'\\');
    } else if (unit == 0x22) {
      out.write(r'\"');
    } else if (unit < 0x20 ||
        (unit >= 0x7F && unit <= 0x9F) ||
        unit == 0x2028 ||
        unit == 0x2029 ||
        unit == 0xFEFF) {
      out.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
    } else {
      out.writeCharCode(unit);
    }
  }
  out.write('"');
  return out.toString();
}
