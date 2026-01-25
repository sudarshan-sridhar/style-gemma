import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media/media_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'wardrobe_category.dart';

class WardrobePhotoIntakeScreen extends StatefulWidget {
  final WardrobeCategory category;

  const WardrobePhotoIntakeScreen({super.key, required this.category});

  @override
  State<WardrobePhotoIntakeScreen> createState() =>
      _WardrobePhotoIntakeScreenState();
}

class _WardrobePhotoIntakeScreenState extends State<WardrobePhotoIntakeScreen> {
  final List<XFile> _photos = [];

  Future<void> _addFromCamera() async {
    final file = await MediaPicker.pickFromCamera();
    if (file == null) return;
    setState(() => _photos.add(file));
  }

  Future<void> _addFromGallery() async {
    final files = await MediaPicker.pickMultipleFromGallery();
    if (files.isEmpty) return;
    setState(() => _photos.addAll(files));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add wardrobe photos'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray1,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name.toUpperCase(),
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 4),
            Text(
              _instructionForCategory(widget.category),
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray1.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hmBlue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _photos.isEmpty
                  ? const Center(child: Text('No photos added yet'))
                  : GridView.builder(
                      itemCount: _photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemBuilder: (_, i) {
                        final file = _photos[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(file.path), fit: BoxFit.cover),
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hmBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _photos.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context, _photos);
                      },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _instructionForCategory(WardrobeCategory category) {
    switch (category) {
      case WardrobeCategory.tops:
        return 'Add front view photos of tops';
      case WardrobeCategory.bottoms:
        return 'Add full-length bottom wear photos';
      case WardrobeCategory.shoes:
        return 'Add left & right shoe photos';
      case WardrobeCategory.accessories:
        return 'Add clear accessory photos';
    }
  }
}
