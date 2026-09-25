import 'image_picker_helper_stub.dart'
    if (dart.library.html) 'image_picker_helper_web.dart';

Future<String?> pickImageCrossPlatform({bool isCamera = false}) =>
    pickImagePlatform(isCamera: isCamera);
