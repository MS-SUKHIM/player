import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/media_provider.dart';
import '../../data/models/video_model.dart';
import '../widgets/video_thumbnail_widget.dart';
import '../widgets/video_actions_sheet.dart';
import 'video_player_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة ⭐')),
      body: foldersAsync.when(
        data: (folders) {
          List<VideoModel> favoriteVideos = [];
          for (var folder in folders) {
            for (var video in folder.videos) {
              if (favorites.contains(video.path)) {
                favoriteVideos.add(video);
              }
            }
          }

          if (favoriteVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star_border_rounded, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'قائمة المفضلة فارغة\nأضف فيديوهاتك المفضلة لتظهر هنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favoriteVideos.length,
            itemBuilder: (context, index) {
              final video = favoriteVideos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: VideoThumbnailWidget(
                    videoPath: video.path,
                    width: 65,
                    height: 55,
                  ),
                  title: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    video.formattedSize,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      VideoActionsSheet.show(context, ref, video);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          playlist: favoriteVideos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        error: (err, _) => Center(
          child: Text('خطأ: $err', style: const TextStyle(color: Colors.red)),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      ),
    );
  }
}
