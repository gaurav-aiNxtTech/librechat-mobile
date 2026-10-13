import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_parser.dart';
import 'package:librechat_flutter/features/chat/artifacts/web_host.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../support/fakes.dart';

// The CSPs from the design.md WebView_Host table, copied as literals so a
// drift in the lib constants fails here.
const _mermaidCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' file:; style-src 'unsafe-inline'; img-src data:;";
const _htmlCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' file:; style-src 'unsafe-inline'; img-src data: blob: https:;";
const _svgCsp =
    "default-src 'none'; style-src 'unsafe-inline'; img-src data: blob:;";
const _reactCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: file:; style-src 'unsafe-inline'; img-src data: blob: https:; font-src data: file:;";

Artifact _artifact(String type, String content) =>
    Artifact(identifier: 'a', type: type, title: 'T', content: content);

String _html(String type, String content, {bool dark = false}) =>
    buildArtifactHtml(_artifact(type, content), dark: dark);

const _reactSource =
    "import React, { useState } from 'react';\n"
    'export default function App() { return <div>hi</div>; }';

/// Every preview document, by a readable name.
final Map<String, String> _documents = {
  'buildMermaidHtml': buildMermaidHtml('graph TD; A-->B', dark: false),
  'mermaid artifact': _html('application/vnd.mermaid', 'graph TD; A-->B'),
  'html fragment': _html('text/html', '<p>hi</p>'),
  'html document': _html(
    'text/html',
    '<!DOCTYPE html><html><head><title>x</title></head><body></body></html>',
  ),
  'code-html': _html('application/vnd.code-html', '<p>hi</p>'),
  'svg': _html('image/svg+xml', '<svg viewBox="0 0 1 1"></svg>'),
  'react': _html('application/vnd.react', _reactSource),
};

final _cspMeta = RegExp(
  r'<meta http-equiv="Content-Security-Policy" content="([^"]*)">',
);

List<String> _csps(String html) => [
  for (final m in _cspMeta.allMatches(html)) m[1]!,
];

List<String> _scripts(String html) => [
  for (final m in RegExp(r'<script src="([^"]*)"').allMatches(html)) m[1]!,
];

