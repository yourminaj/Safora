import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/services/sos_foreground_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/datasources/sos_history_datasource.dart';
import '../../../data/models/sos_history_entry.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/usecases/trigger_sos_usecase.dart';
import 'sos_state.dart';

/// Cubit managing the SOS panic button flow:
/// pre-flight → 30-sec countdown → trigger alert → play siren → send SMS.
class SosCubit extends Cubit<SosState> {
  SosCubit({
    required AudioService audioService,
    required TriggerSosUseCase triggerSosUseCase,
    required ContactsRepository contactsRepository,
    required SosHistoryDatasource sosHistoryDatasource,
    required LocationService locationService,
    required Box settingsBox,
    ConnectivityService? connectivityService,
    SmsService? smsService,
    ProfileRepository? profileRepository,
  }) : _audioService = audioService,
       _triggerSosUseCase = triggerSosUseCase,
       _contactsRepository = contactsRepository,
       _sosHistory = sosHistoryDatasource,
       _locationService = locationService,
       _settingsBox = settingsBox,
       _connectivityService = connectivityService,
       _smsService = smsService,
       _profileRepository = profileRepository,
       super(const SosIdle());

  static const String _deadlineKey = 'sos_countdown_deadline';

  final AudioService _audioService;
  final TriggerSosUseCase _triggerSosUseCase;
  final ContactsRepository _contactsRepository;
  final SosHistoryDatasource _sosHistory;
  final LocationService _locationService;
  final Box _settingsBox;
  final ConnectivityService? _connectivityService;
  final SmsService? _smsService;
  final ProfileRepository? _profileRepository;
  Timer? _countdownTimer;
  Timer? _autoResetTimer;
  int _secondsRemaining = 30;
  SosTriggerSource _currentTriggerSource = SosTriggerSource.manual;

  static const int countdownDuration = 30;

  /// Start the SOS flow with pre-flight checks.
  ///
  /// Pre-flight checks:
  /// 1. GPS: attempts a fresh fix if no cached position.
  /// 2. Network: checks connectivity (warn-only, doesn't block).
  /// 3. Contacts: verifies at least one emergency contact exists (blocks SOS).
  void startCountdown({
    SosTriggerSource triggerSource = SosTriggerSource.manual,
  }) {
    if (state is SosPreparing || state is SosCountdown || state is SosActive) {
      return;
    }

    _currentTriggerSource = triggerSource;
    _runPreflightAndStart();
  }

