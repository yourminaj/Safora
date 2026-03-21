import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora_sos/data/models/user_profile.dart';
import 'package:safora_sos/data/repositories/profile_repository.dart';
import 'package:safora_sos/presentation/blocs/profile/profile_cubit.dart';
import 'package:safora_sos/presentation/blocs/profile/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileCubit cubit;
  late MockProfileRepository mockRepo;

  final testProfile = UserProfile(
    fullName: 'Minhaj Sadik',
    bloodType: 'O+',
    allergies: const ['Peanuts'],
    medicalConditions: const ['Asthma'],
    medications: const ['Salbutamol'],
    emergencyNotes: 'Carries inhaler',
    weight: 75.0,
    height: 175.0,
    organDonor: true,
  );

  setUp(() {
    mockRepo = MockProfileRepository();
    cubit = ProfileCubit(profileRepository: mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(UserProfile(fullName: 'fallback'));
  });

  tearDown(() => cubit.close());

  group('ProfileCubit', () {
    test('initial state is ProfileInitial', () {
      expect(cubit.state, const ProfileInitial());
    });

    test('loadProfile emits ProfileLoaded with profile', () async {
      when(() => mockRepo.load()).thenReturn(testProfile);

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadProfile();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ProfileLoaded>());
      final loaded = states.last as ProfileLoaded;
      expect(loaded.profile?.fullName, 'Minhaj Sadik');
      expect(loaded.profile?.bloodType, 'O+');
      expect(loaded.profile?.organDonor, true);

      await sub.cancel();
    });

    test('loadProfile emits ProfileLoaded(null) when no profile', () async {
      when(() => mockRepo.load()).thenReturn(null);

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadProfile();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ProfileLoaded>());
      final loaded = states.last as ProfileLoaded;
      expect(loaded.profile, isNull);

      await sub.cancel();
    });

    test('saveProfile saves to repo and emits Saved then Loaded', () async {
      when(() => mockRepo.save(any())).thenAnswer((_) async {});

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.saveProfile(testProfile);
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.save(testProfile)).called(1);
      // Should emit ProfileSaved then ProfileLoaded.
      expect(states.any((s) => s is ProfileSaved), true);
      expect(states.last, isA<ProfileLoaded>());

      await sub.cancel();
    });

    test('clearProfile clears repo and emits ProfileLoaded(null)', () async {
      when(() => mockRepo.clear()).thenAnswer((_) async {});

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.clearProfile();
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.clear()).called(1);
      expect(states.last, isA<ProfileLoaded>());
      final loaded = states.last as ProfileLoaded;
      expect(loaded.profile, isNull);

      await sub.cancel();
    });

    test('loadProfile handles errors gracefully', () async {
      when(() => mockRepo.load()).thenThrow(Exception('Storage error'));

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadProfile();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ProfileError>());

      await sub.cancel();
    });

    test('saveProfile handles errors gracefully', () async {
      when(() => mockRepo.save(any())).thenThrow(Exception('Write error'));

      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.saveProfile(testProfile);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ProfileError>());

      await sub.cancel();
    });
  });
}
