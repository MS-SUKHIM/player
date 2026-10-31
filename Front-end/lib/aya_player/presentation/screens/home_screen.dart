import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/media_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/video_model.dart';
import '../../data/services/auth_service.dart';
import '../widgets/network_stream_dialog.dart';
import 'folder_videos_screen.dart';
import 'video_player_screen.dart';
import 'auth_screen.dart';

enum ViewDesign { grid, list, folders, files, allFolders }

enum SortCriteria {
  title,
  date,
  watchTime,
  status,
  duration,
  size,
  resolution,
  path,
  frameRate,
  type,
}

enum SortDirection { asc, desc }

class HomeExplorer extends ConsumerStatefulWidget {
  const HomeExplorer({super.key});

  @override
  ConsumerState<HomeExplorer> createState() => _HomeExplorerState();
}

class _HomeExplorerState extends ConsumerState<HomeExplorer> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  ViewDesign _currentDesign = ViewDesign.folders;
  SortCriteria _currentSort = SortCriteria.title;
  SortDirection _currentDirection = SortDirection.asc;
  bool _showFolderPath = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FolderModel> _filterAndSortFolders(List<FolderModel> folders) {
    List<FolderModel> list = folders.where((folder) {
      return folder.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    list.sort((a, b) {
      int comparison = 0;
      switch (_currentSort) {
        case SortCriteria.title:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortCriteria.duration:
        case SortCriteria.status:
          comparison = a.videos.length.compareTo(b.videos.length);
          break;
        case SortCriteria.path:
          comparison = a.path.toLowerCase().compareTo(b.path.toLowerCase());
          break;
        default:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return _currentDirection == SortDirection.asc ? comparison : -comparison;
    });

    return list;
  }

  List<VideoModel> _getAllVideos(List<FolderModel> folders) {
    List<VideoModel> allVideos = [];
    for (var f in folders) {
      allVideos.addAll(f.videos);
    }
    if (_searchQuery.isNotEmpty) {
      allVideos = allVideos
          .where(
            (v) => v.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    allVideos.sort((a, b) {
      int cmp = 0;
      switch (_currentSort) {
        case SortCriteria.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortCriteria.size:
          cmp = a.size.compareTo(b.size);
          break;
        case SortCriteria.path:
          cmp = a.path.toLowerCase().compareTo(b.path.toLowerCase());
          break;
        default:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _currentDirection == SortDirection.asc ? cmp : -cmp;
    });

    return allVideos;
  }

  void _showMxViewOptionsDialog(bool isDarkMode) {
    ViewDesign tempDesign = _currentDesign;
    SortCriteria tempSort = _currentSort;
    SortDirection tempDirection = _currentDirection;

    final dialogBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF202124);
    final secondaryTextColor = isDarkMode
        ? Colors.white60
        : const Color(0xFF5F6368);
    final activeColor = isDarkMode
        ? Colors.deepPurpleAccent
        : const Color(0xFF1A73E8);
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFEEEEEE);
    final chipBorderColor = isDarkMode
        ? Colors.white24
        : const Color(0xFFDADCE0);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'طريقة العرض',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'التصميم',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDesignItem(
                        'شبكة',
                        Icons.grid_view_rounded,
                        ViewDesign.grid,
                        tempDesign,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempDesign = val);
                        },
                      ),
                      _buildDesignItem(
                        'قائمة',
                        Icons.view_agenda_outlined,
                        ViewDesign.list,
                        tempDesign,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempDesign = val);
                        },
                      ),
                      _buildDesignItem(
                        'مجلدات',
                        Icons.folder_outlined,
                        ViewDesign.folders,
                        tempDesign,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempDesign = val);
                        },
                      ),
                      _buildDesignItem(
                        'ملفات',
                        Icons.insert_drive_file_outlined,
                        ViewDesign.files,
                        tempDesign,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempDesign = val);
                        },
                      ),
                      _buildDesignItem(
                        'كافة المجلدات',
                        Icons.folder_copy_outlined,
                        ViewDesign.allFolders,
                        tempDesign,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempDesign = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(color: borderColor, height: 1, thickness: 1),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'فرز',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSortItem(
                        'العنوان',
                        Icons.sort_by_alpha_rounded,
                        SortCriteria.title,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'التاريخ',
                        Icons.calendar_today_outlined,
                        SortCriteria.date,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'وقت المشاهدة',
                        Icons.history_rounded,
                        SortCriteria.watchTime,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'الحالة',
                        Icons.play_circle_outline_rounded,
                        SortCriteria.status,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'المدة',
                        Icons.slideshow_rounded,
                        SortCriteria.duration,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSortItem(
                        'الحجم',
                        Icons.sd_card_outlined,
                        SortCriteria.size,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'الدقة',
                        Icons.hd_outlined,
                        SortCriteria.resolution,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'المسار',
                        Icons.drive_file_move_outlined,
                        SortCriteria.path,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'سرعة الإطار',
                        Icons.speed_rounded,
                        SortCriteria.frameRate,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                      _buildSortItem(
                        'النوع',
                        Icons.description_outlined,
                        SortCriteria.type,
                        tempSort,
                        activeColor,
                        secondaryTextColor,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(
                            () => tempDirection = SortDirection.asc,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tempDirection == SortDirection.asc
                                  ? activeColor.withOpacity(
                                      isDarkMode ? 0.2 : 0.08,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tempDirection == SortDirection.asc
                                    ? activeColor
                                    : chipBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'أ إلى ي',
                                  style: TextStyle(
                                    color: tempDirection == SortDirection.asc
                                        ? activeColor
                                        : secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 15,
                                  color: tempDirection == SortDirection.asc
                                      ? activeColor
                                      : secondaryTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(
                            () => tempDirection = SortDirection.desc,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tempDirection == SortDirection.desc
                                  ? activeColor.withOpacity(
                                      isDarkMode ? 0.2 : 0.08,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tempDirection == SortDirection.desc
                                    ? activeColor
                                    : chipBorderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ي إلى أ',
                                  style: TextStyle(
                                    color: tempDirection == SortDirection.desc
                                        ? activeColor
                                        : secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 15,
                                  color: tempDirection == SortDirection.desc
                                      ? activeColor
                                      : secondaryTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _buildExpandableTile(
                    'الحقول',
                    primaryTextColor,
                    secondaryTextColor,
                    isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _buildExpandableTile(
                    'متقدم',
                    primaryTextColor,
                    secondaryTextColor,
                    isDarkMode,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentDesign = tempDesign;
                            _currentSort = tempSort;
                            _currentDirection = tempDirection;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'اكتمل',
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignItem(
    String title,
    IconData icon,
    ViewDesign value,
    ViewDesign groupValue,
    Color activeColor,
    Color defaultColor,
    Function(ViewDesign) onChanged,
  ) {
    final isSelected = value == groupValue;
    final color = isSelected ? activeColor : defaultColor;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortItem(
    String title,
    IconData icon,
    SortCriteria value,
    SortCriteria groupValue,
    Color activeColor,
    Color defaultColor,
    Function(SortCriteria) onChanged,
  ) {
    final isSelected = value == groupValue;
    final color = isSelected ? activeColor : defaultColor;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile(
    String title,
    Color textColor,
    Color iconColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252538) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: iconColor, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final isDarkMode = ref.watch(themeProvider);

    final bgColor = isDarkMode
        ? const Color(0xFF12121E)
        : const Color(0xFFF6F8FA);
    final appBarBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF202124);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF202124);
    final subTextColor = isDarkMode ? Colors.white38 : const Color(0xFF5F6368);
    final cardBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final dividerColor = isDarkMode ? Colors.white10 : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مجلد...',
                  hintStyle: TextStyle(color: subTextColor),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                'Aya Player',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDarkMode ? Colors.amber : iconColor,
            ),
            tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.link_rounded,
              color: Colors.deepPurpleAccent,
            ),
            tooltip: 'تشغيل رابط شبكة',
            onPressed: () => NetworkStreamDialog.show(context),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search_rounded,
              color: iconColor,
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
          IconButton(
            icon: Icon(Icons.view_list_rounded, color: iconColor),
            tooltip: 'خيارات العرض والترتيب',
            onPressed: () => _showMxViewOptionsDialog(isDarkMode),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: iconColor),
            onPressed: () => ref.refresh(foldersProvider),
          ),
          FutureBuilder<bool>(
            future: AuthService.isLoggedIn(),
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data ?? false;

              if (isLoggedIn) {
                return PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurpleAccent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await AuthService.logout();
                      if (context.mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تسجيل الخروج بنجاح'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'status',
                      enabled: false,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_done_rounded,
                            color: Colors.greenAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المزامنة السحابية متصلة',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return IconButton(
                icon: Icon(Icons.account_circle_outlined, color: subTextColor),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          final displayFolders = _filterAndSortFolders(folders);

          if (displayFolders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.video_collection_outlined,
                    size: 72,
                    color: subTextColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'لا توجد نتائج تطابق "$_searchQuery"'
                        : 'لم يتم العثور على أي مجلدات تحتوي على فيديو',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (_currentDesign == ViewDesign.files) {
            return _buildFilesListView(
              _getAllVideos(folders),
              textColor,
              subTextColor,
              dividerColor,
              isDarkMode,
            );
          } else if (_currentDesign == ViewDesign.grid) {
            return _buildGridView(
              displayFolders,
              2,
              1.25,
              cardBg,
              textColor,
              subTextColor,
              isDarkMode,
            );
          } else if (_currentDesign == ViewDesign.list) {
            return _buildDetailedListView(
              displayFolders,
              textColor,
              subTextColor,
              dividerColor,
              isDarkMode,
            );
          } else {
            return _buildDetailedListView(
              displayFolders,
              textColor,
              subTextColor,
              dividerColor,
              isDarkMode,
            );
          }
        },
        error: (err, stack) => Center(
          child: Text(
            'خطأ: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      ),
    );
  }

  Widget _buildDetailedListView(
    List<FolderModel> folders,
    Color textColor,
    Color subTextColor,
    Color dividerColor,
    bool isDarkMode,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: folders.length,
      separatorBuilder: (context, index) =>
          Divider(color: dividerColor, height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderVideosScreen(folder: folder),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF252538)
                            : const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: Color(0xFFFFB300),
                        size: 32,
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${folder.videos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (_showFolderPath) ...[
                        const SizedBox(height: 3),
                        Text(
                          folder.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: subTextColor,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesListView(
    List<VideoModel> videos,
    Color textColor,
    Color subTextColor,
    Color dividerColor,
    bool isDarkMode,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: videos.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 70, color: dividerColor),
      itemBuilder: (context, index) {
        final video = videos[index];
        return ListTile(
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF252538)
                  : const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              color: Colors.deepPurpleAccent,
              size: 26,
            ),
          ),
          title: Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: textColor,
            ),
          ),
          subtitle: Text(
            '${(video.size / (1024 * 1024)).toStringAsFixed(1)} MB',
            style: TextStyle(color: subTextColor, fontSize: 11),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  video: video,
                  playlist: videos,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(
    List<FolderModel> folders,
    int crossAxisCount,
    double aspectRatio,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    bool isDarkMode,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: aspectRatio,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderVideosScreen(folder: folder),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFEEEEEE),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFFFFB300),
                      size: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${folder.videos.length}',
                        style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (_showFolderPath && crossAxisCount == 2) ...[
                      const SizedBox(height: 2),
                      Text(
                        folder.path.split('/').take(4).join('/'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subTextColor, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
