import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safora/data/datasources/weather_api_client.dart';

void main() {
  group('WeatherApiClient', () {
    test('fetchCurrentWeather returns WeatherData on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['latitude'], isNotEmpty);
        expect(request.url.queryParameters['longitude'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 32.5,
              'wind_speed_10m': 15.0,
              'precipitation': 0.0,
              'uv_index': 7.2,
            },
          }),
          200,
        );
      });

      final client = WeatherApiClient(client: mockClient);
      final result = await client.fetchCurrentWeather(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(result, isNotNull);
      expect(result!.temperatureCelsius, 32.5);
      expect(result.windSpeedKmh, 15.0);
      expect(result.precipitationMm, 0.0);
      expect(result.uvIndex, 7.2);
    });

    test('fetchCurrentWeather returns null on non-200 response', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Server Error', 500);
      });

      final client = WeatherApiClient(client: mockClient);
      final result = await client.fetchCurrentWeather(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(result, isNull);
    });

    test('fetchCurrentWeather returns null when current is missing', () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'hourly': {}}), 200);
      });

      final client = WeatherApiClient(client: mockClient);
      final result = await client.fetchCurrentWeather(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(result, isNull);
    });

    test('fetchCurrentWeather returns null on network error', () async {
      final mockClient = MockClient((_) async {
        throw Exception('No internet');
      });

      final client = WeatherApiClient(client: mockClient);
      final result = await client.fetchCurrentWeather(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(result, isNull);
    });

    test('fetchCurrentWeather handles partial weather data', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 28.0,
              // wind_speed_10m, precipitation, uv_index missing
            },
          }),
          200,
        );
      });

      final client = WeatherApiClient(client: mockClient);
      final result = await client.fetchCurrentWeather(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(result, isNotNull);
      expect(result!.temperatureCelsius, 28.0);
      expect(result.windSpeedKmh, isNull);
      expect(result.precipitationMm, isNull);
      expect(result.uvIndex, isNull);
    });

    test('WeatherData toString includes all fields', () {
      final data = WeatherData(
        temperatureCelsius: 35.0,
        windSpeedKmh: 20.0,
        precipitationMm: 5.0,
        uvIndex: 8.0,
        fetchedAt: DateTime(2026, 3, 26),
      );
      final s = data.toString();
      expect(s, contains('35.0'));
      expect(s, contains('20.0'));
    });

    test('dispose closes the HTTP client', () {
      // Verify dispose doesn't throw.
      final client = WeatherApiClient();
      expect(() => client.dispose(), returnsNormally);
    });
  });
}