  Future<void> _runPreflightAndStart() async {
    final gpsReady = _locationService.lastPosition != null;
    final networkReady = _connectivityService?.isOnline ?? true;
    final contacts = _contactsRepository.getAll();
    final contactsReady = contacts.isNotEmpty;

    emit(
      SosPreparing(
        gpsReady: gpsReady,
        networkReady: networkReady,
        contactsReady: contactsReady,
      ),
    );

    AppLogger.info(
      '[SOS] Pre-flight: GPS=$gpsReady, '
      'Network=$networkReady, '
      'Contacts=${contacts.length}',
    );

    // Block SOS if no emergency contacts exist.
    if (!contactsReady) {
      emit(const SosPreflightFailed(reason: SosFailureReason.noContacts));
      // Return to idle after a brief pause.
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) emit(const SosIdle());
      });
      return;
    }

    // On Android, request SOS-critical permissions NOW — shows native OS
    // dialog if not yet granted. If already allowed (from onboarding), this
    // returns instantly with zero delay.
    //
    // SMS denial → SmsService falls back to url_launcher (opens SMS app).
    // Phone denial → tel: URI still opens dialer (just doesn't auto-dial).
    // Neither blocks the SOS flow — it's a safety-first approach.
    if (Platform.isAndroid) {
      final statuses = await [Permission.sms, Permission.phone].request();
      final smsGranted = statuses[Permission.sms]?.isGranted ?? false;
      final phoneGranted = statuses[Permission.phone]?.isGranted ?? false;
      if (!smsGranted) {
        AppLogger.warning(
          '[SOS] SEND_SMS not granted — SmsService will use url_launcher fallback.',
        );
      }
      if (!phoneGranted) {
        AppLogger.warning(
          '[SOS] CALL_PHONE not granted — will open dialer instead of auto-dial.',
        );
      }
    }

    // If GPS not ready, attempt a quick fix (non-blocking).
    if (!gpsReady) {
      AppLogger.info('[SOS] No cached GPS — attempting quick fix...');
      try {
        await _locationService.getCurrentPosition().timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {
        AppLogger.warning(
          '[SOS] GPS fix timed out — proceeding without location',
        );
      }
    }

    _secondsRemaining = countdownDuration;
    emit(SosCountdown(secondsRemaining: _secondsRemaining));

    final deadline = DateTime.now().add(
      const Duration(seconds: countdownDuration),
    );
    _settingsBox.put(_deadlineKey, deadline.toIso8601String());

    /// Start foreground service to keep the app alive during the countdown
    /// and continues to monitor for shake/crash/fall events even when the app
    /// is in the background or the screen is off.
    unawaited(SosForegroundService.instance.start());

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  /// Resumes the countdown if the app was killed while it was active.
  void resumeCountdown(DateTime deadline) {
    if (state is SosActive || state is SosPreparing) return;

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      _triggerSos();
      return;
    }

    _secondsRemaining = remaining.inSeconds;
    emit(SosCountdown(secondsRemaining: _secondsRemaining));

    unawaited(SosForegroundService.instance.start());

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
    _settingsBox.delete(_deadlineKey);
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsRemaining = countdownDuration;
    emit(const SosCancelled());

    // Stop foreground service if SOS was cancelled before trigger.
    unawaited(SosForegroundService.instance.stop());

    // Log cancelled SOS in history.
    final pos = _locationService.lastPosition;
    _sosHistory.add(
      SosHistoryEntry(
        timestamp: DateTime.now(),
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        contactsNotified: 0,
        smsSentCount: 0,
        wasCancelled: true,
        triggerSource: _currentTriggerSource,
      ),
    );

    // Return to idle after a brief pause (guarded timer to prevent race).
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(seconds: 1), () {
      if (!isClosed) emit(const SosIdle());
    });
  }

  /// Trigger the full SOS alert.
  Future<void> _triggerSos() async {
    _settingsBox.delete(_deadlineKey);
    emit(const SosActive());

    // Play siren (fire-and-forget — siren runs independently from SMS flow).
    unawaited(_audioService.playSiren());

    // Load medical profile for SMS (non-blocking — null if unavailable).
    final profile = _profileRepository?.load();

    // Send SMS + notification via use case.
    final contacts = _contactsRepository.getAll();
    final result = await _triggerSosUseCase.execute(
      contacts: contacts,
      userProfile: profile,
      triggerType: _currentTriggerSource.name,
    );

    // Log successful SOS in history.
    final pos = _locationService.lastPosition;
    await _sosHistory.add(
      SosHistoryEntry(
        timestamp: DateTime.now(),
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        contactsNotified: result.totalContacts,
        smsSentCount: result.smsSentCount,
        wasCancelled: false,
        triggerSource: _currentTriggerSource,
      ),
    );
  }

  /// Deactivate SOS, stop the siren, and notify contacts that user is safe.
  Future<void> deactivateSos() async {
    _settingsBox.delete(_deadlineKey);
    await _audioService.stopAll();
    await _triggerSosUseCase.cancel();
    await SosForegroundService.instance.stop();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsRemaining = countdownDuration;

    // Notify emergency contacts that user is safe.
    if (_smsService != null) {
      final contacts = _contactsRepository.getAll();
      if (contacts.isNotEmpty) {
        unawaited(_smsService.sendIAmSafeSms(contacts: contacts));
      }
    }

    emit(const SosIdle());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _autoResetTimer?.cancel();
    _audioService.stopAll();
    return super.close();
  }
}
