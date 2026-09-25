import 'dart:typed_data';
import 'pdf_web_helper_stub.dart'
    if (dart.library.html) 'pdf_web_helper_web.dart';

Future<void> openOrDownloadPdf(Uint8List bytes, String filename) =>
    openOrDownloadPdfWeb(bytes, filename);
