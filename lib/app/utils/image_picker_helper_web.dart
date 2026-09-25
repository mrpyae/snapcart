import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<String?> pickImagePlatform({bool isCamera = false}) async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  if (isCamera) {
    uploadInput.setAttribute('capture', 'environment');
  }
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is String) {
          completer.complete(result);
        } else if (result is List<int>) {
          completer.complete('data:image/jpeg;base64,${base64Encode(result)}');
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) => completer.complete(null));
      reader.readAsDataUrl(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
