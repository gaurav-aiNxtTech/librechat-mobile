import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';

String messageFor(
  FailureKind kind, {
  int? status,
  String? message,
  bool signedIn = true,
}) => userMessage(
  AppException(kind, status: status, message: message, signedIn: signedIn),
);

void main() {
  group('userMessage gives each kind its KMP copy', () {
    test('network, timeout and malformed', () {
      expect(
        messageFor(FailureKind.network),
        'Network unavailable. Check your connection.',
      );
      expect(
        messageFor(FailureKind.timeout),
        'The server took too long to respond.',
      );
      expect(
        messageFor(FailureKind.malformed),
        'Unexpected response from the server.',
      );
    });

    test('unsupported, sessionExpired and unknown', () {
      expect(
        messageFor(FailureKind.unsupported),
        'This feature is not supported on your server version.',
      );
      expect(
        messageFor(FailureKind.sessionExpired),
        'Your session has expired. Sign in again to continue.',
      );
      expect(
        messageFor(FailureKind.unknown),
        'Something went wrong. Please try again.',
      );
    });

    test('gateway points to Settings when signed in', () {
      expect(
        messageFor(FailureKind.gateway),
        "Your server's access gateway rejected this request. "
        'Check Server connection in Settings.',
      );
    });

    test('gateway points to Advanced when signed out', () {
      expect(
        messageFor(FailureKind.gateway, signedIn: false),
        "Your server's access gateway rejected this request. "
        'Check the gateway headers under Advanced.',
      );
    });

    test('server falls back by status', () {
      expect(messageFor(FailureKind.server, status: 400), 'Bad request');
      expect(messageFor(FailureKind.server, status: 403), 'Access denied');
      expect(messageFor(FailureKind.server, status: 404), 'Not found');
      expect(
        messageFor(FailureKind.server, status: 429),
        'Too many requests. Please try again later.',
      );
      expect(
        messageFor(FailureKind.server, status: 500),
        'Server error. Please try again later.',
      );
      expect(
        messageFor(FailureKind.server, status: 599),
        'Server error. Please try again later.',
      );
      expect(
        messageFor(FailureKind.server, status: 418),
        'Request failed (HTTP 418)',
      );
      expect(
        messageFor(FailureKind.server),
        'Something went wrong. Please try again.',
      );
    });

    test('any other error gets the unknown copy', () {
      expect(
        userMessage(StateError('https://host/?token=abc')),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('server message', () {
    test('is shown when it reads as a sentence', () {
      expect(
        messageFor(
          FailureKind.server,
          status: 401,
          message: 'Invalid credentials',
        ),
        'Invalid credentials',
      );
      expect(
        messageFor(FailureKind.server, status: 400, message: '  Email taken  '),
        'Email taken',
      );
    });

    test('is ignored for kinds other than server', () {
      expect(
        messageFor(FailureKind.gateway, message: 'Invalid credentials'),
        startsWith("Your server's access gateway"),
      );
    });

    test('falls back to the status copy for HTML, URLs and long bodies', () {
      final rejected = [
        '<html><body>Sign in</body></html>',
        'Redirecting to https://team.cloudflareaccess.com/login?token=x',
        'line one\nline two',
        'line one\rline two',
        'a' * 41,
        'Bad token ${'x' * 41} here',
        ('word ' * 41).trim(),
        '   ',
      ];
      for (final body in rejected) {
        expect(
          messageFor(FailureKind.server, status: 403, message: body),
          'Access denied',
          reason: body,
        );
      }
    });

    test('is shown at 200 characters after trimming and not at 201', () {
      final at200 = '${'abcd ' * 39}abcde';
      expect(at200.length, 200);
      expect(
        messageFor(FailureKind.server, status: 500, message: '  $at200 \n'),
        at200,
      );
      expect(
        messageFor(FailureKind.server, status: 500, message: '${at200}f'),
        'Server error. Please try again later.',
      );
    });

    test('falls back when it contains >', () {
      expect(
        messageFor(
          FailureKind.server,
          status: 400,
          message: 'Value must be > 0',
        ),
        'Bad request',
      );
    });
  });

  group('looksLikeUserMessage', () {
    test('accepts up to the limits', () {
      expect(looksLikeUserMessage('a' * 40), isTrue);
      expect(looksLikeUserMessage(('abcd ' * 40).trim()), isTrue);
      expect(looksLikeUserMessage('Access denied'), isTrue);
    });

    test('rejects past the limits', () {
      expect(looksLikeUserMessage(''), isFalse);
      expect(looksLikeUserMessage('a' * 41), isFalse);
      expect(looksLikeUserMessage('${'abcd ' * 40}x'), isFalse);
      expect(looksLikeUserMessage('see <b>here</b>'), isFalse);
      expect(looksLikeUserMessage('go to https://example.com'), isFalse);
    });
  });

  test('toString leaves out the server message', () {
    final text = AppException(
      FailureKind.server,
      status: 500,
      message: 'secret-token',
    ).toString();
    expect(text, isNot(contains('secret-token')));
    expect(text, contains('server'));
  });
}
