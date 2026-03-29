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

/// SOS is running pre-flight checks before starting countdown.
class SosPreparing extends SosState {
  const SosPreparing({
    required this.gpsReady,
    required this.networkReady,
    required this.contactsReady,
  });

  /// Whether GPS coordinates are available.
  final bool gpsReady;

  /// Whether network connectivity is available.
  final bool networkReady;

  /// Whether at least one emergency contact exists.
  final bool contactsReady;

  /// Whether all checks passed.
  bool get allClear => gpsReady && contactsReady;

  @override
  List<Object?> get props => [gpsReady, networkReady, contactsReady];
}

/// Reason why pre-flight failed — mapped to l10n in the UI layer.
enum SosFailureReason {
  noContacts,
  noGps,
  noNetwork,
  /// Android SEND_SMS permission was denied — SOS SMS will not be sent.
  smsPermissionDenied,
}

/// Pre-flight failed — SOS cannot proceed (e.g., no contacts).
class SosPreflightFailed extends SosState {
  const SosPreflightFailed({required this.reason});

  /// Machine-readable reason — the UI maps this to a localized string.
  final SosFailureReason reason;

  @override
  List<Object?> get props => [reason];
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
