import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'wardrobe_item.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = _heroTag();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: heroTag,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.gray1.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildImage(),
                    ),
                  ),

                  // Upload state badge (subtle)
                  Positioned(top: 10, right: 10, child: _buildStatusBadge()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _heroTag() {
    if (item.photos.isNotEmpty && item.photos.first.remoteUrl != null) {
      return 'wardrobe_${item.photos.first.remoteUrl}';
    }
    if (item.photos.isNotEmpty) {
      return 'wardrobe_${item.photos.first.localPath}';
    }
    return 'wardrobe_${item.name}';
  }

  Widget _buildImage() {
    if (item.photos.isEmpty) return const SizedBox.shrink();

    final first = item.photos.first;

    if (first.remoteUrl != null && first.remoteUrl!.isNotEmpty) {
      return Image.network(
        first.remoteUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localImage(first.localPath),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(color: AppColors.gray1.withValues(alpha: 0.04));
        },
      );
    }

    return _localImage(first.localPath);
  }

  Widget _localImage(String path) {
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _buildStatusBadge() {
    if (item.uploadState == UploadState.uploading) {
      return _pill(
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (item.uploadState == UploadState.failed) {
      return _pill(child: const Icon(Icons.warning_amber_rounded, size: 18));
    }

    return const SizedBox.shrink();
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(99),
      ),
      child: child,
    );
  }
}
