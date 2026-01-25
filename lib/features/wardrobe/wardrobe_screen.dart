import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/navigation/app_page_transition.dart';
import '../../core/storage/firestore_service.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/storage_upload_service.dart';
import '../../core/theme/app_colors.dart';
import 'add_wardrobe_item_sheet.dart';
import 'wardrobe_category.dart';
import 'wardrobe_category_tabs.dart';
import 'wardrobe_empty_state.dart';
import 'wardrobe_item.dart';
import 'wardrobe_item_card.dart';
import 'wardrobe_item_detail_screen.dart';
import 'wardrobe_photo.dart';
import 'wardrobe_photo_intake_screen.dart';
import 'wardrobe_skeleton_grid.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  WardrobeCategory _selectedCategory = WardrobeCategory.tops;
  bool _initialLoading = true;

  Box<WardrobeItem> get _wardrobeBox {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return HiveBoxes.guestWardrobe();
    return HiveBoxes.wardrobeForUser(user.uid);
  }

  @override
  void initState() {
    super.initState();
    _simulateInitialLoad();
  }

  Future<void> _simulateInitialLoad() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _startPhotoFlow() async {
    final photos = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(
        builder: (_) => WardrobePhotoIntakeScreen(category: _selectedCategory),
      ),
    );

    if (!mounted) return;
    if (photos == null || photos.isEmpty) return;

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddWardrobeItemSheet(
        initialCategory: _selectedCategory,
        onAdd: (category, name) async {
          final item = WardrobeItem(
            name: name,
            category: category,
            photos: photos
                .map((e) => WardrobePhoto(localPath: e.path))
                .toList(),
            uploadState: UploadState.localOnly,
            isDeleted: false,
          );

          final key = await _wardrobeBox.add(item);
          HapticFeedback.selectionClick();

          // Fire & forget upload + Firestore creation
          _uploadItemInBackground(hiveKey: key, item: item);
        },
      ),
    );
  }

  Future<void> _uploadItemInBackground({
    required dynamic hiveKey,
    required WardrobeItem item,
  }) async {
    // Only upload for signed-in users
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Mark uploading immediately
    await _wardrobeBox.put(
      hiveKey,
      item.copyWith(uploadState: UploadState.uploading),
    );

    try {
      final itemId = hiveKey.toString();
      final updatedPhotos = List<WardrobePhoto>.from(item.photos);
      final imageUrls = <String>[];

      // Upload all images to Storage
      for (int i = 0; i < updatedPhotos.length; i++) {
        final p = updatedPhotos[i];
        final url = await StorageUploadService.uploadWardrobeImage(
          file: File(p.localPath),
          itemId: itemId,
          imageId: 'img_$i',
        );

        imageUrls.add(url);
        updatedPhotos[i] = p.copyWith(remoteUrl: url);

        // Save progress so UI can switch to remote quickly
        final current = _wardrobeBox.get(hiveKey);
        if (current == null) return;

        await _wardrobeBox.put(
          hiveKey,
          current.copyWith(
            photos: updatedPhotos,
            uploadState: UploadState.uploading,
          ),
        );
      }

      // ✅ AUTO-CREATE FIRESTORE DOC
      final firestoreDocId = await FirestoreService.createWardrobeItem(
        name: item.name,
        category: item.category.name,
        imageUrls: imageUrls,
      );

      print('✅ Firestore doc created: $firestoreDocId');

      // Mark as uploaded
      final current = _wardrobeBox.get(hiveKey);
      if (current == null) return;

      await _wardrobeBox.put(
        hiveKey,
        current.copyWith(
          photos: updatedPhotos,
          uploadState: UploadState.uploaded,
        ),
      );
    } catch (e) {
      print('❌ Upload failed: $e');
      final current = _wardrobeBox.get(hiveKey);
      if (current == null) return;

      await _wardrobeBox.put(
        hiveKey,
        current.copyWith(uploadState: UploadState.failed),
      );
    }
  }

  Future<void> _softDeleteItem(dynamic hiveKey, WardrobeItem item) async {
    HapticFeedback.heavyImpact();

    // Hide from UI immediately
    await _wardrobeBox.put(hiveKey, item.copyWith(isDeleted: true));

    // Attempt backend cleanup
    try {
      final urls = item.photos
          .map((p) => p.remoteUrl)
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList();

      if (urls.isNotEmpty) {
        await StorageUploadService.deleteManyByUrl(urls);
      }

      // ✅ DELETE FROM FIRESTORE
      // We need to find the Firestore doc ID that matches this item
      // For now, we'll skip Firestore deletion (Phase 1B will add doc ID tracking)
      // TODO: Track Firestore doc ID in Hive to enable deletion

      // Delete from Hive (DB)
      await _wardrobeBox.delete(hiveKey);
    } catch (_) {
      // Keep hidden item in Hive so retry can happen from detail screen if needed
      await _wardrobeBox.put(
        hiveKey,
        item.copyWith(isDeleted: true, uploadState: UploadState.failed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = _wardrobeBox;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray1,
        elevation: 0,
      ),
      body: Column(
        children: [
          WardrobeCategoryTabs(
            selected: _selectedCategory,
            onChanged: (c) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = c);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _initialLoading
                ? const WardrobeSkeletonGrid()
                : ValueListenableBuilder<Box<WardrobeItem>>(
                    valueListenable: box.listenable(),
                    builder: (context, box, _) {
                      final entries = box
                          .toMap()
                          .entries
                          .where((e) => !e.value.isDeleted)
                          .where((e) => e.value.category == _selectedCategory)
                          .toList();

                      if (entries.isEmpty) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: WardrobeEmptyState(
                            key: ValueKey(_selectedCategory),
                            category: _selectedCategory,
                          ),
                        );
                      }

                      return GridView.builder(
                        key: ValueKey(_selectedCategory),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65,
                            ),
                        itemBuilder: (_, i) {
                          final hiveKey = entries[i].key;
                          final item = entries[i].value;

                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 200 + (i * 40)),
                            tween: Tween(begin: 0.95, end: 1),
                            curve: Curves.easeOut,
                            builder: (_, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(opacity: scale, child: child),
                              );
                            },
                            child: WardrobeItemCard(
                              item: item,
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                await Navigator.push(
                                  context,
                                  AppPageTransition.fadeSlide(
                                    WardrobeItemDetailScreen(
                                      hiveKey: hiveKey,
                                      initialItem: item,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () => _softDeleteItem(hiveKey, item),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          backgroundColor: AppColors.hmBlue,
          onPressed: _startPhotoFlow,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
