import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_api.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';

/// One `classifyRefresh` input and the outcome it should give.
typedef _Case = ({
  String name,
  int status,
  Map<String, List<String>> headers,
  String body,
  String serverUrl,
  Matcher outcome,
});

const _server = 'https://chat.example.com';
const _subpath = 'https://chat.example.com/librechat';

_Case _case(
  String name,
  int status, {
  String body = '',
  Map<String, List<String>> headers = const {},
  String serverUrl = _server,
  required Matcher outcome,
}) => (
  name: name,
  status: status,
  headers: headers,
  body: body,
  serverUrl: serverUrl,
  outcome: outcome,
);

Matcher _rejected(int status) =>
    isA<RefreshRejected>().having((r) => r.status, 'status', status);

Matcher _failed(FailureKind kind, int status) => isA<RefreshFailed>()
    .having((r) => r.error.kind, 'error.kind', kind)
    .having((r) => r.error.status, 'error.status', status);

/// Alternates upper and lower case: `InVaLiD ReFrEsH ToKeN`.
String _mixedCase(String text) => [
  for (var i = 0; i < text.length; i++)
    i.isEven ? text[i].toUpperCase() : text[i].toLowerCase(),
].join();

void main() {
  group('classifyRefresh', () {
    final cases = <_Case>[
      // The five LibreChat rejection bodies, as 401 and 403, in mixed case,
      // as plain text and inside a JSON message.
      for (final body in refreshRejectionBodies)
        for (final status in const [401, 403]) ...[
          _case(
            '$status "$body" in mixed case',
            status,
            body: _mixedCase(body),
            outcome: _rejected(status),
          ),
          _case(
            '$status JSON message "$body"',
            status,
            body: jsonEncode({'message': body.toUpperCase()}),
            outcome: _rejected(status),
          ),
        ],
      _case(
        '200 "Refresh token not provided"',
        200,
        body: 'Refresh token not provided',
        outcome: _rejected(200),
      ),
      _case(
        '302 to /login',
        302,
        headers: {
          'location': ['/login'],
        },
        outcome: _rejected(302),
      ),
      _case(
        '302 to the absolute same-authority /login',
        302,
        headers: {
          'location': ['https://CHAT.example.com:443/login'],
        },
        outcome: _rejected(302),
      ),
      _case(
        '302 to {subpath}/login',
        302,
        headers: {
          'location': ['/librechat/login'],
        },
        serverUrl: _subpath,
        outcome: _rejected(302),
      ),
      _case(
        '302 to the absolute {subpath}/login',
        302,
        headers: {
          'location': ['https://chat.example.com/librechat/login'],
        },
        serverUrl: _subpath,
        outcome: _rejected(302),
      ),
      _case(
        '302 to the root /login under a subpath',
        302,
        headers: {
          'location': ['/login'],
        },
        serverUrl: _subpath,
        outcome: _rejected(302),
      ),

      // Failures: the session stays.
      _case(
        '302 to another host /login (a portal)',
        302,
        headers: {
          'location': ['https://auth.example.com/login'],
        },
        outcome: _failed(FailureKind.server, 302),
      ),
      _case(
        '302 to a protocol-relative //other/login',
        302,
        headers: {
          'location': ['//other.example.com/login'],
        },
        outcome: _failed(FailureKind.server, 302),
      ),
      _case(
        '302 to another same-authority path',
        302,
        headers: {
          'location': ['/oauth/start'],
        },
        outcome: _failed(FailureKind.server, 302),
      ),
      _case(
        '302 without a location',
        302,
        outcome: _failed(FailureKind.server, 302),
      ),
      _case(
        '403 with an unrelated body (a WAF)',
        403,
        body: jsonEncode({'message': 'Request blocked by firewall'}),
        outcome: _failed(FailureKind.server, 403),
      ),
      _case(
        '403 HTML page',
        403,
        body: '<!DOCTYPE html><html><body>Forbidden</body></html>',
        outcome: _failed(FailureKind.server, 403),
      ),
      _case(
        '401 with an unrelated body',
        401,
        body: 'Unauthorized',
        outcome: _failed(FailureKind.server, 401),
      ),
      _case(
        '500 with a rejection-like body',
        500,
        body: 'No session found',
        outcome: _failed(FailureKind.server, 500),
      ),
      _case(
        '500',
        500,
        body: 'Internal Server Error',
        outcome: _failed(FailureKind.server, 500),
      ),
      _case(
        '200 without a token',
        200,
        body: jsonEncode({
          'user': {'_id': 'u1'},
        }),
        outcome: _failed(FailureKind.malformed, 200),
      ),
      _case(
        '200 with an empty token',
        200,
        body: jsonEncode({'token': ''}),
        outcome: _failed(FailureKind.malformed, 200),
      ),
      _case(
        '200 with a non-string token',
        200,
        body: jsonEncode({'token': 42}),
        outcome: _failed(FailureKind.malformed, 200),
      ),
      _case(
        '200 with a non-JSON body',
        200,
        body: 'OK',
        outcome: _failed(FailureKind.malformed, 200),
      ),
      _case(
        '204 with no body',
        204,
        outcome: _failed(FailureKind.malformed, 204),
      ),
      _case(
        '403 "Refresh token not provided" (only a 200 is a rejection)',
        403,
        body: 'Refresh token not provided',
        outcome: _failed(FailureKind.server, 403),
      ),
    ];

    for (final c in cases) {
      test(c.name, () {
        expect(
          classifyRefresh(c.status, c.headers, c.body, c.serverUrl),
          c.outcome,
        );
      });
    }

    test('a failure keeps the Server message', () {
      final result = classifyRefresh(
        503,
        const {},
        jsonEncode({'message': 'Maintenance'}),
        _server,
      );
      expect(
        result,
        isA<RefreshFailed>().having(
          (r) => r.error.message,
          'message',
          'Maintenance',
        ),
      );
    });

    test('success with a rotated Set-Cookie refreshToken and a user', () {
      final result = classifyRefresh(
        200,
        const {
          'set-cookie': ['refreshToken=refresh-2; Path=/; HttpOnly; Secure'],
        },
        jsonEncode({
          'token': 'access-2',
          'user': {'_id': 'u1', 'email': 'user@example.com'},
        }),
        _server,
      );

      expect(result, isA<RefreshSuccess>());
      final success = result as RefreshSuccess;
      expect(success.accessToken, 'access-2');
      expect(success.refreshToken, 'refresh-2');
      expect(success.user?.id, 'u1');
      expect(success.user?.email, 'user@example.com');
    });

    test('success without a cookie gives a null refreshToken', () {
      final result = classifyRefresh(
        200,
        const {},
        jsonEncode({'token': 'access-2'}),
        _server,
      );

      expect(result, isA<RefreshSuccess>());
      final success = result as RefreshSuccess;
      expect(success.accessToken, 'access-2');
      expect(success.refreshToken, isNull);
      expect(success.user, isNull);
    });

    test('success with a user that does not decode gives a null user', () {
      final result = classifyRefresh(
        200,
        const {},
        jsonEncode({
          'token': 'access-2',
          'user': {'email': 'no-id@example.com'},
        }),
        _server,
      );

      expect(
        result,
        isA<RefreshSuccess>().having((r) => r.user, 'user', isNull),
      );
    });
  });

  group('refreshTokenFrom', () {
    test('null and empty lists give null', () {
      expect(refreshTokenFrom(null), isNull);
      expect(refreshTokenFrom(const []), isNull);
    });

    test('finds refreshToken among several Set-Cookie lines', () {
      expect(
        refreshTokenFrom(const [
          'token_provider=librechat; Path=/',
          'refreshToken=refresh-2; Path=/; HttpOnly',
          'openid_user_id=abc; Path=/',
        ]),
        'refresh-2',
      );
    });

    test('skips an empty value and takes the next one', () {
      expect(
        refreshTokenFrom(const [
          'refreshToken=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
          'refreshToken=refresh-3; Path=/',
        ]),
        'refresh-3',
      );
      expect(refreshTokenFrom(const ['refreshToken=; Path=/']), isNull);
    });

    test('ignores the attributes', () {
      expect(
        refreshTokenFrom(const [
          'refreshToken=abc.def-ghi; Expires=Wed, 21 Oct 2026 07:28:00 GMT; '
              'Max-Age=604800; Path=/; Secure; HttpOnly; SameSite=Strict',
        ]),
        'abc.def-ghi',
      );
      expect(
        refreshTokenFrom(const ['other=x; refreshToken=attr-value']),
        isNull,
      );
    });

    test('does not match another letter case', () {
      expect(
        refreshTokenFrom(const [
          'refreshtoken=lower; Path=/',
          'REFRESHTOKEN=upper; Path=/',
        ]),
        isNull,
      );
    });
  });
}
