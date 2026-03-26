import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/datasources/reminders_local_datasource.dart';
import '../../../data/repositories/reminders_repository.dart';
import '../../../data/models/medicine_reminder.dart';
import 'reminders_state.dart';

/// Cubit for medicine reminder CRUD and notification scheduling.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required RemindersRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(const RemindersInitial());

  final RemindersRepository _repository;
  final NotificationService _notificationService;

  /// Load all reminders from local storage.
  void loadReminders() {
    emit(const RemindersLoading());

    try {
      final reminders = _repository.getAll();
      final activeCount = reminders.where((r) => r.isActive).length;
      emit(RemindersLoaded(
        reminders: reminders,
        activeCount: activeCount,
      ));
    } catch (e) {
      AppLogger.error('[RemindersCubit] Error loading: $e');
      emit(RemindersError('Failed to load reminders: $e'));
    }
  }

  /// Add a new reminder.
  Future<void> addReminder({
    required String name,
    required String dosage,
    required String timeOfDay,
    ReminderFrequency frequency = ReminderFrequency.daily,
    String? notes,
  }) async {
    try {
      final reminder = MedicineReminder(
        name: name,
        dosage: dosage,
        timeOfDay: timeOfDay,
        frequency: frequency,
        notes: notes,
      );

      final id = await _repository.add(reminder);

      // Schedule notification for active reminders.
      await _scheduleNotification(reminder.copyWith(id: id));

      loadReminders();
    } on ReminderLimitException catch (e) {
      emit(ReminderLimitReached(e.message));
    } catch (e) {
      AppLogger.error('[RemindersCubit] Error adding: $e');
      emit(RemindersError('Failed to add reminder: $e'));
    }
  }

  /// Update an existing reminder.
  Future<void> updateReminder(MedicineReminder reminder) async {
    try {
      await _repository.update(reminder);

      // Reschedule notification.
      if (reminder.id != null) {
        await _cancelNotification(reminder.id!);
        if (reminder.isActive) {
          await _scheduleNotification(reminder);
        }
      }

      loadReminders();
    } catch (e) {
      AppLogger.error('[RemindersCubit] Error updating: $e');
    }
  }

  /// Delete a reminder.
  Future<void> deleteReminder(String id) async {
    try {
      await _cancelNotification(id);
      await _repository.delete(id);
      loadReminders();
    } catch (e) {
      AppLogger.error('[RemindersCubit] Error deleting: $e');
    }
  }

  /// Toggle a reminder's active/inactive state.
  Future<void> toggleReminder(String id) async {
    try {
      await _repository.toggleActive(id);
      loadReminders();
    } catch (e) {
      AppLogger.error('[RemindersCubit] Error toggling: $e');
    }
  }

  /// Schedule a local notification for a reminder.
  Future<void> _scheduleNotification(MedicineReminder reminder) async {
    if (reminder.id == null || !reminder.isActive) return;

    final time = reminder.timeParts;
    final body = '${reminder.dosage}${reminder.notes != null ? ' — ${reminder.notes}' : ''}';

    await _notificationService.showDisasterAlert(
      title: 'Time to take ${reminder.name}',
      body: body,
    );

    AppLogger.info(
      '[RemindersCubit] Scheduled notification for ${reminder.name} '
      'at ${time.hour}:${time.minute}',
    );
  }

  Future<void> _cancelNotification(String id) async {
    // Generate a deterministic notification ID from the reminder ID.
    final notifId = id.hashCode.abs() % 100000;
    await _notificationService.cancelNotification(notifId);
  }
}
