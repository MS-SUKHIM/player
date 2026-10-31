import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbnailWidget extends StatelessWidget {
  final String videoPath;
  final double width;
  final double height;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoPath,
    this.width = 60,
    this.height = 60,
  }) : super(key: key);

  Future<String?> _getThumbnail() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final XFile thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 150,
        quality: 75,
      );
      return thumbnailFile.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF2A2A3C),
        child: FutureBuilder<String?>(
          future: _getThumbnail(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(snapshot.data!), fit: BoxFit.cover),
                  Container(color: Colors.black26),
                  const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Icon(
                Icons.video_file_rounded,
                color: Colors.deepPurpleAccent,
                size: 28,
              ),
            );
          },
        ),
      ),
    );
  }
}
