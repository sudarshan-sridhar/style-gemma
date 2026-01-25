import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/storage/firestore_service.dart';
import 'gemini_service.dart';
import 'nanobanana_service.dart';

class AiStylingService {
  AiStylingService._();

  /// Run complete AI styling workflow
  static Future<void> runAiStyling() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    print('🎨 Starting AI styling...');

    // Step 1: Fetch wardrobe items
    final wardrobeSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wardrobe')
        .get();

    if (wardrobeSnapshot.docs.isEmpty) {
      throw Exception(
        'No wardrobe items found. Please add some clothes first!',
      );
    }

    final wardrobeItems = wardrobeSnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();

    // Create lookup map
    final wardrobeMap = <String, Map<String, dynamic>>{};
    for (final item in wardrobeItems) {
      wardrobeMap[item['id'] as String] = item;
    }

    print('📦 Fetched ${wardrobeItems.length} wardrobe items');

    // Step 2: Fetch user profile (including body images)
    final userProfile = await FirestoreService.loadProfile() ?? {};
    final gender = userProfile['gender'] as String? ?? 'male';

    // Get body images
    final frontImageUrl = userProfile['frontImageUrl'] as String?;
    final sideImageUrl = userProfile['sideImageUrl'] as String?;
    final backImageUrl = userProfile['backImageUrl'] as String?;

    final hasBodyImages =
        frontImageUrl != null && sideImageUrl != null && backImageUrl != null;

    if (!hasBodyImages) {
      print('⚠️ No body images found - virtual try-on will be skipped');
    } else {
      print('👤 Found body images for virtual try-on');
    }

    print('👤 Fetched user profile (gender: $gender)');

    // Step 3: Call Gemini to generate outfits
    final outfits = await GeminiService.generateOutfits(
      wardrobeItems: wardrobeItems,
      userProfile: userProfile,
    );

    print('🤖 Gemini generated ${outfits.length} outfits');

    // Step 4: Generate images and upload to Storage
    int savedCount = 0;
    int imagesGenerated = 0;

    for (int i = 0; i < outfits.length; i++) {
      final outfit = outfits[i];

      try {
        String? imageUrl;

        // Only generate images for first 3 outfits (rate limit protection)
        if (hasBodyImages &&
            imagesGenerated < NanoBananaService.maxImagesPerRun) {
          print(
            '🍌 Generating virtual try-on for outfit ${imagesGenerated + 1}/${NanoBananaService.maxImagesPerRun}',
          );

          try {
            // Collect clothing images from outfit items
            final clothingImageUrls = <String>[];

            final items = outfit['items'] as Map<String, dynamic>;

            for (final itemId in [
              items['tops'],
              items['bottoms'],
              items['dresses'],
              items['shoes'],
              items['accessories'],
            ]) {
              if (itemId != null) {
                final item = wardrobeMap[itemId];
                if (item != null) {
                  // Get first image URL from wardrobe item
                  final imagePath = item['imagePath'] as String?;
                  if (imagePath != null && imagePath.isNotEmpty) {
                    clothingImageUrls.add(imagePath);
                  } else {
                    final imageUrls = item['imageUrls'] as List<dynamic>?;
                    if (imageUrls != null && imageUrls.isNotEmpty) {
                      clothingImageUrls.add(imageUrls.first as String);
                    }
                  }
                }
              }
            }

            if (clothingImageUrls.isNotEmpty) {
              final base64Image = await NanoBananaService.generateTryOnImage(
                frontBodyImageUrl: frontImageUrl!,
                sideBodyImageUrl: sideImageUrl!,
                backBodyImageUrl: backImageUrl!,
                clothingImageUrls: clothingImageUrls,
                description: outfit['description'] as String,
                gender: gender,
              );

              if (base64Image != null) {
                // Upload base64 to Firebase Storage
                imageUrl = await _uploadBase64ToStorage(
                  base64Image,
                  uid,
                  'outfit_$i',
                );

                print(
                  '✅ Virtual try-on generated for outfit ${imagesGenerated + 1}',
                );
                imagesGenerated++;

                // Delay to avoid rate limiting
                // Small delay to avoid overwhelming API
                await Future.delayed(const Duration(milliseconds: 500));
              }
            }
          } catch (e) {
            print('⚠️ Virtual try-on failed for outfit ${i + 1}: $e');
          }
        } else if (hasBodyImages &&
            imagesGenerated >= NanoBananaService.maxImagesPerRun) {
          print('⏭️ Skipping outfit ${i + 1} (rate limit: max 3 images)');
        }

        // Save outfit to Firestore
        await FirestoreService.createOutfit({
          'topId': outfit['items']['tops'],
          'bottomId': outfit['items']['bottoms'],
          'shoesId': outfit['items']['shoes'],
          'accessoryId': outfit['items']['accessories'],
          'dressId': outfit['items']['dresses'],
          'category': outfit['category'],
          'description': outfit['description'],
          'tags': outfit['tags'],
          'generatedImageUrl': imageUrl,
        });

        savedCount++;
      } catch (e) {
        print('⚠️ Failed to save outfit ${i + 1}: $e');
      }
    }

    print('✅ Saved $savedCount outfits to Firestore');
    print('🍌 Generated $imagesGenerated virtual try-on images');
    print('🎉 AI styling complete!');
  }

  /// Upload base64 image to Firebase Storage
  static Future<String> _uploadBase64ToStorage(
    String base64DataUrl,
    String uid,
    String fileName,
  ) async {
    try {
      // Extract base64 string from data URL
      final base64String = base64DataUrl.split(',').last;
      final bytes = base64Decode(base64String);

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref(
        'users/$uid/ai_outfits/$fileName.png',
      );

      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));

      final url = await ref.getDownloadURL();
      print('📤 Uploaded image to Storage: $fileName');
      return url;
    } catch (e) {
      print('❌ Failed to upload image: $e');
      rethrow;
    }
  }

  /// Clear all existing outfits
  static Future<void> clearExistingOutfits() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('outfits')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    print('🗑️ Cleared ${snapshot.docs.length} existing outfits');
  }
}
