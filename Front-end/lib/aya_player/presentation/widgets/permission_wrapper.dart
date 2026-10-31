import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionWrapper extends StatefulWidget {
  final Widget child;
  const PermissionWrapper({super.key, required this.child});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() => _granted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) return widget.child;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_rounded, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 20),
            const Text('نحتاج إذن الوصول للملفات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('بدون الإذن لا يمكننا عرض فيديوهاتك', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                _checkPermission();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text('فتح الإعدادات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}