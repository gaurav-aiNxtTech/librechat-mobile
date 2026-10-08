import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/file_config.dart';
import 'package:librechat_flutter/features/chat/composer/attachments.dart';

FileInfo file(String name, int size, [String mimeType = 'image/png']) =>
    FileInfo(name: name, size: size, mimeType: mimeType);

FileConfig config(Map<String, EndpointFileConfig> endpoints) =>
    FileConfig(endpoints: endpoints);

const accepted = AttachmentAccepted();

AttachmentRejected rejected(AttachmentLimit limit, [String? fileName]) =>
    AttachmentRejected(limit, fileName: fileName);

void main() {
  const limits = EndpointFileConfig(
    fileLimit: 2,
    fileSizeLimit: 100,
    totalSizeLimit: 150,
    supportedMimeTypes: ['^image/.*\$', '^application/pdf\$'],
  );

  test('an endpoint entry wins over default as a whole entry', () {
    final c = config({
      'openAI': const EndpointFileConfig(fileLimit: 5),
      'default': limits,
    });
    expect(
      checkAttachments([file('a', 500, 'audio/x'), file('b', 1)], c, 'openAI'),
      accepted,
    );
  });

  test('an unknown endpoint uses default', () {
    final c = config({'default': limits});
    expect(
      checkAttachments([file('a', 500)], c, 'custom'),
      rejected(AttachmentLimit.fileSizeLimit, 'a'),
    );
  });

  test('with neither entry, anything is accepted', () {
    final c = config({'agents': const EndpointFileConfig(disabled: true)});
    expect(
      checkAttachments([file('a', 1 << 40, 'x/y')], c, 'openAI'),
      accepted,
    );
    expect(checkAttachments([file('a', 1)], const FileConfig(), 'x'), accepted);
  });

  test('disabled rejects, even an empty set', () {
    final c = config({'agents': const EndpointFileConfig(disabled: true)});
    expect(
      checkAttachments([], c, 'agents'),
      rejected(AttachmentLimit.disabled),
    );
  });

  test('a count over fileLimit is rejected', () {
    final c = config({'default': limits});
    expect(
      checkAttachments([file('a', 1), file('b', 1), file('c', 1)], c, 'x'),
      rejected(AttachmentLimit.fileLimit),
    );
  });

  test('a size over fileSizeLimit names the first big file', () {
    final c = config({'default': limits});
    expect(
      checkAttachments([file('small', 10), file('big', 101)], c, 'x'),
      rejected(AttachmentLimit.fileSizeLimit, 'big'),
    );
  });

  test('a total over totalSizeLimit is rejected', () {
    final c = config({'default': limits});
    expect(
      checkAttachments([file('a', 100), file('b', 51)], c, 'x'),
      rejected(AttachmentLimit.totalSizeLimit),
    );
  });

  test('a mime mismatch names the file', () {
    final c = config({'default': limits});
    expect(
      checkAttachments(
        [file('a.pdf', 1, 'application/pdf'), file('b.mp3', 1, 'audio/mpeg')],
        c,
        'x',
      ),
      rejected(AttachmentLimit.mimeType, 'b.mp3'),
    );
  });

  test('values exactly at each limit are accepted', () {
    final c = config({'default': limits});
    expect(
      checkAttachments(
        [file('a', 100), file('b', 50, 'application/pdf')],
        c,
        'x',
      ),
      accepted,
    );
  });

  test('the first broken limit is reported, in order', () {
    final c = config({'default': limits});
    expect(
      checkAttachments(
        [file('a', 999, 'x/y'), file('b', 999), file('c', 999)],
        c,
        'x',
      ),
      rejected(AttachmentLimit.fileLimit),
    );
    expect(
      checkAttachments([file('a', 101, 'x/y')], c, 'x'),
      rejected(AttachmentLimit.fileSizeLimit, 'a'),
    );
  });

  test('a limit of 0 restricts', () {
    final c = config({'default': const EndpointFileConfig(fileLimit: 0)});
    expect(
      checkAttachments([file('a', 1)], c, 'x'),
      rejected(AttachmentLimit.fileLimit),
    );
    final sized = config({
      'default': const EndpointFileConfig(fileSizeLimit: 0),
    });
    expect(checkAttachments([file('empty', 0)], sized, 'x'), accepted);
    expect(
      checkAttachments([file('a', 1)], sized, 'x'),
      rejected(AttachmentLimit.fileSizeLimit, 'a'),
    );
  });

  test('null limits and an empty pattern list accept', () {
    final c = config({'default': const EndpointFileConfig()});
    expect(
      checkAttachments(
        [for (var i = 0; i < 50; i++) file('f$i', 1 << 40, 'x/y')],
        c,
        'x',
      ),
      accepted,
    );
  });

  test('an invalid pattern is ignored', () {
    final onlyInvalid = config({
      'default': const EndpointFileConfig(supportedMimeTypes: ['[']),
    });
    expect(checkAttachments([file('a', 1, 'x/y')], onlyInvalid, 'x'), accepted);
    final mixed = config({
      'default': const EndpointFileConfig(supportedMimeTypes: ['[', '^text/']),
    });
    expect(
      checkAttachments([file('a.txt', 1, 'text/plain')], mixed, 'x'),
      accepted,
    );
    expect(
      checkAttachments([file('a', 1, 'x/y')], mixed, 'x'),
      rejected(AttachmentLimit.mimeType, 'a'),
    );
  });

  group('FileInfo.detect', () {
    test('reads the extension', () {
      expect(FileInfo.detect(name: 'a.png', size: 3).mimeType, 'image/png');
    });

    test('header bytes win over the extension', () {
      final info = FileInfo.detect(
        name: 'photo.txt',
        size: 8,
        headerBytes: const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
      expect(info.mimeType, 'image/png');
    });

    test('an unknown type is application/octet-stream', () {
      final info = FileInfo.detect(name: 'a.zzz-unknown', size: 1);
      expect(info, file('a.zzz-unknown', 1, 'application/octet-stream'));
    });
  });
}
