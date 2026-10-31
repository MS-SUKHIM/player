import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackPositionNotifier extends Notifier<void> {
  @override
  void build() {}

  static const String _prefix = 'playback_pos_';

  Future<int> getSavedPosition(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$videoPath') ?? 0;
  }

  Future<void> savePosition(String videoPath, int positionInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    if (positionInSeconds > 5) {
      await prefs.setInt('$_prefix$videoPath', positionInSeconds);
    }
  }

  Future<void> clearPosition(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$videoPath');
  }
}

final playbackPositionProvider =
    NotifierProvider<PlaybackPositionNotifier, void>(
      PlaybackPositionNotifier.new,
    );
