import 'video_model.dart';

class FolderModel {
  final String name;
  final String path;
  final List<VideoModel> videos;

  FolderModel({required this.name, required this.path, required this.videos});

  int get videoCount => videos.length;

  String get formattedTotalSize {
    int totalBytes = videos.fold(0, (sum, video) => sum + video.size);
    double sizeInMB = totalBytes / (1024 * 1024);
    if (sizeInMB >= 1024) {
      double sizeInGB = sizeInMB / 1024;
      return '${sizeInGB.toStringAsFixed(1)} GB';
    }
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
}
