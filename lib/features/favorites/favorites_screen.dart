import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/outfit_card.dart';
import 'favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favourites'), elevation: 0),
        body: const Center(child: Text('Please sign in to view favorites')),
      );
    }

    if (favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favourites'), elevation: 0),
        body: const Center(
          child: Text('No favourites yet', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites'), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('outfits')
            .where(FieldPath.documentId, whereIn: favorites.take(10).toList())
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final outfits = snapshot.data!.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();

          if (outfits.isEmpty) {
            return const Center(
              child: Text(
                'Your favorite outfits will appear here',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfit = outfits[index];

              return OutfitCard(
                outfitId: outfit['id'] ?? '',
                category: (outfit['category'] ?? 'casual').toString(),
                label: (outfit['description'] ?? 'Outfit').toString(),
                imageUrl: outfit['generatedImageUrl'],
              );
            },
          );
        },
      ),
    );
  }
}
