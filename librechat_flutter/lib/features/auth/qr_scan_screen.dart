import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'server_url_controller.dart';

/// What [QrScanScreen] pops with: the scanned URL, or why the camera could
/// not run. Closing the screen pops null.
typedef QrScanResult = ({String? url, ScanProblem? problem});

/// Opens the full-screen QR scanner over the current route.
Future<QrScanResult?> showQrScanner(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<QrScanResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScanScreen(),
      ),
    );

/// The text in [barcode] if it is an `http(s)` URL, otherwise null.
String? scannedUrl(Barcode barcode) {
  final text = (barcode.url?.url ?? barcode.rawValue)?.trim();
  if (text == null) return null;
  final lower = text.toLowerCase();
  return lower.startsWith('https://') || lower.startsWith('http://')
      ? text
      : null;
}

/// A full-screen camera that pops with the first QR code holding a URL
/// (Req 7.7). mobile_scanner asks for the camera permission when the camera
/// first starts (Req 44.10); a denial pops back to the Server_URL_Screen with
/// [ScanProblem.cameraDenied], which stays usable (Req 44.11).
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _finish(QrScanResult result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(result);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final url = scannedUrl(barcode);
      if (url != null) return _finish((url: url, problem: null));
    }
  }

  Widget _onError(BuildContext context, MobileScannerException error) {
    final problem = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? ScanProblem.cameraDenied
        : ScanProblem.cameraFailed;
    // Popping during build is not allowed, so it waits for this frame.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _finish((url: null, problem: problem)),
    );
    return const SizedBox.expand();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Scan QR code'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: _onError,
      ),
    );
  }
}
