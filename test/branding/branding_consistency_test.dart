import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/theme/colors.dart';

/// Branding consistency tests.
///
/// Validates that modified screens use AppColors exclusively
/// and that the AppColors palette is complete.
void main() {
  group('AppColors — Palette Completeness', () {
    test('has all required brand colors', () {
      // Brand core
      expect(AppColors.primary, isNotNull);
      expect(AppColors.primaryDark, isNotNull);
      expect(AppColors.primaryLight, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.accent, isNotNull);
    });

    test('has all semantic status colors', () {
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.danger, isNotNull);
      expect(AppColors.info, isNotNull);
      expect(AppColors.error, isNotNull);
    });

    test('has text hierarchy colors', () {
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.textDisabled, isNotNull);
      expect(AppColors.textOnPrimary, isNotNull);
    });

    test('has surface and background colors', () {
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.darkBackground, isNotNull);
      expect(AppColors.darkSurface, isNotNull);
      expect(AppColors.darkSurfaceVariant, isNotNull);
    });

    test('has all alert priority levels', () {
      expect(AppColors.critical, isNotNull);
      expect(AppColors.high, isNotNull);
      expect(AppColors.medium, isNotNull);
      expect(AppColors.low, isNotNull);
    });

    test('has gradient presets', () {
      expect(AppColors.sosGradient, isNotNull);
      expect(AppColors.safeGradient, isNotNull);
      expect(AppColors.headerGradient, isNotNull);
      expect(AppColors.dangerGradient, isNotNull);
    });
  });

  group('Branding — No Raw Colors in Modified Files', () {
    /// Scans the given file for raw Flutter Colors.colorName usage.
    /// Ignores Colors.white, Colors.black, Colors.transparent
    /// (structural/contrast colors that are acceptable).
    List<String> findRawColors(String filePath) {
      final content = File(filePath).readAsStringSync();
      final lines = content.split('\n');
      final violations = <String>[];
      final rawColorPattern = RegExp(
        r'Colors\.(red|orange|amber|green|grey|blue|purple|teal|pink|cyan|indigo|brown|yellow|greenAccent|lime|deepPurple|deepOrange|lightBlue|lightGreen)',
      );
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Skip comments and imports
        if (line.trimLeft().startsWith('//') ||
            line.trimLeft().startsWith('import')) continue;
        if (rawColorPattern.hasMatch(line)) {
          violations.add('Line ${i + 1}: ${line.trim()}');
        }
      }
      return violations;
    }

    test('settings_screen.dart has no raw Colors.*', () {
      final violations = findRawColors(
        'lib/presentation/screens/settings/settings_screen.dart',
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('more_screen.dart has no raw Colors.*', () {
      final violations = findRawColors(
        'lib/presentation/screens/more/more_screen.dart',
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('sos_history_screen.dart has no raw Colors.*', () {
      final violations = findRawColors(
        'lib/presentation/screens/settings/sos_history_screen.dart',
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('alert_map_screen.dart has no raw Colors.*', () {
      final violations = findRawColors(
        'lib/presentation/screens/alerts/alert_map_screen.dart',
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('Version Sync — Dynamic Version', () {
    test('more_screen.dart uses PackageInfo, not hardcoded version', () {
      final content = File(
        'lib/presentation/screens/more/more_screen.dart',
      ).readAsStringSync();
      // Must import package_info_plus
      expect(content, contains('package:package_info_plus/package_info_plus.dart'));
      // Must use dynamic version
      expect(content, contains('PackageInfo.fromPlatform()'));
      expect(content, contains(r'v${info.version}'));
      // Must NOT have hardcoded version
      expect(content, isNot(contains("'v1.1.3'")));
      expect(content, isNot(contains("'v0.1.0'")));
    });
  });

  group('Settings Screen — Semantic IconColor', () {
    test('_SettingsTile widget accepts iconColor parameter', () {
      final content = File(
        'lib/presentation/screens/settings/settings_screen.dart',
      ).readAsStringSync();
      // Widget definition must have iconColor
      expect(content, contains('this.iconColor'));
      expect(content, contains('final Color? iconColor'));
      // Should use iconColor in build method
      expect(content, contains('final color = iconColor ?? AppColors.primary'));
    });

    test('all _SettingsTile calls specify iconColor', () {
      final content = File(
        'lib/presentation/screens/settings/settings_screen.dart',
      ).readAsStringSync();
      // Count _SettingsTile( occurrences (call sites, not class def)
      final tileCallPattern = RegExp(r'_SettingsTile\(');
      final matches = tileCallPattern.allMatches(content).toList();
      // Count iconColor: occurrences (should match call count minus class def)
      final iconColorPattern = RegExp(r'iconColor:');
      final iconColorMatches = iconColorPattern.allMatches(content).toList();
      // Widget class definition has 1 occurrence of _SettingsTile(
      // and 1 occurrence of this.iconColor, so subtract 1
      final callCount = matches.length - 1; // exclude class definition
      expect(
        iconColorMatches.length,
        callCount,
        reason: 'Every _SettingsTile call should specify iconColor. '
            'Found ${iconColorMatches.length} iconColor but $callCount tile calls.',
      );
    });
  });
}
