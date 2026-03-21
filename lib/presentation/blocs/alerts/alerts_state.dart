import 'package:equatable/equatable.dart';
import '../../../core/constants/alert_types.dart';
import '../../../data/models/alert_event.dart';

/// States for the alerts cubit.
sealed class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded.
class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

/// Loading alerts from APIs.
class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

/// Alerts loaded successfully.
class AlertsLoaded extends AlertsState {
  const AlertsLoaded({
    required this.alerts,
    this.filterCategory,
    this.filterPriority,
  });

  /// All fetched alerts.
  final List<AlertEvent> alerts;

  /// Active category filter (null = show all).
  final AlertCategory? filterCategory;

  /// Active priority filter (null = show all).
  final AlertPriority? filterPriority;

  /// Filtered view of alerts.
  List<AlertEvent> get filtered {
    var result = alerts;
    if (filterCategory != null) {
      result =
          result.where((a) => a.type.category == filterCategory).toList();
    }
    if (filterPriority != null) {
      result =
          result.where((a) => a.type.priority == filterPriority).toList();
    }
    return result;
  }

  AlertsLoaded copyWith({
    List<AlertEvent>? alerts,
    AlertCategory? Function()? filterCategory,
    AlertPriority? Function()? filterPriority,
  }) {
    return AlertsLoaded(
      alerts: alerts ?? this.alerts,
      filterCategory:
          filterCategory != null ? filterCategory() : this.filterCategory,
      filterPriority:
          filterPriority != null ? filterPriority() : this.filterPriority,
    );
  }

  @override
  List<Object?> get props => [alerts, filterCategory, filterPriority];
}

/// Error loading alerts.
class AlertsError extends AlertsState {
  const AlertsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
