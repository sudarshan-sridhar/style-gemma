import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

class StorageUploadService {
  StorageUploadService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _uid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Upload wardrobe item image
  static Future<String> uploadWardrobeImage({
    required File file,
    required String itemId,
    required String imageId,
  }) async {
    final uid = _uid();
    final compressed = await _compressImage(file);

    final ref = _storage.ref('users/$uid/wardrobe/$itemId/$imageId.jpg');

    final task = await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return task.ref.getDownloadURL();
  }

  /// Upload body image (front/side/back)
  static Future<String> uploadBodyImage({
    required File file,
    required String position, // 'front', 'side', or 'back'
  }) async {
    final uid = _uid();
    final compressed = await _compressImage(file);

    final ref = _storage.ref('users/$uid/body/$position.jpg');

    final task = await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return task.ref.getDownloadURL();
  }

  /// Delete by URL
  static Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // idempotent: already deleted / invalid / no permission
      rethrow;
    }
  }

  /// Delete multiple URLs
  static Future<void> deleteManyByUrl(List<String> urls) async {
    for (final u in urls) {
      await deleteByUrl(u);
    }
  }

  /// Compress image to max 1080px width, 80% quality
  static Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode image');

    final resized = decoded.width > 1080
        ? img.copyResize(decoded, width: 1080)
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }
}
