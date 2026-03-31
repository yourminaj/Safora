import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:safora/presentation/blocs/theme/theme_cubit.dart';

/// In-memory Hive box for testing.
class _FakeBox extends Fake implements Box<dynamic> {
  final Map<dynamic, dynamic> _store = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _store[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async => _store[key] = value;
}

void main() {
  group('ThemeCubit', () {
    late _FakeBox box;

    setUp(() {
      box = _FakeBox();
    });

    test('defaults to ThemeMode.system when no saved value', () {
      final cubit = ThemeCubit(settingsBox: box);
      expect(cubit.state, ThemeMode.system);
      cubit.close();
    });

    test('loads persisted light theme', () {
      box._store['theme_mode'] = 'light';
      final cubit = ThemeCubit(settingsBox: box);
      expect(cubit.state, ThemeMode.light);
      cubit.close();
    });

    test('loads persisted dark theme', () {
      box._store['theme_mode'] = 'dark';
      final cubit = ThemeCubit(settingsBox: box);
      expect(cubit.state, ThemeMode.dark);
      cubit.close();
    });

    test('setTheme(light) emits ThemeMode.light and persists', () async {
      final cubit = ThemeCubit(settingsBox: box);
      await cubit.setTheme(ThemeMode.light);
      expect(cubit.state, ThemeMode.light);
      expect(box._store['theme_mode'], 'light');
      cubit.close();
    });

    test('setTheme(dark) emits ThemeMode.dark and persists', () async {
      final cubit = ThemeCubit(settingsBox: box);
      await cubit.setTheme(ThemeMode.dark);
      expect(cubit.state, ThemeMode.dark);
      expect(box._store['theme_mode'], 'dark');
      cubit.close();
    });

    test('setTheme(system) emits ThemeMode.system and persists', () async {
      box._store['theme_mode'] = 'dark';
      final cubit = ThemeCubit(settingsBox: box);
      await cubit.setTheme(ThemeMode.system);
      expect(cubit.state, ThemeMode.system);
      expect(box._store['theme_mode'], 'system');
      cubit.close();
    });

    test('handles unknown stored value gracefully', () {
      box._store['theme_mode'] = 'invalid_value';
      final cubit = ThemeCubit(settingsBox: box);
      expect(cubit.state, ThemeMode.system);
      cubit.close();
    });

    test('multiple setTheme calls keep state consistent', () async {
      final cubit = ThemeCubit(settingsBox: box);
      await cubit.setTheme(ThemeMode.dark);
      await cubit.setTheme(ThemeMode.light);
      await cubit.setTheme(ThemeMode.dark);
      expect(cubit.state, ThemeMode.dark);
      expect(box._store['theme_mode'], 'dark');
      cubit.close();
    });
  });
}
