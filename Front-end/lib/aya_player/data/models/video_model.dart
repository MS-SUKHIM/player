import 'dart:io';

class VideoModel {
  final String id;
  final String path;
  final String title;
  final Duration duration;
  final int size;

  VideoModel({
    required this.id,
    required this.path,
    required this.title,
    required this.duration,
    required this.size,
  });

  File get file => File(path);

  String get formattedSize {
    double sizeInMB = size / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
}
