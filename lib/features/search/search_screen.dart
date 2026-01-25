import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/outfit_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to search')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search colors, outfits, styles...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase().trim());
                },
              ),
            ),

            // Search suggestions
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'Blue',
                        'Casual',
                        'Business casual',
                        'Black outfits',
                        'Street wear',
                      ].map((text) {
                        return ActionChip(
                          label: Text(text),
                          onPressed: () {
                            _searchController.text = text;
                            setState(() => _searchQuery = text.toLowerCase());
                          },
                        );
                      }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // Results
            Expanded(
              child: _searchQuery.isEmpty
                  ? const Center(
                      child: Text(
                        'Search by category, color, or style',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('outfits')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Filter outfits by search query
                        final allOutfits = snapshot.data!.docs.map((doc) {
                          return {
                            'id': doc.id,
                            ...doc.data() as Map<String, dynamic>,
                          };
                        }).toList();

                        final filteredOutfits = allOutfits.where((outfit) {
                          final description = (outfit['description'] ?? '')
                              .toString()
                              .toLowerCase();
                          final category = (outfit['category'] ?? '')
                              .toString()
                              .toLowerCase();
                          final tags =
                              (outfit['tags'] as List<dynamic>?)
                                  ?.map((e) => e.toString().toLowerCase())
                                  .toList() ??
                              [];

                          return description.contains(_searchQuery) ||
                              category.contains(_searchQuery) ||
                              tags.any((tag) => tag.contains(_searchQuery));
                        }).toList();

                        if (filteredOutfits.isEmpty) {
                          return const Center(
                            child: Text(
                              'No matching outfits found',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                          itemCount: filteredOutfits.length,
                          itemBuilder: (context, index) {
                            final outfit = filteredOutfits[index];

                            return OutfitCard(
                              outfitId: outfit['id'] ?? '',
                              category: (outfit['category'] ?? 'casual')
                                  .toString(),
                              label: (outfit['description'] ?? 'Outfit')
                                  .toString(),
                              imageUrl: outfit['generatedImageUrl'],
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
