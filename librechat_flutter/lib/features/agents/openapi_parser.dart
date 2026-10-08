/// The OpenAPI_Parser (Req 34.9–34.11): reads an action's OpenAPI spec,
/// written as JSON or YAML, into the action domain and one function
/// definition per operation.
///
/// Ported from the KMP_App's `feature/agents/.../util/OpenApiSpecParser.kt`;
/// the error copy is KMP's, with each message's source noted below.
library;

import 'dart:convert';

import 'package:yaml/yaml.dart';

/// The HTTP methods that become functions, in derivation order.
const openApiMethods = [
  'get',
  'post',
  'put',
  'patch',
  'delete',
  'head',
  'options',
];

/// The user-facing errors [parseOpenApiSpec] reports.
abstract final class OpenApiErrors {
  // KMP OpenApiSpecParser.parse, blank check.
  static const empty = 'Specification is empty';

  // KMP parse catch ("Failed to parse specification: ") around
  // parseSpecToJsonObject ("Not valid JSON or YAML.\n…YAML error: …"). The
  // JSON error line is dropped: once JSON has failed only the YAML error helps.
  static String unparsable(String yamlError) =>
      'Failed to parse specification: Not valid JSON or YAML.\n'
      'YAML error: $yamlError';

  // KMP parseYamlToJsonObject, wrapped by the same parse catch prefix. KMP
  // names a Kotlin class; [kind] is a plain word such as "a list".
  static String notAMap(String kind) =>
      'Failed to parse specification: Expected a YAML mapping (object) at the '
      'root, but got $kind.';

  // KMP parse, Swagger 2.0 branch.
  static const swagger =
      "This is a Swagger 2.0 specification. The server requires an OpenAPI 3 "
      "'servers' array — convert the spec, or add 'servers' with the full "
      "base URL.";

  // KMP parse. The Server's equivalent is "Could not find a valid URL in
  // `servers`".
  static const noServer =
      "No server URL found. Add a 'servers' array with at least one entry.";

  // KMP "Missing 'openapi' or 'swagger' version field.", without "or
  // 'swagger'", since Swagger 2.0 specs are not accepted.
  static const noVersion = "Missing 'openapi' version field.";

  // KMP parse.
  static const noPaths = 'No paths found in the specification.';

  // KMP parse.
  static const noOperations = 'No operations found in paths.';
}

/// One function definition derived from an operation.
final class OpenApiFunction {
  const OpenApiFunction({
    required this.name,
    required this.description,
    required this.parameters,
    required this.method,
    required this.path,
  });

  final String name;
  final String description;

  /// A JSON-schema object: `type`, and `properties` and `required` when set.
  final Map<String, Object?> parameters;

  /// Lowercase, one of [openApiMethods].
  final String method;

  /// The `paths` key, verbatim.
  final String path;

  /// The shape of one entry in the Server's `functions` array (KMP
  /// `FunctionTool`). [method] and [path] are for display only.
  Map<String, Object?> toJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': parameters,
    },
  };
}

/// What [parseOpenApiSpec] derived from a spec.
final class OpenApiParseResult {
  const OpenApiParseResult({
    required this.domain,
    required this.functions,
    required this.errors,
  });

  /// The action domain, or `''` when there is none.
  final String domain;

  /// Empty whenever [errors] is not.
  final List<OpenApiFunction> functions;

  /// User-facing copy, in the order the checks run.
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// Reads [text] as JSON or, when JSON parsing fails, as YAML, and derives the
/// domain and one function per operation (Req 34.9). Any error leaves
/// `functions` empty (Req 34.10). Pure; never throws.
OpenApiParseResult parseOpenApiSpec(String text) {
  OpenApiParseResult failed(String error) =>
      OpenApiParseResult(domain: '', functions: const [], errors: [error]);

  if (text.trim().isEmpty) return failed(OpenApiErrors.empty);

  Object? decoded;
  try {
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      try {
        decoded = loadYaml(text);
      } on YamlException catch (e) {
        // Only `message`: `toString()` quotes the spec text.
        final start = e.span?.start;
        final at = start == null
            ? ''
            : ' (line ${start.line + 1}, column ${start.column + 1})';
        return failed(OpenApiErrors.unparsable('${e.message}$at'));
      }
    }
  } on StackOverflowError {
    return failed(OpenApiErrors.unparsable(_tooDeep));
  }

