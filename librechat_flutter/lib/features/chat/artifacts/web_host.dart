/// The WebView_Host (Req 2.7, 24.6, 24.8–24.11, 24.15, design "Artifacts and
/// Mermaid"): the HTML documents that preview Mermaid, HTML, SVG and React
/// artifacts, ported from KMP `MermaidWebContent` and `ArtifactWebContent`,
/// the pure Host-message and navigation rules, and the [WebContentView]
/// that applies them.
///
/// Every document loads only the bundled `assets/web/` copies, relative to
/// [webAssetBaseUrl], under a CSP that allows no remote script origin.
/// Mermaid code and React source are embedded as base64, so `</script>`,
/// backticks and `${…}` in model output need no escaping.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'artifact_parser.dart';

/// The document base URL: the Flutter assets inside the APK.
const webAssetBaseUrl = 'file:///android_asset/flutter_assets/assets/web/';

/// Whether [scheme] is a dark surface, which picks the document theme
/// (Req 24.15).
bool isDarkSurface(ColorScheme scheme) =>
    scheme.surface.computeLuminance() < 0.5;

/// Whether an artifact of [type] previews in a WebView. Markdown and plain
/// text preview natively, and other types show as code only.
bool hasWebPreview(String type) => switch (artifactKind(type)) {
  ArtifactKind.mermaid ||
  ArtifactKind.html ||
  ArtifactKind.svg ||
  ArtifactKind.react => true,
  ArtifactKind.markdown || ArtifactKind.plain || ArtifactKind.code => false,
};

const _mermaidCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' file:; "
    "style-src 'unsafe-inline'; img-src data:;";
const _htmlCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' file:; "
    "style-src 'unsafe-inline'; img-src data: blob: https:;";
const _svgCsp =
    "default-src 'none'; style-src 'unsafe-inline'; img-src data: blob:;";
const _reactCsp =
    "default-src 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval' "
    "blob: file:; style-src 'unsafe-inline'; img-src data: blob: https:; "
    "font-src data: file:;";

String _cspMeta(String csp) =>
    '<meta http-equiv="Content-Security-Policy" content="$csp">';

/// Posts a message object to the App through the `Host` channel. A missing
/// channel or a failure never breaks the page.
const _reportScript = '''
function report(message) {
  try {
    if (window.Host) window.Host.postMessage(JSON.stringify(message));
  } catch (e) { /* the page renders without the App */ }
}
function reportHeight() {
  report({ height: Math.ceil(document.documentElement.scrollHeight) });
}''';

/// A JS expression that decodes the UTF-8 base64 [b64] in the page.
String _decodeBase64Js(String b64) =>
    "new TextDecoder().decode(Uint8Array.from(atob('$b64'), "
    'function(c) { return c.charCodeAt(0); }))';

String _base64(String text) => base64Encode(utf8.encode(text));

/// `#RRGGBB` for [color], dropping alpha.
String _css(Color color) {
  final rgb = (color.toARGB32() & 0xFFFFFF).toRadixString(16);
  return '#${rgb.padLeft(6, '0').toUpperCase()}';
}

/// Mermaid's `securityLevel`, as KMP sets it per render path.
enum MermaidSecurityLevel {
  /// Markdown code fences, as KMP `MermaidDiagram.kt`.
  strict,

  /// Mermaid artifacts, as KMP `MermaidWebContent.kt`.
  loose,
}

