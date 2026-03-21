import 'package:equatable/equatable.dart';

/// States for the SOS emergency cubit.
sealed class SosState extends Equatable {
  const SosState();

  @override
  List<Object?> get props => [];
}

/// SOS is idle — no countdown or alert active.
class SosIdle extends SosState {
  const SosIdle();
}

/// SOS countdown is in progress.
class SosCountdown extends SosState {
  const SosCountdown({required this.secondsRemaining});

  /// Total countdown duration in seconds (must match SosCubit.countdownDuration).
  static const int countdownDuration = 30;

  final int secondsRemaining;

  double get progress => secondsRemaining / countdownDuration;

  @override
  List<Object?> get props => [secondsRemaining];
}

/// SOS has been triggered — alert is active.
class SosActive extends SosState {
  const SosActive();
}

/// SOS was cancelled during countdown.
class SosCancelled extends SosState {
  const SosCancelled();
}
