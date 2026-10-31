class AudioModel {
  final String id;
  final String title;
  final String artist;
  final String path;
  final int size;
  final Duration duration;

  AudioModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    required this.size,
    required this.duration,
  });
}
