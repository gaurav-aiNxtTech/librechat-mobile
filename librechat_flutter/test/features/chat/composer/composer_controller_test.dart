import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/auth/auth_service.dart';
import 'package:librechat_flutter/core/config/feature_gate.dart';
import 'package:librechat_flutter/core/config/server_config.dart';
import 'package:librechat_flutter/core/log/diagnostic_log.dart';
import 'package:librechat_flutter/core/models/endpoint_config.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';
import 'package:librechat_flutter/core/network/app_exception.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';
import 'package:librechat_flutter/core/storage/settings_store.dart';
import 'package:librechat_flutter/core/stream/stream_client.dart';
import 'package:librechat_flutter/core/ui/platform_actions.dart';
import 'package:librechat_flutter/features/chat/composer/attachments.dart';
import 'package:librechat_flutter/features/chat/composer/composer_controller.dart';
import 'package:librechat_flutter/features/chat/data/chat_api.dart';
import 'package:librechat_flutter/features/chat/data/conversation_messages.dart';
import 'package:librechat_flutter/features/chat/data/messages_repository.dart';
import 'package:librechat_flutter/features/chat/run/run_service.dart';
import 'package:librechat_flutter/features/chat/send/chat_turn.dart';
import 'package:librechat_flutter/features/conversations/conversations_repository.dart';
import 'package:librechat_flutter/features/files/files_api.dart';

import '../../../support/fakes.dart';

