import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/folder_model.dart';
import '../data/models/video_model.dart';

const Set<String> _videoExtensions = {
  '.mp4',
  '.mkv',
  '.avi',
  '.mov',
  '.flv',
  '.wmv',
  '.webm',
  '.3gp',
  '.ts',
  '.m4v',
  '.mpg',
  '.mpeg',
};

final foldersProvider = FutureProvider<List<FolderModel>>((ref) async {
  bool hasPermission = false;

  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      hasPermission = true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      hasPermission = status.isGranted;
    }

    if (!hasPermission) {
      final mediaStatus = await Permission.videos.request();
      final storageStatus = await Permission.storage.request();
      hasPermission = mediaStatus.isGranted || storageStatus.isGranted;
    }
  } else {
    hasPermission = true;
  }

  if (!hasPermission) {
    return [];
  }

  final List<Directory> rootDirectories = [];

  final primaryStorage = Directory('/storage/emulated/0');
  if (await primaryStorage.exists()) {
    rootDirectories.add(primaryStorage);
  }

  final storageDir = Directory('/storage');
  if (await storageDir.exists()) {
    try {
      final entries = storageDir.listSync(followLinks: false);
      for (var entry in entries) {
        if (entry is Directory &&
            entry.path != '/storage/emulated' &&
            entry.path != '/storage/self') {
          rootDirectories.add(entry);
        }
      }
    } catch (_) {}
  }

  final Map<String, List<VideoModel>> folderMap = {};

  for (final root in rootDirectories) {
    await _scanDirectory(root, folderMap);
  }

  final List<FolderModel> folders = [];
  folderMap.forEach((folderPath, videos) {
    if (videos.isNotEmpty) {
      final folderName = folderPath.split('/').where((s) => s.isNotEmpty).last;
      folders.add(
        FolderModel(name: folderName, path: folderPath, videos: videos),
      );
    }
  });

  folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return folders;
});

Future<void> _scanDirectory(
  Directory dir,
  Map<String, List<VideoModel>> folderMap,
) async {
  try {
    final List<FileSystemEntity> entities = dir.listSync(followLinks: false);

    for (final entity in entities) {
      final name = entity.path.split('/').last;

      if (name.startsWith('.') ||
          name.toLowerCase() == 'android' ||
          name.toLowerCase() == 'cache') {
        continue;
      }

      if (entity is File) {
        final dotIndex = entity.path.lastIndexOf('.');
        if (dotIndex != -1) {
          final ext = entity.path.substring(dotIndex).toLowerCase();
          if (_videoExtensions.contains(ext)) {
            final parentPath = entity.parent.path;
            final stat = entity.statSync();

            final video = VideoModel(
              id: entity.path,
              path: entity.path,
              title: name,
              duration: Duration.zero,
              size: stat.size,
            );

            folderMap.putIfAbsent(parentPath, () => []).add(video);
          }
        }
      } else if (entity is Directory) {
        await _scanDirectory(entity, folderMap);
      }
    }
  } catch (_) {}
}
