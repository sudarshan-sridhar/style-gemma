import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  final _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _load() async {
    if (_uid == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .get();

    state = snap.docs.map((d) => d.id).toSet();
  }

  Future<void> toggleFavorite(String outfitId) async {
    if (_uid == null) return;

    final ref = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(outfitId);

    if (state.contains(outfitId)) {
      await ref.delete();
      state = {...state}..remove(outfitId);
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
      state = {...state, outfitId};
    }
  }
}
