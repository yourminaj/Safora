import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/battery_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../data/repositories/contacts_repository.dart';
import 'battery_state.dart';

/// Cubit that monitors battery level and alerts contacts when critical.
class BatteryCubit extends Cubit<BatteryState> {
  BatteryCubit({
    required BatteryService batteryService,
    required NotificationService notificationService,
    required SmsService smsService,
    required ContactsRepository contactsRepository,
  })  : _batteryService = batteryService,
        _notificationService = notificationService,
        _smsService = smsService,
        _contactsRepository = contactsRepository,
        super(const BatteryUnknown());

  final BatteryService _batteryService;
  final NotificationService _notificationService;
  final SmsService _smsService;
  final ContactsRepository _contactsRepository;

  bool _criticalAlertSent = false;

  /// Start monitoring battery level.
  void startMonitoring() {
    _batteryService.startMonitoring(
      onLevelChanged: _onBatteryChanged,
    );
  }

  void _onBatteryChanged(int level, bp.BatteryState state) {
    // Don't alert while charging.
    if (state == bp.BatteryState.charging ||
        state == bp.BatteryState.full) {
      _criticalAlertSent = false;
      if (level > 0) {
        emit(BatteryNormal(level: level));
      }
      return;
    }

    if (BatteryService.isCritical(level)) {
      emit(BatteryCritical(level: level));
      _sendCriticalAlert(level);
    } else if (BatteryService.isLow(level)) {
      _criticalAlertSent = false;
      emit(BatteryLow(level: level));
    } else if (level > 0) {
      _criticalAlertSent = false;
      emit(BatteryNormal(level: level));
    }
  }

  /// Send critical battery alert to primary contact.
  Future<void> _sendCriticalAlert(int level) async {
    if (_criticalAlertSent) return;
    _criticalAlertSent = true;

    // Show local notification.
    await _notificationService.showBatteryAlert(level);

    // Find primary contact (or first contact).
    final contacts = _contactsRepository.getAll();
    if (contacts.isEmpty) return;

    final primary = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.first,
    );

    await _smsService.sendBatteryAlert(
      contact: primary,
      batteryLevel: level,
    );
  }

  @override
  Future<void> close() {
    _batteryService.stopMonitoring();
    return super.close();
  }
}