/// The Mermaid document for [code], with zoom controls, themed `dark` or
/// `default`. It reports `{height}` after rendering, and `{error}` plus
/// `{height}` when the diagram does not parse.
///
/// [securityLevel] defaults to [MermaidSecurityLevel.strict], for code
/// fences; [buildArtifactHtml] passes [MermaidSecurityLevel.loose].
String buildMermaidHtml(
  String code, {
  required bool dark,
  MermaidSecurityLevel securityLevel = MermaidSecurityLevel.strict,
}) {
  final theme = dark ? 'dark' : 'default';
  final bgColor = dark ? '#1C1B1F' : '#FFFBFE';
  final fgColor = dark ? '#E6E1E5' : '#1C1B1F';
  final btnBg = dark ? '#332D41' : '#E8DEF8';
  return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ${_cspMeta(_mermaidCsp)}
    <style>
        html, body { max-width: 100%; overflow-x: hidden; }
        body {
            margin: 0;
            padding: 16px;
            background: $bgColor;
            color: $fgColor;
            display: flex;
            flex-direction: column;
            align-items: center;
            font-family: -apple-system, sans-serif;
        }
        #mermaid-container {
            transform-origin: top center;
            transition: transform 0.2s ease;
            overflow: visible;
            width: 100%;
            display: flex;
            justify-content: center;
        }
        #mermaid-container svg {
            max-width: 100%;
            height: auto;
        }
        .zoom-controls {
            position: fixed;
            bottom: 12px;
            right: 12px;
            display: flex;
            gap: 8px;
            z-index: 10;
        }
        .zoom-btn {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            border: none;
            background: $btnBg;
            color: $fgColor;
            font-size: 18px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        #error-display {
            display: none;
            padding: 12px;
            background: #B3261E22;
            border: 1px solid #B3261E;
            border-radius: 8px;
            color: $fgColor;
            font-family: monospace;
            font-size: 13px;
            white-space: pre-wrap;
            width: 100%;
            box-sizing: border-box;
        }
    </style>
</head>
<body>
    <div id="mermaid-container"></div>
    <div id="error-display"></div>
    <div class="zoom-controls">
        <button class="zoom-btn" onclick="zoom(-0.2)" aria-label="Zoom out">-</button>
        <button class="zoom-btn" onclick="zoom(0.2)" aria-label="Zoom in">+</button>
    </div>
    <script>
        // Polyfills for older Android WebView (Chrome 91 on API 31)
        if (typeof structuredClone === 'undefined') {
            window.structuredClone = function(obj) {
                return JSON.parse(JSON.stringify(obj));
            };
        }
        if (!Object.hasOwn) {
            Object.hasOwn = function(obj, prop) {
                return Object.prototype.hasOwnProperty.call(obj, prop);
            };
        }
        if (typeof Array.prototype.at === 'undefined') {
            Array.prototype.at = function(n) {
                n = Math.trunc(n) || 0;
                if (n < 0) n += this.length;
                return this[n];
            };
        }
        if (typeof String.prototype.at === 'undefined') {
            String.prototype.at = function(n) {
                n = Math.trunc(n) || 0;
                if (n < 0) n += this.length;
                return this[n];
            };
        }
        if (typeof String.prototype.replaceAll === 'undefined') {
            String.prototype.replaceAll = function(search, replacement) {
                return this.split(search).join(replacement);
            };
        }
    </script>
    <script src="mermaid/mermaid.min.js"></script>
    <script>
        $_reportScript

        var scale = 1;
        function zoom(delta) {
            scale = Math.max(0.2, Math.min(3, scale + delta));
            document.getElementById('mermaid-container').style.transform = 'scale(' + scale + ')';
        }

        mermaid.initialize({
            startOnLoad: false,
            theme: '$theme',
            securityLevel: '${securityLevel.name}'
        });

        (async function() {
            var code = ${_decodeBase64Js(_base64(code))};
            try {
                var result = await mermaid.render('mermaid-graph', code);
                document.getElementById('mermaid-container').innerHTML = result.svg;
                reportHeight();
            } catch (e) {
                var message = (e && e.message) || String(e);
                var errorDisplay = document.getElementById('error-display');
                errorDisplay.style.display = 'block';
                errorDisplay.textContent = 'Mermaid parse error:\\n' + message + '\\n\\nRaw code:\\n' + code;
                report({ error: message });
                reportHeight();
            }
        })();
    </script>
