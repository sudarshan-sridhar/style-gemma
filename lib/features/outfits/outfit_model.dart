import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitModel {
  final String id;
  final String topId;
  final String bottomId;
  final String? shoesId;
  final String? accessoryId;
  final String category; // casual, formal, party, etc.
  final String description;
  final String? generatedImageUrl; // Nano Banana generated image
  final List<String> tags;
  final DateTime createdAt;

  OutfitModel({
    required this.id,
    required this.topId,
    required this.bottomId,
    this.shoesId,
    this.accessoryId,
    required this.category,
    required this.description,
    this.generatedImageUrl,
    this.tags = const [],
    required this.createdAt,
  });

  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OutfitModel(
      id: doc.id,
      topId: data['topId'] ?? '',
      bottomId: data['bottomId'] ?? '',
      shoesId: data['shoesId'],
      accessoryId: data['accessoryId'],
      category: data['category'] ?? 'casual',
      description: data['description'] ?? '',
      generatedImageUrl: data['generatedImageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'topId': topId,
      'bottomId': bottomId,
      if (shoesId != null) 'shoesId': shoesId,
      if (accessoryId != null) 'accessoryId': accessoryId,
      'category': category,
      'description': description,
      if (generatedImageUrl != null) 'generatedImageUrl': generatedImageUrl,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
