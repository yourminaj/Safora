import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final dob = DateTime(1995, 6, 15);

    test('toMap serializes all fields', () {
      final profile = UserProfile(
        fullName: 'Jane Doe',
        bloodType: 'O+',
        allergies: ['Penicillin'],
        medicalConditions: ['Asthma'],
        medications: ['Inhaler'],
        emergencyNotes: 'Uses wheelchair',
        dateOfBirth: dob,
        weight: 65.5,
        height: 170.0,
        organDonor: true,
      );
      final map = profile.toMap();
      expect(map['fullName'], 'Jane Doe');
      expect(map['bloodType'], 'O+');
      expect(map['allergies'], ['Penicillin']);
      expect(map['medicalConditions'], ['Asthma']);
      expect(map['medications'], ['Inhaler']);
      expect(map['emergencyNotes'], 'Uses wheelchair');
      expect(map['dateOfBirth'], dob.toIso8601String());
      expect(map['weight'], 65.5);
      expect(map['height'], 170.0);
      expect(map['organDonor'], true);
    });

    test('fromMap deserializes all fields', () {
      final map = {
        'fullName': 'John Doe',
        'bloodType': 'A-',
        'allergies': ['Peanuts', 'Shellfish'],
        'medicalConditions': ['Diabetes'],
        'medications': ['Insulin'],
        'emergencyNotes': 'Diabetic alert bracelet',
        'dateOfBirth': dob.toIso8601String(),
        'weight': 80.0,
        'height': 175.0,
        'organDonor': false,
      };
      final profile = UserProfile.fromMap(map, id: 'abc123');
      expect(profile.id, 'abc123');
      expect(profile.fullName, 'John Doe');
      expect(profile.bloodType, 'A-');
      expect(profile.allergies, ['Peanuts', 'Shellfish']);
      expect(profile.dateOfBirth, dob);
      expect(profile.weight, 80.0);
      expect(profile.organDonor, false);
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = <String, dynamic>{};
      final profile = UserProfile.fromMap(map);
      expect(profile.fullName, '');
      expect(profile.bloodType, isNull);
      expect(profile.allergies, isEmpty);
      expect(profile.medicalConditions, isEmpty);
      expect(profile.medications, isEmpty);
      expect(profile.dateOfBirth, isNull);
      expect(profile.weight, isNull);
      expect(profile.height, isNull);
      expect(profile.organDonor, false);
    });

    test('copyWith preserves unchanged fields', () {
      const original = UserProfile(
        fullName: 'Jane',
        bloodType: 'B+',
        weight: 60.0,
      );
      final updated = original.copyWith(fullName: 'Jane Doe');
      expect(updated.fullName, 'Jane Doe');
      expect(updated.bloodType, 'B+');
      expect(updated.weight, 60.0);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = UserProfile(
        fullName: 'Test User',
        allergies: ['Dust'],
        dateOfBirth: dob,
        organDonor: true,
      );
      final restored = UserProfile.fromMap(original.toMap());
      expect(restored.fullName, original.fullName);
      expect(restored.allergies, original.allergies);
      expect(restored.organDonor, original.organDonor);
    });

    test('Equatable equality works', () {
      const a = UserProfile(fullName: 'X', id: '1');
      const b = UserProfile(fullName: 'X', id: '1');
      expect(a, b);
    });

    test('Equatable detects inequality', () {
      const a = UserProfile(fullName: 'X');
      const b = UserProfile(fullName: 'Y');
      expect(a, isNot(b));
    });
  });
}
