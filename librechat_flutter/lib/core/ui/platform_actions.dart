import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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

/// The platform calls behind save, pick, share and copy, in one seam so
/// widget tests never reach a plugin channel.
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

  /// Opens the system share sheet with [text].
  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  /// Puts [text] on the clipboard.
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
