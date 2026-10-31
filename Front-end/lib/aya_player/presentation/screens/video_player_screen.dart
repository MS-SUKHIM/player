import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/video_model.dart';
import '../../providers/playback_position_provider.dart';
import '../../data/models/subtitle_model.dart';
import '../../data/services/cloud_history_service.dart';

enum BoxFitMode { fitScreen, stretch, crop, fit100 }

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VideoModel? video;
  final List<VideoModel>? playlist;
  final int? initialIndex;

  const VideoPlayerScreen({
    super.key,
    this.video,
    this.playlist,
    this.initialIndex,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  final TransformationController _transformController =
      TransformationController();

  late List<VideoModel> _playlist;
  late int _currentIndex;

  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isLooping = false;
  bool _isMuted = false;
  bool _isBackgroundPlay = false;
  String _decoderMode = 'HW';
  double _currentSpeed = 1.0;
  BoxFitMode _fitMode = BoxFitMode.fitScreen;

  Timer? _sleepTimer;
  int _sleepTimerRemainingSeconds = 0;
  bool _stopAtEndOfVideo = false;

  bool _isAutoPlayCountingDown = false;
  int _autoPlayCountdown = 5;
  Timer? _autoPlayTimer;

  List<SubtitleItem> _subtitles = [];
  final ValueNotifier<String> _currentSubtitleNotifier = ValueNotifier<String>(
    '',
  );
  double _subtitleFontSize = 18.0;
  bool _subtitlesEnabled = true;
  int _subtitleOffsetMs = 0;

  double _volume = 0.5;
  double _brightness = 0.5;
  double _audioBoostVolume = 1.0;
  bool _isDisplayingVolume = false;
  bool _isDisplayingBrightness = false;

  bool _isSeekingByDrag = false;
  Duration _dragTargetPosition = Duration.zero;

  bool _showForwardRipple = false;
  bool _showBackwardRipple = false;
  bool _showPlayPauseRipple = false;

  Timer? _controlsTimer;
  final List<double> _playbackSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  VideoModel get _currentVideo => _playlist[_currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      _playlist = widget.playlist!;
    } else if (widget.video != null) {
      _playlist = [widget.video!];
    } else {
      _playlist = [];
    }

    if (widget.initialIndex != null &&
        widget.initialIndex! >= 0 &&
        widget.initialIndex! < _playlist.length) {
      _currentIndex = widget.initialIndex!;
    } else if (widget.video != null) {
      final index = _playlist.indexWhere((v) => v.path == widget.video!.path);
      _currentIndex = index != -1 ? index : 0;
    } else {
      _currentIndex = 0;
    }

    // إجبار الشاشة على الوضع الأفقي عند فتح الفيديو
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isInitialized = false;
      _subtitles = [];
      _currentSubtitleNotifier.value = '';
      _subtitleOffsetMs = 0;
      _isAutoPlayCountingDown = false;
    });

    if (_playlist.isEmpty) return;

    if (_currentVideo.path.startsWith('http://') ||
        _currentVideo.path.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(_currentVideo.path),
      );
    } else {
      _controller = VideoPlayerController.file(File(_currentVideo.path));
    }

    await _controller.initialize();

    try {
      _brightness = await ScreenBrightness().current;
      _volume = await VolumeController.instance.getVolume();
    } catch (_) {}

    _controller.addListener(_videoListener);

    setState(() {
      _isInitialized = true;
    });

    _checkAutoSubtitle();

    final savedSeconds = await _getResumePosition();
    if (savedSeconds > 3) {
      await _controller.seekTo(Duration(seconds: savedSeconds));
    }

    _controller.setPlaybackSpeed(_currentSpeed);
    _controller.setVolume(_isMuted ? 0.0 : _audioBoostVolume);
    _controller.play();
    _startControlsTimer();
  }

  Future<int> _getResumePosition() async {
    int resumeSeconds = 0;
    try {
      final cloudHistories = await CloudHistoryService.fetchHistory();
      final item = cloudHistories.firstWhere(
        (element) => element['video_identifier'] == _currentVideo.path,
        orElse: () => null,
      );

      if (item != null && item['last_position_seconds'] != null) {
        final bool isCompleted = item['is_completed'] ?? false;
        if (!isCompleted) {
          resumeSeconds = item['last_position_seconds'];
        }
      }
    } catch (_) {}

    if (resumeSeconds <= 3) {
      resumeSeconds = await ref
          .read(playbackPositionProvider.notifier)
          .getSavedPosition(_currentVideo.path);
    }

    return resumeSeconds;
  }

  void _syncToCloud() {
    if (!_isInitialized) return;
    final position = _controller.value.position.inSeconds;
    final duration = _controller.value.duration.inSeconds;

    CloudHistoryService.syncProgress(
      videoIdentifier: _currentVideo.path,
      videoTitle: _currentVideo.title,
      lastPositionSeconds: position,
      totalDurationSeconds: duration,
    );
  }

  void _videoListener() {
    if (!mounted) return;

    if (_stopAtEndOfVideo &&
        _controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      _controller.pause();
      _saveCurrentPosition();
      _syncToCloud();
      _cancelSleepTimer();
      return;
    }

    if (_isInitialized &&
        !_isLooping &&
        !_stopAtEndOfVideo &&
        _controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero &&
        !_isAutoPlayCountingDown) {
      _saveCurrentPosition();
      _syncToCloud();
      if (_currentIndex < _playlist.length - 1) {
        _startAutoPlayCountdown();
      }
    }

    if (_subtitlesEnabled && _subtitles.isNotEmpty) {
      final currentPos = _controller.value.position;
      final effectivePos =
          currentPos - Duration(milliseconds: _subtitleOffsetMs);

      final currentSub = _subtitles.firstWhere(
        (sub) => effectivePos >= sub.start && effectivePos <= sub.end,
        orElse: () =>
            SubtitleItem(start: Duration.zero, end: Duration.zero, text: ''),
      );

      if (_currentSubtitleNotifier.value != currentSub.text) {
        _currentSubtitleNotifier.value = currentSub.text;
      }
    } else if (_currentSubtitleNotifier.value.isNotEmpty) {
      _currentSubtitleNotifier.value = '';
    }
  }

  // دالة الخروج واستعادة الوضع الطبيعي
  Future<void> _exitPlayer() async {
    _controller.pause();
    _saveCurrentPosition();
    _syncToCloud();

    // إجبار الجهاز على العودة للوضع العمودي ثم إتاحة جميع الاتجاهات
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await Future.delayed(const Duration(milliseconds: 100));

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isLocked || !_isInitialized) return;

    if (_transformController.value.getMaxScaleOnAxis() > 1.05) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final currentPos = _controller.value.position;

    if (tapX < screenWidth * 0.35) {
      _controller.seekTo(currentPos - const Duration(seconds: 10));
      setState(() => _showBackwardRipple = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showBackwardRipple = false);
      });
    } else if (tapX > screenWidth * 0.65) {
      _controller.seekTo(currentPos + const Duration(seconds: 10));
      setState(() => _showForwardRipple = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showForwardRipple = false);
      });
    } else {
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
          _saveCurrentPosition();
          _syncToCloud();
        } else {
          _controller.play();
        }
        _showPlayPauseRipple = true;
      });
      _startControlsTimer();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showPlayPauseRipple = false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isBackgroundPlay && _controller.value.isPlaying) {
        _controller.pause();
      }
      _saveCurrentPosition();
      _syncToCloud();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _autoPlayTimer?.cancel();
    _sleepTimer?.cancel();

    _saveCurrentPosition();
    _syncToCloud();

    _controller.pause();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _transformController.dispose();
    _currentSubtitleNotifier.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _setSleepTimer(int minutes) {
    _cancelSleepTimer();
    setState(() {
      _stopAtEndOfVideo = false;
      _sleepTimerRemainingSeconds = minutes * 60;
    });

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemainingSeconds > 1) {
        setState(() {
          _sleepTimerRemainingSeconds--;
        });
      } else {
        timer.cancel();
        _controller.pause();
        _saveCurrentPosition();
        _syncToCloud();
        setState(() {
          _sleepTimerRemainingSeconds = 0;
        });
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerRemainingSeconds = 0;
      _stopAtEndOfVideo = false;
    });
  }

  void _startAutoPlayCountdown() {
    setState(() {
      _isAutoPlayCountingDown = true;
      _autoPlayCountdown = 5;
    });

    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoPlayCountdown > 1) {
        setState(() {
          _autoPlayCountdown--;
        });
      } else {
        timer.cancel();
        _playNextVideo();
      }
    });
  }

  void _playNextVideo() {
    _autoPlayTimer?.cancel();
    if (_currentIndex < _playlist.length - 1) {
      _saveCurrentPosition();
      _syncToCloud();
      _controller.pause();
      _controller.removeListener(_videoListener);
      _controller.dispose();
      setState(() {
        _currentIndex++;
      });
      _initPlayer();
    }
  }

  void _playPreviousVideo() {
    _autoPlayTimer?.cancel();
    if (_currentIndex > 0) {
      _saveCurrentPosition();
      _syncToCloud();
      _controller.pause();
      _controller.removeListener(_videoListener);
      _controller.dispose();
      setState(() {
        _currentIndex--;
      });
      _initPlayer();
    }
  }

  void _saveCurrentPosition() {
    if (_isInitialized) {
      final currentPos = _controller.value.position.inSeconds;
      final totalDuration = _controller.value.duration.inSeconds;
      if (totalDuration - currentPos > 5 && currentPos > 3) {
        ref
            .read(playbackPositionProvider.notifier)
            .savePosition(_currentVideo.path, currentPos);
      } else {
        ref
            .read(playbackPositionProvider.notifier)
            .clearPosition(_currentVideo.path);
      }
    }
  }

  Future<void> _checkAutoSubtitle() async {
    try {
      final srtPath = _currentVideo.path.replaceAll(
        RegExp(r'\.[a-zA-Z0-9]+$'),
        '.srt',
      );
      final srtFile = File(srtPath);
      if (await srtFile.exists()) {
        final content = await srtFile.readAsString();
        _subtitles = SubtitleParser.parseSrt(content);
      }
    } catch (_) {}
  }

  Future<void> _pickExternalSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      _subtitles = SubtitleParser.parseSrt(content);
      _subtitlesEnabled = true;
      _subtitleOffsetMs = 0;
      if (mounted) setState(() {});
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControls && !_isLocked) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _toggleAspectRatio() {
    setState(() {
      switch (_fitMode) {
        case BoxFitMode.fitScreen:
          _fitMode = BoxFitMode.stretch;
          break;
        case BoxFitMode.stretch:
          _fitMode = BoxFitMode.crop;
          break;
        case BoxFitMode.crop:
          _fitMode = BoxFitMode.fit100;
          break;
        case BoxFitMode.fit100:
          _fitMode = BoxFitMode.fitScreen;
          break;
      }
    });
  }

  void _toggleRotation() {
    final currentOrientation = MediaQuery.of(context).orientation;
    if (currentOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    Future.delayed(const Duration(seconds: 2), () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
  }

  void _handleVerticalDrag(
    DragUpdateDetails details,
    BuildContext context,
  ) async {
    if (_isLocked || _transformController.value.getMaxScaleOnAxis() > 1.05)
      return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx < (screenWidth / 2);
    final delta = -details.primaryDelta! / 200;

    if (isLeftSide) {
      _brightness = (_brightness + delta).clamp(0.0, 1.0);
      try {
        await ScreenBrightness().setScreenBrightness(_brightness);
      } catch (_) {}
      setState(() {
        _isDisplayingBrightness = true;
        _isDisplayingVolume = false;
      });
    } else {
      _volume = (_volume + delta).clamp(0.0, 1.0);
      VolumeController.instance.setVolume(_volume);
      setState(() {
        _isDisplayingVolume = true;
        _isDisplayingBrightness = false;
      });
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isLocked ||
        !_isInitialized ||
        _transformController.value.getMaxScaleOnAxis() > 1.05) {
      return;
    }

    final totalDuration = _controller.value.duration;
    final delta = details.primaryDelta! / 5;
    final currentSeek = _isSeekingByDrag
        ? _dragTargetPosition
        : _controller.value.position;
    final newSeconds = (currentSeek.inSeconds + delta.round()).clamp(
      0,
      totalDuration.inSeconds,
    );

    setState(() {
      _isSeekingByDrag = true;
      _dragTargetPosition = Duration(seconds: newSeconds);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isSeekingByDrag) {
      _controller.seekTo(_dragTargetPosition);
      _saveCurrentPosition();
      setState(() {
        _isSeekingByDrag = false;
      });
      _startControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitPlayer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isInitialized
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                onDoubleTapDown: _handleDoubleTap,
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDrag(details, context),
                onVerticalDragEnd: (_) {
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) {
                      setState(() {
                        _isDisplayingVolume = false;
                        _isDisplayingBrightness = false;
                      });
                    }
                  });
                },
                onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                onHorizontalDragEnd: _handleHorizontalDragEnd,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      panEnabled: !_isLocked,
                      scaleEnabled: !_isLocked,
                      child: _buildVideoSurface(),
                    ),

                    if (_subtitlesEnabled)
                      ValueListenableBuilder<String>(
                        valueListenable: _currentSubtitleNotifier,
                        builder: (context, subText, child) {
                          if (subText.isEmpty) return const SizedBox.shrink();
                          return Positioned(
                            bottom: _showControls ? 75 : 25,
                            left: 20,
                            right: 20,
                            child: Text(
                              subText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _subtitleFontSize,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(1.5, 1.5),
                                  ),
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(-1.5, -1.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    if (_showForwardRipple)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3,
                          color: Colors.white.withOpacity(0.12),
                          child: const Center(
                            child: Icon(
                              Icons.fast_forward_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                    if (_showBackwardRipple)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3,
                          color: Colors.white.withOpacity(0.12),
                          child: const Center(
                            child: Icon(
                              Icons.fast_rewind_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                    if (_showPlayPauseRipple)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),

                    if (_isSeekingByDrag)
                      _buildMxIndicator(
                        icon: Icons.access_time_rounded,
                        text:
                            '${_formatDuration(_dragTargetPosition)} / ${_formatDuration(_controller.value.duration)}',
                        progress:
                            _dragTargetPosition.inMilliseconds /
                            (_controller.value.duration.inMilliseconds > 0
                                ? _controller.value.duration.inMilliseconds
                                : 1),
                      ),

                    if (_isDisplayingVolume && !_isLocked)
                      _buildMxIndicator(
                        icon: _volume == 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        text: 'الصوت: ${(_volume * 100).round()}%',
                        progress: _volume,
                      ),

                    if (_isDisplayingBrightness && !_isLocked)
                      _buildMxIndicator(
                        icon: Icons.brightness_6_rounded,
                        text: 'السطوع: ${(_brightness * 100).round()}%',
                        progress: _brightness,
                      ),

                    if (_showControls || _isLocked)
                      Positioned(
                        bottom: 20,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => setState(() => _isLocked = !_isLocked),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              color: _isLocked
                                  ? Colors.blueAccent
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                    if (!_isLocked && _showControls) _buildMxControlsOverlay(),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
      ),
    );
  }

  Widget _buildVideoSurface() {
    BoxFit fit = BoxFit.contain;
    if (_fitMode == BoxFitMode.stretch) fit = BoxFit.fill;
    if (_fitMode == BoxFitMode.crop) fit = BoxFit.cover;

    return Center(
      child: FittedBox(
        fit: fit,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildMxIndicator({
    required IconData icon,
    required String text,
    required double progress,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMxControlsOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 4),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _exitPlayer,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _currentVideo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'المسار الصوتي',
                    onPressed: _showAudioTracksDialog,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.subtitles_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'الترجمة',
                    onPressed: _showSubtitleSettingsDialog,
                  ),
                  InkWell(
                    onTap: _toggleDecoderMode,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _decoderMode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _showMxMenu,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'الموازن والمعادل',
                    onPressed: _showAdvancedAudioDialog,
                  ),
                  InkWell(
                    onTap: _showSpeedDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '${_currentSpeed}X',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.crop_free_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'التقاط صورة',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حفظ لقطة الشاشة'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isBackgroundPlay
                          ? Icons.headset_rounded
                          : Icons.headset_off_rounded,
                      color: _isBackgroundPlay
                          ? Colors.blueAccent
                          : Colors.white,
                      size: 20,
                    ),
                    tooltip: 'تشغيل في الخلفية',
                    onPressed: () {
                      setState(() => _isBackgroundPlay = !_isBackgroundPlay);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.screen_rotation_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'تدوير الشاشة',
                    onPressed: _toggleRotation,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onPressed: _showAdvancedAudioDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: Colors.blueAccent,
                            inactiveTrackColor: Colors.white30,
                            thumbColor: Colors.blueAccent,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: value.position.inMilliseconds
                                .toDouble()
                                .clamp(
                                  0.0,
                                  value.duration.inMilliseconds.toDouble(),
                                ),
                            min: 0.0,
                            max: value.duration.inMilliseconds.toDouble() > 0
                                ? value.duration.inMilliseconds.toDouble()
                                : 1.0,
                            onChanged: (val) {
                              _controller.seekTo(
                                Duration(milliseconds: val.toInt()),
                              );
                              _saveCurrentPosition();
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 28,
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _currentIndex > 0
                                  ? _playPreviousVideo
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              iconSize: 42,
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (value.isPlaying) {
                                  _controller.pause();
                                  _saveCurrentPosition();
                                  _syncToCloud();
                                } else {
                                  _controller.play();
                                }
                                _startControlsTimer();
                              },
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              iconSize: 28,
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _currentIndex < _playlist.length - 1
                                  ? _playNextVideo
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _fitMode == BoxFitMode.fitScreen
                              ? Icons.fit_screen_rounded
                              : (_fitMode == BoxFitMode.stretch
                                    ? Icons.aspect_ratio_rounded
                                    : Icons.fullscreen_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _toggleAspectRatio,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_in_picture_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleDecoderMode() {
    setState(() {
      if (_decoderMode == 'HW') {
        _decoderMode = 'SW';
      } else if (_decoderMode == 'SW') {
        _decoderMode = 'HW+';
      } else {
        _decoderMode = 'HW';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('وضع فك الترميز: $_decoderMode'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAudioTracksDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'المسار الصوتي (Audio Track)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            RadioListTile<int>(
              value: 1,
              groupValue: 1,
              activeColor: Colors.blueAccent,
              title: const Text(
                'المسار 1 (افتراضي)',
                style: TextStyle(color: Colors.white),
              ),
              onChanged: (val) => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showMxMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime_rounded, color: Colors.white),
              title: const Text(
                'مؤقت النوم',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showSleepTimerPicker();
              },
            ),
            ListTile(
              leading: Icon(
                _isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                color: Colors.white,
              ),
              title: const Text(
                'تكرار الفيديو',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: _isLooping,
                activeColor: Colors.blueAccent,
                onChanged: (val) {
                  setState(() {
                    _isLooping = val;
                    _controller.setLooping(_isLooping);
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'مؤقت النوم',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              title: const Text(
                '15 دقيقة',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setSleepTimer(15);
              },
            ),
            ListTile(
              title: const Text(
                '30 دقيقة',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setSleepTimer(30);
              },
            ),
            ListTile(
              title: const Text(
                'عند نهاية الفيديو',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _stopAtEndOfVideo = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedAudioDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'مضخم الصوت (Audio Boost)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    Row(
                      children: [
                        const Text(
                          'مستوى التعزيز: ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${(_audioBoostVolume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _audioBoostVolume,
                            min: 1.0,
                            max: 2.0,
                            divisions: 10,
                            activeColor: Colors.blueAccent,
                            onChanged: (val) {
                              setModalState(() => _audioBoostVolume = val);
                              setState(() {
                                _audioBoostVolume = val;
                                if (!_isMuted) {
                                  _controller.setVolume(val);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSubtitleSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final offsetSeconds = (_subtitleOffsetMs / 1000).toStringAsFixed(1);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'إعدادات الترجمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      title: const Text(
                        'تفعيل الترجمة',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _subtitlesEnabled,
                      activeColor: Colors.blueAccent,
                      onChanged: (val) {
                        setModalState(() => _subtitlesEnabled = val);
                        setState(() => _subtitlesEnabled = val);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.file_open_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: const Text(
                        'اختيار ملف ترجمة (.srt)',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickExternalSubtitle();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مزامنة التوقيت:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Colors.amberAccent,
                              ),
                              onPressed: () {
                                setModalState(() => _subtitleOffsetMs -= 500);
                                setState(() => _subtitleOffsetMs -= 500);
                              },
                            ),
                            Text(
                              '${_subtitleOffsetMs >= 0 ? '+' : ''}${offsetSeconds}s',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: Colors.amberAccent,
                              ),
                              onPressed: () {
                                setModalState(() => _subtitleOffsetMs += 500);
                                setState(() => _subtitleOffsetMs += 500);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'سرعة التشغيل',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ..._playbackSpeeds.map((speed) {
                final isSelected = _currentSpeed == speed;
                return ListTile(
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blueAccent)
                      : null,
                  onTap: () {
                    setState(() {
                      _currentSpeed = speed;
                      _controller.setPlaybackSpeed(speed);
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
