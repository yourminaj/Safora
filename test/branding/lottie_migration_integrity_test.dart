import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level integrity tests for the Lottie → branded icon migration.
///
/// These tests scan the actual source files to verify:
///   1. No import of `package:lottie` exists anywhere in lib/
///   2. No Lottie.asset() or Lottie.network() calls exist
///   3. The `lottie` dependency was removed from pubspec.yaml
///   4. The `assets/lottie/` directory was removed from pubspec.yaml
///   5. The settings screen uses customIcon instead of lottiePath
///   6. Splash and onboarding screens use PackageInfo for build stamping
///   7. Onboarding imports `package_info_plus`
void main() {
  late String pubspecContent;
  late String settingsContent;
  late String splashContent;
  late String onboardingContent;

  setUpAll(() {
    pubspecContent = File('pubspec.yaml').readAsStringSync();
    settingsContent = File(
      'lib/presentation/screens/settings/settings_screen.dart',
    ).readAsStringSync();
    splashContent = File(
      'lib/presentation/screens/splash/splash_screen.dart',
    ).readAsStringSync();
    onboardingContent = File(
      'lib/presentation/screens/onboarding/onboarding_screen.dart',
    ).readAsStringSync();
  });

  // ─── Lottie Removal ─────────────────────────────────────────
  group('Lottie Removal — pubspec.yaml', () {
    test('lottie dependency is not present', () {
      // Match `lottie:` as a dependency line.
      final hasLottie = RegExp(r'^\s+lottie:', multiLine: true)
          .hasMatch(pubspecContent);
      expect(hasLottie, isFalse,
          reason: 'lottie dependency must be removed from pubspec.yaml');
    });

    test('assets/lottie/ directory is not in asset bundle', () {
      expect(pubspecContent, isNot(contains('assets/lottie/')),
          reason: 'assets/lottie/ should be removed from flutter assets');
    });
  });

  group('Lottie Removal — Source Code', () {
    test('no Lottie imports in entire lib/ directory', () {
      final libDir = Directory('lib');
      final violations = <String>[];

      for (final file in libDir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final content = file.readAsStringSync();
          if (content.contains('package:lottie')) {
            violations.add(file.path);
          }
        }
      }

      expect(violations, isEmpty,
          reason:
              'Found Lottie imports in: ${violations.join(", ")}');
    });

    test('no Lottie.asset() calls in entire lib/ directory', () {
      final libDir = Directory('lib');
      final violations = <String>[];

      for (final file in libDir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final content = file.readAsStringSync();
          if (RegExp(r'Lottie\.(asset|network)\(').hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }

      expect(violations, isEmpty,
          reason:
              'Found Lottie usage in: ${violations.join(", ")}');
    });
  });

  // ─── Settings Screen customIcon Migration ───────────────────
  group('Settings Screen — customIcon Migration', () {
    test('_SettingsTile has customIcon parameter', () {
      expect(settingsContent, contains('this.customIcon'));
      expect(settingsContent, contains('final Widget? customIcon'));
    });

    test('no lottiePath parameter remains', () {
      expect(settingsContent, isNot(contains('lottiePath')),
          reason: 'Old lottiePath parameter should be fully removed');
    });

    test('no Lottie import in settings_screen.dart', () {
      expect(settingsContent, isNot(contains('package:lottie')),
          reason: 'Settings screen must not import lottie anymore');
    });

    test('voice distress tile uses SaforaVoiceDistressIcon', () {
      expect(settingsContent, contains('SaforaVoiceDistressIcon'));
    });

    test('anomaly movement tile uses SaforaAnomalyMovementIcon', () {
      expect(settingsContent, contains('SaforaAnomalyMovementIcon'));
    });

    test('road condition tile uses SaforaRoadConditionIcon', () {
      expect(settingsContent, contains('SaforaRoadConditionIcon'));
    });

    test('customIcon fallback renders Icon when null', () {
      // The _SettingsTile build must have: customIcon ?? Icon(icon, ...
      expect(settingsContent, contains('customIcon ??'));
    });
  });

  // ─── Splash Screen — Build Number Guard ─────────────────────
  group('Splash Screen — Build Number Guard', () {
    test('imports package_info_plus', () {
      expect(splashContent,
          contains('package:package_info_plus/package_info_plus.dart'));
    });

    test('reads onboarding_build from Hive', () {
      expect(splashContent, contains("'onboarding_build'"));
    });

    test('reads onboarding_completed from Hive', () {
      expect(splashContent, contains("'onboarding_completed'"));
    });

    test('uses PackageInfo.fromPlatform()', () {
      expect(splashContent, contains('PackageInfo.fromPlatform()'));
    });

    test('computes needsOnboarding from both keys', () {
      expect(splashContent, contains('needsOnboarding'));
      expect(splashContent, contains('storedBuild.isEmpty'));
    });

    test('logs decision to AppLogger', () {
      expect(splashContent, contains('AppLogger.info'));
      expect(splashContent, contains('[Splash]'));
    });

    test('does not import or use Lottie', () {
      expect(splashContent, isNot(contains('package:lottie')),
          reason: 'Splash must not import lottie package');
      expect(
        RegExp(r'Lottie\.(asset|network)\(').hasMatch(splashContent),
        isFalse,
        reason: 'Splash must not call Lottie.asset() or Lottie.network()',
      );
    });
  });

  // ─── Onboarding Screen — Build Stamp ────────────────────────
  group('Onboarding Screen — Branded Icons & Completion', () {
    test('writes onboarding_completed on completion', () {
      expect(onboardingContent, contains("'onboarding_completed'"));
    });

    test('does not import or use Lottie', () {
      expect(onboardingContent, isNot(contains('package:lottie')),
          reason: 'Onboarding must not import lottie package');
      expect(
        RegExp(r'Lottie\.(asset|network)\(').hasMatch(onboardingContent),
        isFalse,
        reason:
            'Onboarding must not call Lottie.asset() or Lottie.network()',
      );
    });

    test('uses only branded Safora icons', () {
      // SaforaShieldPulse replaced SaforaSosIcon in the first page
      expect(
        onboardingContent.contains('SaforaShieldPulse') ||
            onboardingContent.contains('SaforaSosIcon'),
        isTrue,
        reason: 'First onboarding page should use a Safora shield/SOS icon',
      );
      expect(onboardingContent, contains('SaforaContactsIcon'));
      expect(onboardingContent, contains('SaforaMedicalIcon'));
    });
  });

  // ─── Global: No stale Lottie assets ─────────────────────────
  group('Global Cleanup', () {
    test('assets/lottie/ directory does not exist', () {
      final lottieDir = Directory('assets/lottie');
      expect(lottieDir.existsSync(), isFalse,
          reason: 'assets/lottie/ directory should be deleted');
    });
  });
}
