import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/app_logger.dart';
import '../../core/constants/alert_types.dart';
import '../models/alert_event.dart';

/// Region enum for military alert detection.
///
/// Each region maps to a government-provided alert API:
/// - Ukraine: alerts.in.ua (free, real-time air raid sirens)
/// - Israel: Home Front Command (pikud ha-oref) alerts
/// - US: FEMA IPAWS (Integrated Public Alert & Warning System)
enum ConflictRegion {
  ukraine,
  israel,
  unitedStates,
  none,
}

/// Client for fetching military/conflict alerts from government APIs.
///
/// This client is region-gated: it auto-detects the user's region from
/// GPS coordinates and only fetches from the relevant regional API.
/// If the user is not in a conflict zone, no requests are made.
///
/// All APIs used are free and publicly accessible:
/// - **Ukraine**: https://alerts.in.ua/api (Ukrainian Air Raid Alerts)
/// - **Israel**: https://www.oref.org.il/WarningMessages/ (public feed)
/// - **US**: https://api.weather.gov/alerts (NWS/FEMA unified alerts)
class MilitaryAlertClient {
  MilitaryAlertClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  /// Auto-detect the conflict region from GPS coordinates.
  ///
  /// Uses simple bounding-box approximation:
  /// - Ukraine:  lat 44–53, lng 22–41
  /// - Israel:   lat 29–34, lng 34–36
  /// - US:       lat 24–50, lng -125—-66
  static ConflictRegion detectRegion(double latitude, double longitude) {
    // Ukraine bounding box.
    if (latitude >= 44 && latitude <= 53 &&
        longitude >= 22 && longitude <= 41) {
      return ConflictRegion.ukraine;
    }

    // Israel bounding box (including occupied territories).
    if (latitude >= 29 && latitude <= 34 &&
        longitude >= 34 && longitude <= 36) {
      return ConflictRegion.israel;
    }

    // US continental bounding box.
    if (latitude >= 24 && latitude <= 50 &&
        longitude >= -125 && longitude <= -66) {
      return ConflictRegion.unitedStates;
    }

    return ConflictRegion.none;
  }

  /// Fetch military/conflict alerts based on user's GPS position.
  ///
  /// Returns empty list if user is not in a recognized conflict zone,
  /// or if the regional API is unreachable.
  Future<List<AlertEvent>> fetchMilitaryAlerts({
    required double latitude,
    required double longitude,
  }) async {
    final region = detectRegion(latitude, longitude);

    return switch (region) {
      ConflictRegion.ukraine => _fetchUkraineAlerts(latitude, longitude),
      ConflictRegion.israel => _fetchIsraelAlerts(latitude, longitude),
      ConflictRegion.unitedStates => _fetchFemaAlerts(latitude, longitude),
      ConflictRegion.none => <AlertEvent>[],
    };
  }

  // ─── Ukraine: alerts.in.ua ──────────────────────────────

  /// Fetch active air raid alerts from the Ukrainian government system.
  ///
  /// The free API provides oblast-level alerts in real-time.
  /// Endpoint: https://alerts.in.ua/api/states (no key needed for basic access)
  Future<List<AlertEvent>> _fetchUkraineAlerts(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse('https://alerts.in.ua/api/states');
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      final states = json is List ? json : (json as Map)['states'] as List?;
      if (states == null) return [];

      final alerts = <AlertEvent>[];
      for (final state in states) {
        final stateMap = state as Map<String, dynamic>;
        final alertStatus = stateMap['alert'] as bool? ?? false;
        if (!alertStatus) continue;

        final stateName = stateMap['name'] as String? ?? 'Unknown Oblast';
        final alertType = _mapUkraineThreatType(
          stateMap['alert_type'] as String?,
        );
        final changedAt = DateTime.tryParse(
              stateMap['changed'] as String? ?? '',
            ) ??
            DateTime.now();

        alerts.add(AlertEvent(
          id: 'ua_alert_${stateMap['id']}',
          type: alertType,
          title: '🚨 ${alertType.label} — $stateName',
          description:
              'Active ${alertType.label.toLowerCase()} alert in $stateName. '
              'Seek shelter immediately.',
          latitude: latitude,
          longitude: longitude,
          timestamp: changedAt,
          source: 'Ukraine Alert System',
        ));
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[MilitaryAlert] Ukraine alerts fetch failed: $e');
      return [];
    }
  }

  AlertType _mapUkraineThreatType(String? type) {
    return switch (type?.toLowerCase()) {
      'air_raid' || 'air' => AlertType.airRaid,
      'artillery' || 'shelling' => AlertType.missileStrike,
      'urban_fights' => AlertType.activeShooter,
      'chemical' => AlertType.nuclearEvent,
      'nuclear' => AlertType.nuclearEvent,
      'drone' || 'drones' => AlertType.droneAttack,
      _ => AlertType.airRaid,
    };
  }

