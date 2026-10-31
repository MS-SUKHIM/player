import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/video_model.dart';
import '../../providers/theme_provider.dart';
import '../widgets/video_thumbnail_widget.dart';
import '../widgets/video_actions_sheet.dart';
import 'video_player_screen.dart';

enum VideoSortOption { name, size }

class FolderVideosScreen extends ConsumerStatefulWidget {
  final FolderModel folder;

  const FolderVideosScreen({super.key, required this.folder});

  @override
  ConsumerState<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends ConsumerState<FolderVideosScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  VideoSortOption _currentSort = VideoSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VideoModel> _filterAndSortVideos() {
    List<VideoModel> list = widget.folder.videos.where((video) {
      return video.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_currentSort == VideoSortOption.name) {
      list.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_currentSort == VideoSortOption.size) {
      list.sort((a, b) => b.size.compareTo(a.size));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayVideos = _filterAndSortVideos();
    final isDarkMode = ref.watch(themeProvider);

    final bgColor = isDarkMode
        ? const Color(0xFF12121E)
        : const Color(0xFFF6F8FA);
    final appBarBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final cardBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF202124);
    final subTextColor = isDarkMode ? Colors.white54 : const Color(0xFF5F6368);
    final borderColor = isDarkMode ? Colors.white10 : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيديو...',
                  hintStyle: TextStyle(color: subTextColor),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                widget.folder.name,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: textColor,
            ),
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
          PopupMenuButton<VideoSortOption>(
            icon: Icon(Icons.sort_rounded, color: textColor),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (option) {
              setState(() {
                _currentSort = option;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: VideoSortOption.name,
                child: Text(
                  'ترتيب حسب الاسم',
                  style: TextStyle(color: textColor),
                ),
              ),
              PopupMenuItem(
                value: VideoSortOption.size,
                child: Text(
                  'ترتيب حسب الحجم (الأكبر أولاً)',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
      body: displayVideos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: subTextColor),
                  const SizedBox(height: 12),
                  Text(
                    'لا يوجد فيديو يطابق "$_searchQuery"',
                    style: TextStyle(color: subTextColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: displayVideos.length,
              itemBuilder: (context, index) {
                final video = displayVideos[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
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
                      style: TextStyle(
                        color: textColor,
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
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert_rounded, color: subTextColor),
                      onPressed: () {
                        VideoActionsSheet.show(context, ref, video);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            playlist: displayVideos,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
