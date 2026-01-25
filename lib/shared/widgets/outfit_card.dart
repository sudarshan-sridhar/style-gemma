import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/favorites/favorites_provider.dart';

class OutfitCard extends ConsumerWidget {
  final String outfitId;
  final String category;
  final String label;
  final String? imageUrl;

  const OutfitCard({
    super.key,
    required this.outfitId,
    required this.category,
    required this.label,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(outfitId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: imageUrl == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.black,
                              body: SafeArea(
                                child: Stack(
                                  children: [
                                    Center(child: _buildFullImage()),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.gray1.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImage(),
                ),
              ),

              // ❤️ Favorite button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(outfitId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite
                          ? AppColors.warningRed
                          : AppColors.gray1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (imageUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No preview', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Check if base64 data URL
    if (imageUrl!.startsWith('data:image')) {
      return _buildBase64Image(imageUrl!);
    }

    // HTTP URL
    if (imageUrl!.startsWith('http')) {
      return Image.network(imageUrl!, fit: BoxFit.cover);
    }

    // Local file path
    return Image.file(File(imageUrl!), fit: BoxFit.cover);
  }

  Widget _buildFullImage() {
    if (imageUrl == null) return const SizedBox.shrink();

    if (imageUrl!.startsWith('data:image')) {
      return _buildBase64Image(imageUrl!);
    }

    if (imageUrl!.startsWith('http')) {
      return Image.network(imageUrl!, fit: BoxFit.contain);
    }

    return Image.file(File(imageUrl!), fit: BoxFit.contain);
  }

  Widget _buildBase64Image(String dataUrl) {
    try {
      final base64String = dataUrl.split(',').last;
      final Uint8List bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      return const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      );
    }
  }
}
