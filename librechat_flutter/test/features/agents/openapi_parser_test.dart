// 27.6 covers only the OpenAPI error cases here; marketplace paging and
// debounce, actions hidden by permission bits and the dirty-draft prompt are
// tested with 27.1 and 27.5.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/agents/openapi_parser.dart';

const _noServer =
    "No server URL found. Add a 'servers' array with at least one entry.";
const _noVersion = "Missing 'openapi' version field.";
const _noPaths = 'No paths found in the specification.';
const _parseError =
    'Failed to parse specification: Not valid JSON or YAML.\nYAML error: ';

/// A valid spec with one operation, with [overrides] applied; a `null`
/// override removes the key.
String _spec([Map<String, Object?> overrides = const {}]) {
  final spec = <String, Object?>{
    'openapi': '3.0.0',
    'info': {'title': 'T', 'version': '1'},
    'servers': [
      {'url': 'https://api.example.com/v1/'},
    ],
    'paths': {
      '/items': {
        'get': {'operationId': 'listItems'},
      },
    },
    ...overrides,
  }..removeWhere((_, value) => value == null);
  return jsonEncode(spec);
}

/// The single function derived from a valid spec with [paths].
Map<String, Object?> _onlyFunction(Map<String, Object?> paths) {
  final result = parseOpenApiSpec(_spec({'paths': paths}));
  expect(result.errors, isEmpty);
  expect(result.functions, hasLength(1));
  return result.functions.single.toJson()['function']! as Map<String, Object?>;
}

void _expectErrors(
  OpenApiParseResult result,
  List<String> errors, {
  String domain = '',
}) {
  expect(result.errors, errors);
  expect(result.functions, isEmpty);
  expect(result.domain, domain);
  expect(result.isValid, isFalse);
}

