import 'dart:typed_data';

Future<void> openOrDownloadPdfWeb(Uint8List bytes, String filename) async {
  // No-op on mobile & desktop native platforms (handled by printing spooler)
}
