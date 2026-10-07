import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/server_url.dart';

String? urlOf(String input) => normalizeServerUrl(input).url;
UrlProblem? problemOf(String input) => normalizeServerUrl(input).problem;

void main() {
  group('normalizeServerUrl accepts', () {
    test('prefixes https:// when no scheme is written', () {
      expect(urlOf('localhost:3080'), 'https://localhost:3080');
      expect(urlOf('chat.example.com'), 'https://chat.example.com');
    });

    test('trims and lowercases the scheme and the host', () {
      expect(urlOf('  HTTP://Chat.Example.COM  '), 'http://chat.example.com');
    });

    test('drops the default port and keeps any other', () {
      expect(urlOf('https://host:443'), 'https://host');
      expect(urlOf('http://host:80/app'), 'http://host/app');
      expect(urlOf('http://host:443'), 'http://host:443');
      expect(urlOf('https://host:8443'), 'https://host:8443');
    });

    test('strips user info up to the last @', () {
      expect(urlOf('https://user:p@ss@host:3080/x'), 'https://host:3080/x');
    });

    test('drops the query and the fragment', () {
      expect(urlOf('https://host/app?a=1#top'), 'https://host/app');
      expect(urlOf('https://host#frag'), 'https://host');
      expect(urlOf('https://host?a=/b'), 'https://host');
    });

    test('removes trailing slashes and keeps the path case', () {
      expect(urlOf('https://Host/LibreChat///'), 'https://host/LibreChat');
      expect(urlOf('https://host/'), 'https://host');
    });

    test('keeps an IPv6 literal and splits its port', () {
      expect(urlOf('http://[::1]:3080'), 'http://[::1]:3080');
      expect(urlOf('https://[FE80::1]:443/'), 'https://[fe80::1]');
    });

    test(
      'strips whitespace before a query or fragment and at the path end',
      () {
        expect(urlOf('https://h/a ?q'), 'https://h/a');
        expect(urlOf('https://h/a\t#f'), 'https://h/a');
        expect(urlOf('https://h ?q'), 'https://h');
        expect(urlOf('https://h/a/ /'), 'https://h/a');
        expect(urlOf('https://h/a/ / ?q'), 'https://h/a');
        expect(urlOf('https://h/ /'), 'https://h');
      },
    );

    test('strips whitespace between the host and the first /', () {
      final once = urlOf('https://h /')!;
      expect(once, 'https://h');
      expect(normalizeServerUrl(once), (url: once, problem: null));
      expect(urlOf('https://localhost\t/'), 'https://localhost');
    });

    test('returns its own output unchanged', () {
      for (final input in [
        'localhost:3080',
        ' HTTPS://u@Host:443/A/b//?q#f ',
        'http://[::1]:80/x/',
        'https://h/a ?q',
        'https://h ?q',
        'https://h/a/ / ?q',
        'https://h/a\u0085?q',
      ]) {
        final once = urlOf(input)!;
        expect(normalizeServerUrl(once), (url: once, problem: null));
      }
    });
  });

  group('normalizeServerUrl rejects', () {
    test('an empty input', () {
      expect(problemOf(''), UrlProblem.empty);
      expect(problemOf('   '), UrlProblem.empty);
    });

    test('a scheme other than http or https', () {
      expect(problemOf('ftp://host'), UrlProblem.scheme);
      expect(problemOf('://host'), UrlProblem.scheme);
    });

    test('an empty host', () {
      expect(problemOf('https://'), UrlProblem.host);
      expect(problemOf('https://user@:3080/x'), UrlProblem.host);
      expect(problemOf('https:// ?q'), UrlProblem.host);
      expect(problemOf('https:// /x'), UrlProblem.host);
    });

    test('a host with a colon outside an IPv6 literal', () {
      expect(problemOf('https://a:b:443'), UrlProblem.host);
      expect(problemOf('https://a:b:3080/x'), UrlProblem.host);
      expect(problemOf('http://[::1]:x:80'), UrlProblem.host);
      expect(problemOf('https://[::1:443'), UrlProblem.host);
      expect(urlOf('https://[::1]:443'), 'https://[::1]');
    });

    test('a port that is not a number from 1 to 65535', () {
      for (final input in [
        'host:0',
        'host:65536',
        'host:abc',
        'host:-1',
        'host:',
      ]) {
        expect(problemOf(input), UrlProblem.port, reason: input);
      }
      expect(urlOf('host:65535'), 'https://host:65535');
      expect(urlOf('host:1'), 'https://host:1');
    });

    test('with the first reason that applies', () {
      expect(problemOf('ftp://'), UrlProblem.scheme);
      expect(problemOf('ftp://host:99999'), UrlProblem.scheme);
      expect(problemOf('https://:99999'), UrlProblem.host);
    });

    test('with the reason copy', () {
      expect(UrlProblem.empty.message, 'Please enter a server URL');
      expect(UrlProblem.scheme.message, 'Use an http:// or https:// URL');
      expect(UrlProblem.host.message, "Enter the server's host name");
      expect(UrlProblem.port.message, 'Port must be a number from 1 to 65535');
    });
  });

  group('isServerAuthority', () {
    const server = 'https://chat.example.com/librechat';

    test('matches the same scheme, host and port, filling in defaults', () {
      expect(
        isServerAuthority(Uri.parse('https://chat.example.com/api'), server),
        isTrue,
      );
      expect(
        isServerAuthority(Uri.parse('https://CHAT.example.com:443/x'), server),
        isTrue,
      );
      expect(
        isServerAuthority(
          Uri.parse('http://localhost/api'),
          'http://localhost:80',
        ),
        isTrue,
      );
    });

    test('rejects another scheme, host or port', () {
      expect(
        isServerAuthority(Uri.parse('http://chat.example.com/api'), server),
        isFalse,
      );
      expect(
        isServerAuthority(Uri.parse('https://cdn.example.com/api'), server),
        isFalse,
      );
      expect(
        isServerAuthority(Uri.parse('https://chat.example.com:8443/'), server),
        isFalse,
      );
      expect(
        isServerAuthority(
          Uri.parse('https://localhost/api'),
          'https://localhost:3080',
        ),
        isFalse,
      );
    });
  });

  group('serverUri', () {
    const server = 'https://chat.example.com/librechat';

    test('keeps the Server_URL subpath', () {
      expect(
        serverUri(server, '/api/config').toString(),
        'https://chat.example.com/librechat/api/config',
      );
      expect(
        serverUri(server, 'api/config').toString(),
        'https://chat.example.com/librechat/api/config',
      );
    });

    test('keeps a query in the path', () {
      final uri = serverUri(server, '/api/convos?cursor=abc&limit=25');
      expect(uri.path, '/librechat/api/convos');
      expect(uri.queryParameters, {'cursor': 'abc', 'limit': '25'});
    });

    test('works without a subpath', () {
      expect(
        serverUri('http://localhost:3080', '/api/config').toString(),
        'http://localhost:3080/api/config',
      );
    });

    test('passes an absolute http(s) URL through unchanged', () {
      const absolute = 'https://cdn.example.com/images/a.png?x=1';
      expect(serverUri(server, absolute), Uri.parse(absolute));
      expect(serverUri(server, 'http://other/x').toString(), 'http://other/x');
    });
  });
}