void main() {
  late Directory logDir;
  late DiagnosticLog log;
  late FakeMessagesRepository messages;
  late FakeChatApi chatApi;
  late FakeFilesApi files;
  late FakeSettingsStore settings;
  late ProviderContainer container;

  setUp(() async {
    logDir = await Directory.systemTemp.createTemp('composer_test');
    log = await DiagnosticLog.open(directory: logDir);
    messages = FakeMessagesRepository();
    chatApi = FakeChatApi();
    files = FakeFilesApi();
    settings = FakeSettingsStore(
      const AppSettings(lastEndpoint: 'openAI', lastModel: 'gpt-4o'),
    );
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authServiceProvider.overrideWith((ref) => FakeAuthService()),
        diagnosticLogProvider.overrideWithValue(log),
        chatApiProvider.overrideWithValue(chatApi),
        filesApiProvider.overrideWithValue(files),
        streamClientProvider.overrideWithValue(FakeStreamClient()),
        messagesRepositoryProvider.overrideWithValue(messages),
        conversationsRepositoryProvider.overrideWithValue(
          FakeConversationsRepository(),
        ),
        deviceTimeZoneProvider.overrideWith((ref) async => 'UTC'),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
        settingsProvider.overrideWith(() => settings),
        serverConfigProvider.overrideWith(
          () => FakeServerConfig(const ServerInfo(config: StartupConfig())),
        ),
        missingFeaturesProvider.overrideWithValue(ValueNotifier(const {})),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await log.file();
    await logDir.delete(recursive: true);
  });

  /// Keeps [key]'s Composer alive, as an open Composer bar does, and lets
  /// its draft load.
  Future<ComposerController> open(String key) async {
    container.listen(composerProvider(key), (_, _) {});
    container.listen(composerSelectionProvider(key), (_, _) {});
    await pumpEventQueue();
    return container.read(composerProvider(key).notifier);
  }

  ComposerState state(String key) => container.read(composerProvider(key));

  group('drafts', () {
    test('restores the saved draft', () async {
      messages.drafts['c1'] = 'half a thought';
      await open('c1');
      expect(state('c1').text, 'half a thought');
    });

    test('text typed before the draft loads wins', () async {
      messages.drafts[newChatKey] = 'old';
      container.listen(composerProvider(newChatKey), (_, _) {});
      container.read(composerProvider(newChatKey).notifier).setText('new');
      await pumpEventQueue();
      expect(state(newChatKey).text, 'new');
    });

    test('saves after the delay, and at once on dispose', () async {
      final composer = await open('c1');
      composer.setText('draft');
      expect(messages.drafts, isEmpty);
      await Future<void>.delayed(
        ComposerController.draftDelay + const Duration(milliseconds: 50),
      );
      expect(messages.drafts['c1'], 'draft');

      composer.setText('draft 2');
      container.dispose();
      await pumpEventQueue();
      expect(messages.drafts['c1'], 'draft 2');
    });

    test('a temporary chat keeps no draft', () async {
      messages.drafts['t1'] = 'stale';
      container.read(temporaryChatsProvider.notifier).add('t1');
      final composer = await open('t1');
      expect(state('t1').text, isEmpty);
      expect(state('t1').temporary, isTrue);
      composer.setText('secret');
      container.dispose();
      await pumpEventQueue();
      expect(messages.drafts['t1'], 'stale');
    });
  });

  group('submit', () {
    test('blank text is ignored', () async {
      final composer = await open(newChatKey);
      composer.setText('   \n ');
      expect(composer.submit('new:1'), isFalse);
      await pumpEventQueue();
      expect(chatApi.starts, isEmpty);
      expect(container.read(runServiceProvider).runs, isEmpty);
    });

    test('sends the text with the selection, then clears it', () async {
      messages.drafts['c1'] = 'Hello';
      final composer = await open('c1');
      expect(composer.submit('c1', parentMessageId: 'p1'), isTrue);
      expect(state('c1').text, isEmpty);
      await pumpEventQueue();
      final (endpoint, body) = chatApi.starts.single;
      expect(endpoint, 'openAI');
      expect(body['text'], 'Hello');
      expect(body['model'], 'gpt-4o');
      expect(body['parentMessageId'], 'p1');
      expect(messages.drafts, isEmpty, reason: 'the send deletes the draft');
    });

    test('a picked model is used and stored as the last one', () async {
      final composer = await open(newChatKey);
      composer.select(const ChatSelection(endpoint: 'agents', agentId: 'a1'));
      expect(settings.saved.last.lastEndpoint, 'agents');
      expect(settings.saved.last.lastModel, 'a1');
      composer.setText('Hi');
      composer.submit('new:1');
      await pumpEventQueue();
      expect(chatApi.starts.single.$2['agent_id'], 'a1');
    });

    test('the temporary toggle sends isTemporary', () async {
      final composer = await open(newChatKey);
      composer.toggleTemporary();
      composer.setText('Off the record');
      composer.submit('new:1');
      await pumpEventQueue();
      expect(chatApi.starts.single.$2['isTemporary'], isTrue);
    });

    test('without a selection the send is refused with the KMP copy', () async {
      await container.read(settingsProvider.notifier).save(const AppSettings());
      final composer = await open(newChatKey);
      composer.setText('Hi');
      expect(composer.submit('new:1'), isFalse);
      expect(
        state(newChatKey).error,
        'Select a model before sending your message.',
      );
      expect(state(newChatKey).text, 'Hi');
    });

    test('a failed start puts the text back into the open Composer', () async {
      chatApi.startError = AppException(FailureKind.network);
      final composer = await open(newChatKey);
      composer.setText('Try this');
      composer.submit('new:1');
      expect(state(newChatKey).text, isEmpty);
      await pumpEventQueue();
      expect(state(newChatKey).text, 'Try this');
      expect(container.read(runServiceProvider).errors, contains('new:1'));
    });

    test('a starter is sent without touching the typed text', () async {
      final composer = await open(newChatKey);
      composer.setText('typed');
      expect(composer.submitText('new:1', 'Plan a trip'), isTrue);
      await pumpEventQueue();
      expect(chatApi.starts.single.$2['text'], 'Plan a trip');
      expect(state(newChatKey).text, 'typed');
    });
  });

  /// Attachments, from the check through the upload to the send
  /// (Req 26.3, 26.5-26.8).
  group('attachments', () {
    PickedFile picked(String name, [int size = 4]) =>
        (name: name, size: size, read: () async => Uint8List(size));

    /// Stages [files] and attaches them on the delivery the sheet would
    /// return, which is the provider unless [routes] says otherwise.
    Future<List<StagedAttachment>> attach(
      ComposerController composer,
      List<PickedFile> files, {
      List<UploadRoute>? routes,
    }) async {
      final batch = await composer.stageFiles(files);
      if (batch == null) return const [];
      composer.attach(
        batch.files,
        routes ?? [for (final _ in batch.files) UploadRoute.provider],
      );
      // An image reads its pixel size before it uploads.
      await pumpEventQueue();
      return batch.files;
    }

    test('the set is checked against the Server limits', () async {
      files.configReply = mergeFileConfig(
        const FileConfig(
          endpoints: {'default': EndpointFileConfig(fileLimit: 1)},
        ),
      );
      final composer = await open(newChatKey);

      expect(
        await attach(composer, [picked('a.txt'), picked('b.txt')]),
        isEmpty,
      );
      expect(
        state(newChatKey).error,
        'You can attach at most 1 files at a time.',
      );
      expect(files.uploads, isEmpty, reason: 'a refused set is not uploaded');
    });

    test('an unaccepted type is refused by name', () async {
      final composer = await open(newChatKey);
      // The Server's built-in list carries no `application/octet-stream`.
      expect(await attach(composer, [picked('blob.unknown-type')]), isEmpty);
      expect(
        state(newChatKey).error,
        'blob.unknown-type is not a type this endpoint accepts.',
      );
    });

    test('the files already staged count towards the limits', () async {
      files.configReply = mergeFileConfig(
        const FileConfig(
          endpoints: {'default': EndpointFileConfig(fileLimit: 1)},
        ),
      );
      final composer = await open(newChatKey);
      await attach(composer, [picked('a.txt')]);
      expect(state(newChatKey).files, hasLength(1));

      await attach(composer, [picked('b.txt')]);

      expect(state(newChatKey).files, hasLength(1));
      expect(state(newChatKey).error, isNotNull);
    });

    test('each file uploads with the selection, then sends', () async {
      final composer = await open(newChatKey);
      files.uploadGate = Completer<void>();

      await attach(composer, [picked('note.txt', 5)]);

      final upload = files.uploads.single;
      expect(upload.filename, 'note.txt');
      expect(upload.type, 'text/plain');
      expect(upload.endpoint, 'openAI');
      expect(upload.model, 'gpt-4o');
      expect(upload.toolResource, isNull);
      // Sending is off while the upload runs (Req 26.7).
      composer.setText('Look at this');
      expect(state(newChatKey).isUploading, isTrue);
      expect(composer.submit('new:1'), isFalse);

      files.progress[upload.fileId]!(2, 5);
      await pumpEventQueue();
      expect(state(newChatKey).files.single.progress, 0.4);

      files.uploadGate!.complete();
      await pumpEventQueue();
      expect(state(newChatKey).isUploading, isFalse);
      expect(state(newChatKey).files.single.uploaded?.fileId, upload.fileId);

      expect(composer.submit('new:1'), isTrue);
      await pumpEventQueue();
      expect(chatApi.starts.single.$2['files'], [
        {
          'file_id': upload.fileId,
          'filepath': '/uploads/${upload.fileId}',
          'type': 'text/plain',
        },
      ]);
      expect(state(newChatKey).files, isEmpty, reason: 'the send clears them');
    });

    test('a file on its own is a message', () async {
      final composer = await open(newChatKey);
      await attach(composer, [picked('note.txt')]);
      await pumpEventQueue();

      expect(composer.submit('new:1'), isTrue);
      await pumpEventQueue();
      expect(chatApi.starts.single.$2['text'], '');
    });

    test('a failed upload is kept for a retry, and not sent', () async {
      files.uploadError = AppException(FailureKind.network);
      final composer = await open(newChatKey);

      await attach(composer, [picked('note.txt')]);
      await pumpEventQueue();

      final failed = state(newChatKey).files.single;
      expect(failed.error, 'Network unavailable. Check your connection.');
      expect(failed.isUploading, isFalse);
      expect(state(newChatKey).uploaded, isEmpty);

      files.uploadError = null;
      composer.retryUpload(failed);
      await pumpEventQueue();

      expect(files.uploads, hasLength(2));
      expect(state(newChatKey).files.single.error, isNull);
      expect(state(newChatKey).files.single.uploaded, isNotNull);
    });

    test('a cancel ends the upload and drops the chip (Req 26.6)', () async {
      final composer = await open(newChatKey);
      files.uploadGate = Completer<void>();
      await attach(composer, [picked('note.txt')]);

      composer.cancelUpload(state(newChatKey).files.single);
      await pumpEventQueue();

      expect(state(newChatKey).files, isEmpty);
      expect(state(newChatKey).isUploading, isFalse);
    });

    test('removing an attachment drops it from the message', () async {
      final composer = await open(newChatKey);
      await attach(composer, [picked('a.txt'), picked('b.txt')]);
      await pumpEventQueue();
      expect(state(newChatKey).files, hasLength(2));

      composer.removeFile(state(newChatKey).files.first);
      composer.setText('Hi');
      composer.submit('new:1');
      await pumpEventQueue();

      final sent = chatApi.starts.single.$2['files']! as List;
      expect(sent, hasLength(1));
      expect(state(newChatKey).files, isEmpty);
    });

    test('server files need no upload', () async {
      final composer = await open(newChatKey);
      composer.attachServerFiles(const [
        FileObject(
          fileId: 'f9',
          filename: 'report.pdf',
          filepath: '/images/u1/report.pdf',
          type: 'application/pdf',
          bytes: 12,
        ),
      ]);

      expect(files.uploads, isEmpty);
      expect(state(newChatKey).isUploading, isFalse);
      expect(state(newChatKey).uploaded.single.fileId, 'f9');
    });

    group('delivery (Req 26.5)', () {
      /// The agents endpoint with the Server's `context` capability, where
      /// a text-extractable file has a choice.
      Future<ComposerController> onAgents() async {
        // The fake's own build resolves first, or it would overwrite this.
        await container.read(serverConfigProvider.future);
        container.read(serverConfigProvider.notifier).state = AsyncData(
          const ServerInfo(
            config: StartupConfig(),
            endpoints: {
              'agents': EndpointConfig(capabilities: ['context', 'ocr']),
            },
          ),
        );
        final composer = await open(newChatKey);
        composer.select(const ChatSelection(endpoint: 'agents', agentId: 'a1'));
        return composer;
      }

      test('a choice is offered only where text delivery is open', () async {
        final composer = await onAgents();
        final batch = await composer.stageFiles([
          picked('note.txt'),
          picked('photo.png'),
          picked('clip.mp4'),
        ]);
        // Text, but not an image and not a type the Server can extract.
        expect(batch!.choosable, [true, false, false]);
      });

      test('no context capability means no choice', () async {
        final composer = await open(newChatKey);
        final batch = await composer.stageFiles([picked('note.txt')]);
        expect(batch!.choosable, [false]);
      });

      test('the text choice uploads with tool_resource=context', () async {
        final composer = await onAgents();
        await attach(
          composer,
          [picked('note.txt')],
          routes: [UploadRoute.text],
        );

        expect(files.uploads.single.toolResource, 'context');
        expect(files.uploads.single.agentId, 'a1');
        expect(files.uploads.single.model, isNull);
        expect(state(newChatKey).files.single.route, UploadRoute.text);
      });

      test('an image stays on the provider whatever was chosen', () async {
        final composer = await onAgents();
        await attach(
          composer,
          [picked('photo.png')],
          routes: [UploadRoute.text],
        );

        expect(files.uploads.single.toolResource, isNull);
        expect(state(newChatKey).files.single.route, UploadRoute.provider);
      });
    });
  });
}
