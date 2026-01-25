import 'package:image_picker/image_picker.dart';

class MediaPicker {
  MediaPicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
  }

  static Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  static Future<List<XFile>> pickMultipleFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    return files;
  }
}
