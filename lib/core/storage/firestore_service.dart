import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ==================== WARDROBE ====================

  static Future<String> createWardrobeItem({
    required String name,
    required String category,
    required List<String> imageUrls,
  }) async {
    if (_uid == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .add({
          'name': name,
          'category': category,
          'imagePath': imageUrls.isNotEmpty ? imageUrls.first : '',
          'imageUrls': imageUrls,
          'createdAt': FieldValue.serverTimestamp(),
        });

    return doc.id;
  }

  static Future<void> updateWardrobeItem({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .doc(docId)
        .update(data);
  }

  static Future<void> deleteWardrobeItem(String docId) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .doc(docId)
        .delete();
  }

  /// ✅ NEW: fetch single wardrobe doc (for outfit previews)
  static Future<Map<String, dynamic>?> getWardrobeItem(
    String wardrobeId,
  ) async {
    if (_uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .doc(wardrobeId)
        .get();

    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // ==================== PROFILE ====================

  static Future<void> saveProfile({
    List<String>? stylePreferences,
    Map<String, String>? measurements,
    bool? useCm,
    String? frontImageUrl,
    String? sideImageUrl,
    String? backImageUrl,

    // (we’ll use later, keeping ready)
    String? displayName,
    int? age,
    String? gender,
    List<String>? customCategories,
  }) async {
    if (_uid == null) return;

    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (stylePreferences != null) data['stylePreferences'] = stylePreferences;
    if (measurements != null) data['measurements'] = measurements;
    if (useCm != null) data['useCm'] = useCm;

    if (frontImageUrl != null) data['frontImageUrl'] = frontImageUrl;
    if (sideImageUrl != null) data['sideImageUrl'] = sideImageUrl;
    if (backImageUrl != null) data['backImageUrl'] = backImageUrl;

    if (displayName != null) data['displayName'] = displayName;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (customCategories != null) data['customCategories'] = customCategories;

    await _firestore
        .collection('users')
        .doc(_uid)
        .set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    if (_uid == null) return null;

    final doc = await _firestore.collection('users').doc(_uid).get();
    return doc.data();
  }

  // ==================== OUTFITS ====================

  static Future<Map<String, dynamic>?> getOutfit(String outfitId) async {
    if (_uid == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('outfits')
        .doc(outfitId)
        .get();

    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  static Future<List<Map<String, dynamic>>> getAllOutfits() async {
    if (_uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('outfits')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<List<Map<String, dynamic>>> getOutfitsByCategory(
    String category,
  ) async {
    if (_uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('outfits')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<String> createOutfit(Map<String, dynamic> outfitData) async {
    if (_uid == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('outfits')
        .add({...outfitData, 'createdAt': FieldValue.serverTimestamp()});

    return doc.id;
  }

  static Future<void> deleteOutfit(String outfitId) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('outfits')
        .doc(outfitId)
        .delete();
  }
}
