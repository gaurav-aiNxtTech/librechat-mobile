import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/config/server_version.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';

Version v(String text) => Version.parse(text)!;

void main() {
  group('Version.parse', () {
    test('accepts plain, v-prefixed, prerelease and build forms', () {
      expect(Version.parse('0.8.8'), const Version(0, 8, 8));
      expect(Version.parse('v0.8.8-rc4'), const Version(0, 8, 8, 'rc4'));
      expect(Version.parse('v0.8.8-rc4+abc'), const Version(0, 8, 8, 'rc4'));
      expect(Version.parse('v0.8.8-rc4+abc').toString(), '0.8.8-rc4');
    });

    test('rejects other text', () {
      expect(Version.parse('0.8'), isNull);
      expect(Version.parse('latest'), isNull);
      expect(Version.parse(''), isNull);
    });
  });

  group('ordering', () {
    test('rc9 < rc10', () {
      expect(v('0.8.8-rc9') < v('0.8.8-rc10'), isTrue);
    });

    test('0.8.8-rc1 < 0.8.8-rc4 < 0.8.8 (Req 6.4)', () {
      expect(v('0.8.8-rc1') < v('0.8.8-rc4'), isTrue);
      expect(v('0.8.8-rc4') < v('0.8.8'), isTrue);
      expect(v('0.8.8') > v('0.8.8-rc1'), isTrue);
    });

    test('0.7.3-rc < 0.7.3-rc1', () {
      expect(v('0.7.3-rc') < v('0.7.3-rc1'), isTrue);
    });

    test('0.8.7 < 0.8.8-rc1', () {
      expect(v('0.8.7') < v('0.8.8-rc1'), isTrue);
    });

    test('equality agrees with compareTo', () {
      expect(v('0.8.8-rc.4'), v('0.8.8-rc4'));
      expect(v('0.8.8-rc.4').hashCode, v('0.8.8-rc4').hashCode);
      expect(v('0.8.8') == v('0.8.8-rc4'), isFalse);
    });
  });

  test('sameRelease compares major.minor.patch only', () {
    expect(v('0.8.8').sameRelease(v('0.8.8-rc4')), isTrue);
    expect(v('0.8.7').sameRelease(v('0.8.8-rc4')), isFalse);
  });

  group('UPSTREAM_VERSION', () {
    final fields = {
      for (final line in File('../UPSTREAM_VERSION').readAsLinesSync())
        if (!line.startsWith('#') && line.contains('='))
          line.substring(0, line.indexOf('=')): line.substring(
            line.indexOf('=') + 1,
          ),
    };

    test('targetVersion is its tag', () {
      expect(targetVersion, v(fields['tag']!));
      expect('v$targetVersion', fields['tag']);
    });

    test('releaseCommits maps its commit to its tag', () {
      expect(releaseCommits[fields['commit']], fields['tag']);
    });
  });

  test('releaseCommits holds every v* tag', () {
    expect(releaseCommits, hasLength(83));
    expect(
      releaseCommits['361553f3322d7b9bb547d0a9c2c5aaefc2934901'],
      'v0.8.8-rc4',
    );
    expect(
      releaseCommits.values.every((t) => Version.parse(t) != null),
      isTrue,
    );
  });

  group('serverVersionOf', () {
    const rc4 = '361553f3322d7b9bb547d0a9c2c5aaefc2934901';

    test('config version wins over buildInfo.commit', () {
      expect(
        serverVersionOf(
          const StartupConfig(
            version: 'v0.8.7',
            buildInfo: BuildInfo(commit: rc4),
          ),
        ),
        v('0.8.7'),
      );
    });

    test('an unparsable version falls back to the commit', () {
      expect(
        serverVersionOf(
          const StartupConfig(
            version: 'latest',
            buildInfo: BuildInfo(commit: rc4),
          ),
        ),
        v('0.8.8-rc4'),
      );
    });

    test('a 7-char prefix and a full sha resolve', () {
      for (final commit in ['361553f', rc4, ' 361553F ']) {
        expect(
          serverVersionOf(StartupConfig(buildInfo: BuildInfo(commit: commit))),
          v('0.8.8-rc4'),
          reason: commit,
        );
      }
    });

    test('short, non-hex or unknown commits are unknown', () {
      for (final commit in ['361553', 'zzzzzzz', 'deadbeefdeadbeef', '']) {
        expect(versionForCommit(commit), isNull, reason: commit);
      }
      expect(versionForCommit(null), isNull);
      expect(serverVersionOf(const StartupConfig()), isNull);
    });

    test('ServerInfo.version reads the config', () {
      expect(
        const ServerInfo(config: StartupConfig(version: '0.8.6')).version,
        v('0.8.6'),
      );
      expect(const ServerInfo(config: StartupConfig()).version, isNull);
    });
  });
}