</body>
</html>''';
}

/// The preview document for [artifact]: Mermaid, HTML, SVG or React.
///
/// [bg] and [fg] default to the KMP surface colors for [dark]. Throws an
/// [ArgumentError] for types without a WebView preview (see
/// [hasWebPreview]).
String buildArtifactHtml(
  Artifact artifact, {
  required bool dark,
  Color? bg,
  Color? fg,
}) {
  final bgColor = bg != null ? _css(bg) : (dark ? '#1C1B1F' : '#FFFBFE');
  final fgColor = fg != null ? _css(fg) : (dark ? '#E6E1E5' : '#1C1B1F');
  final content = artifact.content;
  return switch (artifact.kind) {
    ArtifactKind.mermaid => buildMermaidHtml(
      content,
      dark: dark,
      securityLevel: MermaidSecurityLevel.loose,
    ),
    ArtifactKind.html => _buildEnhancedHtml(content, bgColor, fgColor),
    ArtifactKind.svg => _buildSvgHtml(content, bgColor),
    ArtifactKind.react => _buildReactHtml(content, bgColor, fgColor),
    ArtifactKind.markdown ||
    ArtifactKind.plain ||
    ArtifactKind.code => throw ArgumentError.value(
      artifact.type,
      'artifact.type',
      'has no WebView preview',
    ),
  };
}

/// HTML whitespace (tab, LF, FF, CR, space), which is narrower than `\s`.
bool _isHtmlSpace(String c) => ' \t\n\r\f'.contains(c);

/// The end of the comment that starts at [at] (`<!--`), or -1 if unclosed.
///
/// Mirrors the HTML tokenizer: `<!-->` and `<!--->` close at once, and both
/// `-->` and `--!>` close a comment, whichever comes first.
int _commentEnd(String html, int at) {
  final dash = html.indexOf('-->', at + 2);
  final bang = html.indexOf('--!>', at + 4);
  if (bang >= 0 && (dash < 0 || bang < dash)) return bang + 4;
  return dash < 0 ? -1 : dash + 3;
}

/// The end of a `<[name] …>` start tag at [at], or null if there is none.
///
/// It accepts only attributes the HTML tokenizer reads the same way: a name
/// with no quote, `<`, `=`, `/` or `>`, optionally followed by `=` and a
/// quoted or unquoted value. A quote opens a value only right after `=`, as
/// in the tokenizer. Anything else returns null, which ends the prologue
/// walk early; that is safe because the parser opens the tag implicitly.
int? _startTagEnd(String html, int at, String name) {
  var i = at + 1 + name.length;
  if (i >= html.length || html.substring(at, i).toLowerCase() != '<$name') {
    return null;
  }
  final next = html[i];
  if (!_isHtmlSpace(next) && next != '/' && next != '>') return null;
  int skipSpace(int from) {
    var j = from;
    while (j < html.length && _isHtmlSpace(html[j])) {
      j++;
    }
    return j;
  }

  while (i < html.length) {
    final c = html[i];
    if (c == '>') return i + 1;
    if (_isHtmlSpace(c) || c == '/') {
      i++;
      continue;
    }
    final nameStart = i;
    while (i < html.length &&
        !_isHtmlSpace(html[i]) &&
        !'"\'<=/>'.contains(html[i])) {
      i++;
    }
    if (i == nameStart) return null;
    var j = skipSpace(i);
    if (j >= html.length || html[j] != '=') continue;
    j = skipSpace(j + 1);
    if (j >= html.length) return null;
    final quote = html[j];
    if (quote == '"' || quote == "'") {
      final close = html.indexOf(quote, j + 1);
      if (close < 0) return null;
      i = close + 1;
    } else {
      final valueStart = j;
      while (j < html.length &&
          !_isHtmlSpace(html[j]) &&
          !'"\'<=>'.contains(html[j])) {
        j++;
      }
      if (j == valueStart) return null;
      i = j;
    }
  }
  return null;
}

/// Where the CSP goes in a full HTML document: before any author content
/// that can run or load anything.
///
/// It walks only the document's prologue: leading whitespace and comments,
/// the doctype, the `<html …>` tag and the `<head …>` tag, each optional and
/// in that order. The point is right after the last one found, so the
/// doctype stays first (no quirks mode) and an existing head keeps the
/// policy (design "WebView_Host"). Any other markup ends the walk, so a
/// `<head>` inside a comment, a script string or the body never moves the
/// CSP behind earlier content. Without `<head>` the parser opens one
/// implicitly at the inserted `<meta>`.
int _headInsertionPoint(String html) {
  var i = 0;
  int skipSpaceAndComments(int from) {
    var at = from;
    while (true) {
      while (at < html.length && _isHtmlSpace(html[at])) {
        at++;
      }
      if (!html.startsWith('<!--', at)) return at;
      final end = _commentEnd(html, at);
      // An unclosed comment hides the rest of the document; stop before it.
      if (end < 0) return at;
      at = end;
    }
  }

  var at = skipSpaceAndComments(i);
  if (html.length - at >= 9 &&
      html.substring(at, at + 9).toLowerCase() == '<!doctype') {
    final end = html.indexOf('>', at);
    if (end < 0) return i;
    i = end + 1;
    at = skipSpaceAndComments(i);
  }
  if (_startTagEnd(html, at, 'html') case final end?) {
    i = end;
    at = skipSpaceAndComments(i);
  }
  if (_startTagEnd(html, at, 'head') case final end?) {
    i = end;
  }
  return i;
}

// Security note: HTML artifacts intentionally render unsanitized HTML, as
// upstream does. The CSP limits scripts to the page and the bundled assets.
String _buildEnhancedHtml(String content, String bgColor, String fgColor) {
  final lower = content.toLowerCase();
  if (lower.contains('<html') || lower.contains('<!doctype')) {
    final themeStyle =
        '${_cspMeta(_htmlCsp)}\n'
        '<style>:root { --bg: $bgColor; --fg: $fgColor; } '
        'html, body { max-width: 100%; overflow-x: hidden; } '
        'body { background: var(--bg); color: var(--fg); margin: 0; '
        'padding: 0; } '
        'img, svg, video, iframe { max-width: 100%; height: auto; }</style>\n'
        '<script src="tailwind/tailwind.min.js"></script>';
    final at = _headInsertionPoint(content);
    return content.replaceRange(at, at, themeStyle);
  }

  return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ${_cspMeta(_htmlCsp)}
    <script src="tailwind/tailwind.min.js"></script>
    <style>
        :root { --bg: $bgColor; --fg: $fgColor; }
        html, body { max-width: 100%; overflow-x: hidden; }
        body { background: var(--bg); color: var(--fg); margin: 0; padding: 0; }
        img, svg, video, iframe { max-width: 100%; height: auto; }
    </style>
</head>
<body>$content</body>
</html>''';
}

