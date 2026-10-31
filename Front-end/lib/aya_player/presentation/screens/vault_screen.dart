import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/media_provider.dart';
import '../../data/models/video_model.dart';
import '../widgets/video_thumbnail_widget.dart';
import 'video_player_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final foldersAsync = ref.watch(foldersProvider);

    if (!vaultState.isUnlocked) {
      final isFirstTime = vaultState.pinCode.isEmpty;
      return Scaffold(
        appBar: AppBar(title: const Text('الخزنة الآمنة 🔒')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 64,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFirstTime
                    ? 'أنشئ رمز PIN لحماية فيديوهاتك'
                    : 'أدخل رمز PIN لفتح الخزنة',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    letterSpacing: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final pin = _pinController.text.trim();
                    if (pin.length < 4) {
                      setState(
                        () => _errorMessage = 'الرمز يجب أن يتكون من 4 أرقام',
                      );
                      return;
                    }

                    if (isFirstTime) {
                      ref.read(vaultProvider.notifier).setPin(pin);
                    } else {
                      final success = ref
                          .read(vaultProvider.notifier)
                          .unlockWithPin(pin);
                      if (!success) {
                        setState(() => _errorMessage = 'رمز PIN غير صحيح');
                      }
                    }
                  },
                  child: Text(
                    isFirstTime ? 'حفظ وتأمين' : 'فتح الخزنة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزنة الآمنة 🔒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_clock_rounded),
            tooltip: 'قفل الخزنة',
            onPressed: () {
              ref.read(vaultProvider.notifier).lockVault();
              _pinController.clear();
            },
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          List<VideoModel> lockedVideos = [];
          for (var folder in folders) {
            for (var video in folder.videos) {
              if (vaultState.lockedVideoPaths.contains(video.path)) {
                lockedVideos.add(video);
              }
            }
          }

          if (lockedVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shield_outlined, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'الخزنة فارغة حالياً\nيمكنك قفل أي فيديو من القائمة الرئيسية',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lockedVideos.length,
            itemBuilder: (context, index) {
              final video = lockedVideos[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    video.formattedSize,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.lock_open_rounded,
                      color: Colors.amberAccent,
                    ),
                    tooltip: 'إلغاء القفل',
                    onPressed: () {
                      ref
                          .read(vaultProvider.notifier)
                          .toggleLockVideo(video.path);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          playlist: lockedVideos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        error: (err, _) => Center(
          child: Text('خطأ: $err', style: const TextStyle(color: Colors.red)),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      ),
    );
  }
}
