import 'package:hive/hive.dart';

import '../../features/profile/body_image.dart';

class BodyBoxes {
  static const _prefix = 'body_';

  static Box<BodyImage> forUser(String uid) {
    return Hive.box<BodyImage>('$_prefix$uid');
  }
}
