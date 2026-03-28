import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/models/alert_event.dart';

/// Unit tests for AlertEvent model —
/// validates fromMap, toMap, confidenceLabel, isExpired.
void main() {
  final now = DateTime.now();

  final sampleMap = {
    'title': 'Severe Thunderstorm Warning',
    'description': 'Heavy rain and high winds expected.',
    'type': 'allergicReaction',
    'latitude': 23.81,
    'longitude': 90.41,
    'timestamp': now.toIso8601String(),
    'source': 'NWS',
    'confidenceLevel': 0.92,
    'riskScore': 75,
    'actionAdvice': 'Seek shelter immediately.',
    'expiresAt': now.add(const Duration(hours: 2)).toIso8601String(),
  };

  group('AlertEvent.fromMap', () {
    test('parses all fields correctly', () {
      final event = AlertEvent.fromMap(sampleMap, id: 'test-001');

      expect(event.id, 'test-001');
      expect(event.title, 'Severe Thunderstorm Warning');
      expect(event.description, 'Heavy rain and high winds expected.');
      expect(event.type, AlertType.allergicReaction);
      expect(event.latitude, 23.81);
      expect(event.longitude, 90.41);
      expect(event.source, 'NWS');
      expect(event.confidenceLevel, 0.92);
      expect(event.riskScore, 75);
      expect(event.actionAdvice, 'Seek shelter immediately.');
    });

    test('handles missing optional fields gracefully', () {
      final minimal = {
        'title': 'Test Alert',
        'description': 'Desc',
        'type': 'heartAttack',
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': now.toIso8601String(),
      };

      final event = AlertEvent.fromMap(minimal);
      expect(event.id, isNull);
      expect(event.source, isNull);
      expect(event.confidenceLevel, isNull);
      expect(event.riskScore, isNull);
      expect(event.actionAdvice, isNull);
      expect(event.expiresAt, isNull);
    });

    test('unknown type falls back to manualSos', () {
      final unknownType = Map<String, dynamic>.from(sampleMap);
      unknownType['type'] = 'unknown_type_xyz';

      final event = AlertEvent.fromMap(unknownType);
      expect(event.type, AlertType.manualSos);
    });
  });

  group('AlertEvent.toMap', () {
    test('round-trips key fields correctly', () {
      final event = AlertEvent.fromMap(sampleMap, id: 'test-001');
      final map = event.toMap();

      expect(map['title'], 'Severe Thunderstorm Warning');
      expect(map['source'], 'NWS');
      expect(map['confidenceLevel'], 0.92);
      expect(map['riskScore'], 75);
      expect(map['type'], 'allergicReaction');
    });
  });

  group('AlertEvent.confidenceLabel', () {
    test('returns High confidence for 0.92', () {
      final event = AlertEvent.fromMap(sampleMap);
      expect(event.confidenceLabel, 'High confidence');
    });

    test('returns Medium confidence for 0.5', () {
      final map = Map<String, dynamic>.from(sampleMap);
      map['confidenceLevel'] = 0.55;
      final event = AlertEvent.fromMap(map);
      expect(event.confidenceLabel, 'Medium confidence');
    });

    test('returns Low confidence for 0.3', () {
      final map = Map<String, dynamic>.from(sampleMap);
      map['confidenceLevel'] = 0.35;
      final event = AlertEvent.fromMap(map);
      expect(event.confidenceLabel, 'Low confidence');
    });

    test('returns Unverified for null confidence', () {
      final noConf = Map<String, dynamic>.from(sampleMap);
      noConf.remove('confidenceLevel');
      final event = AlertEvent.fromMap(noConf);
      expect(event.confidenceLabel, 'Unverified');
    });
  });

  group('AlertEvent.isExpired', () {
    test('not expired when expiresAt is in the future', () {
      final event = AlertEvent.fromMap(sampleMap);
      expect(event.isExpired, isFalse);
    });

    test('expired when expiresAt is in the past', () {
      final expired = Map<String, dynamic>.from(sampleMap);
      expired['expiresAt'] =
          now.subtract(const Duration(hours: 1)).toIso8601String();
      final event = AlertEvent.fromMap(expired);
      expect(event.isExpired, isTrue);
    });

    test('not expired when expiresAt is null', () {
      final noExpiry = Map<String, dynamic>.from(sampleMap);
      noExpiry.remove('expiresAt');
      final event = AlertEvent.fromMap(noExpiry);
      expect(event.isExpired, isFalse);
    });
  });

  group('AlertEvent.copyWith', () {
    test('creates modified copy', () {
      final event = AlertEvent.fromMap(sampleMap, id: 'orig');
      final modified = event.copyWith(
        id: 'copy-001',
        riskScore: 99,
      );
      expect(modified.id, 'copy-001');
      expect(modified.riskScore, 99);
      expect(modified.title, event.title); // unchanged
    });
  });
}
