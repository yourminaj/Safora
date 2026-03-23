import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/datasources/profile_local_datasource.dart';
import 'package:safora/data/models/user_profile.dart';
import 'package:safora/data/repositories/profile_repository.dart';

class MockProfileLocalDataSource extends Mock
    implements ProfileLocalDataSource {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockProfileLocalDataSource mockDataSource;

  const sampleProfile = UserProfile(
    fullName: 'Minhaj Sadik',
    bloodType: 'O+',
    allergies: ['Peanuts', 'Dust'],
    medicalConditions: ['Asthma'],
    medications: ['Salbutamol'],
    emergencyNotes: 'Carries inhaler',
    weight: 75.0,
    height: 175.0,
    organDonor: true,
  );

  setUp(() {
    mockDataSource = MockProfileLocalDataSource();
    repository = ProfileRepositoryImpl(mockDataSource);
  });

  group('ProfileRepository', () {
    test('load returns null when no profile exists', () {
      when(() => mockDataSource.load()).thenReturn(null);

      final result = repository.load();

      expect(result, isNull);
      verify(() => mockDataSource.load()).called(1);
    });

    test('load returns profile when one exists', () {
      when(() => mockDataSource.load()).thenReturn(sampleProfile);

      final result = repository.load();

      expect(result, isNotNull);
      expect(result!.fullName, 'Minhaj Sadik');
      expect(result.bloodType, 'O+');
      expect(result.allergies, ['Peanuts', 'Dust']);
      expect(result.organDonor, true);
    });

    test('save delegates to data source', () async {
      when(() => mockDataSource.save(sampleProfile)).thenAnswer((_) async {});

      await repository.save(sampleProfile);

      verify(() => mockDataSource.save(sampleProfile)).called(1);
    });

    test('clear delegates to data source', () async {
      when(() => mockDataSource.clear()).thenAnswer((_) async {});

      await repository.clear();

      verify(() => mockDataSource.clear()).called(1);
    });

    test('hasProfile reflects data source state', () {
      when(() => mockDataSource.hasProfile).thenReturn(false);
      expect(repository.hasProfile, false);

      when(() => mockDataSource.hasProfile).thenReturn(true);
      expect(repository.hasProfile, true);
    });
  });

  group('UserProfile', () {
    test('toMap and fromMap are reversible', () {
      final map = sampleProfile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.fullName, sampleProfile.fullName);
      expect(restored.bloodType, sampleProfile.bloodType);
      expect(restored.allergies, sampleProfile.allergies);
      expect(restored.medicalConditions, sampleProfile.medicalConditions);
      expect(restored.medications, sampleProfile.medications);
      expect(restored.emergencyNotes, sampleProfile.emergencyNotes);
      expect(restored.weight, sampleProfile.weight);
      expect(restored.height, sampleProfile.height);
      expect(restored.organDonor, sampleProfile.organDonor);
    });

    test('fromMap handles missing optional fields', () {
      final minimalMap = {'fullName': 'Test User'};
      final profile = UserProfile.fromMap(minimalMap);

      expect(profile.fullName, 'Test User');
      expect(profile.bloodType, isNull);
      expect(profile.allergies, isEmpty);
      expect(profile.medicalConditions, isEmpty);
      expect(profile.medications, isEmpty);
      expect(profile.organDonor, false);
    });

    test('copyWith creates a modified copy', () {
      final modified = sampleProfile.copyWith(
        fullName: 'New Name',
        organDonor: false,
      );

      expect(modified.fullName, 'New Name');
      expect(modified.bloodType, 'O+'); // unchanged
      expect(modified.organDonor, false);
    });

    test('equatable compares by value', () {
      final copy = UserProfile(
        fullName: sampleProfile.fullName,
        bloodType: sampleProfile.bloodType,
        allergies: sampleProfile.allergies,
        medicalConditions: sampleProfile.medicalConditions,
        medications: sampleProfile.medications,
        organDonor: sampleProfile.organDonor,
      );

      // Props include: id, fullName, bloodType, allergies,
      // medicalConditions, medications, organDonor.
      expect(copy, equals(sampleProfile));
    });
  });
}
