import '../models/alert_event.dart';
import '../datasources/disaster_api_client.dart';
import '../datasources/military_alert_client.dart';
import '../datasources/alerts_local_datasource.dart';
import '../../core/services/location_service.dart';

/// Abstract repository for disaster alert events.
abstract class AlertsRepository {
  Future<List<AlertEvent>> fetchLatestAlerts();
  List<AlertEvent> getAlertHistory({int limit = 20});
  Future<void> saveAlerts(List<AlertEvent> alerts);
  Future<void> clearHistory();
}

/// Implementation that merges USGS + GDACS + Open-Meteo + NASA + Military + local history.
class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl({
    required DisasterApiClient apiClient,
    required MilitaryAlertClient militaryAlertClient,
    required AlertsLocalDataSource localDataSource,
    required LocationService locationService,
  })  : _apiClient = apiClient,
        _militaryClient = militaryAlertClient,
        _localDataSource = localDataSource,
        _locationService = locationService;

  final DisasterApiClient _apiClient;
  final MilitaryAlertClient _militaryClient;
  final AlertsLocalDataSource _localDataSource;
  final LocationService _locationService;

  @override
  Future<List<AlertEvent>> fetchLatestAlerts() async {
    final allAlerts = <AlertEvent>[];

    // Fetch from all sources concurrently.
    final results = await Future.wait([
      _apiClient.fetchUsgsEarthquakes(),
      _apiClient.fetchGdacsEvents(),
      _fetchFloodRisk(),
      _fetchWeatherAlerts(),
      _fetchAirQualityAlerts(),
      _fetchWildfireHotspots(),
      _apiClient.fetchNasaEonetEvents(),
      _fetchMilitaryAlerts(),
    ]);

    for (final list in results) {
      allAlerts.addAll(list);
    }

    // Deduplicate by ID.
    final seen = <String>{};
    final unique = <AlertEvent>[];
    for (final alert in allAlerts) {
      final key = alert.id ?? '${alert.title}_${alert.timestamp}';
      if (seen.add(key)) {
        unique.add(alert);
      }
    }

    // Sort newest first.
    unique.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Persist to local history.
    await _localDataSource.saveAll(unique);

    return unique;
  }

  Future<List<AlertEvent>> _fetchFloodRisk() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    return _apiClient.fetchFloodRisk(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<List<AlertEvent>> _fetchWeatherAlerts() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    return _apiClient.fetchWeatherAlerts(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<List<AlertEvent>> _fetchAirQualityAlerts() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    return _apiClient.fetchAirQualityAlerts(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<List<AlertEvent>> _fetchWildfireHotspots() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    return _apiClient.fetchWildfireHotspots(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<List<AlertEvent>> _fetchMilitaryAlerts() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return [];

    return _militaryClient.fetchMilitaryAlerts(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  List<AlertEvent> getAlertHistory({int limit = 20}) {
    return _localDataSource.getRecent(limit: limit);
  }

  @override
  Future<void> saveAlerts(List<AlertEvent> alerts) async {
    await _localDataSource.saveAll(alerts);
  }

  @override
  Future<void> clearHistory() async {
    await _localDataSource.clear();
  }
}
