import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/local_storage.dart';
import '../../../di/providers.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ThemeModeNotifier(localStorage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorage _localStorage;

  ThemeModeNotifier(this._localStorage) : super(ThemeMode.system) {
    _init();
  }

  Future<void> _init() async {
    final isDark = await _localStorage.isDarkMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    await _localStorage.setDarkMode(!isDark);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _localStorage.setDarkMode(mode == ThemeMode.dark);
  }
}
