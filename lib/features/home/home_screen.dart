import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/storage/firestore_service.dart';
import '../../shared/widgets/outfit_card.dart';
import '../../shared/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  // tiny cache so we don't refetch wardrobe docs repeatedly
  static final Map<String, String?> _wardrobePreviewCache = {};

  Future<String?> _resolveOutfitPreviewUrl(Map<String, dynamic> outfit) async {
    // Prefer AI-generated image if exists
    final generated = outfit['generatedImageUrl'];
    if (generated is String && generated.isNotEmpty) return generated;

    // Otherwise pick first available wardrobe item id
    final candidateIds = <String?>[
      outfit['dressId'] as String?,
      outfit['topId'] as String?,
      outfit['bottomId'] as String?,
      outfit['shoesId'] as String?,
      outfit['accessoryId'] as String?,
    ].whereType<String>().toList();

    if (candidateIds.isEmpty) return null;

    for (final wid in candidateIds) {
      final cached = _wardrobePreviewCache[wid];
      if (cached != null) return cached;

      final doc = await FirestoreService.getWardrobeItem(wid);
      if (doc == null) continue;

      final imagePath = doc['imagePath'];
      if (imagePath is String && imagePath.isNotEmpty) {
        _wardrobePreviewCache[wid] = imagePath;
        return imagePath;
      }

      final urls = doc['imageUrls'];
      if (urls is List && urls.isNotEmpty && urls.first is String) {
        _wardrobePreviewCache[wid] = urls.first as String;
        return urls.first as String;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final outfitsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('outfits')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: outfitsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'No outfits yet.\nGo to Profile → Re-run AI Styling.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            // group outfits by category
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final category = (data['category'] ?? 'casual').toString();
              grouped.putIfAbsent(category, () => []);
              grouped[category]!.add({'id': d.id, ...data});
            }

            // nicer order (optional)
            const preferredOrder = [
              'casual',
              'business_casual',
              'formal',
              'party',
              'streetwear',
              'athletic',
            ];

            final categories = [
              ...preferredOrder.where(grouped.containsKey),
              ...grouped.keys.where((k) => !preferredOrder.contains(k)),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final cat in categories) ...[
                    SectionHeader(
                      title: _titleFor(cat),
                      subtitle: _subtitleFor(cat),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  0.6, // ✅ LARGER IMAGES (was 0.72)
                            ),
                        itemCount: grouped[cat]!.length,
                        itemBuilder: (context, i) {
                          final outfit = grouped[cat]![i];

                          return FutureBuilder<String?>(
                            future: _resolveOutfitPreviewUrl(outfit),
                            builder: (_, snap) {
                              return OutfitCard(
                                outfitId: outfit['id'] as String,
                                category: cat,
                                label: (outfit['description'] ?? 'Outfit')
                                    .toString(),
                                imageUrl: snap.data,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _titleFor(String cat) {
    switch (cat) {
      case 'business_casual':
        return 'Business Casual';
      default:
        return cat[0].toUpperCase() + cat.substring(1);
    }
  }

  String _subtitleFor(String cat) {
    switch (cat) {
      case 'casual':
        return 'Relaxed everyday looks';
      case 'business_casual':
        return 'Office-ready but comfortable';
      case 'formal':
        return 'Clean, sharp, elegant';
      case 'party':
        return 'Event-ready outfits';
      case 'streetwear':
        return 'Urban and trendy';
      case 'athletic':
        return 'Gym and sport fits';
      default:
        return 'Styled outfits';
    }
  }
}
