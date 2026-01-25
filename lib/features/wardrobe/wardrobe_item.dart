import 'package:hive/hive.dart';

import 'wardrobe_category.dart';
import 'wardrobe_photo.dart';

part 'wardrobe_item.g.dart';

@HiveType(typeId: 4)
enum UploadState {
  @HiveField(0)
  localOnly,

  @HiveField(1)
  uploading,

  @HiveField(2)
  uploaded,

  @HiveField(3)
  failed,
}

@HiveType(typeId: 1)
class WardrobeItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final WardrobeCategory category;

  /// ✅ New: photos stored as objects (localPath + remoteUrl)
  @HiveField(2)
  final List<WardrobePhoto> photos;

  /// ✅ Upload lifecycle at item-level
  @HiveField(3)
  final UploadState uploadState;

  /// ✅ Soft delete (so we can retry backend cleanup if needed)
  @HiveField(4)
  final bool isDeleted;

  WardrobeItem({
    required this.name,
    required this.category,
    required this.photos,
    UploadState? uploadState,
    bool? isDeleted,
  }) : uploadState = uploadState ?? UploadState.localOnly,
       isDeleted = isDeleted ?? false;

  WardrobeItem copyWith({
    String? name,
    WardrobeCategory? category,
    List<WardrobePhoto>? photos,
    UploadState? uploadState,
    bool? isDeleted,
  }) {
    return WardrobeItem(
      name: name ?? this.name,
      category: category ?? this.category,
      photos: photos ?? this.photos,
      uploadState: uploadState ?? this.uploadState,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
