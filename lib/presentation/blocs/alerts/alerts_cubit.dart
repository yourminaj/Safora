import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/alert_event.dart';
import '../../../data/models/alert_preferences.dart';
import '../../../data/repositories/alerts_repository.dart';
import '../../../services/risk_score_engine.dart';
import 'alerts_state.dart';

/// Cubit for fetching, caching, and filtering disaster alerts.
///
/// **Preference-aware**: Only alerts whose [AlertType] is enabled in
/// [AlertPreferences] are emitted to the UI and trigger notifications.
/// Auto-refreshes every 15 minutes when active.
class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit({
    required AlertsRepository alertsRepository,
    required NotificationService notificationService,
    required AlertPreferences alertPreferences,
  })  : _alertsRepository = alertsRepository,
        _notificationService = notificationService,
        _prefs = alertPreferences,
        super(const AlertsInitial());

  final AlertsRepository _alertsRepository;
  final NotificationService _notificationService;
  final AlertPreferences _prefs;
  static const _riskEngine = RiskScoreEngine();
  Timer? _refreshTimer;

  static const Duration refreshInterval = Duration(minutes: 15);

  /// Load alerts — from cache then API — filtered by user preferences.
  Future<void> loadAlerts() async {
    emit(const AlertsLoading());

    try {
      // First show cached data quickly.
      final cached = _filterByPreferences(
        _alertsRepository.getAlertHistory(limit: 50),
      );
      if (cached.isNotEmpty) {
        emit(AlertsLoaded(alerts: cached, preferencesApplied: true));
      }

      // Then fetch fresh data from APIs, enrich with risk scores.
      final rawFresh = await _alertsRepository.fetchLatestAlerts();
      final scored = _riskEngine.enrichAndSort(_filterByPreferences(rawFresh));

      // Notify about new critical alerts (only if enabled by user).
      _notifyNewCritical(scored, cached);

      emit(AlertsLoaded(alerts: scored, preferencesApplied: true));

      // Start auto-refresh timer.
      _startAutoRefresh();
    } catch (e) {
      final cached = _filterByPreferences(
        _alertsRepository.getAlertHistory(limit: 50),
      );
      if (cached.isNotEmpty) {
        emit(AlertsLoaded(alerts: cached, preferencesApplied: true));
      } else {
        emit(AlertsError(e.toString()));
      }
    }
  }

  /// Inject a locally-detected alert (from on-device services) into
  /// the cubit state and trigger notification — only if the user has
  /// enabled that alert type.
  void addLocalAlert(AlertEvent alert) {
    // Gate: if the user has disabled this alert type, drop it silently.
    if (!_prefs.isEnabled(alert.type)) return;

    // Enrich with composite risk score before inserting into pipeline.
    final enriched = _riskEngine.enrichWithScore(alert);

    final currentState = state;
    final List<AlertEvent> current;

    if (currentState is AlertsLoaded) {
      current = List.of(currentState.alerts);
    } else {
      current = <AlertEvent>[];
    }

    // Add to front (newest first) and deduplicate.
    current.insert(0, enriched);
    final seen = <String>{};
    final unique = <AlertEvent>[];
    for (final a in current) {
      final key = a.id ?? '${a.title}_${a.timestamp}';
      if (seen.add(key)) unique.add(a);
    }

    // Persist to history.
    _alertsRepository.saveAlerts(unique);

    emit(AlertsLoaded(alerts: unique, preferencesApplied: true));

    // Notify if critical.
    if (enriched.type.priority == AlertPriority.critical ||
        (enriched.riskScore ?? 0) >= 80) {
      _notificationService.showDisasterAlert(
        title: '${enriched.type.category.label}: ${enriched.title}',
        body: enriched.description ??
            'Critical alert from ${enriched.source ?? "on-device detection"}',
      );
    }
  }

  /// Force refresh alerts from all APIs — filtered by preferences + scored.
  Future<void> refreshAlerts() async {
    final currentState = state;

    try {
      final rawFresh = await _alertsRepository.fetchLatestAlerts();
      final scored = _riskEngine.enrichAndSort(_filterByPreferences(rawFresh));

      if (currentState is AlertsLoaded) {
        _notifyNewCritical(scored, currentState.alerts);
        emit(currentState.copyWith(
          alerts: scored,
          preferencesApplied: true,
        ));
      } else {
        emit(AlertsLoaded(alerts: scored, preferencesApplied: true));
      }
    } catch (_) {
      // Keep current state on refresh failure.
    }
  }

  /// Re-apply preferences filter (call after user changes preferences).
  void reapplyPreferences() {
    final currentState = state;
    if (currentState is AlertsLoaded) {
      // Re-filter against the backing store (unfiltered history).
      final allAlerts = _alertsRepository.getAlertHistory(limit: 200);
      final filtered = _filterByPreferences(allAlerts);
      emit(AlertsLoaded(
        alerts: filtered,
        filterCategory: currentState.filterCategory,
        filterPriority: currentState.filterPriority,
        preferencesApplied: true,
      ));
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

  /// Core filter: drops alerts whose type is disabled or below severity threshold.
  List<AlertEvent> _filterByPreferences(List<AlertEvent> alerts) {
    return alerts.where((a) => _prefs.shouldReceive(a.type)).toList();
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
