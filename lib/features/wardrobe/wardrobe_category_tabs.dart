import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'wardrobe_category.dart';

class WardrobeCategoryTabs extends StatelessWidget {
  final WardrobeCategory selected;
  final ValueChanged<WardrobeCategory> onChanged;

  const WardrobeCategoryTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: WardrobeCategory.values.map((category) {
          final isSelected = category == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) => onChanged(category),
              selectedColor: AppColors.hmBlue,
              backgroundColor: AppColors.gray1.withOpacity(0.08),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.gray1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
