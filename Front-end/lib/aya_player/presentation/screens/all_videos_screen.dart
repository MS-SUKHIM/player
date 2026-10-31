import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/media_provider.dart';
import '../../providers/vault_provider.dart';
import '../../data/models/video_model.dart';
import '../widgets/video_thumbnail_widget.dart';
import '../widgets/video_actions_sheet.dart';
import 'video_player_screen.dart';

enum AllVideosSortOption { name, size }

class AllVideosScreen extends ConsumerStatefulWidget {
  const AllVideosScreen({super.key});

  @override
  ConsumerState<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends ConsumerState<AllVideosScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AllVideosSortOption _currentSort = AllVideosSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VideoModel> _getAllVideos(List folders, List<String> lockedPaths) {
    List<VideoModel> all = [];
    for (var folder in folders) {
      all.addAll(folder.videos);
    }

    List<VideoModel> visible = all
        .where((v) => !lockedPaths.contains(v.path))
        .toList();

    List<VideoModel> filtered = visible.where((video) {
      return video.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_currentSort == AllVideosSortOption.name) {
      filtered.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_currentSort == AllVideosSortOption.size) {
      filtered.sort((a, b) => b.size.compareTo(a.size));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final vaultState = ref.watch(vaultProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث في كل الفيديوهات...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('كل الفيديوهات'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<AllVideosSortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) => setState(() => _currentSort = option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AllVideosSortOption.name,
                child: Text('ترتيب حسب الاسم'),
              ),
              const PopupMenuItem(
                value: AllVideosSortOption.size,
                child: Text('ترتيب حسب الحجم'),
              ),
            ],
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          final videos = _getAllVideos(folders, vaultState.lockedVideoPaths);

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'لا توجد نتائج تطابق "$_searchQuery"'
                        : 'لم يتم العثور على أي مقاطع فيديو',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.path.split('.').last.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          video.formattedSize,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
                          playlist: videos,
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
