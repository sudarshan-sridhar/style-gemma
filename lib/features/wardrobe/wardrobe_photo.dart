import 'package:hive/hive.dart';

part 'wardrobe_photo.g.dart';

@HiveType(typeId: 5)
class WardrobePhoto {
  @HiveField(0)
  final String localPath;

  @HiveField(1)
  final String? remoteUrl;

  const WardrobePhoto({required this.localPath, this.remoteUrl});

  WardrobePhoto copyWith({
    String? localPath,
    String? remoteUrl,
    bool clearRemote = false,
  }) {
    return WardrobePhoto(
      localPath: localPath ?? this.localPath,
      remoteUrl: clearRemote ? null : (remoteUrl ?? this.remoteUrl),
    );
  }
}
