import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/video_model.dart';
import '../../providers/media_provider.dart';
import '../../providers/vault_provider.dart';

class VideoActionsSheet {
  static void show(BuildContext context, WidgetRef ref, VideoModel video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.movie_rounded,
                      color: Colors.deepPurpleAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                ),
                title: const Text(
                  'معلومات الفيديو',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInfoDialog(context, video);
                },
              ),

              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text(
                  'مشاركة',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles([XFile(video.path)], text: video.title);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.amberAccent,
                ),
                title: const Text(
                  'نقل إلى الخزنة الآمنة',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(vaultProvider.notifier).toggleLockVideo(video.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نقل الفيديو إلى الخزنة الآمنة 🔒'),
                      backgroundColor: Color(0xFF1E1E2C),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                title: const Text(
                  'إعادة تسمية',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, ref, video);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'حذف من الجهاز',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmDialog(context, ref, video);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showInfoDialog(BuildContext context, VideoModel video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تفاصيل الملف',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('الاسم:', video.title),
            _buildInfoRow('الحجم:', video.formattedSize),
            _buildInfoRow('المسار:', video.path),
            _buildInfoRow(
              'الامتداد:',
              video.path.split('.').last.toUpperCase(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إغلاق',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          text: '$title ',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    VideoModel video,
  ) {
    final controller = TextEditingController(text: video.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'إعادة تسمية الفيديو',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'الاسم الجديد',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurpleAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != video.title) {
                try {
                  final file = File(video.path);
                  final dir = file.parent.path;
                  final ext = video.path.split('.').last;
                  final newPath = '$dir/$newName.$ext';
                  await file.rename(newPath);
                  ref.refresh(foldersProvider);
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل تغيير الاسم: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    VideoModel video,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف "${video.title}" نهائياً من ذاكرة الهاتف؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                final file = File(video.path);
                if (await file.exists()) {
                  await file.delete();
                  ref.refresh(foldersProvider);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف الفيديو بنجاح'),
                        backgroundColor: Color(0xFF1E1E2C),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحذف: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
