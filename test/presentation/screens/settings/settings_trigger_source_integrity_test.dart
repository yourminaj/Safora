import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsScreen SOS Trigger Source Integrity', () {
    late String settingsContent;

    setUpAll(() {
      settingsContent = File(
        'lib/presentation/screens/settings/settings_screen.dart',
      ).readAsStringSync();
    });

    test('shake detection starts SOS with shake trigger source', () {
      expect(settingsContent, contains('triggerSource: SosTriggerSource.shake'));
    });

    test('crash detection starts SOS with crash trigger source', () {
      expect(
        settingsContent,
        contains('triggerSource: SosTriggerSource.crashDetection'),
      );
    });

    test('voice distress starts SOS with voice trigger source', () {
      expect(
        settingsContent,
        contains('triggerSource: SosTriggerSource.voiceDistress'),
      );
    });

    test('anomaly movement starts SOS with anomaly trigger source', () {
      expect(
        settingsContent,
        contains('triggerSource: SosTriggerSource.anomalyMovement'),
      );
    });

    test('geofence exit starts SOS with geofence trigger source', () {
      expect(
        settingsContent,
        contains('triggerSource: SosTriggerSource.geofenceExit'),
      );
    });

    test('snatch detection starts SOS with snatch trigger source', () {
      expect(settingsContent, contains('triggerSource: SosTriggerSource.snatch'));
    });
  });
}
