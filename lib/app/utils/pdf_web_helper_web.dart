import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openOrDownloadPdfWeb(Uint8List bytes, String filename) async {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Open PDF in a new tab for native browser viewer & 1-click printing
    html.window.open(url, '_blank');
  } catch (_) {
    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {}
  }
}