void main() {
  group('error cases', () {
    test('an empty or blank spec', () {
      for (final text in ['', '   \n\t']) {
        _expectErrors(parseOpenApiSpec(text), ['Specification is empty']);
      }
      expect(OpenApiErrors.empty, 'Specification is empty');
    });

    test('text that is neither JSON nor YAML', () {
      for (final text in ['{"openapi": "3.0.0",', 'openapi: [3.0']) {
        final result = parseOpenApiSpec(text);
        expect(result.errors, hasLength(1), reason: text);
        expect(result.errors.single, startsWith(_parseError), reason: text);
        expect(result.errors.single, contains('(line '), reason: text);
        expect(result.functions, isEmpty);
        expect(result.domain, '');
      }
    });

    test('the parse error does not quote the spec text', () {
      final result = parseOpenApiSpec('secret-token: [unclosed');
      expect(result.errors.single, isNot(contains('secret-token')));
    });

    test('a root that is not a map', () {
      const prefix =
          'Failed to parse specification: Expected a YAML mapping (object) at '
          'the root, but got ';
      for (final (text, kind) in [
        ('[1, 2]', 'a list'),
        ('- a\n- b', 'a list'),
        ('hello', 'a string'),
        ('42', 'a number'),
        ('true', 'a boolean'),
      ]) {
        _expectErrors(parseOpenApiSpec(text), ['$prefix$kind.']);
      }
    });

    test('a comment-only document reads as an empty map', () {
      _expectErrors(parseOpenApiSpec('# nothing here'), [
        _noServer,
        _noVersion,
        _noPaths,
      ]);
    });

    test('no usable servers[0].url', () {
      for (final servers in <Object?>[
        null,
        <Object?>[],
        'https://x',
        [
          {'description': 'x'},
        ],
        [
          {'url': '  '},
        ],
        [
          {'url': 7},
        ],
        [
          {'url': '///'},
        ],
        ['https://x'],
      ]) {
        _expectErrors(parseOpenApiSpec(_spec({'servers': servers})), [
          _noServer,
        ]);
      }
    });

    test('a Swagger 2.0 spec', () {
      final text = jsonEncode({
        'swagger': '2.0',
        'host': 'api.example.com',
        'basePath': '/v1',
        'paths': {
          '/items': {
            'get': {'operationId': 'listItems'},
          },
        },
      });
      _expectErrors(parseOpenApiSpec(text), [
        "This is a Swagger 2.0 specification. The server requires an OpenAPI "
            "3 'servers' array — convert the spec, or add 'servers' with the "
            "full base URL.",
      ]);
    });

    test('no openapi field', () {
      _expectErrors(
        parseOpenApiSpec(_spec({'openapi': null})),
        [_noVersion],
        domain: 'https://api.example.com/v1',
      );
    });

    test('paths missing, empty or not a map', () {
      for (final paths in <Object?>[
        null,
        <String, Object?>{},
        ['a'],
      ]) {
        _expectErrors(
          parseOpenApiSpec(_spec({'paths': paths})),
          [_noPaths],
          domain: 'https://api.example.com/v1',
        );
      }
    });

    test('paths without operations', () {
      final text = _spec({
        'paths': {
          '/a': {
            'parameters': <Object?>[],
            'summary': 's',
            'trace': <String, Object?>{},
          },
          '/b': 'x',
        },
      });
      _expectErrors(parseOpenApiSpec(text), [
        'No operations found in paths.',
      ], domain: 'https://api.example.com/v1');
    });

    test('errors accumulate in order', () {
      _expectErrors(parseOpenApiSpec('{"info": {"title": "T"}}'), [
        _noServer,
        _noVersion,
        _noPaths,
      ]);
    });

    test('never throws on odd input', () {
      for (final text in [
        'openapi: 3.0.0\nopenapi: 3.1.0\n',
        '{"openapi": "3.0.0", "paths": {"/a": {"get": 5}}}',
        'openapi: 3.0.0\npaths:\n  /a:\n    get:\n      responses:\n'
            '        200: {description: ok}\n',
        'paths: {"/a": {"get": {"parameters": [1, {"in": "query"}, null]}}}',
        '~: x',
        'null',
      ]) {
        expect(() => parseOpenApiSpec(text), returnsNormally, reason: text);
      }
    });
  });

  group('domain', () {
    String domainOf(List<Object?> servers) =>
        parseOpenApiSpec(_spec({'servers': servers})).domain;

    test('drops trailing slashes only', () {
      expect(
        domainOf([
          {'url': 'https://api.example.com/'},
        ]),
        'https://api.example.com',
      );
      expect(
        domainOf([
          {'url': 'https://h:8443/v1//'},
        ]),
        'https://h:8443/v1',
      );
      expect(
        domainOf([
          {'url': 'https://h:443/v1'},
        ]),
        'https://h:443/v1',
      );
    });

    test('uses servers[0] only', () {
      expect(
        domainOf([
          {'url': 'https://first.example'},
          {'url': 'https://second.example'},
        ]),
        'https://first.example',
      );
    });

    test('openApiDomain reads a spec map', () {
      expect(
        openApiDomain({
          'servers': [
            {'url': 'https://x.example/'},
          ],
        }),
        'https://x.example',
      );
      expect(openApiDomain({}), isNull);
    });
  });

  group('functions', () {
    test('one per method, in method order', () {
      final result = parseOpenApiSpec(
        _spec({
          'paths': {
            '/a': {
              for (final method in openApiMethods.reversed)
                method: <String, Object?>{},
              'trace': <String, Object?>{},
            },
          },
        }),
      );
      expect(result.isValid, isTrue);
      expect([for (final f in result.functions) f.method], openApiMethods);
      expect([for (final f in result.functions) f.path], everyElement('/a'));
      expect(result.functions.first.name, 'get_a');
    });

    test('toJson has the Server wire shape', () {
      final result = parseOpenApiSpec(_spec());
      expect(result.domain, 'https://api.example.com/v1');
      expect(result.functions.single.toJson(), {
        'type': 'function',
        'function': {
          'name': 'listItems',
          'description': 'get /items',
          'parameters': {'type': 'object'},
        },
      });
    });

    test('name comes from a sanitized operationId', () {
      final function = _onlyFunction({
        '/a': {
          'get': {'operationId': 'get user-by.id!'},
        },
      });
      expect(function['name'], 'get_user_by_id');
    });

    test('name falls back to method and path', () {
      for (final operationId in [null, '   ', '!!!']) {
        final function = _onlyFunction({
          '/users/{id}/posts': {
            'get': {'operationId': ?operationId},
          },
        });
        expect(function['name'], 'get_users_id_posts', reason: operationId);
      }
    });

    test('description is the summary, else the description', () {
      String descriptionOf(Map<String, Object?> operation) =>
          _onlyFunction({
                '/items': {'post': operation},
              })['description']!
              as String;

      expect(descriptionOf({'summary': 'S', 'description': 'D'}), 'S');
      expect(descriptionOf({'summary': '  ', 'description': 'D'}), 'D');
      expect(descriptionOf({'description': ' '}), 'post /items');
      expect(descriptionOf({}), 'post /items');
    });

    test('parameters merge path-level and operation entries', () {
      final function = _onlyFunction({
        '/users/{id}': {
          'parameters': [
            {'name': 'id', 'in': 'path', 'schema': <String, Object?>{}},
            {
              'name': 'limit',
              'in': 'query',
              'schema': {'type': 'string'},
              'description': 'path-level',
            },
            {
              'name': 'trace',
              'in': 'header',
              'required': true,
              'type': 'string',
            },
          ],
          'get': {
            'parameters': [
              {
                'name': 'limit',
                'in': 'query',
                'required': true,
                'schema': {'type': 'integer'},
                'description': 'Max rows',
              },
              {'name': 'trace', 'in': 'cookie', 'required': false},
              {'name': 'flag', 'in': 'query', 'type': 'boolean'},
              {'name': 'off', 'in': 'path', 'required': false},
              {r'$ref': '#/components/parameters/x'},
            ],
          },
        },
      });
      expect(function['parameters'], {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'limit': {'type': 'integer', 'description': 'Max rows'},
          'trace': {'type': 'string'},
          'flag': {'type': 'boolean'},
          'off': {'type': 'string'},
        },
        // The header `trace` is not replaced by the cookie one, so its
        // required name stays; the later entry's schema wins under `trace`.
        'required': ['id', 'limit', 'trace'],
      });
    });

    test('request body properties and required names are merged', () {
      final function = _onlyFunction({
        '/items': {
          'post': {
            'parameters': [
              {'name': 'dry', 'in': 'query', 'required': 'true'},
            ],
            'requestBody': {
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string', 'default': 'x'},
                      'dry': {'type': 'boolean'},
                    },
                    'required': ['name', 'dry', 5],
                  },
                },
                'text/plain': {
                  'schema': {
                    'properties': {
                      'ignored': {'type': 'string'},
                    },
                  },
                },
              },
            },
          },
        },
      });
      expect(function['parameters'], {
        'type': 'object',
        'properties': {
          'dry': {'type': 'boolean'},
          'name': {'type': 'string', 'default': 'x'},
        },
        'required': ['dry', 'name'],
      });
    });

    test('YAML and its JSON twin give the same result', () {
      const yaml = '''
openapi: 3.1.0
servers:
  - url: https://h.example:8443/api/
paths:
  /pets/{petId}:
    parameters:
      - name: petId
        in: path
        schema:
          type: string
    get:
      operationId: getPet
      summary: Get a pet
      responses:
        200:
          description: ok
    delete: {}
''';
      final json = jsonEncode({
        'openapi': '3.1.0',
        'servers': [
          {'url': 'https://h.example:8443/api/'},
        ],
        'paths': {
          '/pets/{petId}': {
            'parameters': [
              {
                'name': 'petId',
                'in': 'path',
                'schema': {'type': 'string'},
              },
            ],
            'get': {
              'operationId': 'getPet',
              'summary': 'Get a pet',
              'responses': {
                '200': {'description': 'ok'},
              },
            },
            'delete': <String, Object?>{},
          },
        },
      });
      final fromYaml = parseOpenApiSpec(yaml);
      final fromJson = parseOpenApiSpec(json);
      expect(fromYaml.errors, isEmpty);
      expect(fromYaml.domain, 'https://h.example:8443/api');
      expect(fromYaml.domain, fromJson.domain);
      expect(
        [for (final f in fromYaml.functions) f.toJson()],
        [for (final f in fromJson.functions) f.toJson()],
      );
      expect(
        [for (final f in fromYaml.functions) f.name],
        ['getPet', 'delete_pets_petId'],
      );
    });

    test('tab-indented JSON parses', () {
      final result = parseOpenApiSpec(
        '{\n\t"openapi": "3.0.0",\n\t"servers": [{"url": "https://x.example"}],'
        '\n\t"paths": {"/a": {"get": {}}}\n}',
      );
      expect(result.errors, isEmpty);
      expect(result.domain, 'https://x.example');
      expect(result.functions.single.name, 'get_a');
    });
  });
}
