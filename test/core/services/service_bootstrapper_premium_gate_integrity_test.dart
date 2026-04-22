import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceBootstrapper Premium Gate Integrity', () {
    late String bootstrapperContent;

    setUpAll(() {
      bootstrapperContent = File(
        'lib/core/services/service_bootstrapper.dart',
      ).readAsStringSync();
    });

    test('crash/fall startup checks Pro feature availability', () {
      expect(
        bootstrapperContent,
        contains('ProFeature.crashFallDetection'),
      );
    });

    test('geofence startup checks Pro feature availability', () {
      expect(
        bootstrapperContent,
        contains('ProFeature.unlimitedGeofenceZones'),
      );
    });

    test('snatch and speed startup checks Pro feature availability', () {
      expect(bootstrapperContent, contains('ProFeature.snatchDetection'));
      expect(bootstrapperContent, contains('ProFeature.speedAlert'));
    });

    test('context and dead-man-switch startup checks Pro availability', () {
      expect(bootstrapperContent, contains('ProFeature.contextAlerts'));
      expect(bootstrapperContent, contains('ProFeature.deadManSwitch'));
    });

    test('voice, anomaly, and road startup checks Pro availability', () {
      expect(
        bootstrapperContent,
        contains('ProFeature.voiceDistressDetection'),
      );
      expect(
        bootstrapperContent,
        contains('ProFeature.anomalyMovementDetection'),
      );
      expect(
        bootstrapperContent,
        contains('ProFeature.roadConditionDetection'),
      );
    });

    test('stale premium flags are actively disabled in settings', () {
      expect(
        bootstrapperContent,
        contains('Disabled stale voice_distress_enabled for Free tier'),
      );
      expect(
        bootstrapperContent,
        contains('Disabled stale road_condition_enabled for Free tier'),
      );
    });
  });
}
