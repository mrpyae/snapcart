import 'dart:convert';
import 'package:image_picker/image_picker.dart';

Future<String?> pickImagePlatform({bool isCamera = false}) async {
  try {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  } catch (_) {}
  return null;
}