// Security note: SVG renders unsanitized; the CSP forbids every script.
String _buildSvgHtml(String content, String bgColor) =>
    '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ${_cspMeta(_svgCsp)}
    <style>
        html, body { max-width: 100%; overflow-x: hidden; }
        body {
            margin: 0;
            padding: 16px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: $bgColor;
        }
        svg, .svg-container {
            width: 100%;
            height: auto;
            max-width: 100%;
        }
    </style>
</head>
<body><div class="svg-container">$content</div></body>
</html>''';

/// Every `import … from 'X'` and bare `import 'X'` specifier.
final _moduleSpecifier = RegExp(r'''(?:from|import)\s*['"]([^'"]+)['"]''');

/// Specifiers the runner satisfies from the bundled UMD globals.
const _coreImports = {
  'react',
  'react/jsx-runtime',
  'react-dom',
  'react-dom/client',
};

/// npm package names only. Anything else is dropped rather than embedded:
/// the strings come from model output and go into a script.
final _safeSpecifier = RegExp(r'^[A-Za-z0-9@][A-Za-z0-9@/._-]*$');

/// The clause and specifier of `import <clause> from 'X'`.
final _importClause = RegExp(
  r'''import\s+([^'"]+?)\s+from\s*['"]([^'"]+)['"]''',
);

/// A binding inside `{ … }`, keeping the imported name, not the alias.
final _namedBinding = RegExp(
  r'([A-Za-z_$][A-Za-z0-9_$]*)(?:\s+as\s+[A-Za-z_$][A-Za-z0-9_$]*)?',
);

/// Every bare specifier [content] imports that the bundle cannot satisfy, in
/// first-use order. Relative, absolute and URL specifiers are left to the
/// browser.
List<String> _missingSpecifiers(String content) => {
  for (final match in _moduleSpecifier.allMatches(content))
    if (match[1]! case final spec
        when spec.trim().isNotEmpty &&
            !spec.startsWith('.') &&
            !spec.startsWith('/') &&
            !spec.contains(':') &&
            !_coreImports.contains(spec) &&
            _safeSpecifier.hasMatch(spec))
      spec,
}.toList();

