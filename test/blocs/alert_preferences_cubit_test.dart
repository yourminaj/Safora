import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/alert_permission_gate.dart';
import 'package:safora/core/services/premium_manager.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/presentation/blocs/alert_preferences/alert_preferences_cubit.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeGate extends Fake implements AlertPermissionGate {
  bool grantAll = true;

  @override
  Future<PermissionResult> requestForAlert(AlertType type) async {
    return grantAll
        ? const PermissionResult(granted: true, denied: {})
        : const PermissionResult(granted: false, denied: {});
  }
}

class _FakePremiumManager extends Fake implements PremiumManager {
  bool _isPremium = false;

  @override
  bool get isPremium => _isPremium;

  set isPremium(bool value) => _isPremium = value;
}

// ── Test helpers ──────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late Box box;
  late AlertPreferences prefs;
  late _FakeGate gate;
  late _FakePremiumManager fakePremium;
  late AlertPreferencesCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cubit_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('test_cubit_prefs');
    prefs = AlertPreferences(box);
    gate = _FakeGate();
    fakePremium = _FakePremiumManager();
    cubit = AlertPreferencesCubit(
      alertPreferences: prefs,
      permissionGate: gate,
      premiumManager: fakePremium,
    );
  });

  tearDown(() async {
    await cubit.close();
    await box.deleteFromDisk();
    await Hive.close();
  });

  // ── Initial state ─────────────────────────────────────────────────────────
  group('Initial state', () {
    test('free alerts are enabled by default', () {
      for (final type in AlertType.values.where((t) => t.isFree)) {
        expect(
          cubit.state.preferences[type],
          isTrue,
          reason: '${type.name} should default to enabled',
        );
      }
    });

    test('premium alerts are disabled by default', () {
      for (final type in AlertType.values.where((t) => !t.isFree)) {
        expect(
          cubit.state.preferences[type],
          isFalse,
          reason: '${type.name} should default to disabled',
        );
      }
    });

    test('isLoading is false initially', () {
      expect(cubit.state.isLoading, isFalse);
    });

    test('permissionDeniedMessage is null initially', () {
      expect(cubit.state.permissionDeniedMessage, isNull);
    });

    test('groupedByCategory contains all categories that have alert types', () {
      final grouped = cubit.state.groupedByCategory;
      final presentCategories = AlertType.values.map((t) => t.category).toSet();
      for (final cat in presentCategories) {
        expect(
          grouped.containsKey(cat),
          isTrue,
          reason: '${cat.name} not found in groupedByCategory',
        );
      }
    });

    test('totalCount equals AlertType.values.length', () {
      expect(cubit.state.totalCount, equals(AlertType.values.length));
    });

    test('enabledCount matches preferences map', () {
      final manual = cubit.state.preferences.values.where((v) => v).length;
      expect(cubit.state.enabledCount, equals(manual));
    });
  });

  // ── toggleAlert ───────────────────────────────────────────────────────────
  group('toggleAlert', () {
    test('disabling an enabled (free) alert requires no permission', () async {
      final freeType = AlertType.values.firstWhere((t) => t.isFree);

      await cubit.toggleAlert(freeType);

      expect(cubit.state.preferences[freeType], isFalse);
    });

    test(
      'enabling alert with permission granted → alert becomes enabled',
      () async {
        gate.grantAll = true;
        fakePremium.isPremium = true;
        final premType = AlertType.values.firstWhere((t) => !t.isFree);

        await cubit.toggleAlert(premType);

        expect(cubit.state.preferences[premType], isTrue);
        expect(cubit.state.permissionDeniedMessage, isNull);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test(
      'enabling alert with permission denied → alert stays disabled',
      () async {
        gate.grantAll = false;
        fakePremium.isPremium = true;
        final premType = AlertType.values.firstWhere((t) => !t.isFree);

        await cubit.toggleAlert(premType);

        expect(
          cubit.state.preferences[premType],
          isFalse,
          reason: 'Alert must stay disabled when permission is denied',
        );
        expect(
          cubit.state.permissionDeniedMessage,
          isNotNull,
          reason: 'Must surface a user-facing permission denial message',
        );
      },
    );

    // REGRESSION: The original code emitted isLoading:true before calling
    // requestForAlert. Combined with the OS permission dialog, this caused
    // the screen to appear dim/frozen — reported as a "crash" in production.
    test(
      'toggleAlert NEVER emits isLoading:true (dim-screen regression)',
      () async {
        gate.grantAll = true;
        fakePremium.isPremium = true;
        final premType = AlertType.values.firstWhere((t) => !t.isFree);

        var sawLoadingTrue = false;
        final sub = cubit.stream.listen((s) {
          if (s.isLoading) sawLoadingTrue = true;
        });

        await cubit.toggleAlert(premType);
        await sub.cancel();

        expect(
          sawLoadingTrue,
          isFalse,
          reason:
              'toggleAlert must never emit isLoading:true — '
              'doing so behind an OS dialog causes the dim/crash visual bug',
        );
      },
    );
  });

  // ── enableCategory ────────────────────────────────────────────────────────
  group('enableCategory', () {
    test('permission granted → all alerts in category enabled', () async {
      gate.grantAll = true;
      fakePremium.isPremium = true;
      const cat = AlertCategory.healthMedical;

      await cubit.enableCategory(cat);

      for (final t in AlertType.values.where((t) => t.category == cat)) {
        expect(
          cubit.state.preferences[t],
          isTrue,
          reason: '${t.name} should be enabled after enableCategory',
        );
      }
      expect(cubit.state.isLoading, isFalse);
    });

    test('permission denied → no alerts enabled, message set', () async {
      gate.grantAll = false;
      fakePremium.isPremium = true;
      const cat = AlertCategory.healthMedical;

      await cubit.enableCategory(cat);

      for (final t in AlertType.values.where((t) => t.category == cat)) {
        expect(
          cubit.state.preferences[t],
          isFalse,
          reason:
              '${t.name} must stay disabled when category permission denied',
        );
      }
      expect(cubit.state.permissionDeniedMessage, isNotNull);
      expect(
        cubit.state.isLoading,
        isFalse,
        reason: 'isLoading must not remain true after permission denied',
      );
    });

    // REGRESSION: Same dim-screen bug for enableCategory.
    test('enableCategory NEVER emits isLoading:true '
        '(Health & Medical dim-screen regression)', () async {
      gate.grantAll = true;
      fakePremium.isPremium = true;

      var sawLoadingTrue = false;
      final sub = cubit.stream.listen((s) {
        if (s.isLoading) sawLoadingTrue = true;
      });

      await cubit.enableCategory(AlertCategory.healthMedical);
      await sub.cancel();

      expect(
        sawLoadingTrue,
        isFalse,
        reason:
            'enableCategory must never emit isLoading:true — '
            'this was the root cause of the Health & Medical frozen-UI bug',
      );
    });

    test('successive enable then disable leaves category disabled', () async {
      gate.grantAll = true;
      fakePremium.isPremium = true;
      const cat = AlertCategory.naturalDisaster;

      await cubit.enableCategory(cat);
      await cubit.disableCategory(cat);

      for (final t in AlertType.values.where((t) => t.category == cat)) {
        expect(cubit.state.preferences[t], isFalse);
      }
    });
  });

  // ── disableCategory ───────────────────────────────────────────────────────
  group('disableCategory', () {
    test(
      'disables all alerts in category without permission request',
      () async {
        gate.grantAll = true;
        fakePremium.isPremium = true;
        const cat = AlertCategory.naturalDisaster;
        // First enable everything.
        await cubit.enableCategory(cat);

        // Now disable.
        await cubit.disableCategory(cat);

        for (final t in AlertType.values.where((t) => t.category == cat)) {
          expect(cubit.state.preferences[t], isFalse);
        }
      },
    );
  });

  // ── setSeverity ───────────────────────────────────────────────────────────
  group('setSeverity', () {
    test('updates severityThreshold in state', () async {
      expect(cubit.state.severityThreshold, AlertPriority.info);

      await cubit.setSeverity(AlertPriority.warning);

      expect(cubit.state.severityThreshold, AlertPriority.warning);
    });

    test('can cycle through all priority levels', () async {
      for (final priority in AlertPriority.values) {
        await cubit.setSeverity(priority);
        expect(cubit.state.severityThreshold, priority);
      }
    });
  });

  // ── isEnabled helper ──────────────────────────────────────────────────────
  group('isEnabled helper', () {
    test('reflects persisted state', () async {
      gate.grantAll = true;
      fakePremium.isPremium = true;
      final premType = AlertType.values.firstWhere((t) => !t.isFree);

      expect(cubit.isEnabled(premType), isFalse);
      await cubit.toggleAlert(premType);
      expect(cubit.isEnabled(premType), isTrue);
    });
  });
}
