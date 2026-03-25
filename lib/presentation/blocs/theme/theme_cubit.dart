import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

/// Cubit managing the app's [ThemeMode] with Hive persistence.
///
/// Supports three modes: system, light, dark.
/// Persists the user's choice to the `app_settings` Hive box.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required Box settingsBox})
      : _box = settingsBox,
        super(_loadSaved(settingsBox));

  final Box _box;
  static const String _key = 'theme_mode';

  static ThemeMode _loadSaved(Box box) {
    final raw = box.get(_key, defaultValue: 'system') as String;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Change the theme mode and persist it.
  Future<void> setTheme(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _box.put(_key, value);
    emit(mode);
  }
}
