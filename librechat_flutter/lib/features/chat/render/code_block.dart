import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../../core/ui/platform_actions.dart';

/// The bundled grammars, each also registered under its aliases (`js`,
/// `py`, `kt`, `sh`, `html`, `yml`, `toml`, …).
final Highlight _engine = Highlight()..registerLanguages(_grammars);

/// Every bundled name and alias, mapped to its grammar's name, so `py` and
/// `python` share one memo entry.
final Map<String, String> _canonical = {
  for (final MapEntry(:key, :value) in _grammars.entries) ...{
    for (final alias in value.aliases ?? const <String>[])
      alias.toLowerCase(): key,
    key: key,
  },
};

final Map<String, Mode> _grammars = {
  'bash': langBash,
  'c': langC,
  'cpp': langCpp,
  'csharp': langCsharp,
  'css': langCss,
  'dart': langDart,
  'diff': langDiff,
  'dockerfile': langDockerfile,
  'go': langGo,
  'ini': langIni,
  'java': langJava,
  'javascript': langJavascript,
  'json': langJson,
  'kotlin': langKotlin,
  'markdown': langMarkdown,
  'php': langPhp,
  'python': langPython,
  'ruby': langRuby,
  'rust': langRust,
  'scss': langScss,
  'shell': langShell,
  'sql': langSql,
  'swift': langSwift,
  'typescript': langTypescript,
  'xml': langXml,
  'yaml': langYaml,
};

/// The highlight colors without the theme's `root` background, so the
/// block keeps the App's surface color.
Map<String, TextStyle> _theme(Brightness brightness) => {
  for (final MapEntry(:key, :value)
      in (brightness == Brightness.dark ? atomOneDarkTheme : atomOneLightTheme)
          .entries)
    if (key != 'root') key: value,
};

final _darkTheme = _theme(Brightness.dark);
final _lightTheme = _theme(Brightness.light);

/// The fence language as a lookup key: the first word of the info string,
/// lowercased (`Python title=x` → `python`).
String fenceLanguage(String info) {
  final trimmed = info.trim().toLowerCase();
  final space = trimmed.indexOf(RegExp(r'\s'));
  return space < 0 ? trimmed : trimmed.substring(0, space);
}

/// Highlighted code, memoized by language and code in a [capacity]-entry
/// map (Req 22.2), so the 50 ms stream flushes that rebuild a message don't
/// re-highlight its finished code blocks. The least recently used entry
/// goes first.
class CodeHighlighter {
  CodeHighlighter({this.capacity = 64});

  final int capacity;
  // A map literal is a LinkedHashMap: insertion order is recency order.
  final _memo = <(String, String, Brightness), TextSpan>{};

  /// The number of memoized results.
  int get length => _memo.length;

  /// [code] highlighted as [language] for a [brightness] theme, or null
  /// when [language] is empty or not bundled (it then renders plain).
  TextSpan? highlight(String language, String code, Brightness brightness) {
    final key = _canonical[fenceLanguage(language)];
    if (key == null) return null;
    final memoKey = (key, code, brightness);
    final hit = _memo.remove(memoKey);
    if (hit != null) return _memo[memoKey] = hit;
    final renderer = TextSpanRenderer(
      null,
      brightness == Brightness.dark ? _darkTheme : _lightTheme,
    );
    _engine.highlight(code: code, language: key).render(renderer);
    final span = renderer.span ?? TextSpan(text: code);
    _memo[memoKey] = span;
    if (_memo.length > capacity) _memo.remove(_memo.keys.first);
    return span;
  }
}

/// The App's shared memo.
final codeHighlighter = CodeHighlighter();

/// A fenced code block (Req 22.2): a header with the language label and a
/// copy button, and the code, highlighted when its fence is [closed] and
/// its language is bundled, plain monospace otherwise. The code scrolls
/// sideways rather than wrapping.
///
/// Copy writes to the clipboard through [PlatformActions.copy] and shows a
/// check mark for 3 seconds.
class CodeBlock extends ConsumerStatefulWidget {
  const CodeBlock({
    super.key,
    required this.language,
    required this.code,
    this.closed = true,
  });

  /// The fence info string; empty for a bare fence.
  final String language;
  final String code;

  /// False while the fence is still open, as when a reply streams.
  final bool closed;

  @override
  ConsumerState<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends ConsumerState<CodeBlock> {
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await ref.read(platformActionsProvider).copy(widget.code);
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() {
      _copiedTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copiedTimer = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = fenceLanguage(widget.language);
    final label = language.isEmpty ? 'code' : language; // KMP CodeBlock.kt
    final copied = _copiedTimer != null;
    final codeStyle = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 20 / 13,
      color: colors.onSurface,
    );
    final highlighted = widget.closed
        ? codeHighlighter.highlight(language, widget.code, theme.brightness)
        : null;

    return Semantics(
      container: true,
      label: '$label code block', // KMP CodeBlock.kt
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: colors.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Expanded(
                      // The block's label already names the language.
                      child: ExcludeSemantics(
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copy,
                      tooltip: copied
                          ? 'Copied' // KMP cd_copied
                          : 'Copy code', // KMP cd_copy_code
                      icon: Icon(
                        copied ? Icons.check : Icons.content_copy,
                        size: 18,
                        color: copied
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Text.rich(
                highlighted ?? TextSpan(text: widget.code),
                style: codeStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
