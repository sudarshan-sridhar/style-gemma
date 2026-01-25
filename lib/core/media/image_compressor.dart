import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class ImageCompressor {
  static Future<File> compress(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) return file;

    final resized = img.copyResize(
      decoded,
      width: 1024, // max width
    );

    final compressedBytes = img.encodeJpg(resized, quality: 80);

    final newPath = p.join(
      file.parent.path,
      'compressed_${p.basename(file.path)}',
    );

    final compressedFile = File(newPath);
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }
}
