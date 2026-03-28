import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/alert_permission_gate.dart';
import '../../../data/models/alert_preferences.dart';

/// State for alert preferences.
class AlertPreferencesState extends Equatable {
  const AlertPreferencesState({
    required this.preferences,
    this.severityThreshold = AlertPriority.info,
    this.isLoading = false,
    this.permissionDeniedMessage,
  });

  /// Map of all alert types to their enabled status.
  final Map<AlertType, bool> preferences;

  /// Minimum severity threshold — alerts below this are suppressed.
  final AlertPriority severityThreshold;

  /// Loading state during permission requests.
  final bool isLoading;

  /// Set when a permission was denied — cleared on next action.
  final String? permissionDeniedMessage;

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
    );
  }

  @override
  List<Object?> get props => [preferences, severityThreshold, isLoading, permissionDeniedMessage];
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

    // Enabling — check permissions.
    emit(state.copyWith(isLoading: true, permissionDeniedMessage: null));

    final result = await _gate.requestForAlert(type);

    if (!result.granted) {
      emit(state.copyWith(
        isLoading: false,
        permissionDeniedMessage:
            '${type.label} requires ${result.deniedNames.join(" & ")} permission',
      ));
      return;
    }

    await _prefs.setEnabled(type, true);
    emit(state.copyWith(isLoading: false));
    _emitUpdated();
  }

  /// Enable all alerts in a category (requests permissions first).
  Future<void> enableCategory(AlertCategory category) async {
    emit(state.copyWith(isLoading: true, permissionDeniedMessage: null));

    // Check permissions for the category once.
    final sampleType = AlertType.values.firstWhere(
      (t) => t.category == category,
    );
    final result = await _gate.requestForAlert(sampleType);

    if (!result.granted) {
      emit(state.copyWith(
        isLoading: false,
        permissionDeniedMessage:
            '${category.label} requires ${result.deniedNames.join(" & ")} permission',
      ));
      return;
    }

    await _prefs.enableCategory(category);
    emit(state.copyWith(isLoading: false));
    _emitUpdated();
  }

  /// Disable all alerts in a category.
  Future<void> disableCategory(AlertCategory category) async {
    await _prefs.disableCategory(category);
    _emitUpdated();
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
