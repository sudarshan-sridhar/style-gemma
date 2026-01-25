import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'wardrobe_category.dart';

class WardrobeEmptyState extends StatelessWidget {
  final WardrobeCategory category;

  const WardrobeEmptyState({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 56,
              color: AppColors.gray1.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              category.emptyTitle,
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to start styling outfits.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray1.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
