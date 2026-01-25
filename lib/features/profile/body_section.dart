import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../core/media/media_picker.dart';
import '../../core/storage/body_boxes.dart';
import '../../core/storage/firestore_service.dart';
import '../../core/storage/storage_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'body_image.dart';

class BodySection extends StatefulWidget {
  const BodySection({super.key});

  @override
  State<BodySection> createState() => _BodySectionState();
}

class _BodySectionState extends State<BodySection> {
  Box<BodyImage> get _box {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return BodyBoxes.forUser(uid);
  }

  Future<void> _pick(BodyImagePosition position) async {
    final useCamera = await _chooseSource();
    if (useCamera == null) return;

    final picked = useCamera
        ? await MediaPicker.pickFromCamera()
        : await MediaPicker.pickFromGallery();

    if (picked == null) return;

    HapticFeedback.mediumImpact();

    final image = BodyImage(
      position: position,
      localPath: picked.path,
      remoteUrl: null,
      uploadState: BodyUploadState.localOnly,
    );

    await _box.put(position.name, image);
    setState(() {});

    // Upload to Storage + Firestore
    try {
      final url = await StorageUploadService.uploadBodyImage(
        file: File(picked.path),
        position: position.name, // 'front', 'side', or 'back'
      );

      // ✅ SAVE TO FIRESTORE
      final firestoreData = <String, String?>{
        'frontImageUrl': position == BodyImagePosition.front ? url : null,
        'sideImageUrl': position == BodyImagePosition.side ? url : null,
        'backImageUrl': position == BodyImagePosition.back ? url : null,
      }..removeWhere((key, value) => value == null);

      await FirestoreService.saveProfile(
        frontImageUrl: firestoreData['frontImageUrl'],
        sideImageUrl: firestoreData['sideImageUrl'],
        backImageUrl: firestoreData['backImageUrl'],
      );

      print('✅ Body image saved to Firestore: ${position.name}');

      // Update Hive with uploaded state
      await _box.put(
        position.name,
        image.copyWith(remoteUrl: url, uploadState: BodyUploadState.uploaded),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Body image upload failed: $e');
      await _box.put(
        position.name,
        image.copyWith(uploadState: BodyUploadState.failed),
      );
    }
  }

  Future<bool?> _chooseSource() async {
    if (kIsWeb) {
      return false; // gallery
    }

    return showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BodyImage image) async {
    HapticFeedback.heavyImpact();

    // Try delete remote if present
    if (image.remoteUrl != null) {
      try {
        await StorageUploadService.deleteByUrl(image.remoteUrl!);

        // ✅ REMOVE FROM FIRESTORE
        final firestoreData = <String, String?>{
          'frontImageUrl': image.position == BodyImagePosition.front
              ? null
              : null,
          'sideImageUrl': image.position == BodyImagePosition.side
              ? null
              : null,
          'backImageUrl': image.position == BodyImagePosition.back
              ? null
              : null,
        }..removeWhere((key, value) => value != null);

        await FirestoreService.saveProfile(
          frontImageUrl: image.position == BodyImagePosition.front ? '' : null,
          sideImageUrl: image.position == BodyImagePosition.side ? '' : null,
          backImageUrl: image.position == BodyImagePosition.back ? '' : null,
        );
      } catch (_) {
        // keep going; local delete still happens
      }
    }

    await _box.delete(image.position.name);
    if (mounted) setState(() {});
  }

  Widget _slot(BodyImagePosition position, String label) {
    final img = _box.get(position.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pick(position),
          onLongPress: img == null ? null : () => _delete(img),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray1.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: img == null
                ? const Center(
                    child: Icon(Icons.add_a_photo, color: Colors.grey),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(img.localPath), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen(_box.name)) return const SizedBox.shrink();

    return Column(
      children: [
        _slot(BodyImagePosition.front, 'Front view'),
        const SizedBox(height: 16),
        _slot(BodyImagePosition.side, 'Side view'),
        const SizedBox(height: 16),
        _slot(BodyImagePosition.back, 'Back view'),
      ],
    );
  }
}
