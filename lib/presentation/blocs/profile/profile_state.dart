import 'package:equatable/equatable.dart';
import '../../../data/models/user_profile.dart';

/// States for the profile cubit.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial — profile not loaded yet.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Profile loaded (may be null if no profile saved).
class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final UserProfile? profile;

  @override
  List<Object?> get props => [profile];
}

/// Profile saved successfully.
class ProfileSaved extends ProfileState {
  const ProfileSaved(this.profile);

  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// Error.
class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
