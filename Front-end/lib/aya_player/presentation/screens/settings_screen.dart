import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // إعدادات المشغل (Player)
  String _decoder = 'HW';
  bool _backgroundPlay = false;
  bool _autoResume = true;
  int _seekDuration = 10;
  bool _volumeGestures = true;
  bool _brightnessGestures = true;
  bool _autoRotate = true;
  bool _pipEnabled = true;

  // إعدادات الصوت (Audio)
  bool _audioBoost = false;
  bool _duckAudio = true;
  bool _rememberAudioTrack = true;

  // إعدادات الترجمة (Subtitles)
  bool _autoSubtitles = true;
  double _subtitleSize = 18.0;
  String _subtitleColor = 'أبيض';
  String _subtitleEncoding = 'UTF-8';

  // إعدادات القائمة والتخزين (List & Storage)
  bool _showThumbnails = true;
  bool _showHiddenFiles = false;
  bool _scanAudioOnlyMusic = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _decoder = prefs.getString('pref_decoder') ?? 'HW';
      _backgroundPlay = prefs.getBool('pref_bg_play') ?? false;
      _autoResume = prefs.getBool('pref_auto_resume') ?? true;
      _seekDuration = prefs.getInt('pref_seek_sec') ?? 10;
      _volumeGestures = prefs.getBool('pref_volume_gestures') ?? true;
      _brightnessGestures = prefs.getBool('pref_brightness_gestures') ?? true;
      _autoRotate = prefs.getBool('pref_auto_rotate') ?? true;
      _pipEnabled = prefs.getBool('pref_pip_enabled') ?? true;

      _audioBoost = prefs.getBool('pref_audio_boost') ?? false;
      _duckAudio = prefs.getBool('pref_duck_audio') ?? true;
      _rememberAudioTrack = prefs.getBool('pref_remember_audio') ?? true;

      _autoSubtitles = prefs.getBool('pref_auto_subs') ?? true;
      _subtitleSize = prefs.getDouble('pref_sub_size') ?? 18.0;
      _subtitleColor = prefs.getString('pref_sub_color') ?? 'أبيض';
      _subtitleEncoding = prefs.getString('pref_sub_enc') ?? 'UTF-8';

      _showThumbnails = prefs.getBool('pref_show_thumbs') ?? true;
      _showHiddenFiles = prefs.getBool('pref_show_hidden') ?? false;
      _scanAudioOnlyMusic = prefs.getBool('pref_scan_audio_only') ?? false;
    });
  }

  Future<void> _setBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _setString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  Future<void> _setInt(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, val);
  }

  Future<void> _setDouble(String key, double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات العامة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 1. المظهر والثيم
          _buildHeader('المظهر والواجهة (Appearance)'),
          SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.blueAccent,
            ),
            title: const Text('الوضع الداكن (Dark Mode)'),
            subtitle: Text(isDarkMode ? 'الوضع الليلي مفعّل' : 'الوضع الفاتح مفعّل'),
            value: isDarkMode,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              ref.read(themeProvider.notifier).toggleTheme(val);
            },
          ),

          const Divider(height: 20),
          // 2. التحكم والإيماءات في الفيديو
          _buildHeader('المشغل والإيماءات (Player & Gestures)'),
          ListTile(
            leading: const Icon(Icons.memory_rounded, color: Colors.blueAccent),
            title: const Text('وحدة فك الترميز الافتراضية'),
            subtitle: Text('الوضع: $_decoder (أداء عالي وسلس)'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _pickDecoder,
          ),
          ListTile(
            leading: const Icon(Icons.fast_forward_rounded, color: Colors.blueAccent),
            title: const Text('مدة التقديم والتأخير بالنقر المزدوج'),
            subtitle: Text('$_seekDuration ثوانٍ'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _pickSeekDuration,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.history_rounded, color: Colors.blueAccent),
            title: const Text('استئناف التشغيل الذكي'),
            subtitle: const Text('تذكر موضع التوقف الأخير لكل فيديو تلقائياً'),
            value: _autoResume,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _autoResume = val);
              _setBool('pref_auto_resume', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded, color: Colors.blueAccent),
            title: const Text('إيماءة الصوت باللمس'),
            subtitle: const Text('السحب لأعلى/أسفل على الجانب الأيمن'),
            value: _volumeGestures,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _volumeGestures = val);
              _setBool('pref_volume_gestures', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6_rounded, color: Colors.blueAccent),
            title: const Text('إيماءة السطوع باللمس'),
            subtitle: const Text('السحب لأعلى/أسفل على الجانب الأيسر'),
            value: _brightnessGestures,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _brightnessGestures = val);
              _setBool('pref_brightness_gestures', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.screen_rotation_rounded, color: Colors.blueAccent),
            title: const Text('التدوير التلقائي مع أبعاد الفيديو'),
            subtitle: const Text('تدوير الشاشة أوتوماتيكياً عند تشغيل فيديو عريض'),
            value: _autoRotate,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _autoRotate = val);
              _setBool('pref_auto_rotate', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.blueAccent),
            title: const Text('صورة داخل صورة (PiP)'),
            subtitle: const Text('تصغير الفيديو لنافذة عائمة عند الخروج'),
            value: _pipEnabled,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _pipEnabled = val);
              _setBool('pref_pip_enabled', val);
            },
          ),

          const Divider(height: 20),
          // 3. الصوت والموسيقى
          _buildHeader('الصوتيات والخلفية (Audio Engine)'),
          SwitchListTile(
            secondary: const Icon(Icons.headset_rounded, color: Colors.blueAccent),
            title: const Text('التشغيل في الخلفية'),
            subtitle: const Text('استمرار الصوت عند قفل الشاشة أو استخدام تطبيقات أخرى'),
            value: _backgroundPlay,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _backgroundPlay = val);
              _setBool('pref_bg_play', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_down_rounded, color: Colors.blueAccent),
            title: const Text('خفض الصوت أثناء الإشعارات (Audio Focus)'),
            subtitle: const Text('تخفيض صوت المشغل تلقائياً عند وصول تنبيه'),
            value: _duckAudio,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _duckAudio = val);
              _setBool('pref_duck_audio', val);
            },
          ),

          const Divider(height: 20),
          // 4. الترجمة وتخصيصها
          _buildHeader('الترجمة والخطوط (Subtitles)'),
          SwitchListTile(
            secondary: const Icon(Icons.subtitles_rounded, color: Colors.blueAccent),
            title: const Text('البحث التلقائي عن الترجمة'),
            subtitle: const Text('تحميل ملفات .srt المطابقة لاسم الفيديو'),
            value: _autoSubtitles,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _autoSubtitles = val);
              _setBool('pref_auto_subs', val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_size_rounded, color: Colors.blueAccent),
            title: const Text('حجم خط الترجمة'),
            subtitle: Text('${_subtitleSize.toInt()} نقطة'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _pickSubtitleSize,
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: Colors.blueAccent),
            title: const Text('لون نص الترجمة'),
            subtitle: Text(_subtitleColor),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _pickSubtitleColor,
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded, color: Colors.blueAccent),
            title: const Text('ترميز نصوص الترجمة الافتراضي'),
            subtitle: Text(_subtitleEncoding),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _pickSubtitleEncoding,
          ),

          const Divider(height: 20),
          // 5. التخزين والملفات
          _buildHeader('إدارة الملفات والمجلدات (Storage & Library)'),
          SwitchListTile(
            secondary: const Icon(Icons.photo_library_outlined, color: Colors.blueAccent),
            title: const Text('الصور المصغرة للملفات'),
            subtitle: const Text('توليد بوسترات سريعة لملفات الفيديو'),
            value: _showThumbnails,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _showThumbnails = val);
              _setBool('pref_show_thumbs', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined, color: Colors.blueAccent),
            title: const Text('إظهار المجلدات والملفات المخفية'),
            subtitle: const Text('إظهار مجلدات .nomedia والتسجيلات الخاصة'),
            value: _showHiddenFiles,
            activeColor: Colors.blueAccent,
            onChanged: (val) {
              setState(() => _showHiddenFiles = val);
              _setBool('pref_show_hidden', val);
            },
          ),

          const Divider(height: 20),
          // 6. عن التطبيق
          _buildHeader('حول التطبيق (About)'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
            title: const Text('Aya Player Pro', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('الإصدار 1.0.0 (MX Style Edition)'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Aya Player Pro',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.play_circle_fill_rounded, size: 48, color: Colors.blueAccent),
                children: const [
                  Text('مشغل وسائط احترافي يدعم كافة صيغ الفيديو والصوت مع إيماءات تحكم متقدمة، دعم الترجمة، والمزامنة السحابية.'),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _pickDecoder() {
    final list = ['HW (عتاد الجهاز الأسرع)', 'SW (برمجي متوافق)', 'HW+ (المتقدم)'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('وحدة فك الترميز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((opt) {
            final key = opt.split(' ').first;
            return RadioListTile<String>(
              value: key,
              groupValue: _decoder,
              activeColor: Colors.blueAccent,
              title: Text(opt),
              onChanged: (val) {
                setState(() => _decoder = val!);
                _setString('pref_decoder', val!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _pickSeekDuration() {
    final list = [5, 10, 15, 20, 30];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مدة التقديم / التأخير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((sec) {
            return RadioListTile<int>(
              value: sec,
              groupValue: _seekDuration,
              activeColor: Colors.blueAccent,
              title: Text('$sec ثوانٍ'),
              onChanged: (val) {
                setState(() => _seekDuration = val!);
                _setInt('pref_seek_sec', val!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _pickSubtitleSize() {
    final list = [14.0, 16.0, 18.0, 20.0, 24.0, 28.0];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حجم خط الترجمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((size) {
            return RadioListTile<double>(
              value: size,
              groupValue: _subtitleSize,
              activeColor: Colors.blueAccent,
              title: Text('${size.toInt()} pt'),
              onChanged: (val) {
                setState(() => _subtitleSize = val!);
                _setDouble('pref_sub_size', val!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _pickSubtitleColor() {
    final list = ['أبيض', 'أصفر', 'سماوي', 'أخضر'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لون الترجمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((c) {
            return RadioListTile<String>(
              value: c,
              groupValue: _subtitleColor,
              activeColor: Colors.blueAccent,
              title: Text(c),
              onChanged: (val) {
                setState(() => _subtitleColor = val!);
                _setString('pref_sub_color', val!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _pickSubtitleEncoding() {
    final list = ['UTF-8', 'Windows-1256 (عربي)', 'ISO-8859-6', 'ASCII'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ترميز النصوص'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((enc) {
            return RadioListTile<String>(
              value: enc,
              groupValue: _subtitleEncoding,
              activeColor: Colors.blueAccent,
              title: Text(enc),
              onChanged: (val) {
                setState(() => _subtitleEncoding = val!);
                _setString('pref_sub_enc', val!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}