import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends Notifier<List<String>> {
  static const String _key = 'favorite_video_paths';

  @override
  List<String> build() {
    _loadFavorites();
    return [];
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> toggleFavorite(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.contains(videoPath)) {
      state = state.where((path) => path != videoPath).toList();
    } else {
      state = [...state, videoPath];
    }
    await prefs.setStringList(_key, state);
  }

  bool isFavorite(String videoPath) => state.contains(videoPath);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);
