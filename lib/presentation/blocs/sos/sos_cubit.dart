import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sos_foreground_service.dart';
import '../../../data/datasources/sos_history_datasource.dart';
import '../../../data/models/sos_history_entry.dart';
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
    required SosHistoryDatasource sosHistoryDatasource,
    required LocationService locationService,
  })  : _audioService = audioService,
        _triggerSosUseCase = triggerSosUseCase,
        _contactsRepository = contactsRepository,
        _sosHistory = sosHistoryDatasource,
        _locationService = locationService,
        super(const SosIdle());

  final AudioService _audioService;
  final TriggerSosUseCase _triggerSosUseCase;
  final ContactsRepository _contactsRepository;
  final SosHistoryDatasource _sosHistory;
  final LocationService _locationService;
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

    // Log cancelled SOS in history.
    final pos = _locationService.lastPosition;
    _sosHistory.add(SosHistoryEntry(
      timestamp: DateTime.now(),
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      contactsNotified: 0,
      smsSentCount: 0,
      wasCancelled: true,
    ));

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

    // Start foreground service to keep SOS alive when app goes to background.
    unawaited(SosForegroundService.instance.start());

    // Send SMS + notification via use case.
    final contacts = _contactsRepository.getAll();
    final result = await _triggerSosUseCase.execute(contacts: contacts);

    // Log successful SOS in history.
    final pos = _locationService.lastPosition;
    await _sosHistory.add(SosHistoryEntry(
      timestamp: DateTime.now(),
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      contactsNotified: result.totalContacts,
      smsSentCount: result.smsSentCount,
      wasCancelled: false,
    ));
  }

  /// Deactivate SOS and stop the siren.
  Future<void> deactivateSos() async {
    await _audioService.stopAll();
    await _triggerSosUseCase.cancel();
    await SosForegroundService.instance.stop();
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
