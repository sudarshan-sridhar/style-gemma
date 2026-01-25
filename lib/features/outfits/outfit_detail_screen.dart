import 'package:flutter/material.dart';

class OutfitDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String label;
  final String category;

  const OutfitDetailScreen({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Chip(label: Text(category)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
