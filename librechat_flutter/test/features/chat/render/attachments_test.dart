// Images, attachments, office previews and media sources
// (Req 23.4-23.8).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/images/image_loader.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/data/file_downloads.dart';
import 'package:librechat_flutter/features/chat/render/attachment_card.dart';
import 'package:librechat_flutter/features/chat/render/content_part_view.dart';
import 'package:librechat_flutter/features/chat/render/image_viewer.dart';
import 'package:librechat_flutter/features/chat/render/markdown_text.dart';
import 'package:librechat_flutter/features/chat/render/media_player.dart';
import 'package:librechat_flutter/features/chat/render/message_view.dart';
import 'package:librechat_flutter/features/chat/render/tool_call_card.dart';

import '../../../support/fakes.dart';

const _webSearch = Attachment(
  type: 'web_search',
  toolCallId: 'ws',
  webSearch: {'organic': <Object?>[]},
);
const _fileSearch = Attachment(
  type: 'file_search',
  toolCallId: 'fs',
  fileSearch: {'sources': <Object?>[]},
);
const _toolFile = Attachment(
  fileId: 'f-tool',
  filename: 'out.csv',
  type: 'text/csv',
  toolCallId: 't1',
);
const _orphan = Attachment(
  fileId: 'f-orphan',
  filename: 'notes.pdf',
  type: 'application/pdf',
  toolCallId: 'gone',
);
const _office = Attachment(
  fileId: 'f-doc',
  filename: 'report.docx',
  type: 'application/vnd.librechat.docx-preview',
  toolCallId: 't1',
);

