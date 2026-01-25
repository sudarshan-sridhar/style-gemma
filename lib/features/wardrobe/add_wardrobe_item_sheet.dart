import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'wardrobe_category.dart';

class AddWardrobeItemSheet extends StatefulWidget {
  final WardrobeCategory initialCategory;
  final String? initialName;
  final void Function(WardrobeCategory category, String name) onAdd;

  const AddWardrobeItemSheet({
    super.key,
    required this.initialCategory,
    required this.onAdd,
    this.initialName,
  });

  @override
  State<AddWardrobeItemSheet> createState() => _AddWardrobeItemSheetState();
}

class _AddWardrobeItemSheetState extends State<AddWardrobeItemSheet> {
  late WardrobeCategory _category;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialName == null ? 'Add item' : 'Edit item',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<WardrobeCategory>(
            value: _category,
            items: WardrobeCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
            decoration: const InputDecoration(labelText: 'Category'),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hmBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isEmpty) return;
                widget.onAdd(_category, name);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