  final Object? plain;
  try {
    plain = _plain(decoded);
  } on _TooLarge catch (e) {
    return failed(OpenApiErrors.unparsable(e.reason));
  }
  final Map<String, Object?> root;
  switch (plain) {
    case null:
      // A comment-only YAML document; KMP reads it as an empty map.
      root = const {};
    case Map<String, Object?>():
      root = plain;
    default:
      return failed(OpenApiErrors.notAMap(_kind(plain)));
  }

  final errors = <String>[];
  final domain = openApiDomain(root);
  final isSwagger = domain == null && root.containsKey('swagger');
  if (isSwagger) {
    errors.add(OpenApiErrors.swagger);
  } else if (domain == null) {
    errors.add(OpenApiErrors.noServer);
  }
  if (root['openapi'] == null && !isSwagger) {
    errors.add(OpenApiErrors.noVersion);
  }

  final paths = root['paths'];
  final functions = <OpenApiFunction>[];
  if (paths is! Map<String, Object?> || paths.isEmpty) {
    errors.add(OpenApiErrors.noPaths);
  } else {
    for (final MapEntry(key: path, value: item) in paths.entries) {
      if (item is! Map<String, Object?>) continue;
      final pathParams = _parameters(item['parameters']);
      for (final method in openApiMethods) {
        final operation = item[method];
        if (operation is! Map<String, Object?>) continue;
        functions.add(_function(method, path, operation, pathParams));
      }
    }
    if (functions.isEmpty) errors.add(OpenApiErrors.noOperations);
  }

  return OpenApiParseResult(
    domain: domain ?? '',
    functions: errors.isEmpty ? List.unmodifiable(functions) : const [],
    errors: List.unmodifiable(errors),
  );
}

/// The action domain: `servers[0].url` verbatim apart from trailing `/`s,
/// because the Server validates `metadata.domain` against that exact string.
/// `null` when there is no non-blank string url.
String? openApiDomain(Map<String, Object?> spec) {
  final servers = spec['servers'];
  if (servers is! List<Object?> || servers.isEmpty) return null;
  final first = servers.first;
  if (first is! Map<String, Object?>) return null;
  final url = first['url'];
  if (url is! String || url.trim().isEmpty) return null;
  final domain = url.replaceFirst(RegExp(r'/+$'), '');
  return domain.isEmpty ? null : domain;
}

/// A parameter entry, as KMP's `ParameterInfo`.
typedef _Parameter = ({
  String name,
  String location,
  bool required,
  String type,
  String? description,
});

OpenApiFunction _function(
  String method,
  String path,
  Map<String, Object?> operation,
  List<_Parameter> pathParams,
) {
  // Path-level first; the operation's parameter wins on a name and `in`
  // clash, keeping the position of the first.
  final merged = <String, _Parameter>{
    for (final p in [...pathParams, ..._parameters(operation['parameters'])])
      '${p.name}:${p.location}': p,
  };
  final properties = <String, Object?>{
    for (final p in merged.values)
      p.name: {
        'type': p.type,
        if (p.description != null) 'description': p.description,
      },
  };
  final required = <String>{
    for (final p in merged.values)
      if (p.required) p.name,
  };
  final schema = _at(operation, [
    'requestBody',
    'content',
    'application/json',
    'schema',
  ]);
  if (schema != null) {
    final bodyProperties = schema['properties'];
    if (bodyProperties is Map<String, Object?>) {
      properties.addAll(bodyProperties);
    }
    final bodyRequired = schema['required'];
    if (bodyRequired is List<Object?>) {
      required.addAll(bodyRequired.whereType<String>());
    }
  }

  final operationId = _nonBlank(operation['operationId']);
  final name = operationId == null ? '' : _sanitize(operationId);

  return OpenApiFunction(
    name: name.isEmpty ? _fallbackName(method, path) : name,
    description:
        _nonBlank(operation['summary']) ??
        _nonBlank(operation['description']) ??
        '$method $path',
    parameters: {
      'type': 'object',
      if (properties.isNotEmpty) 'properties': properties,
      if (required.isNotEmpty) 'required': required.toList(),
    },
    method: method,
    path: path,
  );
}

