import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/audio_model.dart';

const Set<String> _audioExtensions = {
  '.mp3',
  '.m4a',
  '.aac',
  '.wav',
  '.ogg',
  '.flac',
  '.opus',
  '.wma',
  '.amr',
  '.3gp',
  '.awb',
  '.mid',
  '.mp2',
};

final audioListProvider = FutureProvider<List<AudioModel>>((ref) async {
  bool hasPermission = false;

  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      hasPermission = true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      hasPermission = status.isGranted;
    }

    if (!hasPermission) {
      final audioStatus = await Permission.audio.request();
      final storageStatus = await Permission.storage.request();
      hasPermission = audioStatus.isGranted || storageStatus.isGranted;
    }
  } else {
    hasPermission = true;
  }

  if (!hasPermission) return [];

  final List<Directory> scanRoots = [];

  final primaryStorage = Directory('/storage/emulated/0');
  if (await primaryStorage.exists()) {
    scanRoots.add(primaryStorage);
  }

  final storageDir = Directory('/storage');
  if (await storageDir.exists()) {
    try {
      final entries = storageDir.listSync(followLinks: false);
      for (var entry in entries) {
        if (entry is Directory &&
            entry.path != '/storage/emulated' &&
            entry.path != '/storage/self') {
          scanRoots.add(entry);
        }
      }
    } catch (_) {}
  }

  final List<AudioModel> audios = [];

  for (final root in scanRoots) {
    await _scanAudioDirectoryRecursive(root, audios);
  }

  final Map<String, AudioModel> uniqueMap = {};
  for (var audio in audios) {
    uniqueMap[audio.path] = audio;
  }

  final result = uniqueMap.values.toList();
  result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  return result;
});

Future<void> _scanAudioDirectoryRecursive(
  Directory dir,
  List<AudioModel> audios,
) async {
  try {
    final List<FileSystemEntity> entities = dir.listSync(followLinks: false);

    for (final entity in entities) {
      final name = entity.path.split('/').last;

      if (name.startsWith('.') ||
          name.toLowerCase() == 'cache' ||
          name.toLowerCase() == 'android/data' ||
          name.toLowerCase() == 'android/obb') {
        continue;
      }

      if (entity is File) {
        final dotIndex = entity.path.lastIndexOf('.');
        if (dotIndex != -1) {
          final ext = entity.path.substring(dotIndex).toLowerCase();
          if (_audioExtensions.contains(ext)) {
            final stat = entity.statSync();
            if (stat.size > 1024) {
              final title = name.substring(0, dotIndex);
              final parentDirName = entity.parent.path.split('/').last;

              audios.add(
                AudioModel(
                  id: entity.path,
                  title: title.isEmpty ? name : title,
                  artist: parentDirName,
                  path: entity.path,
                  size: stat.size,
                  duration: Duration.zero,
                ),
              );
            }
          }
        }
      } else if (entity is Directory) {
        await _scanAudioDirectoryRecursive(entity, audios);
      }
    }
  } catch (_) {}
}
