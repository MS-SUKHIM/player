import 'package:flutter/material.dart';
import '../../data/models/video_model.dart';
import '../screens/video_player_screen.dart';

class NetworkStreamDialog extends StatefulWidget {
  const NetworkStreamDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const NetworkStreamDialog(),
    );
  }

  @override
  State<NetworkStreamDialog> createState() => _NetworkStreamDialogState();
}

class _NetworkStreamDialogState extends State<NetworkStreamDialog> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _playStream() {
    if (_formKey.currentState?.validate() ?? false) {
      final url = _urlController.text.trim();
      Navigator.pop(context);

      final networkVideo = VideoModel(
        id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
        title: url.split('/').last.isNotEmpty ? url.split('/').last : 'بث مباشر / شبكة',
        path: url,
        duration: Duration.zero,
        size: 0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: networkVideo,
            playlist: [networkVideo],
            initialIndex: 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.link_rounded, color: Colors.blueAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'تشغيل عبر الشبكة (URL)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://example.com/video.mp4',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF12121E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رابط الفيديو';
                  }
                  if (!value.trim().startsWith('http://') && !value.trim().startsWith('https://')) {
                    return 'يجب أن يبدأ الرابط بـ http:// أو https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _playStream,
                    child: const Text('تشغيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
