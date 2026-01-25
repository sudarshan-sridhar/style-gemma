import 'package:hive/hive.dart';

import '../../features/profile/body_image.dart';
import '../../features/wardrobe/wardrobe_item.dart';

class HiveBoxes {
  HiveBoxes._();

  static const String _wardrobePrefix = 'wardrobe_';
  static const String _bodyPrefix = 'body_';

  /// Returns the wardrobe box for a specific user
  static Box<WardrobeItem> wardrobeForUser(String uid) {
    final boxName = '$_wardrobePrefix$uid';
    return Hive.box<WardrobeItem>(boxName);
  }

  /// Guest wardrobe (pre-auth or anonymous usage)
  static Box<WardrobeItem> guestWardrobe() {
    return Hive.box<WardrobeItem>('wardrobe_guest');
  }

  /// Body images box for a specific user
  static Box<BodyImage> bodyImagesForUser(String uid) {
    final boxName = '$_bodyPrefix$uid';
    return Hive.box<BodyImage>(boxName);
  }

  // ❌ REMOVED: Outfit boxes (outfits will come from Firestore in Phase 2)
}
