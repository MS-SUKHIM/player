import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/audio_model.dart';

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  VideoPlayerController? _audioPlayerController;
  AudioModel? _currentPlaying;
  bool _isPlaying = false;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _audioPlayerController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _playAudio(AudioModel audio) async {
    if (_currentPlaying?.path == audio.path && _audioPlayerController != null) {
      if (_isPlaying) {
        await _audioPlayerController!.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayerController!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    await _audioPlayerController?.dispose();

    _audioPlayerController = VideoPlayerController.file(File(audio.path));
    await _audioPlayerController!.initialize();

    _audioPlayerController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _audioPlayerController!.value.isPlaying;
        });
      }
    });

    setState(() {
      _currentPlaying = audio;
      _isPlaying = true;
    });

    await _audioPlayerController!.play();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeProvider);
    final audioListAsync = ref.watch(audioListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: const InputDecoration(
                  hintText: 'بحث في الأغاني والصوتيات...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text(
                'الموسيقى والأغاني',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          // زر التبديل السريع للوضع الداكن / الفاتح
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDarkMode
                  ? const Color(0xFFFFB300)
                  : Colors.blueGrey[800],
            ),
            tooltip: isDarkMode ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الداكن',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(audioListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: audioListAsync.when(
              data: (audios) {
                final displayAudios = audios.where((a) {
                  return a.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

                if (displayAudios.isEmpty) {
                  return const Center(
                    child: Text('لا توجد ملفات صوتية في الهاتف'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: displayAudios.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: theme.dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    final audio = displayAudios[index];
                    final isCurrent = _currentPlaying?.path == audio.path;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.blueAccent.withOpacity(0.15)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.blueAccent
                                : theme.dividerColor,
                          ),
                        ),
                        child: Icon(
                          isCurrent && _isPlaying
                              ? Icons.graphic_eq_rounded
                              : Icons.music_note_rounded,
                          color: isCurrent
                              ? Colors.blueAccent
                              : const Color(0xFFFFB300),
                          size: 26,
                        ),
                      ),
                      title: Text(
                        audio.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.blueAccent
                              : theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${(audio.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isCurrent && _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: Colors.blueAccent,
                          size: 32,
                        ),
                        onPressed: () => _playAudio(audio),
                      ),
                      onTap: () => _playAudio(audio),
                    );
                  },
                );
              },
              error: (err, _) => Center(
                child: Text(
                  'خطأ: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
          ),

          if (_currentPlaying != null && _audioPlayerController != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPlaying!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_formatDuration(_audioPlayerController!.value.position)} / ${_formatDuration(_audioPlayerController!.value.duration)}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                        onPressed: () => _playAudio(_currentPlaying!),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: theme.dividerColor,
                      thumbColor: Colors.blueAccent,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _audioPlayerController!
                          .value
                          .position
                          .inMilliseconds
                          .toDouble()
                          .clamp(
                            0.0,
                            _audioPlayerController!
                                .value
                                .duration
                                .inMilliseconds
                                .toDouble(),
                          ),
                      min: 0.0,
                      max:
                          _audioPlayerController!.value.duration.inMilliseconds
                                  .toDouble() >
                              0
                          ? _audioPlayerController!
                                .value
                                .duration
                                .inMilliseconds
                                .toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _audioPlayerController!.seekTo(
                          Duration(milliseconds: val.toInt()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
