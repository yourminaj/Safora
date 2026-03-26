import 'dart:async';
import '../services/app_logger.dart';
import '../services/location_service.dart';
import '../services/context_alert_service.dart';
import '../../data/datasources/weather_api_client.dart';

/// App-level singleton that periodically fetches weather data and injects
/// it into [ContextAlertService].
///
/// Unlike the previous approach (which lived inside SettingsScreen and died
/// on navigation), this service persists for the app's entire lifecycle once
/// started, ensuring context-aware risk alerts always have fresh data.
class WeatherFeedService {
  WeatherFeedService({
    required LocationService locationService,
    required WeatherApiClient weatherApiClient,
    required ContextAlertService contextAlertService,
  })  : _locationService = locationService,
        _weatherApiClient = weatherApiClient,
        _contextAlertService = contextAlertService;

  final LocationService _locationService;
  final WeatherApiClient _weatherApiClient;
  final ContextAlertService _contextAlertService;
  Timer? _timer;

  /// Whether the feed is currently running.
  bool get isRunning => _timer != null;

  /// Start the periodic weather feed.
  ///
  /// Fetches GPS + weather immediately, then every [intervalMinutes].
  /// No-op if already running.
  void start({int? intervalMinutes}) {
    if (_timer != null) return;

    final interval = intervalMinutes ?? _contextAlertService.checkIntervalMinutes;

    // Fetch immediately.
    _fetchAndInject();

    _timer = Timer.periodic(
      Duration(minutes: interval),
      (_) => _fetchAndInject(),
    );

    AppLogger.info('[WeatherFeed] Started (interval: ${interval}min)');
  }

  /// Stop the periodic weather feed.
  void stop() {
    _timer?.cancel();
    _timer = null;
    AppLogger.info('[WeatherFeed] Stopped');
  }

  /// Single fetch cycle: GPS → Weather API → ContextAlertService fields.
  Future<void> _fetchAndInject() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) return;

      final weather = await _weatherApiClient.fetchCurrentWeather(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (weather != null) {
        _contextAlertService.currentTemperatureCelsius =
            weather.temperatureCelsius;
        _contextAlertService.currentWindSpeedKmh = weather.windSpeedKmh;
        _contextAlertService.currentPrecipitationMm = weather.precipitationMm;
        _contextAlertService.currentUvIndex = weather.uvIndex;
        _contextAlertService.currentSpeedKmh = pos.speed * 3.6; // m/s → km/h
      }
    } catch (e) {
      AppLogger.warning('[WeatherFeed] Fetch failed: $e');
    }
  }

  /// Release resources.
  void dispose() {
    stop();
  }
}
