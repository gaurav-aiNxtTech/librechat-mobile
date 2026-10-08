import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The Vendored_Web_Assets the copies come from, relative to the package root.
const _kmpWeb = '../feature/chat/src/commonMain/composeResources/files/web';

const _dirs = {'babel', 'mermaid', 'react', 'react-dom', 'tailwind'};

/// Every file under `assets/web/`, as paths relative to it.
List<String> _assetFiles() => [
  for (final entity in Directory('assets/web').listSync(recursive: true))
    if (entity is File)
      entity.path.substring('assets/web/'.length).replaceAll(r'\', '/'),
]..sort();

void main() {
  test('assets/web holds exactly the five libraries, each with a LICENSE', () {
    final dirs = {
      for (final entity in Directory('assets/web').listSync())
        if (entity is Directory) p.basename(entity.path),
    };
    expect(dirs, _dirs);
    for (final dir in _dirs) {
      expect(File('assets/web/$dir/LICENSE').existsSync(), isTrue, reason: dir);
    }
    expect(
      Directory('assets/web').listSync().whereType<File>(),
      isEmpty,
      reason: 'no loose files',
    );
  });

  test('every asset matches the KMP bytes (Task 35.1 cmp)', () {
    final files = _assetFiles();
    expect(files, hasLength(10));
    for (final path in files) {
      final copy = File('assets/web/$path').readAsBytesSync();
      final source = File('$_kmpWeb/$path').readAsBytesSync();
      expect(listEquals(copy, source), isTrue, reason: path);
    }
  });

  test('pubspec.yaml lists every asset directory', () {
    final lines = File(
      'pubspec.yaml',
    ).readAsLinesSync().map((l) => l.trim()).toSet();
    for (final dir in _dirs) {
      expect(lines, contains('- assets/web/$dir/'), reason: dir);
    }
  });
}
