import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/models/alert_preferences.dart';

/// Unit tests for AlertPreferences model —
/// validates enable/disable, severity threshold, and shouldReceive logic.
///
/// NOTE: Free types (isFree: true) default to enabled.
///       Premium types (isFree: false) default to disabled.
void main() {
  late Box box;
  late AlertPreferences prefs;

  setUpAll(() async {
    Hive.init('/tmp/safora_test_hive_${DateTime.now().millisecondsSinceEpoch}');
  });

  setUp(() async {
    box = await Hive.openBox(
      'test_prefs_${DateTime.now().microsecondsSinceEpoch}',
    );
    prefs = AlertPreferences(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  group('AlertPreferences.isEnabled / setEnabled', () {
    test('free types enabled by default', () {
      // earthquake is a free type (isFree: true)
      expect(prefs.isEnabled(AlertType.earthquake), isTrue);
      expect(prefs.isEnabled(AlertType.flashFlood), isTrue);
      expect(prefs.isEnabled(AlertType.seatbeltReminder), isTrue);
    });

    test('premium types disabled by default', () {
      // allergicReaction is premium (isFree: false)
      expect(prefs.isEnabled(AlertType.allergicReaction), isFalse);
      expect(prefs.isEnabled(AlertType.heartAttack), isFalse);
    });

    test('disabling a free type persists', () async {
      await prefs.setEnabled(AlertType.earthquake, false);
      expect(prefs.isEnabled(AlertType.earthquake), isFalse);
    });

    test('enabling a premium type persists', () async {
      await prefs.setEnabled(AlertType.heartAttack, true);
      expect(prefs.isEnabled(AlertType.heartAttack), isTrue);
    });

    test('re-enabling a free type persists', () async {
      await prefs.setEnabled(AlertType.earthquake, false);
      await prefs.setEnabled(AlertType.earthquake, true);
      expect(prefs.isEnabled(AlertType.earthquake), isTrue);
    });

    test('disabling one type does not affect others', () async {
      await prefs.setEnabled(AlertType.earthquake, false);
      expect(prefs.isEnabled(AlertType.earthquake), isFalse);
      expect(prefs.isEnabled(AlertType.flashFlood), isTrue); // also free
    });
  });

  group('AlertPreferences.enableCategory / disableCategory', () {
    test('disableCategory turns off all types in that category', () async {
      await prefs.disableCategory(AlertCategory.naturalDisaster);

      final typesInCategory = AlertType.values
          .where((t) => t.category == AlertCategory.naturalDisaster);
      for (final type in typesInCategory) {
        expect(prefs.isEnabled(type), isFalse,
            reason: '${type.name} should be disabled');
      }
    });

    test('enableCategory turns on all types in that category', () async {
      await prefs.disableCategory(AlertCategory.naturalDisaster);
      await prefs.enableCategory(AlertCategory.naturalDisaster);

      final typesInCategory = AlertType.values
          .where((t) => t.category == AlertCategory.naturalDisaster);
      for (final type in typesInCategory) {
        expect(prefs.isEnabled(type), isTrue,
            reason: '${type.name} should be re-enabled');
      }
    });

    test('disableCategory does not affect other categories', () async {
      await prefs.disableCategory(AlertCategory.naturalDisaster);
      // Free weatherEmergency types should remain enabled
      expect(prefs.isEnabled(AlertType.flashFlood), isTrue);
      expect(prefs.isEnabled(AlertType.thunderstorm), isTrue);
    });
  });

  group('AlertPreferences.minimumSeverity', () {
    test('defaults to info (lowest)', () {
      expect(prefs.minimumSeverity, AlertPriority.info);
    });

    test('setMinimumSeverity persists to warning', () async {
      await prefs.setMinimumSeverity(AlertPriority.warning);
      expect(prefs.minimumSeverity, AlertPriority.warning);
    });

    test('setMinimumSeverity to critical', () async {
      await prefs.setMinimumSeverity(AlertPriority.critical);
      expect(prefs.minimumSeverity, AlertPriority.critical);
    });
  });

  group('AlertPreferences.isAllowedBySeverity', () {
    test('all severities pass at info threshold', () {
      for (final p in AlertPriority.values) {
        expect(prefs.isAllowedBySeverity(p), isTrue);
      }
    });

    test('info priority blocked at warning threshold', () async {
      await prefs.setMinimumSeverity(AlertPriority.warning);
      expect(prefs.isAllowedBySeverity(AlertPriority.info), isFalse);
      expect(prefs.isAllowedBySeverity(AlertPriority.advisory), isFalse);
    });

    test('critical priority passes at critical threshold', () async {
      await prefs.setMinimumSeverity(AlertPriority.critical);
      expect(prefs.isAllowedBySeverity(AlertPriority.critical), isTrue);
    });

    test('warning priority blocked at danger threshold', () async {
      await prefs.setMinimumSeverity(AlertPriority.danger);
      expect(prefs.isAllowedBySeverity(AlertPriority.warning), isFalse);
      expect(prefs.isAllowedBySeverity(AlertPriority.advisory), isFalse);
      expect(prefs.isAllowedBySeverity(AlertPriority.info), isFalse);
    });

    test('danger and critical pass at danger threshold', () async {
      await prefs.setMinimumSeverity(AlertPriority.danger);
      expect(prefs.isAllowedBySeverity(AlertPriority.danger), isTrue);
      expect(prefs.isAllowedBySeverity(AlertPriority.critical), isTrue);
    });
  });

  group('AlertPreferences.shouldReceive', () {
    test('free + enabled + passes severity = true', () {
      // earthquake is free (default enabled), threshold info (passes all)
      expect(prefs.shouldReceive(AlertType.earthquake), isTrue);
    });

    test('disabled free type = false regardless of severity', () async {
      await prefs.setEnabled(AlertType.earthquake, false);
      expect(prefs.shouldReceive(AlertType.earthquake), isFalse);
    });

    test('premium type disabled by default = false', () {
      // heartAttack is premium (default disabled)
      expect(prefs.shouldReceive(AlertType.heartAttack), isFalse);
    });

    test('enabled but below severity = false', () async {
      await prefs.setMinimumSeverity(AlertPriority.critical);
      // seatbeltReminder is advisory — below critical
      expect(prefs.shouldReceive(AlertType.seatbeltReminder), isFalse);
    });

    test('enabled and at severity = true', () async {
      await prefs.setMinimumSeverity(AlertPriority.critical);
      // earthquake is critical and free (default enabled)
      expect(prefs.shouldReceive(AlertType.earthquake), isTrue);
    });

    test('enabled premium + at severity = true', () async {
      await prefs.setEnabled(AlertType.heartAttack, true);
      await prefs.setMinimumSeverity(AlertPriority.critical);
      expect(prefs.shouldReceive(AlertType.heartAttack), isTrue);
    });
  });

  group('AlertPreferences computed sets', () {
    test('enabledAlerts includes only free types initially', () {
      final enabled = prefs.enabledAlerts;
      for (final type in enabled) {
        expect(type.isFree, isTrue,
            reason: '${type.name} should be free (enabled by default)');
      }
    });

    test('totalAlerts matches AlertType.values.length', () {
      expect(prefs.totalAlerts, AlertType.values.length);
    });
  });
}