/// The export names each of the [missing] specifiers is imported under.
///
/// A stub module must declare them even though it only throws: named
/// imports are resolved while the module graph links, before any code runs,
/// so a stub without them fails with "does not provide an export named" and
/// its own message never shows. Namespace imports need no entry.
Map<String, List<String>> _missingModuleExports(
  String content,
  Set<String> missing,
) {
  final exports = <String, Set<String>>{};
  for (final match in _importClause.allMatches(content)) {
    final spec = match[2]!;
    if (!missing.contains(spec)) continue;
    final names = exports.putIfAbsent(spec, () => <String>{});
    final clause = match[1]!;
    final open = clause.indexOf('{');
    final close = open < 0 ? -1 : clause.indexOf('}', open + 1);
    if (close >= 0) {
      final braces = clause.substring(open + 1, close);
      for (final binding in _namedBinding.allMatches(braces)) {
        names.add(binding[1]!);
      }
    }
    // Anything before the brace or the `* as` is a default import.
    var head = open < 0 ? clause : clause.substring(0, open);
    final star = head.indexOf('*');
    if (star >= 0) head = head.substring(0, star);
    head = head.trim();
    while (head.endsWith(',')) {
      head = head.substring(0, head.length - 1);
    }
    if (head.trim().isNotEmpty) names.add('default');
  }
  return {
    for (final MapEntry(:key, :value) in exports.entries) key: value.toList(),
  };
}

// Security note: React artifacts run unsanitized, model-generated JSX under
// a CSP that permits no remote origin. React 18 has no browser ESM build, so
// the UMD builds load as scripts and an import map points at blob modules
// that re-export their globals. Tailwind loads too, as in KMP, because
// upstream React artifacts are styled with its classes.
String _buildReactHtml(String content, String bgColor, String fgColor) {
  final missing = _missingSpecifiers(content);
  final missingExports = _missingModuleExports(content, missing.toSet());
  final missingJson = jsonEncode([
    for (final spec in missing) [spec, missingExports[spec] ?? const []],
  ]);
  return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    ${_cspMeta(_reactCsp)}
    <script src="react/react.production.min.js"></script>
    <script src="react-dom/react-dom.production.min.js"></script>
    <script src="babel/babel.min.js"></script>
    <script src="tailwind/tailwind.min.js"></script>
    <style>
        :root { --bg: $bgColor; --fg: $fgColor; }
        html, body { max-width: 100%; overflow-x: hidden; }
        body { background: var(--bg); color: var(--fg); margin: 0; padding: 0; }
        img, svg, video, iframe { max-width: 100%; height: auto; }
        #error-display {
            display: none;
            padding: 16px;
            margin: 16px;
            background: #B3261E22;
            border: 1px solid #B3261E;
            border-radius: 8px;
            font-family: monospace;
            font-size: 13px;
            white-space: pre-wrap;
            color: $fgColor;
        }
    </style>
