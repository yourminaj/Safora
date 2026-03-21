import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Cubit for managing the user's medical profile.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial());

  final ProfileRepository _profileRepository;

  /// Load the profile from local storage.
  void loadProfile() {
    try {
      final profile = _profileRepository.load();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Save or update the profile.
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _profileRepository.save(profile);
      emit(ProfileSaved(profile));
      // Re-emit as loaded so UI stays in loaded state.
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Clear the profile.
  Future<void> clearProfile() async {
    try {
      await _profileRepository.clear();
      emit(const ProfileLoaded(null));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