  // ─── Israel: Home Front Command (Pikud HaOref) ──────────

  /// Fetch active alerts from Israel's Home Front Command.
  ///
  /// Public feed is available as JSON (no key required).
  Future<List<AlertEvent>> _fetchIsraelAlerts(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://www.oref.org.il/WarningMessages/History/AlertsHistory.json',
      );
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://www.oref.org.il/',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> events = jsonDecode(response.body);
      final alerts = <AlertEvent>[];
      final now = DateTime.now();

      // Only show alerts from the last 30 minutes.
      for (final event in events.take(20)) {
        final eventMap = event as Map<String, dynamic>;
        final alertDate = DateTime.tryParse(
              eventMap['alertDate'] as String? ?? '',
            ) ??
            now;

        // Skip alerts older than 30 minutes.
        if (now.difference(alertDate).inMinutes > 30) continue;

        final category = (eventMap['category_desc'] as String? ?? '')
            .toLowerCase();
        final alertType = _mapIsraelThreatType(category);
        final area = eventMap['data'] as String? ?? 'Unknown Area';

        alerts.add(AlertEvent(
          id: 'il_alert_${eventMap['rid'] ?? alertDate.millisecondsSinceEpoch}',
          type: alertType,
          title: '🚨 ${alertType.label} — $area',
          description:
              'Active alert: ${eventMap['title'] ?? alertType.label} '
              'in $area. Take cover immediately.',
          latitude: latitude,
          longitude: longitude,
          timestamp: alertDate,
          source: 'Israel HFC',
        ));
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[MilitaryAlert] Israel HFC alerts fetch failed: $e');
      return [];
    }
  }

  AlertType _mapIsraelThreatType(String category) {
    if (category.contains('missile') || category.contains('rocket')) {
      return AlertType.missileStrike;
    }
    if (category.contains('drone') || category.contains('uav')) {
      return AlertType.droneAttack;
    }
    if (category.contains('terror')) {
      return AlertType.terrorism;
    }
    return AlertType.airRaid;
  }

  // ─── US: FEMA / NWS Alerts ──────────────────────────────

  /// Fetch emergency alerts from FEMA/NWS unified alert system.
  ///
  /// Uses the free NWS API (api.weather.gov/alerts) which includes:
  /// - Civil danger, active shooter, nuclear, evacuation alerts
  /// No API key required.
  Future<List<AlertEvent>> _fetchFemaAlerts(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.weather.gov/alerts/active',
      ).replace(queryParameters: {
        'point': '$latitude,$longitude',
        'severity': 'Extreme,Severe',
        'limit': '10',
      });

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/geo+json',
          'User-Agent': 'Safora Emergency App',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? [];

      final alerts = <AlertEvent>[];
      for (final feature in features) {
        final props = (feature as Map<String, dynamic>)['properties']
            as Map<String, dynamic>?;
        if (props == null) continue;

        final event = props['event'] as String? ?? '';
        final alertType = _mapFemaEventType(event);

        // Only include security/military related events, not weather.
        if (alertType == null) continue;

        final sent = DateTime.tryParse(
              props['sent'] as String? ?? '',
            ) ??
            DateTime.now();

        alerts.add(AlertEvent(
          id: props['id'] as String?,
          type: alertType,
          title: '🚨 $event',
          description: props['headline'] as String? ??
              props['description'] as String? ??
              event,
          latitude: latitude,
          longitude: longitude,
          timestamp: sent,
          source: 'FEMA/NWS',
          magnitude: _femaUrgencyToMagnitude(
            props['urgency'] as String?,
          ),
        ));
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[MilitaryAlert] FEMA alerts fetch failed: $e');
      return [];
    }
  }

  /// Map NWS/FEMA event types to AlertType.
  ///
  /// Returns null for weather-only events (already handled by Phase 1).
  AlertType? _mapFemaEventType(String event) {
    final lower = event.toLowerCase();

    if (lower.contains('civil danger') || lower.contains('civil emergency')) {
      return AlertType.terrorism;
    }
    if (lower.contains('nuclear')) {
      return AlertType.nuclearEvent;
    }
    if (lower.contains('shelter in place')) {
      return AlertType.activeShooter;
    }
    if (lower.contains('evacuation')) {
      return AlertType.bombThreat;
    }
    if (lower.contains('law enforcement')) {
      return AlertType.activeShooter;
    }

    // Weather events are handled by Phase 1 — skip here.
    return null;
  }

  double? _femaUrgencyToMagnitude(String? urgency) {
    return switch (urgency?.toLowerCase()) {
      'immediate' => 10.0,
      'expected' => 7.0,
      'future' => 5.0,
      _ => null,
    };
  }

  /// Dispose HTTP client.
  void dispose() {
    _client.close();
  }
}
