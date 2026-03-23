import 'package:equatable/equatable.dart';
import '../../../data/models/medicine_reminder.dart';

/// States for the medicine reminders cubit.
sealed class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => [];
}

class RemindersInitial extends RemindersState {
  const RemindersInitial();
}

class RemindersLoading extends RemindersState {
  const RemindersLoading();
}

class RemindersLoaded extends RemindersState {
  const RemindersLoaded({
    required this.reminders,
    required this.activeCount,
  });

  final List<MedicineReminder> reminders;
  final int activeCount;

  @override
  List<Object?> get props => [reminders, activeCount];
}

class RemindersError extends RemindersState {
  const RemindersError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ReminderLimitReached extends RemindersState {
  const ReminderLimitReached(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
