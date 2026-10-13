import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A file the user picked: its [name], its [size] in bytes when known, and
/// [read] for its bytes.
typedef PickedFile = ({
  String name,
  int? size,
  Future<Uint8List> Function() read,
});

/// The [PlatformActions] screens call. Tests override it.
final platformActionsProvider = Provider<PlatformActions>(
  (ref) => const PlatformActions(),
);

/// The platform calls behind save, pick, share, copy, external links and
/// opening files, in one seam so widget tests never reach a plugin channel.
class PlatformActions {
  const PlatformActions();

  /// Opens the Android document picker to save [bytes] as [fileName].
  /// True when saved, false when the user cancelled.
  Future<bool> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return uri != null;
  }

  /// Opens the document picker for one `.json` file, or null when the user
  /// cancelled.
  Future<PickedFile?> pickJsonFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return (name: file.name, size: await file.length(), read: file.readAsBytes);
  }

  /// Opens the document picker for any number of files, for the Composer's
  /// "Files" source (Req 26.1). Empty when the user cancelled.
  Future<List<PickedFile>> pickFiles() async {
    final files = await FilePicker.pickFiles();
    return [
      for (final file in files)
        (name: file.name, size: await file.length(), read: file.readAsBytes),
    ];
  }

  /// Opens the photo picker for any number of images (Req 26.1). Empty when
  /// the user cancelled.
  Future<List<PickedFile>> pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    return [
      for (final image in images)
        (name: image.name, size: await image.length(), read: image.readAsBytes),
    ];
  }

  /// Takes one photo with the camera (Req 26.1), or null when the user
  /// backed out.
  ///
  /// The plugin asks for the CAMERA permission the first time (Req 44.10);
  /// a denial throws a [PlatformException], which the caller explains
  /// without closing anything down (Req 44.11).
  Future<PickedFile?> takePhoto() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    return (
      name: photo.name,
      size: await photo.length(),
      read: photo.readAsBytes,
    );
  }

  /// Opens the system share sheet with [text].
  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  /// Puts [text] on the clipboard.
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Opens [uri] in the external app for its scheme, such as the browser
  /// (Req 22.7). False when no app handles it.
  Future<bool> openExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system share sheet with [bytes] as the file [fileName].
  Future<void> shareFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
      fileNameOverrides: [fileName],
    ),
  );

  /// Opens the local file at [path] in the app the user picks for
  /// [mimeType], through open_filex's FileProvider (Req 23.6).
  Future<OpenFileResult> openFile(String path, {String? mimeType}) async {
    try {
      final result = await OpenFilex.open(path, type: mimeType);
      return switch (result.type) {
        ResultType.done => OpenFileResult.opened,
        ResultType.noAppToOpen => OpenFileResult.noApp,
        _ => OpenFileResult.failed,
      };
    } on PlatformException {
      return OpenFileResult.failed;
    }
  }
}

/// How [PlatformActions.openFile] ended.
enum OpenFileResult { opened, noApp, failed }
