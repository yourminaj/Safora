import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../domain/usecases/trigger_sos_usecase.dart';
import 'sos_state.dart';

/// Cubit managing the SOS panic button flow:
/// tap → 30-sec countdown → trigger alert → play siren → send SMS.
class SosCubit extends Cubit<SosState> {
  SosCubit({
    required AudioService audioService,
    required TriggerSosUseCase triggerSosUseCase,
    required ContactsRepository contactsRepository,
  })  : _audioService = audioService,
        _triggerSosUseCase = triggerSosUseCase,
        _contactsRepository = contactsRepository,
        super(const SosIdle());

  final AudioService _audioService;
  final TriggerSosUseCase _triggerSosUseCase;
  final ContactsRepository _contactsRepository;
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  static const int countdownDuration = 30;

  /// Start the SOS countdown.
  void startCountdown() {
    if (state is SosCountdown || state is SosActive) return;

    _secondsRemaining = countdownDuration;
    emit(SosCountdown(secondsRemaining: _secondsRemaining));

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  void _tick() {
    _secondsRemaining--;

    if (_secondsRemaining <= 0) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _triggerSos();
    } else {
      emit(SosCountdown(secondsRemaining: _secondsRemaining));
    }
  }

  /// Cancel the countdown and return to idle.
  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsRemaining = countdownDuration;
    emit(const SosCancelled());

    // Return to idle after a brief pause.
    Future.delayed(const Duration(seconds: 1), () {
      if (!isClosed) emit(const SosIdle());
    });
  }

  /// Trigger the full SOS alert.
  Future<void> _triggerSos() async {
    emit(const SosActive());

    // Play siren (fire-and-forget — siren runs independently from SMS flow).
    unawaited(_audioService.playSiren());

    // Send SMS + notification via use case.
    final contacts = _contactsRepository.getAll();
    await _triggerSosUseCase.execute(contacts: contacts);
  }

  /// Deactivate SOS and stop the siren.
  Future<void> deactivateSos() async {
    await _audioService.stopAll();
    await _triggerSosUseCase.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsRemaining = countdownDuration;
    emit(const SosIdle());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _audioService.stopAll();
    return super.close();
  }
}
