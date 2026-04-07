import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/alert_permission_gate.dart';
import '../../../core/services/premium_manager.dart';
import '../../../data/models/alert_preferences.dart';

/// State for alert preferences.
class AlertPreferencesState extends Equatable {
  const AlertPreferencesState({
    required this.preferences,
    this.severityThreshold = AlertPriority.info,
    this.isLoading = false,
    this.permissionDeniedMessage,
    this.successMessage,
    this.infoMessage,
  });

  /// Map of all alert types to their enabled status.
  final Map<AlertType, bool> preferences;

  /// Minimum severity threshold — alerts below this are suppressed.
  final AlertPriority severityThreshold;

  /// Loading state during permission requests.
  final bool isLoading;

  /// Set when a permission was denied — cleared on next action.
  final String? permissionDeniedMessage;

  /// Set when an action (like bulk enable) succeeds — cleared on next action.
  final String? successMessage;

  /// Set when an action was partially successful OR informational (e.g. Pro alerts skipped).
  final String? infoMessage;

  /// Helper: grouped by category for UI.
  Map<AlertCategory, List<AlertTypeStatus>> get groupedByCategory {
    final map = <AlertCategory, List<AlertTypeStatus>>{};
    for (final entry in preferences.entries) {
      final list = map.putIfAbsent(entry.key.category, () => []);
      list.add(AlertTypeStatus(type: entry.key, enabled: entry.value));
    }
    return map;
  }

  int get enabledCount => preferences.values.where((v) => v).length;
  int get totalCount => preferences.length;

  AlertPreferencesState copyWith({
    Map<AlertType, bool>? preferences,
    AlertPriority? severityThreshold,
    bool? isLoading,
    String? permissionDeniedMessage,
  }) {
    return AlertPreferencesState(
      preferences: preferences ?? this.preferences,
      severityThreshold: severityThreshold ?? this.severityThreshold,
      isLoading: isLoading ?? this.isLoading,
      permissionDeniedMessage: permissionDeniedMessage,
      successMessage: successMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
        preferences,
        severityThreshold,
        isLoading,
        permissionDeniedMessage,
        successMessage,
        infoMessage,
      ];
}

/// Cubit managing per-alert enable/disable preferences.
class AlertPreferencesCubit extends Cubit<AlertPreferencesState> {
  AlertPreferencesCubit({
    required AlertPreferences alertPreferences,
    required AlertPermissionGate permissionGate,
  })  : _prefs = alertPreferences,
        _gate = permissionGate,
        super(AlertPreferencesState(
          preferences: _buildInitial(alertPreferences),
          severityThreshold: alertPreferences.minimumSeverity,
        ));

  final AlertPreferences _prefs;
  final AlertPermissionGate _gate;

  /// Build initial state from Hive.
  static Map<AlertType, bool> _buildInitial(AlertPreferences prefs) {
    return {
      for (final type in AlertType.values) type: prefs.isEnabled(type),
    };
  }

  /// Toggle a single alert type.
  ///
  /// If enabling and the alert requires permissions, requests them first.
  /// If permissions are denied, the alert stays disabled.
  Future<void> toggleAlert(AlertType type) async {
    final currentlyEnabled = _prefs.isEnabled(type);

    if (currentlyEnabled) {
      // Disabling — no permission needed.
      await _prefs.setEnabled(type, false);
      _emitUpdated();
      return;
    }

    if (!type.isFree && !GetIt.instance<PremiumManager>().isPremium) {
      emit(AlertPreferencesState(
        preferences: _buildInitial(_prefs),
        severityThreshold: _prefs.minimumSeverity,
        permissionDeniedMessage: 'Pro subscription required for ${type.label}',
      ));
      return;
    }

    // Enabling — check permissions WITHOUT showing loading overlay.
    final result = await _gate.requestForAlert(type);

    if (!result.granted) {
      // Emit updated state with permission denied message — no isLoading.
      emit(AlertPreferencesState(
        preferences: _buildInitial(_prefs),
        severityThreshold: _prefs.minimumSeverity,
        permissionDeniedMessage:
            '${type.label} requires ${result.deniedNames.join(" & ")} permission',
      ));
      return;
    }

    await _prefs.setEnabled(type, true);
    emit(AlertPreferencesState(
      preferences: _buildInitial(_prefs),
      severityThreshold: _prefs.minimumSeverity,
      successMessage: '${type.label} enabled',
    ));
  }

  /// Enable all alerts in a category (requests permissions first).
  Future<void> enableCategory(AlertCategory category) async {
    // Check permissions WITHOUT showing loading overlay first.
    // The OS permission dialog causes the app to appear dimmed — adding
    // another loading indicator on top makes it look crashed.
    // We only find a representative type that actually needs a permission.
    final typesInCategory =
        AlertType.values.where((t) => t.category == category);
    if (typesInCategory.isEmpty) return;

    // Pick first type; permission check is per-category, not per-type.
    final sampleType = typesInCategory.first;
    final result = await _gate.requestForAlert(sampleType);

    if (!result.granted) {
      emit(AlertPreferencesState(
        preferences: _buildInitial(_prefs),
        severityThreshold: _prefs.minimumSeverity,
        permissionDeniedMessage:
            '${category.label} requires ${result.deniedNames.join(" & ")} permission',
      ));
      return;
    }

    final isPro = GetIt.instance<PremiumManager>().isPremium;
    final enabledCount = await _prefs.enableCategory(category, isUserPremium: isPro);

    String message = 'Enabled $enabledCount alerts in ${category.label}';
    int proCount = 0;
    if (!isPro) {
      proCount = AlertType.values
          .where((t) => t.category == category && !t.isFree)
          .length;
      if (proCount > 0) {
        message += '. Upgrade to PRO for all ${category.label} alerts.';
      }
    }

    emit(AlertPreferencesState(
      preferences: _buildInitial(_prefs),
      severityThreshold: _prefs.minimumSeverity,
      successMessage: (!isPro && proCount > 0) ? null : message,
      infoMessage: (!isPro && proCount > 0) ? message : null,
    ));
  }

  /// Disable all alerts in a category.
  Future<void> disableCategory(AlertCategory category) async {
    final disabledCount = await _prefs.disableCategory(category);
    emit(AlertPreferencesState(
      preferences: _buildInitial(_prefs),
      severityThreshold: _prefs.minimumSeverity,
      successMessage: 'Disabled $disabledCount alerts in ${category.label}',
    ));
  }

  /// Enable all free alerts.
  Future<void> enableAllFree() async {
    final count = await _prefs.enableAllFree();
    emit(AlertPreferencesState(
      preferences: _buildInitial(_prefs),
      severityThreshold: _prefs.minimumSeverity,
      successMessage: 'Enabled $count free alerts',
    ));
  }

  /// Check if a specific alert is enabled.
  bool isEnabled(AlertType type) => _prefs.isEnabled(type);

  /// Set the minimum severity threshold.
  Future<void> setSeverity(AlertPriority priority) async {
    await _prefs.setMinimumSeverity(priority);
    _emitUpdated();
  }

  void _emitUpdated() {
    emit(AlertPreferencesState(
      preferences: _buildInitial(_prefs),
      severityThreshold: _prefs.minimumSeverity,
    ));
  }
}