void main() {
  group('CSP per type', () {
    const expected = {
      'buildMermaidHtml': _mermaidCsp,
      'mermaid artifact': _mermaidCsp,
      'html fragment': _htmlCsp,
      'html document': _htmlCsp,
      'code-html': _htmlCsp,
      'svg': _svgCsp,
      'react': _reactCsp,
    };
    for (final MapEntry(key: name, value: csp) in expected.entries) {
      test(name, () => expect(_csps(_documents[name]!), [csp]));
    }
  });

  group('script paths per type', () {
    test('mermaid', () {
      expect(_scripts(_documents['buildMermaidHtml']!), [
        'mermaid/mermaid.min.js',
      ]);
      expect(_scripts(_documents['mermaid artifact']!), [
        'mermaid/mermaid.min.js',
      ]);
    });

    test('html', () {
      for (final name in ['html fragment', 'html document', 'code-html']) {
        expect(_scripts(_documents[name]!), [
          'tailwind/tailwind.min.js',
        ], reason: name);
      }
    });

    test('svg has no script at all', () {
      expect(_documents['svg'], isNot(contains('<script')));
    });

    test('react', () {
      expect(_scripts(_documents['react']!), [
        'react/react.production.min.js',
        'react-dom/react-dom.production.min.js',
        'babel/babel.min.js',
        'tailwind/tailwind.min.js',
      ]);
    });
  });

  test('every referenced asset exists and its directory is listed', () {
    final pubspec = File(
      'pubspec.yaml',
    ).readAsLinesSync().map((l) => l.trim()).toSet();
    final reference = RegExp(r'''(?:src|href)="([^"]*)"''');
    var checked = 0;
    for (final MapEntry(key: name, value: html) in _documents.entries) {
      for (final match in reference.allMatches(html)) {
        final path = match[1]!;
        if (path.startsWith('#') || Uri.parse(path).hasScheme) continue;
        checked++;
        expect(
          File('assets/web/$path').existsSync(),
          isTrue,
          reason: '$name: $path',
        );
        final dir = path.substring(0, path.lastIndexOf('/') + 1);
        expect(pubspec, contains('- assets/web/$dir'), reason: '$name: $path');
      }
    }
    expect(checked, 9);
  });

  test('no document names a remote origin outside img-src (Req 24.8)', () {
    // Scripts, styles and fonts come from the page and the APK only; a
    // remote URL is allowed for images and nowhere else.
    const local = {
      "'none'",
      "'self'",
      "'unsafe-inline'",
      "'unsafe-eval'",
      'data:',
      'blob:',
      'file:',
    };
    for (final MapEntry(key: name, value: html) in _documents.entries) {
      final csp = _csps(html).single;
      final directives = {
        for (final part in csp.split(';').map((p) => p.trim()))
          if (part.isNotEmpty)
            part.split(' ').first: part.split(' ').skip(1).toList(),
      };
      expect(directives['default-src'], ["'none'"], reason: name);
      for (final MapEntry(key: directive, value: sources)
          in directives.entries) {
        if (directive == 'img-src') continue;
        expect(sources, isNotEmpty, reason: '$name: $directive');
        expect(sources, everyElement(isIn(local)), reason: '$name: $directive');
      }
      // Only images may name a remote scheme, and only by scheme.
      expect(
        directives['img-src']!,
        everyElement(isIn({...local, 'https:'})),
        reason: name,
      );
    }
  });

  group('theme', () {
    test('mermaid is dark or default', () {
      expect(buildMermaidHtml('a', dark: true), contains("theme: 'dark'"));
      expect(buildMermaidHtml('a', dark: false), contains("theme: 'default'"));
    });

    test('custom bg and fg become #RRGGBB variables', () {
      for (final type in ['text/html', 'application/vnd.react']) {
        final html = buildArtifactHtml(
          _artifact(type, '<p>x</p>'),
          dark: false,
          bg: const Color(0xFF102030),
          fg: const Color(0x80A0B0C0),
        );
        expect(html, contains('--bg: #102030'), reason: type);
        expect(html, contains('--fg: #A0B0C0'), reason: type);
      }
    });

    test('defaults follow dark', () {
      expect(_html('text/html', 'x', dark: true), contains('--bg: #1C1B1F'));
      expect(_html('text/html', 'x'), contains('--bg: #FFFBFE'));
    });

    test('isDarkSurface reads the surface luminance', () {
      ColorScheme scheme(Brightness b) =>
          ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: b);
      expect(isDarkSurface(scheme(Brightness.dark)), isTrue);
      expect(isDarkSurface(scheme(Brightness.light)), isFalse);
    });
  });

  group('react', () {
    String missingList(String html) =>
        RegExp(r'(\[.*\])\.forEach\(function \(e\)').firstMatch(html)![1]!;

    test('the import map covers the four core specifiers', () {
      final html = _documents['react']!;
      for (final key in [
        "'react':",
        "'react/jsx-runtime':",
        "'react-dom':",
        "'react-dom/client':",
      ]) {
        expect(html, contains(key));
      }
      expect(html, contains("mapTag.type = 'importmap'"));
      expect(
        html.indexOf('document.head.appendChild(mapTag)'),
        lessThan(html.indexOf("await import('react')")),
      );
    });

    test('the embedded base64 decodes to the source', () {
      const source = "const s = '</script>`\${x}` é 中';\n$_reactSource";
      final html = _html('application/vnd.react', source);
      final b64 = RegExp(r"atob\('([^']*)'\)").firstMatch(html)![1]!;
      expect(utf8.decode(base64Decode(b64)), source);
      expect(html, isNot(contains('</script>`')));
    });

    test('unbundled imports get stubs with their export names', () {
      final html = _html(
        'application/vnd.react',
        "import _ from 'lodash';\n"
            "import { motion } from 'framer-motion';\n"
            "import { a as b, c } from 'lib-x';\n"
            "import Def, * as NS from 'lib-y';\n"
            "import './x.css';\n"
            "import React from 'react';\n"
            "import { createRoot } from 'react-dom/client';\n"
            "import x from 'https://cdn.example/x.js';\n"
            "import bad from 'a b';\n"
            "import 'lodash';\n$_reactSource",
      );
      expect(jsonDecode(missingList(html)), [
        [
          'lodash',
          ['default'],
        ],
        [
          'framer-motion',
          ['motion'],
        ],
        [
          'lib-x',
          ['a', 'c'],
        ],
        [
          'lib-y',
          ['default'],
        ],
      ]);
      expect(html, contains('an npm package that is not'));
    });

    test('no unbundled imports give an empty list', () {
      expect(missingList(_documents['react']!), '[]');
    });

    test('showError reports the error to the App', () {
      expect(_documents['react'], contains('report({ error: String(msg) })'));
    });
  });

  group('html', () {
    test('a fragment is wrapped in <body>', () {
      expect(
        _html('text/html', '<p>hi</p>'),
        contains('<body><p>hi</p></body>'),
      );
    });

    test('the CSP lands right after <head>', () {
      final html = _html(
        'text/html',
        '<html><HEAD><title>x</title></HEAD></html>',
      );
      expect(
        html,
        startsWith('<html><HEAD><meta http-equiv="Content-Security-Policy"'),
      );
      expect(_csps(html), [_htmlCsp]);
    });

    test('the CSP lands right after <head lang="en">', () {
      final html = _html('text/html', '<html><head lang="en"><title>x</title>');
      expect(
        html,
        startsWith(
          '<html><head lang="en"><meta http-equiv="Content-Security-Policy"',
        ),
      );
    });

    test('a document without a head keeps its doctype first', () {
      final html = _html('text/html', '<!DOCTYPE html><body>x</body>');
      expect(
        html,
        startsWith('<!DOCTYPE html><meta http-equiv="Content-Security-Policy"'),
      );
      expect(html, endsWith('</script><body>x</body>'));
      expect(_csps(html), [_htmlCsp]);
    });

    test('comments before the doctype keep it first', () {
      final html = _html('text/html', '<!-- c -->\n<!doctype html><p>x</p>');
      expect(
        html,
        startsWith(
          '<!-- c -->\n<!doctype html><meta http-equiv="Content-Security-Policy"',
        ),
      );
    });

    /// The CSP must come before [marker], the first author content that
    /// can load or run anything.
    void expectCspBefore(String content, String marker) {
      final html = _html('text/html', content);
      final csp = html.indexOf('<meta http-equiv="Content-Security-Policy"');
      expect(csp, isNonNegative);
      expect(csp, lessThan(html.indexOf(marker)), reason: html);
      expect(_csps(html), [_htmlCsp]);
    }

    test('the CSP precedes a script placed before <head>', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      expectCspBefore('<!DOCTYPE html><html>$evil<head></head></html>', evil);
      expectCspBefore('<html lang="en">\n$evil<head></head></html>', evil);
      expectCspBefore('$evil<html><head></head></html>', evil);
    });

    test('a <head> inside a comment does not capture the CSP', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      const content =
          '<!DOCTYPE html><html><!-- <head> -->$evil<head></head></html>';
      expectCspBefore(content, evil);
      final html = _html('text/html', content);
      expect(
        html.indexOf('Content-Security-Policy'),
        isNot(inInclusiveRange(html.indexOf('<!--'), html.indexOf('-->'))),
      );
    });

    test('a <head> inside a script string does not capture the CSP', () {
      expectCspBefore(
        "<!DOCTYPE html><script>var s = '<head>';</script><head></head>",
        "<script>var s = '<head>'",
      );
    });

    test('abrupt and --!> comment closes do not hide a script', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      const tail = '<!DOCTYPE html><html><head></head></html>';
      expectCspBefore('<!-->$evil<!-- -->$tail', evil);
      expectCspBefore('<!--->$evil<!-- -->$tail', evil);
      expectCspBefore('<!-- a --!>$evil -->$tail', evil);
      expectCspBefore('<!DOCTYPE html><html><!-->$evil--><head></head>', evil);
    });

    test('a --!> close still keeps the doctype first', () {
      final html = _html('text/html', '<!-- c --!><!DOCTYPE html><p>x</p>');
      expect(
        html,
        startsWith(
          '<!-- c --!><!DOCTYPE html><meta http-equiv="Content-Security-Policy"',
        ),
      );
    });

    test('an unclosed comment puts the CSP before it', () {
      final html = _html('text/html', '<!-- x <!DOCTYPE html><html><head>');
      expect(html, startsWith('<meta http-equiv="Content-Security-Policy"'));
    });

    test('bogus comments before the doctype keep it first', () {
      const prologue = '<?xml version="1.0"?>\n<!foo>\n<!DOCTYPE html>';
      final html = _html(
        'text/html',
        '$prologue<html><head><title>x</title></head></html>',
      );
      expect(
        html,
        startsWith(
          '$prologue<html><head><meta http-equiv="Content-Security-Policy"',
        ),
      );
      expect(_csps(html), [_htmlCsp]);
    });

    test('a bogus comment ends at the first > and hides no script', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      const tail = '<!DOCTYPE html><html><head></head></html>';
      expectCspBefore('<?x a=">$evil"?>$tail', evil);
      expectCspBefore('<!x a=">$evil">$tail', evil);
    });

    test('an unclosed bogus comment puts the CSP before it', () {
      final html = _html('text/html', '<?xml <!DOCTYPE html<html<head');
      expect(html, startsWith('<meta http-equiv="Content-Security-Policy"'));
    });

    test('a quote outside an attribute value does not open one', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      expectCspBefore('<html a"b>$evil"><head></head></html>', evil);
      expectCspBefore("<html><head x'y>$evil'></head></html>", evil);
      expectCspBefore('<html a="x"="y>$evil"><head></head></html>', evil);
      expectCspBefore('<html a=b"c>$evil"><head></head></html>', evil);
    });

    test('only HTML whitespace separates = from a quoted value', () {
      const evil = '<script src="https://evil.example/x.js"></script>';
      expectCspBefore('<html a=\u00a0"x>$evil"><head></head></html>', evil);
    });

    test('a > inside an <html> attribute does not split the tag', () {
      final html = _html(
        'text/html',
        '<html data-x="a>b"><head><title>x</title></head></html>',
      );
      expect(
        html,
        startsWith(
          '<html data-x="a>b"><head><meta http-equiv="Content-Security-Policy"',
        ),
      );
    });
  });

  group('mermaid security level', () {
    test('code fences default to strict, as KMP MermaidDiagram.kt', () {
      final html = buildMermaidHtml('graph TD; A-->B', dark: false);
      expect(html, contains("securityLevel: 'strict'"));
      expect(html, isNot(contains("securityLevel: 'loose'")));
    });

    test('artifacts use loose, as KMP MermaidWebContent.kt', () {
      final html = _documents['mermaid artifact']!;
      expect(html, contains("securityLevel: 'loose'"));
      expect(html, isNot(contains("securityLevel: 'strict'")));
    });

    test('the level can be passed explicitly', () {
      expect(
        buildMermaidHtml(
          'a',
          dark: true,
          securityLevel: MermaidSecurityLevel.loose,
        ),
        contains("securityLevel: 'loose'"),
      );
    });
  });

  test('mermaid code is embedded as base64, not verbatim', () {
    const code = 'graph TD; A["</script><script>alert(1)"]-->B';
    final html = buildMermaidHtml(code, dark: false);
    expect(html, isNot(contains('</script><script>alert(1)')));
    final b64 = RegExp(r"atob\('([^']*)'\)").firstMatch(html)![1]!;
    expect(utf8.decode(base64Decode(b64)), code);
    expect(html, contains('report({ error: message })'));
    expect(html, contains('reportHeight()'));
  });

  group('parseHostMessage', () {
    test('accepts height and error', () {
      expect(parseHostMessage('{"height":120}'), const HostHeight(120));
      expect(parseHostMessage('{"height":12.5}'), const HostHeight(12.5));
      expect(parseHostMessage('{"height":0}'), const HostHeight(0));
      expect(parseHostMessage('{"error":"x"}'), const HostError('x'));
    });

    for (final raw in [
      'not json',
      '',
      '[1]',
      '"height"',
      '{}',
      '{"height":1,"error":"x"}',
      '{"height":1,"extra":true}',
      '{"height":-1}',
      '{"height":"12"}',
      '{"height":null}',
      '{"error":1}',
      '{"error":null}',
      '{"other":"x"}',
    ]) {
      test('rejects $raw', () => expect(parseHostMessage(raw), isNull));
    }
  });

  group('webNavigationAction', () {
    WebNavigationAction mainFrame(String url) =>
        webNavigationAction(url, isMainFrame: true);

    test('allows the initial document, its anchors and about:blank', () {
      expect(mainFrame(webAssetBaseUrl), WebNavigationAction.allow);
      expect(mainFrame('$webAssetBaseUrl#frag'), WebNavigationAction.allow);
      expect(mainFrame('about:blank'), WebNavigationAction.allow);
    });

    test('opens main-frame web links externally', () {
      expect(
        mainFrame('https://example.com'),
        WebNavigationAction.openExternally,
      );
      expect(
        mainFrame('http://example.com/a?b'),
        WebNavigationAction.openExternally,
      );
    });

    test('opens main-frame mailto: and tel: links externally', () {
      for (final url in [
        'mailto:someone@example.com',
        'mailto:someone@example.com?subject=Hi',
        'MAILTO:someone@example.com',
        'tel:+15555550100',
        'tel:555-0100',
      ]) {
        expect(mainFrame(url), WebNavigationAction.openExternally, reason: url);
      }
      for (final url in ['mailto:someone@example.com', 'tel:+15555550100']) {
        expect(
          webNavigationAction(url, isMainFrame: false),
          WebNavigationAction.block,
          reason: url,
        );
      }
    });

    test('blocks everything else', () {
      expect(
        webNavigationAction('https://example.com', isMainFrame: false),
        WebNavigationAction.block,
      );
      for (final url in [
        'file:///data/data/x',
        '${webAssetBaseUrl}react/react.production.min.js',
        'javascript:alert(1)',
        'intent://x#Intent;end',
        'data:text/html,x',
        'content://x',
        'https://',
        'sms:+15555550100',
        'geo:0,0',
        'market://details?id=x',
      ]) {
        expect(mainFrame(url), WebNavigationAction.block, reason: url);
      }
    });
  });

  test('types without a web preview throw and hasWebPreview agrees', () {
    for (final type in ['text/markdown', 'text/plain', 'application/json']) {
      expect(() => _html(type, 'x'), throwsArgumentError, reason: type);
      expect(hasWebPreview(type), isFalse, reason: type);
    }
    for (final type in [
      'application/vnd.mermaid',
      'text/html',
      'application/vnd.code-html',
      'image/svg+xml',
      'application/vnd.react',
    ]) {
      expect(hasWebPreview(type), isTrue, reason: type);
      expect(() => _html(type, 'x'), returnsNormally, reason: type);
    }
  });

  group('inlineWebHeight', () {
    test('a page that has not reported yet gets the floor', () {
      expect(inlineWebHeight(null, 1000), minInlineHeight);
    });

    test('a short page gets the floor', () {
      expect(inlineWebHeight(0, 1000), minInlineHeight);
      expect(inlineWebHeight(minInlineHeight, 1000), minInlineHeight);
      expect(inlineWebHeight(minInlineHeight - 1, 1000), minInlineHeight);
    });

    test('a page between the floor and the cap gets its own height', () {
      expect(inlineWebHeight(minInlineHeight + 1, 1000), minInlineHeight + 1);
      expect(inlineWebHeight(300, 1000), 300);
      // Exactly the cap.
      expect(inlineWebHeight(700, 1000), 700);
    });

    test('a long page is capped to the window fraction', () {
      expect(inlineWebHeight(900, 1000), 1000 * inlineMaxHeightFraction);
      expect(inlineWebHeight(100000, 1000), 700);
    });

    test('a window too short for the cap still gets the floor', () {
      // 0.7 × 150 is below the floor, so the floor wins over the cap.
      expect(inlineWebHeight(140, 150), minInlineHeight);
      expect(inlineWebHeight(10000, 150), minInlineHeight);
      expect(inlineWebHeight(300, 0), minInlineHeight);
    });
  });

  // These mount the real WebContentView over a fake WebView platform, so
  // the Host channel, the navigation rule and the load calls are exercised
  // as the App wires them. The fake leaves every other platform member
  // unimplemented, so a call the App should not make (a load with headers,
  // a user agent, a cookie) would throw instead of passing silently
  // (Req 24.9).
  group('WebContentView', () {
    late FakeWebViewPlatform webView;
    late FakePlatformActions platform;

    setUp(() {
      webView = FakeWebViewPlatform.install();
      platform = FakePlatformActions();
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [platformActionsProvider.overrideWithValue(platform)],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the document loads from the APK assets, with one channel', (
      tester,
    ) async {
      const html = '<p>hi</p>';
      await pump(tester, const WebContentView(html));
      final controller = webView.controller;
      expect(controller.loads, [(html, webAssetBaseUrl)]);
      expect(controller.javaScriptMode, JavaScriptMode.unrestricted);
      expect(controller.backgroundColor, Colors.transparent);
      expect(controller.channels.keys, ['Host']);
      // A platform that is not AndroidWebViewController is simply left
      // alone; the view still configures and loads.
      expect(controller.navigationDelegate, isNotNull);
    });

    testWidgets('the Host channel reports height and error, and drops the '
        'rest (Req 24.14)', (tester) async {
      final heights = <double>[];
      final errors = <String>[];
      await pump(
        tester,
        WebContentView('<p>hi</p>', onHeight: heights.add, onError: errors.add),
      );
      final controller = webView.controller;
      controller.postHostMessage('{"height":240}');
      controller.postHostMessage('{"error":"Mermaid parse error"}');
      for (final junk in ['not json', '{}', '{"other":1}', '{"height":-1}']) {
        controller.postHostMessage(junk);
      }
      expect(heights, [240.0]);
      expect(errors, ['Mermaid parse error']);
    });

    testWidgets('a main-frame load error becomes an error, a subframe one '
        'does not (Req 24.14)', (tester) async {
      final errors = <String>[];
      await pump(tester, WebContentView('<p>hi</p>', onError: errors.add));
      webView.controller.failLoad('net::ERR_FAILED', isForMainFrame: false);
      expect(errors, isEmpty);
      webView.controller.failLoad('net::ERR_FAILED');
      expect(errors, ['net::ERR_FAILED']);
    });

    testWidgets('the initial document and about:blank load in the view', (
      tester,
    ) async {
      await pump(tester, const WebContentView('<p>hi</p>'));
      for (final url in [
        webAssetBaseUrl,
        '$webAssetBaseUrl#section',
        'about:blank',
      ]) {
        expect(
          await webView.controller.navigate(url),
          NavigationDecision.navigate,
          reason: url,
        );
      }
      expect(platform.opened, isEmpty);
    });

    testWidgets('a web, mailto or tel link leaves the view and opens an '
        'external app (Req 24.10)', (tester) async {
      await pump(tester, const WebContentView('<p>hi</p>'));
      const urls = [
        'https://example.com/docs',
        'http://example.com/a?b=1',
        'mailto:someone@example.com?subject=Hi',
        'tel:+15555550100',
      ];
      for (final url in urls) {
        expect(
          await webView.controller.navigate(url),
          NavigationDecision.prevent,
          reason: url,
        );
      }
      await tester.pump();
      expect(platform.opened.map((u) => u.toString()), urls);
      // Nothing but the first document ever loads in the WebView itself.
      expect(webView.controller.loads, hasLength(1));
    });

    testWidgets('every other link is blocked without opening an app', (
      tester,
    ) async {
      await pump(tester, const WebContentView('<p>hi</p>'));
      for (final (url, isMainFrame) in [
        ('javascript:alert(1)', true),
        ('file:///data/data/x', true),
        ('${webAssetBaseUrl}react/react.production.min.js', true),
        ('intent://x#Intent;end', true),
        ('data:text/html,x', true),
        ('content://x', true),
        ('https://example.com', false),
        ('mailto:someone@example.com', false),
      ]) {
        expect(
          await webView.controller.navigate(url, isMainFrame: isMainFrame),
          NavigationDecision.prevent,
          reason: url,
        );
      }
      await tester.pump();
      expect(platform.opened, isEmpty);
    });

    testWidgets('new html reloads the same controller, the same html does '
        'not', (tester) async {
      await pump(tester, const WebContentView('<p>one</p>'));
      await pump(tester, const WebContentView('<p>two</p>'));
      expect(webView.controllers, hasLength(1));
      expect(webView.controller.loads.map((l) => l.$1), [
        '<p>one</p>',
        '<p>two</p>',
      ]);

      await pump(tester, const WebContentView('<p>two</p>'));
      expect(webView.controller.loads, hasLength(2));
    });

    testWidgets('an inline preview sizes itself from the page, clamped to '
        'the window', (tester) async {
      await pump(tester, const InlineWebView('<p>hi</p>'));
      double height() => tester.getSize(find.byType(WebContentView)).height;
      // 800×600 is the test window, so the cap is 420.
      final cap = 600 * inlineMaxHeightFraction;
      expect(height(), minInlineHeight);

      webView.controller.postHostMessage('{"height":300}');
      await tester.pump();
      expect(height(), 300);

      webView.controller.postHostMessage('{"height":5000}');
      await tester.pump();
      expect(height(), cap);

      webView.controller.postHostMessage('{"height":40}');
      await tester.pump();
      expect(height(), minInlineHeight);

      // A new document starts over at the floor until its page reports.
      webView.controller.postHostMessage('{"height":300}');
      await tester.pump();
      expect(height(), 300);
      await pump(tester, const InlineWebView('<p>other</p>'));
      expect(height(), minInlineHeight);
    });

    testWidgets('a Mermaid view renders its code in a themed document', (
      tester,
    ) async {
      await pump(tester, const MermaidView('graph TD; A-->B'));
      final html = webView.controller.loads.single.$1;
      expect(html, contains("securityLevel: 'strict'"));
      expect(html, contains("theme: 'default'"));
      expect(html, contains('mermaid/mermaid.min.js'));
    });
  });
}
