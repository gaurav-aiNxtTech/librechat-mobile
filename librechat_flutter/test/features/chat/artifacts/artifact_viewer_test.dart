// The artifact button, inline artifacts and the Artifact_Viewer
// (Req 24.4, 24.5, 24.7, 24.12, 24.13). The WebView types are left to the
// web_host tests: a widget test has no WebView platform, so these cases use
// `text/markdown` and `text/plain`, which preview natively (Req 24.7).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:librechat_flutter/app/routes.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_button.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_parser.dart';
import 'package:librechat_flutter/features/chat/artifacts/artifact_viewer.dart';
import 'package:librechat_flutter/features/chat/render/code_block.dart';
import 'package:librechat_flutter/features/chat/render/message_view.dart';

import '../../../support/fakes.dart';

/// Whether the icon button behind [tooltip] takes a tap.
bool _enabled(WidgetTester tester, String tooltip) =>
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed !=
    null;

Artifact _markdown(String content, {String title = 'Notes'}) => Artifact(
  identifier: 'notes',
  type: 'text/markdown',
  title: title,
  content: content,
);

void main() {
  group('type metadata', () {
    test('labels and icons follow the artifact kind', () {
      expect(artifactTypeLabel('application/vnd.mermaid'), 'Mermaid Diagram');
      expect(artifactTypeLabel('application/vnd.react'), 'React Component');
      expect(artifactTypeLabel('image/svg+xml'), 'SVG Image');
      expect(artifactTypeLabel('text/markdown'), 'Markdown Document');
      expect(artifactTypeLabel('application/vnd.code-html'), 'HTML Page');
      expect(artifactTypeLabel('text/plain'), 'Plain Text');
      expect(artifactTypeLabel('text/x-python'), 'Code');

      expect(artifactTypeIcon('text/markdown'), Icons.article);
      expect(artifactTypeIcon('text/x-python'), Icons.code);
    });

    test('the fence language comes from the type', () {
      expect(artifactLanguage('application/vnd.mermaid'), 'mermaid');
      expect(artifactLanguage('application/vnd.react'), 'jsx');
      expect(artifactLanguage('text/html'), 'html');
      expect(artifactLanguage('image/svg+xml'), 'xml');
      expect(artifactLanguage('text/plain'), '');
    });

    test('only the five settings types render inline', () {
      expect(inlineArtifactType('text/html'), InlineArtifact.html);
      expect(inlineArtifactType('application/vnd.react'), InlineArtifact.react);
      expect(inlineArtifactType('image/svg+xml'), InlineArtifact.svg);
      expect(
        inlineArtifactType('application/vnd.mermaid'),
        InlineArtifact.mermaid,
      );
      expect(inlineArtifactType('text/markdown'), InlineArtifact.markdown);
      expect(inlineArtifactType('text/plain'), isNull);
      expect(inlineArtifactType('text/x-python'), isNull);
    });

    test('everything but plain code previews (Req 24.7)', () {
      expect(artifactPreviewable('text/markdown'), isTrue);
      expect(artifactPreviewable('text/plain'), isTrue);
      expect(artifactPreviewable('text/x-python'), isFalse);
    });

    test('the share file name sanitizes the title (Req 24.13)', () {
      expect(artifactFileName(_markdown('x')), 'Notes.md');
      expect(
        artifactFileName(_markdown('x', title: 'a/b:c*d?"<>|')),
        'a_b_c_d_____.md',
      );
      expect(artifactFileName(_markdown('x', title: '   ')), 'artifact.md');
      expect(
        artifactFileName(_markdown('x', title: 'A' * 150)),
        '${'A' * 100}.md',
      );
    });

    test('the extension and MIME type follow the artifact type', () {
      const cases = {
        'application/vnd.mermaid': ('mmd', 'text/plain'),
        'text/html': ('html', 'text/html'),
        'application/vnd.code-html': ('html', 'text/html'),
        'application/vnd.react': ('jsx', 'text/javascript'),
        'image/svg+xml': ('svg', 'image/svg+xml'),
        'text/css': ('css', 'text/css'),
        'application/json': ('json', 'application/json'),
        'text/markdown': ('md', 'text/markdown'),
        'text/md': ('md', 'text/markdown'),
        'text/x-python': ('txt', 'text/plain'),
      };
      for (final MapEntry(key: type, value: (ext, mime)) in cases.entries) {
        expect(artifactFileExtension(type), ext, reason: type);
        expect(artifactShareMimeType(type), mime, reason: type);
      }
    });
  });

  group('in a message', () {
    Future<void> pump(
      WidgetTester tester,
      String text, {
      Set<InlineArtifact> inline = const {},
      bool streaming = false,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformActionsProvider.overrideWithValue(FakePlatformActions()),
          settingsProvider.overrideWith(
            () => FakeSettingsStore(AppSettings(inlineArtifacts: inline)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MessageView(
                Message(messageId: 'm', conversationId: 'c', text: text),
                streaming: streaming,
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('a complete artifact renders as a button (Req 24.4)', (
      tester,
    ) async {
      await pump(
        tester,
        'Here you go.\n${formatArtifact(_markdown('# Heading'))}\nEnjoy.',
      );
      expect(find.byType(ArtifactButton), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Markdown Document'), findsOneWidget);
      expect(find.byIcon(Icons.article), findsOneWidget);
      // The text around the block still renders as Markdown.
      expect(find.text('Here you go.', findRichText: true), findsOneWidget);
      expect(find.text('Enjoy.', findRichText: true), findsOneWidget);
      // The button shows the title, not the source.
      expect(find.text('Heading', findRichText: true), findsNothing);
    });

    testWidgets('an inline type renders inline once settled (Req 24.5)', (
      tester,
    ) async {
      final text = formatArtifact(_markdown('Rendered body'));
      await pump(tester, text, inline: {InlineArtifact.markdown});
      expect(find.byType(InlineArtifactCard), findsOneWidget);
      expect(find.byType(ArtifactButton), findsNothing);
      expect(find.text('Rendered body', findRichText: true), findsOneWidget);

      // While the reply streams the same artifact stays a button.
      await pump(
        tester,
        text,
        inline: {InlineArtifact.markdown},
        streaming: true,
      );
      expect(find.byType(ArtifactButton), findsOneWidget);
      expect(find.byType(InlineArtifactCard), findsNothing);
    });

    testWidgets('a type the settings leave off stays a button', (tester) async {
      await pump(
        tester,
        formatArtifact(_markdown('Body')),
        inline: {InlineArtifact.html},
      );
      expect(find.byType(ArtifactButton), findsOneWidget);
      expect(find.byType(InlineArtifactCard), findsNothing);
    });

    testWidgets('an unclosed block renders its source (Req 24.3)', (
      tester,
    ) async {
      await pump(
        tester,
        ':::artifact{identifier=notes type=text/markdown title=Notes}\n'
        '```\nhalf written',
      );
      expect(find.byType(IncompleteArtifactView), findsOneWidget);
      expect(find.text('Incomplete'), findsOneWidget);
      expect(find.byType(CodeBlock), findsOneWidget);
      expect(find.text('half written', findRichText: true), findsOneWidget);
      expect(find.byType(ArtifactButton), findsNothing);
    });

    testWidgets('a button shows the number of versions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(FakeSettingsStore.new),
            platformActionsProvider.overrideWithValue(FakePlatformActions()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ArtifactButton(
                artifact: _markdown('a'),
                onTap: () {},
                versionCount: 3,
              ),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      // One tappable node, read as "Open artifact, <title>, <type>, <n>".
      expect(
        find.bySemanticsLabel(
          RegExp('^Open artifact\nNotes\nMarkdown Document\n3'),
        ),
        findsOneWidget,
      );
    });
  });

  group('the viewer', () {
    late FakePlatformActions platform;

    setUp(() => platform = FakePlatformActions());

    /// A `/` screen whose button opens [artifact], plus the `/artifact`
    /// route, so both the sheet and the fullscreen mode are reachable.
    Future<void> pump(
      WidgetTester tester,
      Artifact artifact, {
      List<Artifact> versions = const [],
      ArtifactViewer mode = ArtifactViewer.sheet,
    }) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () =>
                      openArtifact(context, ref, artifact, versions: versions),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.artifactFullscreen,
            builder: (context, state) =>
                ArtifactFullscreenScreen(args: state.extra! as ArtifactArgs),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformActionsProvider.overrideWithValue(platform),
            settingsProvider.overrideWith(
              () => FakeSettingsStore(AppSettings(artifactViewer: mode)),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('the sheet opens on the preview, and the toggle shows the '
        'source (Req 24.13)', (tester) async {
      await pump(tester, _markdown('Rendered body'));
      expect(find.byType(ArtifactPanel), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Rendered body', findRichText: true), findsOneWidget);
      expect(find.byType(CodeBlock), findsNothing);

      await tester.tap(find.byTooltip('View source'));
      await tester.pumpAndSettle();
      expect(find.byType(CodeBlock), findsOneWidget);

      await tester.tap(find.byTooltip('View preview'));
      await tester.pumpAndSettle();
      expect(find.byType(CodeBlock), findsNothing);
    });

    testWidgets('a code artifact has no toggle and opens on its source', (
      tester,
    ) async {
      await pump(
        tester,
        const Artifact(
          identifier: 'script',
          type: 'text/x-python',
          title: 'script.py',
          content: 'print(1)',
        ),
      );
      expect(find.byType(CodeBlock), findsOneWidget);
      expect(find.byTooltip('View source'), findsNothing);
      expect(find.byTooltip('View preview'), findsNothing);
    });

    testWidgets('copy and share carry the version in view (Req 24.13)', (
      tester,
    ) async {
      await pump(tester, _markdown('Rendered body'));
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pumpAndSettle();
      expect(platform.copies, ['Rendered body']);
      expect(find.byTooltip('Copied'), findsOneWidget);

      await tester.tap(find.byTooltip('Share artifact'));
      await tester.pumpAndSettle();
      final shared = platform.sharedFiles.single;
      expect(shared.fileName, 'Notes.md');
      expect(shared.mimeType, 'text/markdown');
      expect(utf8.decode(shared.bytes), 'Rendered body');
    });

    testWidgets('the version pager steps through the identifier (Req 24.12)', (
      tester,
    ) async {
      final versions = [
        _markdown('First draft'),
        _markdown('Second draft'),
        _markdown('Third draft'),
      ];
      await pump(tester, versions[1], versions: versions);
      expect(find.text('v2/3'), findsOneWidget);
      expect(find.text('Second draft', findRichText: true), findsOneWidget);

      await tester.tap(find.byTooltip('Next version'));
      await tester.pumpAndSettle();
      expect(find.text('v3/3'), findsOneWidget);
      expect(find.text('Third draft', findRichText: true), findsOneWidget);
      // The newest version has nothing after it.
      expect(_enabled(tester, 'Next version'), isFalse);

      await tester.tap(find.byTooltip('Previous version'));
      await tester.tap(find.byTooltip('Previous version'));
      await tester.pumpAndSettle();
      expect(find.text('v1/3'), findsOneWidget);
      expect(find.text('First draft', findRichText: true), findsOneWidget);
      expect(_enabled(tester, 'Previous version'), isFalse);
      expect(_enabled(tester, 'Next version'), isTrue);
    });

    testWidgets('a single version has no pager', (tester) async {
      await pump(tester, _markdown('Only one'));
      expect(find.byTooltip('Next version'), findsNothing);
      expect(find.textContaining('v1/'), findsNothing);
    });

    testWidgets('Fullscreen opens /artifact on the version in view '
        '(Req 24.13)', (tester) async {
      final versions = [_markdown('First draft'), _markdown('Second draft')];
      await pump(tester, versions[0], versions: versions);
      await tester.tap(find.byTooltip('Next version'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fullscreen'));
      await tester.pumpAndSettle();

      // The sheet is gone and the route carries the version in view, with
      // its pager, to the root navigator.
      expect(find.byType(ArtifactFullscreenScreen), findsOneWidget);
      expect(find.byType(ArtifactPanel), findsOneWidget);
      expect(find.text('Second draft', findRichText: true), findsOneWidget);
      expect(find.text('v2/2'), findsOneWidget);
      expect(find.byTooltip('Fullscreen'), findsNothing);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ArtifactFullscreenScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('the fullscreen setting opens the route instead of the sheet '
        '(Req 24.5, 40.3)', (tester) async {
      await pump(
        tester,
        _markdown('Rendered body'),
        mode: ArtifactViewer.fullscreen,
      );
      expect(find.byType(ArtifactFullscreenScreen), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byTooltip('Fullscreen'), findsNothing);
      expect(find.text('Rendered body', findRichText: true), findsOneWidget);
    });

    // An HTML artifact previews through the WebView_Host, so these run over
    // a fake WebView platform and drive the two error paths the design
    // names: a page `{error}` message and a main-frame load failure.
    group('a page that fails to render (Req 24.14)', () {
      late FakeWebViewPlatform webView;

      setUp(() => webView = FakeWebViewPlatform.install());

      Artifact page([String content = '<p>hi</p>']) => Artifact(
        identifier: 'page',
        type: 'text/html',
        title: 'Page',
        content: content,
      );

      testWidgets('a page error shows the message with a View code action', (
        tester,
      ) async {
        await pump(tester, page());
        expect(find.byType(CodeBlock), findsNothing);
        expect(find.text('View code'), findsNothing);

        webView.controller.postHostMessage('{"error":"Component failed"}');
        await tester.pumpAndSettle();
        expect(find.text('Component failed'), findsOneWidget);

        await tester.tap(find.text('View code'));
        await tester.pumpAndSettle();
        // The source is on screen, and the error bar steps aside with it.
        expect(find.byType(CodeBlock), findsOneWidget);
        expect(find.text('<p>hi</p>', findRichText: true), findsOneWidget);
        expect(find.text('Component failed'), findsNothing);

        // Back to the preview, the error is still the page's state.
        await tester.tap(find.byTooltip('View preview'));
        await tester.pumpAndSettle();
        expect(find.byType(CodeBlock), findsNothing);
        expect(find.text('Component failed'), findsOneWidget);
      });

      testWidgets('a main-frame load failure shows the same action', (
        tester,
      ) async {
        await pump(tester, page());
        webView.controller.failLoad('net::ERR_FAILED', isForMainFrame: false);
        await tester.pumpAndSettle();
        expect(find.text('View code'), findsNothing);

        webView.controller.failLoad('net::ERR_FAILED');
        await tester.pumpAndSettle();
        expect(find.text('net::ERR_FAILED'), findsOneWidget);

        await tester.tap(find.text('View code'));
        await tester.pumpAndSettle();
        expect(find.byType(CodeBlock), findsOneWidget);
      });

      testWidgets('another version starts without the error (Req 24.12)', (
        tester,
      ) async {
        final versions = [page('<p>one</p>'), page('<p>two</p>')];
        await pump(tester, versions[0], versions: versions);
        webView.controller.postHostMessage('{"error":"Component failed"}');
        await tester.pumpAndSettle();
        expect(find.text('Component failed'), findsOneWidget);

        await tester.tap(find.byTooltip('Next version'));
        await tester.pumpAndSettle();
        expect(find.text('v2/2'), findsOneWidget);
        expect(find.text('Component failed'), findsNothing);
        expect(find.text('View code'), findsNothing);
        // The new version's document is what the WebView now holds.
        expect(webView.controller.loads.last.$1, contains('<p>two</p>'));
      });
    });
  });
}
