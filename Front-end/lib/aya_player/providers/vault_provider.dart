import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultState {
  final bool isUnlocked;
  final String pinCode;
  final List<String> lockedVideoPaths;

  VaultState({
    required this.isUnlocked,
    required this.pinCode,
    required this.lockedVideoPaths,
  });

  VaultState copyWith({
    bool? isUnlocked,
    String? pinCode,
    List<String>? lockedVideoPaths,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      pinCode: pinCode ?? this.pinCode,
      lockedVideoPaths: lockedVideoPaths ?? this.lockedVideoPaths,
    );
  }
}

class VaultNotifier extends Notifier<VaultState> {
  static const String _pinKey = 'vault_pin_code';
  static const String _lockedVideosKey = 'vault_locked_videos';

  @override
  VaultState build() {
    _loadVaultData();
    return VaultState(isUnlocked: false, pinCode: '', lockedVideoPaths: []);
  }

  Future<void> _loadVaultData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey) ?? '';
    final savedLocked = prefs.getStringList(_lockedVideosKey) ?? [];
    state = state.copyWith(pinCode: savedPin, lockedVideoPaths: savedLocked);
  }

  Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, newPin);
    state = state.copyWith(pinCode: newPin, isUnlocked: true);
  }

  bool unlockWithPin(String inputPin) {
    if (state.pinCode.isEmpty || state.pinCode == inputPin) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    return false;
  }

  void lockVault() {
    state = state.copyWith(isUnlocked: false);
  }

  Future<void> toggleLockVideo(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> updated = List.from(state.lockedVideoPaths);
    if (updated.contains(videoPath)) {
      updated.remove(videoPath);
    } else {
      updated.add(videoPath);
    }
    await prefs.setStringList(_lockedVideosKey, updated);
    state = state.copyWith(lockedVideoPaths: updated);
  }

  bool isLocked(String videoPath) => state.lockedVideoPaths.contains(videoPath);
}

final vaultProvider = NotifierProvider<VaultNotifier, VaultState>(
  VaultNotifier.new,
);