</head>
<body>
    <div id="root"></div>
    <div id="error-display"></div>
    <script>
    (function () {
        $_reportScript

        var root = document.getElementById('root');
        var errDiv = document.getElementById('error-display');
        function showError(msg) {
            if (root.hasChildNodes()) return;
            errDiv.style.display = 'block';
            errDiv.textContent = 'Component failed to render:\\n' + msg;
            report({ error: String(msg) });
        }
        window.addEventListener('error', function(e) { showError(e.message || 'Unknown error'); });
        window.addEventListener('unhandledrejection', function(e) {
            showError((e.reason && e.reason.message) || String(e.reason));
        });

        // Module code is strict mode, so the strict-only reserved words are
        // as fatal here as the ordinary ones.
        var RESERVED = ['default','class','function','const','let','var','import','export',
            'new','delete','typeof','in','of','do','if','else','return','switch','case',
            'break','continue','for','while','with','try','catch','finally','throw','this',
            'super','void','yield','await','enum','null','true','false','instanceof',
            'extends','debugger','implements','interface','package','private','protected',
            'public','static','arguments','eval'];

        // Only plain ASCII identifiers can be re-exported by name; anything
        // else stays reachable through the module's default export.
        function isSafeName(k) {
            if (!k || RESERVED.indexOf(k) !== -1) return false;
            for (var i = 0; i < k.length; i++) {
                var c = k.charCodeAt(i);
                var ok = (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c === 95 ||
                    (i > 0 && c >= 48 && c <= 57);
                if (!ok) return false;
            }
            return true;
        }

        function moduleUrl(source) {
            return URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
        }

        // Re-exports a UMD global as an ES module, naming each export so
        // `import { useState } from 'react'` binds like it would from npm.
        function globalModule(globalName, obj) {
            var lines = ['const m = window.' + globalName + ';', 'export default m;'];
            Object.keys(obj).forEach(function (k) {
                if (isSafeName(k)) lines.push('export const ' + k + ' = m.' + k + ';');
            });
            return moduleUrl(lines.join('\\n'));
        }

        // The stub declares the names the artifact imports from it, then
        // throws. Named imports resolve while the module graph links, so a
        // stub that exports nothing fails before this message can show.
        function missingModule(spec, names) {
            var lines = [];
            names.forEach(function (n) {
                if (n === 'default') lines.push('export default undefined;');
                else if (isSafeName(n)) lines.push('export const ' + n + ' = undefined;');
            });
            lines.push('throw new Error(' + JSON.stringify(
                'This artifact imports "' + spec + '", an npm package that is not ' +
                'bundled with the app, so it cannot be loaded.'
            ) + ');');
            return moduleUrl(lines.join('\\n'));
        }

        // Babel's automatic runtime imports jsx()/jsxs() from
        // react/jsx-runtime, which React 18's UMD build does not expose.
        // `children` goes to createElement as one argument, never spread, so
        // a one-item list still reconciles by key.
        var JSX_RUNTIME = [
            'const R = window.React;',
            'export const Fragment = R.Fragment;',
            'export function jsx(type, props, key) {',
            '  const p = Object.assign({}, props);',
            '  const children = p.children;',
            '  delete p.children;',
            '  if (key !== undefined) p.key = key;',
            '  if (children === undefined) return R.createElement(type, p);',
            '  return R.createElement(type, p, children);',
            '}',
            'export const jsxs = jsx;',
            'export const jsxDEV = jsx;'
        ].join('\\n');

        var DOM_CLIENT = [
            'const m = window.ReactDOM;',
            'export const createRoot = m.createRoot;',
            'export const hydrateRoot = m.hydrateRoot;',
            'export default { createRoot: m.createRoot, hydrateRoot: m.hydrateRoot };'
        ].join('\\n');

        var imports = {
            'react': globalModule('React', window.React),
            'react/jsx-runtime': moduleUrl(JSX_RUNTIME),
            'react-dom': globalModule('ReactDOM', window.ReactDOM),
            'react-dom/client': moduleUrl(DOM_CLIENT)
        };
        $missingJson.forEach(function (e) { imports[e[0]] = missingModule(e[0], e[1]); });

        // Injected before the first dynamic import, which is the only
        // ordering requirement: no module has been resolved yet.
        var mapTag = document.createElement('script');
        mapTag.type = 'importmap';
        mapTag.textContent = JSON.stringify({ imports: imports });
        document.head.appendChild(mapTag);

        (async function () {
            try {
                var ReactNS = await import('react');
                var React = ReactNS.default || ReactNS;
                var createRoot = (await import('react-dom/client')).createRoot;
                var source = ${_decodeBase64Js(_base64(content))};
                var compiled = Babel.transform(source, {
                    presets: [['react', { runtime: 'automatic', development: false }]],
                    filename: 'artifact.jsx',
                    sourceType: 'module',
                }).code;
                var mod = await import(moduleUrl(compiled));
                var Component = mod.default ||
                    Object.values(mod).find(function(v) { return typeof v === 'function'; });
                if (!Component) {
                    throw new Error('No React component is exported. Add `export default`.');
                }
                createRoot(root).render(React.createElement(Component));
                requestAnimationFrame(function () { requestAnimationFrame(reportHeight); });
            } catch (e) {
                showError((e && e.message) || String(e));
            }
        })();
    })();
    </script>
</body>
</html>''';
}

/// A message a page posts on the `Host` channel.
sealed class HostMessage {
  const HostMessage();
}

/// The page's content height in CSS pixels.
final class HostHeight extends HostMessage {
  const HostHeight(this.height);

  final double height;

  @override
  bool operator ==(Object other) =>
      other is HostHeight && other.height == height;

  @override
  int get hashCode => height.hashCode;

  @override
  String toString() => 'HostHeight($height)';
}

/// A render error the page shows and reports (Req 24.14).
final class HostError extends HostMessage {
  const HostError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is HostError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'HostError($message)';
}

/// Reads a `Host` channel message: a JSON object with exactly one key,
/// `height` (a finite number ≥ 0) or `error` (a string). Anything else is
/// null, and the App ignores it.
HostMessage? parseHostMessage(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded.length != 1) return null;
  return switch (decoded) {
    {'height': final num height} when height.isFinite && height >= 0 =>
      HostHeight(height.toDouble()),
    {'error': final String message} => HostError(message),
    _ => null,
  };
}

/// What [WebContentView] does with a navigation request.
enum WebNavigationAction { allow, openExternally, block }

/// The navigation rule (Req 24.10): only the initial document (and its
/// anchors) and `about:blank` load in the WebView. A main-frame `http` or
/// `https` link opens in the external browser, and a main-frame `mailto:`
/// or `tel:` link opens in the app that handles it. Everything else is
/// blocked, including `file:`, `intent:`, `javascript:`, `data:` and any
/// subframe.
WebNavigationAction webNavigationAction(
  String url, {
  required bool isMainFrame,
}) {
  final hash = url.indexOf('#');
  final document = hash < 0 ? url : url.substring(0, hash);
  if (document == webAssetBaseUrl || url == 'about:blank') {
    return WebNavigationAction.allow;
  }
  final uri = Uri.tryParse(url);
  if (isMainFrame && uri != null) {
    final external = switch (uri.scheme) {
      'http' || 'https' => uri.host.isNotEmpty,
      'mailto' || 'tel' => true,
      _ => false,
    };
    if (external) return WebNavigationAction.openExternally;
  }
  return WebNavigationAction.block;
}

/// A WebView showing one preview document (Req 2.7, 24.8–24.10, design
/// "WebContentView").
///
/// [html] loads with [webAssetBaseUrl] as its base, so it reads the bundled
/// assets; file and content access are off, so it reads nothing else. No
/// headers or cookies are set, so the page never receives tokens,
/// Custom_Headers or App cookies. The one `Host` channel passes only
/// `{height}` to [onHeight] and `{error}` to [onError] (see
/// [parseHostMessage]); a main-frame load error goes to [onError] too.
/// Navigation follows [webNavigationAction]: web, `mailto:` and `tel:`
/// links open in an external app and everything else is blocked.
class WebContentView extends StatefulWidget {
  const WebContentView(this.html, {super.key, this.onHeight, this.onError});

  final String html;
  final ValueChanged<double>? onHeight;
  final ValueChanged<String>? onError;

  @override
  State<WebContentView> createState() => _WebContentViewState();
}

class _WebContentViewState extends State<WebContentView> {
  late final WebViewController _controller;

  /// Completes once the controller is configured and the first load starts.
  late final Future<void> _configured;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _configured = _configure();
    unawaited(_configured);
  }

  /// Configures the WebView before the first load, so the first document
  /// already runs with file access off and navigation guarded.
  Future<void> _configure() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    // Android allows file access by default below API 30 (minSdk is 26).
    // `file:///android_asset/` stays readable with it off.
    if (_controller.platform case final AndroidWebViewController android) {
      await android.setAllowFileAccess(false);
      await android.setAllowContentAccess(false);
    }
    await _controller.addJavaScriptChannel(
      'Host',
      onMessageReceived: (message) {
        if (!mounted) return;
        switch (parseHostMessage(message.message)) {
          case HostHeight(:final height):
            widget.onHeight?.call(height);
          case HostError(:final message):
            widget.onError?.call(message);
          case null:
            break;
        }
      },
    );
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          switch (webNavigationAction(
            request.url,
            isMainFrame: request.isMainFrame,
          )) {
            case WebNavigationAction.allow:
              return NavigationDecision.navigate;
            case WebNavigationAction.openExternally:
              unawaited(_openExternally(Uri.parse(request.url)));
              return NavigationDecision.prevent;
            case WebNavigationAction.block:
              return NavigationDecision.prevent;
          }
        },
        onWebResourceError: (error) {
          if (mounted && (error.isForMainFrame ?? false)) {
            widget.onError?.call(error.description);
          }
        },
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _load() =>
      _controller.loadHtmlString(widget.html, baseUrl: webAssetBaseUrl);

  /// Opens [uri] in the external app for its scheme. A device without one
  /// ignores it.
  Future<void> _openExternally(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      // No app handles the link; the page stays as it is.
    }
  }

  @override
  void didUpdateWidget(WebContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.html != oldWidget.html) {
      unawaited(_configured.then((_) => mounted ? _load() : null));
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
