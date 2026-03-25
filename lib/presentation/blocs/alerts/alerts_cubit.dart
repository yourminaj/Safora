import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/alert_event.dart';
import '../../../data/repositories/alerts_repository.dart';
import 'alerts_state.dart';

/// Cubit for fetching, caching, and filtering disaster alerts.
///
/// Auto-refreshes every 15 minutes when active.
class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit({
    required AlertsRepository alertsRepository,
    required NotificationService notificationService,
  })  : _alertsRepository = alertsRepository,
        _notificationService = notificationService,
        super(const AlertsInitial());

  final AlertsRepository _alertsRepository;
  final NotificationService _notificationService;
  Timer? _refreshTimer;

  static const Duration refreshInterval = Duration(minutes: 15);

  /// Load alerts — either from API or from local cache.
  Future<void> loadAlerts() async {
    emit(const AlertsLoading());

    try {
      // First show cached data quickly.
      final cached = _alertsRepository.getAlertHistory(limit: 50);
      if (cached.isNotEmpty) {
        emit(AlertsLoaded(alerts: cached));
      }

      // Then fetch fresh data from APIs.
      final fresh = await _alertsRepository.fetchLatestAlerts();

      // Notify about new critical alerts.
      _notifyNewCritical(fresh, cached);

      emit(AlertsLoaded(alerts: fresh));

      // Start auto-refresh timer.
      _startAutoRefresh();
    } catch (e) {
      final cached = _alertsRepository.getAlertHistory(limit: 50);
      if (cached.isNotEmpty) {
        emit(AlertsLoaded(alerts: cached));
      } else {
        emit(AlertsError(e.toString()));
      }
    }
  }

  /// Inject a locally-detected alert (from on-device services) into
  /// the cubit state and trigger notification if critical.
  void addLocalAlert(AlertEvent alert) {
    final currentState = state;
    final List<AlertEvent> current;

    if (currentState is AlertsLoaded) {
      current = List.of(currentState.alerts);
    } else {
      current = <AlertEvent>[];
    }

    // Add to front (newest first) and deduplicate.
    current.insert(0, alert);
    final seen = <String>{};
    final unique = <AlertEvent>[];
    for (final a in current) {
      final key = a.id ?? '${a.title}_${a.timestamp}';
      if (seen.add(key)) unique.add(a);
    }

    // Persist to history.
    _alertsRepository.saveAlerts(unique);

    emit(AlertsLoaded(alerts: unique));

    // Notify if critical.
    if (alert.type.priority == AlertPriority.critical) {
      _notificationService.showDisasterAlert(
        title: '${alert.type.category.label}: ${alert.title}',
        body: alert.description ??
            'Critical alert from ${alert.source ?? "on-device detection"}',
      );
    }
  }

  /// Force refresh alerts from all APIs.
  Future<void> refreshAlerts() async {
    final currentState = state;

    try {
      final fresh = await _alertsRepository.fetchLatestAlerts();

      if (currentState is AlertsLoaded) {
        _notifyNewCritical(fresh, currentState.alerts);
        emit(currentState.copyWith(alerts: fresh));
      } else {
        emit(AlertsLoaded(alerts: fresh));
      }
    } catch (_) {
      // Keep current state on refresh failure.
    }
  }

  /// Filter alerts by category.
  void filterByCategory(AlertCategory? category) {
    final currentState = state;
    if (currentState is AlertsLoaded) {
      emit(currentState.copyWith(
        filterCategory: () => category,
      ));
    }
  }

  /// Filter alerts by priority.
  void filterByPriority(AlertPriority? priority) {
    final currentState = state;
    if (currentState is AlertsLoaded) {
      emit(currentState.copyWith(
        filterPriority: () => priority,
      ));
    }
  }

  /// Clear all filters.
  void clearFilters() {
    final currentState = state;
    if (currentState is AlertsLoaded) {
      emit(currentState.copyWith(
        filterCategory: () => null,
        filterPriority: () => null,
      ));
    }
  }

  /// Max notifications per refresh to avoid flooding.
  static const int _maxNotificationsPerRefresh = 3;

  void _notifyNewCritical(
    List<AlertEvent> fresh,
    List<AlertEvent> cached,
  ) {
    final cachedIds = cached
        .map((a) => a.id ?? '${a.title}_${a.timestamp}')
        .toSet();

    int notificationCount = 0;
    for (final alert in fresh) {
      if (notificationCount >= _maxNotificationsPerRefresh) break;

      final id = alert.id ?? '${alert.title}_${alert.timestamp}';
      if (!cachedIds.contains(id) &&
          alert.type.priority == AlertPriority.critical) {
        _notificationService.showDisasterAlert(
          title: '${alert.type.category.label}: ${alert.title}',
          body: alert.description ??
              'Critical alert from ${alert.source ?? "unknown source"}',
        );
        notificationCount++;
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      refreshAlerts();
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
