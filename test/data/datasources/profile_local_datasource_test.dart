import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/datasources/profile_local_datasource.dart';
import 'package:safora/data/models/user_profile.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late ProfileLocalDataSource datasource;

  setUp(() {
    mockBox = MockBox();
    datasource = ProfileLocalDataSource(mockBox);
  });

  group('ProfileLocalDataSource', () {
    group('Load', () {
      test('returns null when no profile stored', () {
        when(() => mockBox.get('profile')).thenReturn(null);
        expect(datasource.load(), isNull);
      });

      test('returns UserProfile from stored JSON', () {
        const profile = UserProfile(
          fullName: 'Jane Doe',
          bloodType: 'O+',
          allergies: ['Peanuts'],
        );
        when(() => mockBox.get('profile'))
            .thenReturn(jsonEncode(profile.toMap()));

        final result = datasource.load();
        expect(result, isNotNull);
        expect(result!.fullName, 'Jane Doe');
        expect(result.bloodType, 'O+');
        expect(result.allergies, ['Peanuts']);
      });

      test('returns null on corrupt JSON', () {
        when(() => mockBox.get('profile')).thenReturn('{bad json{{{');
        expect(datasource.load(), isNull);
      });

      test('handles empty string', () {
        when(() => mockBox.get('profile')).thenReturn('');
        expect(datasource.load(), isNull);
      });

      test('handles profile with multiple allergies', () {
        const profile = UserProfile(
          fullName: 'Multi Allergy',
          allergies: ['Peanuts', 'Gluten', 'Dairy', 'Shellfish'],
        );
        when(() => mockBox.get('profile'))
            .thenReturn(jsonEncode(profile.toMap()));

        final result = datasource.load();
        expect(result, isNotNull);
        expect(result!.allergies, hasLength(4));
        expect(result.allergies, contains('Peanuts'));
        expect(result.allergies, contains('Shellfish'));
      });

      test('handles profile with empty allergies list', () {
        const profile = UserProfile(
          fullName: 'No Allergies',
          allergies: [],
        );
        when(() => mockBox.get('profile'))
            .thenReturn(jsonEncode(profile.toMap()));

        final result = datasource.load();
        expect(result, isNotNull);
        expect(result!.allergies, isEmpty);
      });

      test('handles profile with minimal fields', () {
        const profile = UserProfile(fullName: 'Minimal');
        when(() => mockBox.get('profile'))
            .thenReturn(jsonEncode(profile.toMap()));

        final result = datasource.load();
        expect(result, isNotNull);
        expect(result!.fullName, 'Minimal');
      });
    });

    group('Save', () {
      test('stores profile as JSON string', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
        const profile = UserProfile(fullName: 'Bob');

        await datasource.save(profile);
        verify(() => mockBox.put('profile', any())).called(1);
      });

      test('save then load roundtrip preserves data', () async {
        String? stored;
        when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
          stored = inv.positionalArguments[1] as String;
        });

        const profile = UserProfile(
          fullName: 'Roundtrip Test',
          bloodType: 'AB+',
          allergies: ['Penicillin'],
        );
        await datasource.save(profile);

        // Now mock load to return what was saved
        when(() => mockBox.get('profile')).thenReturn(stored);
        final loaded = datasource.load();
        expect(loaded, isNotNull);
        expect(loaded!.fullName, 'Roundtrip Test');
        expect(loaded.bloodType, 'AB+');
        expect(loaded.allergies, ['Penicillin']);
      });

      test('save overwrites previous profile', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await datasource.save(const UserProfile(fullName: 'First'));
        await datasource.save(const UserProfile(fullName: 'Second'));

        // put should have been called twice
        verify(() => mockBox.put('profile', any())).called(2);
      });
    });

    group('Clear', () {
      test('deletes the profile key', () async {
        when(() => mockBox.delete(any())).thenAnswer((_) async {});
        await datasource.clear();
        verify(() => mockBox.delete('profile')).called(1);
      });
    });

    group('HasProfile', () {
      test('returns true when key exists', () {
        when(() => mockBox.containsKey('profile')).thenReturn(true);
        expect(datasource.hasProfile, true);
      });

      test('returns false when key missing', () {
        when(() => mockBox.containsKey('profile')).thenReturn(false);
        expect(datasource.hasProfile, false);
      });
    });
  });
}
