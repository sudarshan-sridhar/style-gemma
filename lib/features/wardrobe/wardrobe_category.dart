import 'package:hive/hive.dart';

part 'wardrobe_category.g.dart';

@HiveType(typeId: 0)
enum WardrobeCategory {
  @HiveField(0)
  tops,

  @HiveField(1)
  bottoms,

  @HiveField(2)
  shoes,

  @HiveField(3)
  accessories,
}

extension WardrobeCategoryX on WardrobeCategory {
  String get label {
    switch (this) {
      case WardrobeCategory.tops:
        return 'Tops';
      case WardrobeCategory.bottoms:
        return 'Bottoms';
      case WardrobeCategory.shoes:
        return 'Shoes';
      case WardrobeCategory.accessories:
        return 'Accessories';
    }
  }

  String get emptyTitle {
    switch (this) {
      case WardrobeCategory.tops:
        return 'No tops added';
      case WardrobeCategory.bottoms:
        return 'No bottoms added';
      case WardrobeCategory.shoes:
        return 'No shoes added';
      case WardrobeCategory.accessories:
        return 'No accessories added';
    }
  }
}
