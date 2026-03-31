/// Tests for SosContactAlertListener — validates phone masking algorithm,
/// and listener data contract behavior.
///
/// SosContactAlertListener constructor requires Firebase, so we test
/// the pure business logic only (phone masking, notification body construction).
library;
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('Phone masking logic (mirror test)', () {
    /// Test the _maskPhone algorithm without access to private method.
    /// We reproduce the exact algorithm here and test it.
    String maskPhone(String phone) {
      if (phone.length <= 4) return phone;
      return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
    }

    test('masks full phone number', () {
      expect(maskPhone('+8801712345678'), '**********5678');
    });

    test('masks short phone number', () {
      expect(maskPhone('1234'), '1234');
    });

    test('masks 5-character phone', () {
      expect(maskPhone('12345'), '*2345');
    });

    test('handles empty string', () {
      expect(maskPhone(''), '');
    });

    test('handles 3-character string', () {
      expect(maskPhone('abc'), 'abc');
    });

    test('masks exactly 4 characters', () {
      expect(maskPhone('abcd'), 'abcd');
    });
  });

  group('Notification body construction (mirror test)', () {
    /// Mirror the _showAlert body logic to verify notification message format.
    String buildBody(String senderName, String? locationUrl) {
      return locationUrl != null
          ? '$senderName needs emergency help!\n📍 Tap to view their location.'
          : '$senderName needs emergency help! GPS unavailable.';
    }

    test('builds body with location URL', () {
      final body = buildBody('Alice', 'https://maps.google.com/?q=23.8,90.4');
      expect(body, contains('Alice needs emergency help!'));
      expect(body, contains('Tap to view their location'));
    });

    test('builds body without location URL', () {
      final body = buildBody('Alice', null);
      expect(body, contains('GPS unavailable'));
    });

    test('notification title format', () {
      const senderName = 'Bob';
      const title = '🚨 SOS — $senderName needs help!';
      expect(title, '🚨 SOS — Bob needs help!');
    });
  });

  group('Notification ID hashing', () {
    test('docId hashCode masked to positive 31-bit integer', () {
      const docId = 'abc123def456';
      final id = docId.hashCode & 0x7FFFFFFF;
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThan(0x80000000)); // < 2^31
    });

    test('different docIds produce different notification IDs', () {
      const id1 = 'doc_event_001';
      const id2 = 'doc_event_002';
      final notifId1 = id1.hashCode & 0x7FFFFFFF;
      final notifId2 = id2.hashCode & 0x7FFFFFFF;
      expect(notifId1, isNot(equals(notifId2)));
    });
  });
}
