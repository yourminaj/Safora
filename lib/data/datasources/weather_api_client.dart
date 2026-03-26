import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/services/app_logger.dart';

/// Client for fetching current weather data from Open-Meteo API.
///
/// Used by [ContextAlertService] to feed real-time temperature, wind,
/// UV, and precipitation data for composite risk detection.
///
/// Open-Meteo requires no API key and has generous rate limits.
class WeatherApiClient {
  WeatherApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetch current weather conditions for the given coordinates.
  ///
  /// Returns a [WeatherData] snapshot or `null` on failure.
  Future<WeatherData?> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(ApiEndpoints.openMeteoForecast).replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,wind_speed_10m,precipitation,uv_index',
        'timezone': 'auto',
      },
    );

    try {
      final response = await _client.get(url).timeout(_timeout);
      if (response.statusCode != 200) {
        AppLogger.warning(
          '[Weather] API returned ${response.statusCode}',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      return WeatherData(
        temperatureCelsius: (current['temperature_2m'] as num?)?.toDouble(),
        windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
        precipitationMm: (current['precipitation'] as num?)?.toDouble(),
        uvIndex: (current['uv_index'] as num?)?.toDouble(),
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.warning('[Weather] Failed to fetch: $e');
      return null;
    }
  }

  /// Release HTTP client resources.
  void dispose() {
    _client.close();
  }
}

/// Snapshot of current weather conditions.
class WeatherData {
  const WeatherData({
    this.temperatureCelsius,
    this.windSpeedKmh,
    this.precipitationMm,
    this.uvIndex,
    required this.fetchedAt,
  });

  final double? temperatureCelsius;
  final double? windSpeedKmh;
  final double? precipitationMm;
  final double? uvIndex;
  final DateTime fetchedAt;

  @override
  String toString() =>
      'WeatherData(temp: $temperatureCelsius°C, wind: ${windSpeedKmh}km/h, '
      'rain: ${precipitationMm}mm, UV: $uvIndex)';
}
