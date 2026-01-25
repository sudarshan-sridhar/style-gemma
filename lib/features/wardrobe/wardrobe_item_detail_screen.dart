import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/hive_boxes.dart';
import '../../core/storage/storage_upload_service.dart';
import '../../core/theme/app_text_styles.dart';
import 'wardrobe_item.dart';
import 'wardrobe_photo.dart';

class WardrobeItemDetailScreen extends StatefulWidget {
  final dynamic hiveKey;
  final WardrobeItem initialItem;

  const WardrobeItemDetailScreen({
    super.key,
    required this.hiveKey,
    required this.initialItem,
  });

  @override
  State<WardrobeItemDetailScreen> createState() =>
      _WardrobeItemDetailScreenState();
}

class _WardrobeItemDetailScreenState extends State<WardrobeItemDetailScreen> {
  final _picker = ImagePicker();

  Box<WardrobeItem> get _box {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return HiveBoxes.guestWardrobe();
    return HiveBoxes.wardrobeForUser(user.uid);
  }

  WardrobeItem? get _item => _box.get(widget.hiveKey);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(keys: [widget.hiveKey]),
      builder: (context, _, __) {
        final item = _item ?? widget.initialItem;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteEntireItem(item),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: item.photos.isEmpty
                    ? const Center(
                        child: Text(
                          'No photos',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : PageView.builder(
                        itemCount: item.photos.length,
                        itemBuilder: (_, index) {
                          final photo = item.photos[index];
                          final heroTag = _heroTag(item, index);

                          return Stack(
                            children: [
                              Center(
                                child: Hero(
                                  tag: heroTag,
                                  child: _renderPhoto(photo),
                                ),
                              ),

                              // Controls (replace/delete)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 24,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _darkButton(
                                        icon: Icons.edit_outlined,
                                        label: 'Replace',
                                        onTap: () => _replacePhoto(item, index),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _darkButton(
                                        icon: Icons.delete_outline,
                                        label: 'Delete',
                                        onTap: () => _deletePhoto(item, index),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.subtitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (item.uploadState == UploadState.failed)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => _retryUpload(item),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry upload / cleanup'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _heroTag(WardrobeItem item, int index) {
    final p = item.photos[index];
    if (p.remoteUrl != null && p.remoteUrl!.isNotEmpty)
      return 'wardrobe_${p.remoteUrl}';
    return 'wardrobe_${p.localPath}';
  }

  Widget _renderPhoto(WardrobePhoto photo) {
    if (photo.remoteUrl != null && photo.remoteUrl!.isNotEmpty) {
      return Image.network(
        photo.remoteUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Image.file(File(photo.localPath), fit: BoxFit.contain),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Image.file(File(photo.localPath), fit: BoxFit.contain);
  }

  Widget _darkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _retryUpload(WardrobeItem item) async {
    final user = FirebaseAuth.instance.currentUser;

    // If deleted + failed cleanup, retry cleanup
    if (item.isDeleted) {
      try {
        final urls = item.photos
            .map((p) => p.remoteUrl)
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList();

        if (urls.isNotEmpty) await StorageUploadService.deleteManyByUrl(urls);
        await _box.delete(widget.hiveKey);

        if (mounted) Navigator.pop(context);
      } catch (_) {
        // keep failed
      }
      return;
    }

    // Upload retry
    if (user == null) return;

    await _box.put(
      widget.hiveKey,
      item.copyWith(uploadState: UploadState.uploading),
    );

    try {
      final itemId = widget.hiveKey.toString();
      final updated = List<WardrobePhoto>.from(item.photos);

      for (int i = 0; i < updated.length; i++) {
        final p = updated[i];

        // If already uploaded, keep it
        if (p.remoteUrl != null && p.remoteUrl!.isNotEmpty) continue;

        final url = await StorageUploadService.uploadWardrobeImage(
          file: File(p.localPath),
          itemId: itemId,
          imageId: 'img_$i',
        );

        updated[i] = p.copyWith(remoteUrl: url);

        final current = _box.get(widget.hiveKey);
        if (current == null) return;

        await _box.put(
          widget.hiveKey,
          current.copyWith(photos: updated, uploadState: UploadState.uploading),
        );
      }

      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      await _box.put(
        widget.hiveKey,
        current.copyWith(uploadState: UploadState.uploaded),
      );
      HapticFeedback.selectionClick();
    } catch (_) {
      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      await _box.put(
        widget.hiveKey,
        current.copyWith(uploadState: UploadState.failed),
      );
    }
  }

  Future<void> _replacePhoto(WardrobeItem item, int index) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;

    HapticFeedback.mediumImpact();

    final photos = List<WardrobePhoto>.from(item.photos);
    final old = photos[index];
    final newLocal = file.path;

    // Optimistic local replace (instant UI)
    photos[index] = old.copyWith(localPath: newLocal, clearRemote: true);

    await _box.put(
      widget.hiveKey,
      item.copyWith(photos: photos, uploadState: UploadState.uploading),
    );

    // Backend: delete old remote then upload new
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (old.remoteUrl != null && old.remoteUrl!.isNotEmpty) {
        await StorageUploadService.deleteByUrl(old.remoteUrl!);
      }

      final itemId = widget.hiveKey.toString();
      final url = await StorageUploadService.uploadWardrobeImage(
        file: File(newLocal),
        itemId: itemId,
        imageId: 'img_$index',
      );

      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      final updatedPhotos = List<WardrobePhoto>.from(current.photos);
      updatedPhotos[index] = updatedPhotos[index].copyWith(remoteUrl: url);

      await _box.put(
        widget.hiveKey,
        current.copyWith(
          photos: updatedPhotos,
          uploadState: UploadState.uploaded,
        ),
      );
    } catch (_) {
      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      await _box.put(
        widget.hiveKey,
        current.copyWith(uploadState: UploadState.failed),
      );
    }
  }

  Future<void> _deletePhoto(WardrobeItem item, int index) async {
    HapticFeedback.heavyImpact();

    // If last image -> delete item
    if (item.photos.length == 1) {
      await _deleteEntireItem(item);
      return;
    }

    final photos = List<WardrobePhoto>.from(item.photos);
    final target = photos.removeAt(index);

    // Optimistic UI: remove immediately
    await _box.put(
      widget.hiveKey,
      item.copyWith(photos: photos, uploadState: UploadState.uploading),
    );

    // Backend: delete remote if exists
    try {
      if (target.remoteUrl != null && target.remoteUrl!.isNotEmpty) {
        await StorageUploadService.deleteByUrl(target.remoteUrl!);
      }

      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      await _box.put(
        widget.hiveKey,
        current.copyWith(uploadState: UploadState.uploaded),
      );
    } catch (_) {
      final current = _box.get(widget.hiveKey);
      if (current == null) return;

      await _box.put(
        widget.hiveKey,
        current.copyWith(uploadState: UploadState.failed),
      );
    }
  }

  Future<void> _deleteEntireItem(WardrobeItem item) async {
    HapticFeedback.heavyImpact();

    // Mark deleted (so wardrobe grid hides instantly)
    await _box.put(widget.hiveKey, item.copyWith(isDeleted: true));

    try {
      final urls = item.photos
          .map((p) => p.remoteUrl)
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList();

      if (urls.isNotEmpty) await StorageUploadService.deleteManyByUrl(urls);

      await _box.delete(widget.hiveKey);

      if (mounted) Navigator.pop(context);
    } catch (_) {
      // keep hidden but retryable
      await _box.put(
        widget.hiveKey,
        item.copyWith(isDeleted: true, uploadState: UploadState.failed),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed. Open item to retry.')),
        );
        Navigator.pop(context);
      }
    }
  }
}