void main() {
  group('which attachments render where', () {
    test('the message leaves out search payloads and tool-owned files', () {
      final shown = messageAttachments(
        const [_webSearch, _fileSearch, _toolFile, _orphan, _office, _orphan],
        {'t1', 'ws', 'fs'},
      );
      // Office previews stay at message level even when a tool owns them.
      expect(shown, const [_orphan, _office]);
    });

    test('a tool card takes its own files, without previews or payloads', () {
      const memory = Attachment(type: 'memory', toolCallId: 't1');
      const placeholder = Attachment(
        fileId: 'p',
        filename: '_.gitkeep-a1b2c3',
        toolCallId: 't1',
      );
      expect(
        toolCallAttachments(const [
          _toolFile,
          _office,
          memory,
          placeholder,
          _orphan,
          _toolFile,
        ], 't1'),
        const [_toolFile],
      );
      expect(toolCallAttachments(const [_toolFile], null), isEmpty);
    });

    test('an office preview is known by its mime type (Req 23.7)', () {
      for (final type in const [
        'application/vnd.librechat.docx-preview',
        'application/vnd.librechat.xlsx-preview',
      ]) {
        expect(isOfficePreview(Attachment(type: type)), isTrue, reason: type);
      }
      for (final type in const [
        null,
        'application/pdf',
        'application/vnd.librechat.docx',
        'application/vnd.openxmlformats-docx-preview',
      ]) {
        expect(
          isOfficePreview(Attachment(type: type)),
          isFalse,
          reason: '$type',
        );
      }
      // The preview mime type never reaches a download: the name decides.
      expect(
        attachmentMimeType(_office, 'report.docx'),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    });

    test('names, image URLs and download paths', () {
      expect(displayFilename('_.config-abcdef.txt'), '.config.txt');
      expect(displayFilename('report-deadbe.csv'), 'report-deadbe.csv');
      expect(
        isImageAttachment(const Attachment(filepath: '/images/u/a.PNG')),
        isTrue,
      );
      expect(isImageAttachment(const Attachment(filename: 'a.svg')), isFalse);
      expect(
        attachmentImageUrl(const Attachment(filepath: 'images/u/a.png')),
        '/images/u/a.png',
      );
      expect(attachmentImageUrl(const Attachment(fileId: 'x')), '/api/files/x');
      expect(
        attachmentDownloadPath(const Attachment(fileId: 'f 1'), 'u1'),
        '/api/files/download/u1/f%201',
      );
      expect(attachmentDownloadPath(const Attachment(fileId: 'f'), null), null);
      expect(
        attachmentDownloadPath(
          const Attachment(filepath: 'https://cdn.example/a.pdf'),
          null,
        ),
        'https://cdn.example/a.pdf',
      );
      expect(safeFileName('../../etc/passwd'), 'passwd');
      expect(safeFileName('a:b?.txt'), 'a_b_.txt');
      expect(safeFileName('..'), 'file');
    });

    test('image part URLs follow the KMP resolver', () {
      ContentPart file(Map<String, Object?> f) =>
          ContentPart(type: ContentPartType.imageFile, imageFile: f);
      expect(
        imagePartUrl(
          const ContentPart(
            type: ContentPartType.imageUrl,
            imageUrl: {'url': 'https://x.example/a.png'},
          ),
        ),
        'https://x.example/a.png',
      );
      expect(
        imagePartUrl(
          const ContentPart(type: ContentPartType.imageUrl, imageUrl: 'data:,'),
        ),
        'data:,',
      );
      expect(
        imagePartUrl(file({'filepath': '/images/u/a.png'})),
        '/images/u/a.png',
      );
      expect(imagePartUrl(file({'filepath': 'u/a.png'})), '/api/files/u/a.png');
      expect(imagePartUrl(file({'file_id': 'f'})), '/api/files/f');
      expect(imagePartUrl(file({})), isNull);
    });

    test('an HTML preview reads as plain text, nothing rendered', () {
      expect(
        htmlToPlainText(
          '<html><head><style>p{}</style></head><body>'
          '<h1>Title</h1><p>Fish &amp; chips&nbsp;&#x21;</p>'
          '<ul><li>One</li><li>Two</li></ul><script>alert(1)</script>'
          '</body></html>',
        ),
        'Title\n\nFish & chips !\n\n• One\n• Two',
      );
    });

    test('media sources and times', () {
      final audio = audioSource(
        ContentPart(
          type: ContentPartType.inputAudio,
          inputAudio: {
            'data': base64Encode([1, 2]),
            'format': 'mp3',
          },
        ),
      );
      expect(audio?.bytes, [1, 2]);
      expect(audio?.fileName, 'audio.mp3');
      expect(
        audioSource(
          const ContentPart(
            type: ContentPartType.inputAudio,
            inputAudio: {'data': 'not base64!'},
          ),
        ),
        isNull,
      );
      final video = videoSource(
        const ContentPart(
          type: ContentPartType.videoUrl,
          videoUrl: {'url': '/api/files/v/clip.webm'},
        ),
      );
      expect(
        (video?.url, video?.fileName),
        ('/api/files/v/clip.webm', 'clip.webm'),
      );
      expect(
        videoSource(const ContentPart(type: ContentPartType.videoUrl)),
        isNull,
      );
      expect(formatMediaDuration(const Duration(seconds: 65)), '1:05');
      expect(formatMediaDuration(const Duration(seconds: 3725)), '1:02:05');
    });

    test('a saved image is named by its name, URL or bytes', () {
      final png = FakeImageLoader.png;
      expect(imageFileName('/images/u/a.png', 'Cat.jpg', png), 'Cat.jpg');
      expect(imageFileName('/images/u/photo.png', null, png), 'photo.png');
      expect(imageFileName('data:image/png;base64,xx', null, png), 'image.png');
      expect(imageMimeType('photo.png', png), 'image/png');
    });
  });

  group('widgets', () {
    late FakePlatformActions platform;
    late FakeFileDownloads downloads;
    late FakeImageLoader images;

    setUp(() {
      platform = FakePlatformActions();
      downloads = FakeFileDownloads();
      images = FakeImageLoader();
    });

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformActionsProvider.overrideWithValue(platform),
          fileDownloadsProvider.overrideWithValue(downloads),
          imageLoaderProvider.overrideWithValue(images),
          settingsProvider.overrideWith(FakeSettingsStore.new),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

    testWidgets('office previews show pending, ready and failed (Req 23.7)', (
      tester,
    ) async {
      Widget card(Attachment a) => OfficePreviewCard(a, storageKey: 'm/a');

      await pump(tester, card(_office.copyWith(status: 'pending')));
      expect(find.text('Preparing preview of report.docx…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pump(
        tester,
        card(
          _office.copyWith(
            status: 'ready',
            text: '<p>Quarterly <b>results</b></p>',
            textFormat: 'html',
          ),
        ),
      );
      expect(find.text('report.docx'), findsOneWidget);
      expect(find.text('Quarterly results'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await pump(
        tester,
        card(_office.copyWith(status: 'ready', text: 'plain *text*')),
      );
      expect(find.text('plain *text*'), findsOneWidget);

      // A markdown preview renders as markdown, so the syntax is gone.
      await pump(
        tester,
        card(
          _office.copyWith(
            status: 'ready',
            text: 'Quarterly **results**',
            textFormat: 'markdown',
          ),
        ),
      );
      expect(find.byType(MarkdownText), findsOneWidget);
      expect(find.text('Quarterly **results**'), findsNothing);
      expect(
        find.textContaining('Quarterly results', findRichText: true),
        findsOneWidget,
      );

      // No status at all reads as ready.
      await pump(tester, card(_office.copyWith(text: 'ready by default')));
      expect(find.text('ready by default'), findsOneWidget);

      await pump(tester, card(_office.copyWith(status: 'ready')));
      expect(find.text('report.docx — preview not available'), findsOneWidget);

      // Blank text is no preview either.
      await pump(
        tester,
        card(_office.copyWith(status: 'ready', text: '   \n ')),
      );
      expect(find.text('report.docx — preview not available'), findsOneWidget);

      await pump(
        tester,
        card(_office.copyWith(status: 'failed', previewError: 'timeout')),
      );
      expect(
        find.text("Couldn't preview report.docx (timeout)"),
        findsOneWidget,
      );

      // Failed without a reason, and failed text wins over a stale preview.
      await pump(
        tester,
        card(_office.copyWith(status: 'failed', text: 'stale')),
      );
      expect(find.text("Couldn't preview report.docx ()"), findsOneWidget);
      expect(find.text('stale'), findsNothing);
    });

    testWidgets('an image part opens the viewer, which saves and shares', (
      tester,
    ) async {
      await pump(
        tester,
        const MediaPartView(
          part: ContentPart(
            type: ContentPartType.imageFile,
            imageFile: {'filepath': '/images/u/photo.png'},
          ),
        ),
      );
      await tester.pump();
      expect(images.loads, ['/images/u/photo.png']);

      await tester.tap(find.bySemanticsLabel('Embedded image in message'));
      await tester.pumpAndSettle();
      expect(find.byType(ImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byTooltip('Save to device'));
      await tester.pumpAndSettle();
      expect(platform.saves.single.fileName, 'photo.png');
      expect(platform.saves.single.mimeType, 'image/png');

      await tester.tap(find.byTooltip('Share image'));
      await tester.pumpAndSettle();
      expect(platform.sharedFiles.single.bytes, FakeImageLoader.png);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ImageViewer), findsNothing);
    });

    testWidgets('a file card opens and saves through the seams (Req 23.6)', (
      tester,
    ) async {
      await pump(tester, const AttachmentCard(_orphan));
      await tester.tap(find.bySemanticsLabel('Attached file: notes.pdf'));
      await tester.pumpAndSettle();
      expect(downloads.requests, ['f-orphan']);
      expect(platform.openedFiles, [
        ('/fake/downloads/notes.pdf', 'application/pdf'),
      ]);

      await tester.tap(find.byTooltip('Save to device'));
      await tester.pumpAndSettle();
      expect(platform.saves.single.fileName, 'notes.pdf');
      expect(platform.saves.single.bytes, Uint8List.fromList(const [1, 2, 3]));

      platform.openResult = OpenFileResult.noApp;
      await tester.tap(find.bySemanticsLabel('Attached file: notes.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('No app can open this file'), findsOneWidget);
    });

    testWidgets(
      'tool files render under their card; image gen shows its image',
      (tester) async {
        await pump(
          tester,
          const ToolCallCard(
            part: ContentPart(
              type: ContentPartType.toolCall,
              toolCall: ToolCall(id: 't1', name: 'execute_code', output: 'ok'),
            ),
            storageKey: 'm/part:t1',
            attachments: [_toolFile, _orphan],
          ),
        );
        expect(find.text('execute_code'), findsOneWidget);
        expect(find.bySemanticsLabel('Attached file: out.csv'), findsOneWidget);
        expect(find.bySemanticsLabel('Attached file: notes.pdf'), findsNothing);

        await pump(
          tester,
          const ToolCallCard(
            part: ContentPart(
              type: ContentPartType.toolCall,
              toolCall: ToolCall(id: 'g1', name: 'image_gen_oai', output: 'ok'),
            ),
            storageKey: 'm/part:g1',
            attachments: [
              Attachment(
                fileId: 'img',
                filename: 'cat.png',
                filepath: '/images/u/cat.png',
                type: 'image/png',
                toolCallId: 'g1',
              ),
            ],
          ),
        );
        expect(find.text('Image generated'), findsOneWidget);
        expect(find.byType(InlineImage), findsOneWidget);
      },
    );

    testWidgets('a message draws each file once and no search payloads', (
      tester,
    ) async {
      await pump(
        tester,
        const MessageView(
          Message(
            messageId: 'm',
            conversationId: 'c',
            content: [
              ContentPart(
                type: ContentPartType.toolCall,
                toolCall: ToolCall(
                  id: 't1',
                  name: 'execute_code',
                  output: 'ok',
                ),
              ),
              ContentPart(type: ContentPartType.text, text: 'Done.'),
            ],
            attachments: [_webSearch, _fileSearch, _toolFile, _orphan],
            files: [
              Attachment(
                fileId: 'up',
                filename: 'upload.txt',
                type: 'text/plain',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Attached file: out.csv'), findsOneWidget);
      expect(find.bySemanticsLabel('Attached file: notes.pdf'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Attached file: upload.txt'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Attached file')), findsNWidgets(3));
    });
  });
}
