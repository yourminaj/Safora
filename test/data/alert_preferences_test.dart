import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  late Box box;
  late AlertPreferences prefs;

  setUp(() async {
    // Use a temp directory for Hive in tests.
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_alert_preferences');
    prefs = AlertPreferences(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  group('AlertPreferences', () {
    test('free alerts default to enabled', () {
      final freeType = AlertType.values.firstWhere((t) => t.isFree);
      expect(prefs.isEnabled(freeType), isTrue);
    });

    test('premium alerts default to disabled', () {
      final premType = AlertType.values.firstWhere((t) => !t.isFree);
      expect(prefs.isEnabled(premType), isFalse);
    });

    test('setEnabled persists the value', () async {
      final type = AlertType.values.first;
      await prefs.setEnabled(type, false);
      expect(prefs.isEnabled(type), isFalse);

      await prefs.setEnabled(type, true);
      expect(prefs.isEnabled(type), isTrue);
    });

    test('toggle flips the value', () async {
      final type = AlertType.values.first;
      final initial = prefs.isEnabled(type);
      final toggled = await prefs.toggle(type);
      expect(toggled, equals(!initial));
      expect(prefs.isEnabled(type), equals(!initial));
    });

    test('enabledAlerts returns only enabled types', () {
      final enabled = prefs.enabledAlerts;
      for (final type in enabled) {
        expect(prefs.isEnabled(type), isTrue);
      }
    });

    test('enableCategory enables all alerts in category', () async {
      const category = AlertCategory.naturalDisaster;
      await prefs.disableCategory(category);
      // Verify all disabled.
      for (final t in AlertType.values.where((t) => t.category == category)) {
        expect(prefs.isEnabled(t), isFalse);
      }
      await prefs.enableCategory(category);
      // Verify all enabled.
      for (final t in AlertType.values.where((t) => t.category == category)) {
        expect(prefs.isEnabled(t), isTrue);
      }
    });

    test('disableCategory disables all alerts in category', () async {
      const category = AlertCategory.healthMedical;
      await prefs.enableCategory(category);
      await prefs.disableCategory(category);
      for (final t in AlertType.values.where((t) => t.category == category)) {
        expect(prefs.isEnabled(t), isFalse);
      }
    });

    test('groupedByCategory returns all categories', () {
      final grouped = prefs.groupedByCategory();
      // Should have entries for every category that has alert types.
      final presentCategories =
          AlertType.values.map((t) => t.category).toSet();
      for (final cat in presentCategories) {
        expect(grouped.containsKey(cat), isTrue);
      }
    });

    test('totalEnabled matches enabledAlerts.length', () {
      expect(prefs.totalEnabled, equals(prefs.enabledAlerts.length));
    });

    test('totalAlerts matches AlertType.values.length', () {
      expect(prefs.totalAlerts, equals(AlertType.values.length));
    });
  });
}