/// The usable entries of a `parameters` list; ones without a string `name`
/// (such as `$ref`s) are skipped.
List<_Parameter> _parameters(Object? list) {
  if (list is! List<Object?>) return const [];
  final parameters = <_Parameter>[];
  for (final entry in list) {
    if (entry is! Map<String, Object?>) continue;
    final name = entry['name'];
    if (name is! String) continue;
    final location = entry['in'];
    final inValue = location is String ? location : 'query';
    final required = entry['required'];
    final schema = entry['schema'];
    final schemaType = schema is Map<String, Object?> ? schema['type'] : null;
    final type = entry['type'];
    parameters.add((
      name: name,
      location: inValue,
      required: required == null
          ? inValue == 'path'
          : required == true || required == 'true',
      type: schemaType is String
          ? schemaType
          : type is String
          ? type
          : 'string',
      description: _nonBlank(entry['description']),
    ));
  }
  return parameters;
}

/// The map at [keys] under [map], or `null` when any step is not a map.
Map<String, Object?>? _at(Map<String, Object?> map, List<String> keys) {
  Map<String, Object?> current = map;
  for (final key in keys) {
    final next = current[key];
    if (next is! Map<String, Object?>) return null;
    current = next;
  }
  return current;
}

/// `{method}_{path}`: `/users/{id}/posts` gives `get_users_id_posts` (KMP
/// `generateOperationId`), then sanitized.
String _fallbackName(String method, String path) {
  final flat = path
      .replaceAll(RegExp('[{}]'), '')
      .replaceAll(RegExp('[/-]'), '_');
  return _sanitize('${method}_${_trimUnderscores(flat)}');
}

/// A valid function name: `[A-Za-z0-9_]` only, runs of `_` collapsed and none
/// at either end (KMP `sanitizeOperationId`).
String _sanitize(String text) => _trimUnderscores(
  text.replaceAll(RegExp('[^A-Za-z0-9_]'), '_').replaceAll(RegExp('_+'), '_'),
);

String _trimUnderscores(String text) => text.replaceAll(RegExp(r'^_+|_+$'), '');

String? _nonBlank(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// The most values [_plain] produces. A YAML alias is copied each time it is
/// used, so a few lines of aliases (a "billion laughs" spec) could otherwise
/// expand without bound.
const _maxNodes = 100000;

/// The deepest nesting [_plain] follows, well past any real spec.
const _maxDepth = 256;

const _tooDeep = 'The specification is nested too deeply.';

/// A spec past [_maxNodes] or [_maxDepth]; [reason] is user-facing.
final class _TooLarge implements Exception {
  const _TooLarge(this.reason);

  final String reason;
}

/// Turns decoded JSON or YAML into plain Dart values: maps get `String` keys
/// (YAML keys such as `200` become `"200"`), lists become `List<Object?>`.
/// Throws [_TooLarge] past [_maxNodes] values or [_maxDepth] levels.
Object? _plain(Object? value) {
  var nodes = 0;
  Object? convert(Object? value, int depth) {
    if (++nodes > _maxNodes) {
      throw const _TooLarge(
        'The specification expands to more than $_maxNodes values.',
      );
    }
    if (depth > _maxDepth) throw const _TooLarge(_tooDeep);
    return switch (value) {
      Map() => <String, Object?>{
        for (final MapEntry(:key, :value) in value.entries)
          // A collection key is converted too, so its text stays bounded.
          '${key is Map || key is List ? convert(key, depth + 1) : key}':
              convert(value, depth + 1),
      },
      List() => <Object?>[for (final item in value) convert(item, depth + 1)],
      _ => value,
    };
  }

  return convert(value, 0);
}

String _kind(Object value) => switch (value) {
  List() => 'a list',
  String() => 'a string',
  num() => 'a number',
  bool() => 'a boolean',
  _ => 'a ${value.runtimeType}',
};
