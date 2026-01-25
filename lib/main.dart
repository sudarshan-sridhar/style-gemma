import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/auth_gate.dart';
import 'features/profile/body_image.dart';
import 'features/wardrobe/wardrobe_category.dart';
import 'features/wardrobe/wardrobe_item.dart';
import 'features/wardrobe/wardrobe_photo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();

  // Hive
  await Hive.initFlutter();

  // ---------- Adapters (ORDER MATTERS) ----------
  Hive.registerAdapter(WardrobeCategoryAdapter());

  Hive.registerAdapter(BodyImageAdapter());
  Hive.registerAdapter(BodyImagePositionAdapter());
  Hive.registerAdapter(BodyUploadStateAdapter());

  Hive.registerAdapter(UploadStateAdapter());
  Hive.registerAdapter(WardrobePhotoAdapter());
  Hive.registerAdapter(WardrobeItemAdapter());

  // ❌ REMOVED: OutfitAdapter (no longer needed)

  // ---------- Boxes ----------
  await Hive.openBox<WardrobeItem>('wardrobe_guest');

  // ❌ REMOVED: Outfit boxes (outfits will come from Firestore)

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
