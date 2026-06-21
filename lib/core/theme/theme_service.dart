import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  ThemeService._();

  Future<void> initialize() async {
    final storedMode = await StorageService.instance.getThemeMode();
    if (storedMode != null) {
      themeModeNotifier.value = _parseThemeMode(storedMode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await StorageService.instance.saveThemeMode(mode.name);
  }

  ThemeMode _parseThemeMode(String modeStr) {
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
