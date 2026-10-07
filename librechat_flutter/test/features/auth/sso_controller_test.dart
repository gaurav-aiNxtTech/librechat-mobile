import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/features/auth/sso_controller.dart';

void main() {
  // Ported from KMP SsoNavigationGateTest.
  group('SsoNavigationGate', () {
    SsoNavigationGate gate({
      String serverUrl = 'https://chat.example.com',
      String provider = 'google',
    }) => SsoNavigationGate(serverUrl, provider);

    const allow = SsoNavigationDecision.allow;
    const stop = SsoNavigationDecision.stop;

    test('allows the initial provider navigation', () {
      final g = gate();
      expect(g.decide('https://chat.example.com/oauth/google'), allow);
      expect(g.stopped, isFalse);
    });

    test("allows the provider's own pages", () {
      final g = gate()..decide('https://chat.example.com/oauth/google');
      expect(
        g.decide('https://accounts.google.com/o/oauth2/auth?client_id=x'),
        allow,
      );
    });

    test('allows the server callback itself', () {
      expect(
        gate().decide(
          'https://chat.example.com/oauth/google/callback?code=abc&state=xyz',
        ),
        allow,
      );
    });

    test('stops the redirect that follows the callback', () {
      final g = gate()
        ..decide('https://chat.example.com/oauth/google/callback?code=abc');
      expect(g.decide('https://chat.example.com/'), stop);
      expect(g.stopped, isTrue);
    });

    test('stops the error landing that follows the callback', () {
      final g = gate()
        ..decide('https://chat.example.com/oauth/google/callback?code=abc');
      expect(g.decide('https://chat.example.com/oauth/error'), stop);
    });

    test('stays stopped once stopped', () {
      final g = gate()
        ..decide('https://chat.example.com/oauth/google/callback')
        ..decide('https://chat.example.com/');
      expect(g.decide('https://chat.example.com/c/new'), stop);
    });

    test("does not arm on another provider's callback", () {
      final g = gate()
        ..decide('https://chat.example.com/oauth/github/callback?code=abc');
      expect(g.decide('https://chat.example.com/'), allow);
    });

    test('does not arm on a lookalike host', () {
      final g = gate()
        ..decide('https://evil-chat.example.com/oauth/google/callback?code=a');
      expect(g.decide('https://chat.example.com/'), allow);
    });

    test('tolerates a trailing slash on the server url', () {
      final g = gate(serverUrl: 'https://chat.example.com/')
        ..decide('https://chat.example.com/oauth/google/callback?code=abc');
      expect(g.decide('https://chat.example.com/'), stop);
    });

    test('matches a server mounted under a sub-path', () {
      final g = gate(serverUrl: 'https://example.com/librechat')
        ..decide('https://example.com/librechat/oauth/google/callback?code=a');
      expect(g.decide('https://example.com/librechat/'), stop);
    });

    test('arms when the WebView lower-cases a mixed-case host', () {
      final g = gate(serverUrl: 'https://Chat.Example.com')
        ..decide('https://chat.example.com/oauth/google/callback?code=abc');
      expect(g.decide('https://chat.example.com/'), stop);
    });

    test('a callback-prefixed path on a longer segment does not arm', () {
      final g = gate()
        ..decide('https://chat.example.com/oauth/google/callbackextra');
      expect(g.decide('https://chat.example.com/'), allow);
    });
  });

  group('SsoController', () {
    const server = 'https://chat.example.com/librechat';
    late List<String> log;
    late Map<String, String> jar;
    late Object? exchangeError;
    late SsoController flow;

    setUp(() {
      log = [];
      jar = {};
      exchangeError = null;
      flow = SsoController(
        serverUrl: server,
        provider: 'google',
        clearCookies: () async {
          log.add('clear');
          jar.clear();
        },
        readCookies: () async => {...jar},
        load: (uri) async => log.add('load $uri'),
        exchange: (token) async {
          log.add('exchange $token');
          if (exchangeError case final error?) throw error;
        },
      );
      addTearDown(flow.dispose);
    });

    test('a GET callback: the gate cancels the redirect and the token is '
        'exchanged once, with clears before load and after capture', () async {
      jar['refreshToken'] = 'stale';
      await flow.start();
      expect(log, ['clear', 'load $server/oauth/google']);
      expect(jar, isEmpty);

      expect(
        flow.onNavigationRequest(
          'https://accounts.google.com/o/oauth2/auth',
          isMainFrame: true,
        ),
        isTrue,
      );
      expect(
        flow.onNavigationRequest(
          '$server/oauth/google/callback?code=abc',
          isMainFrame: true,
        ),
        isTrue,
      );
      jar['refreshToken'] = 'rt-1';
      // The Server's redirect to its web app is cancelled (Req 13.4).
      expect(
        flow.onNavigationRequest('$server/c/new', isMainFrame: true),
        isFalse,
      );
      // Later events for the same round-trip change nothing.
      flow
        ..onUrlChange('$server/c/new')
        ..onPageFinished('$server/c/new');
      await pumpEventQueue();

      expect(log, [
        'clear',
        'load $server/oauth/google',
        'load about:blank',
        'clear',
        'exchange rt-1',
      ]);
      expect(jar, isEmpty);
      expect(flow.exchanging, isTrue);
      expect(flow.failure, isNull);
    });

    test('a POST callback: the cookie probe finishes on the Server', () async {
      await flow.start();
      flow.onUrlChange('https://appleid.apple.com/auth/authorize');
      jar['refreshToken'] = 'rt-2';
      flow
        ..onPageFinished('$server/c/new')
        ..onPageFinished('$server/c/new');
      await pumpEventQueue();
      expect(log.where((e) => e.startsWith('exchange')), ['exchange rt-2']);
    });

    test('back on the Server without the cookie shows the failure, and Retry '
        'restarts from the clear', () async {
      await flow.start();
      flow.onUrlChange('https://accounts.google.com/o/oauth2/auth');
      flow.onPageFinished('$server/oauth/error?error=AUTH_FAILED');
      await pumpEventQueue();
      expect(flow.failure, (message: ssoSignInFailed, code: 'AUTH_FAILED'));
      expect(log.where((e) => e.startsWith('exchange')), isEmpty);

      log.clear();
      await flow.start();
      expect(flow.failure, isNull);
      expect(log, ['clear', 'load $server/oauth/google']);
    });

    test(
      'a Server page before leaving for the provider is not a failure',
      () async {
        await flow.start();
        flow.onPageFinished('$server/oauth/saml');
        await pumpEventQueue();
        expect(flow.failure, isNull);
      },
    );

    test('an exchange error shows its userMessage with Retry', () async {
      exchangeError = AppException(FailureKind.network);
      await flow.start();
      flow.onUrlChange('https://accounts.google.com/');
      jar['refreshToken'] = 'rt-3';
      flow.onPageFinished('$server/');
      await pumpEventQueue();
      expect(flow.exchanging, isFalse);
      expect(flow.failure?.message, userMessage(exchangeError!));
    });
  });
}
