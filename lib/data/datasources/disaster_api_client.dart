import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/alert_types.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/app_logger.dart';
import '../models/alert_event.dart';

/// HTTP client for fetching disaster data from external APIs.
///
/// Sources:
/// - USGS: Earthquakes (GeoJSON)
/// - GDACS: Cyclones, floods, earthquakes (JSON)
/// - Open-Meteo: Flood risk (river discharge)
class DisasterApiClient {
  DisasterApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  // ─── USGS Earthquakes ────────────────────────────────────

  /// Fetch earthquakes from the last 24 hours.
  ///
  /// Returns [AlertEvent] list sorted by time (newest first).
  Future<List<AlertEvent>> fetchUsgsEarthquakes() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiEndpoints.usgsEarthquakeDay))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;

        return AlertEvent(
          id: (feature['id'])?.toString(),
          type: AlertType.earthquake,
          title: props['title'] as String? ?? 'Earthquake',
          description: props['place'] as String?,
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (props['time'] as num).toInt(),
          ),
          source: 'USGS',
          magnitude: (props['mag'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] USGS earthquakes fetch failed: $e');
      return [];
    }
  }

  /// Fetch only significant earthquakes from the last 24 hours.
  Future<List<AlertEvent>> fetchUsgsSignificant() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiEndpoints.usgsSignificantDay))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;

        return AlertEvent(
          id: (feature['id'])?.toString(),
          type: AlertType.earthquake,
          title: props['title'] as String? ?? 'Significant Earthquake',
          description: props['place'] as String?,
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (props['time'] as num).toInt(),
          ),
          source: 'USGS',
          magnitude: (props['mag'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] USGS significant fetch failed: $e');
      return [];
    }
  }

  // ─── GDACS (Global Disaster Alerts) ──────────────────────

  /// Fetch recent disaster events from GDACS.
  ///
  /// Includes earthquakes, tropical cyclones, and floods worldwide.
  Future<List<AlertEvent>> fetchGdacsEvents() async {
    try {
      final uri = Uri.parse(ApiEndpoints.gdacsJson).replace(
        queryParameters: {
          'fromDate': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String()
              .split('T')
              .first,
          'toDate': DateTime.now().toIso8601String().split('T').first,
          'alertlevel': 'Green;Orange;Red',
        },
      );

      final response =
          await _client.get(uri, headers: {
            'Accept': 'application/json',
          }).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (json['features'] as List<dynamic>?) ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>?;
        final coords = geometry?['coordinates'] as List<dynamic>?;

        final eventType = _gdacsEventTypeToAlertType(
          props['eventtype'] as String? ?? '',
        );

        return AlertEvent(
          id: props['eventid']?.toString(),
          type: eventType,
          title: props['name'] as String? ??
              props['eventtype'] as String? ??
              'Disaster Alert',
          description: props['description'] as String? ??
              props['country'] as String?,
          longitude: coords != null ? (coords[0] as num).toDouble() : 0,
          latitude: coords != null ? (coords[1] as num).toDouble() : 0,
          timestamp: DateTime.tryParse(
                  props['fromdate'] as String? ?? '') ??
              DateTime.now(),
          source: 'GDACS',
          magnitude: (props['severity'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] GDACS events fetch failed: $e');
      return [];
    }
  }

  AlertType _gdacsEventTypeToAlertType(String eventType) {
    return switch (eventType.toUpperCase()) {
      'EQ' => AlertType.earthquake,
      'TC' => AlertType.cyclone,
      'FL' => AlertType.flood,
      'VO' => AlertType.volcanicEruption,
      'DR' => AlertType.drought,
      'WF' => AlertType.wildfire,
      _ => AlertType.earthquake,
    };
  }

  // ─── Open-Meteo Flood ────────────────────────────────────

  /// Check flood risk at a specific location.
  ///
  /// Returns a list of flood alerts if river discharge exceeds threshold.
  Future<List<AlertEvent>> fetchFloodRisk({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.openMeteoFlood).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'daily': 'river_discharge',
          'forecast_days': '7',
        },
      );

      final response =
          await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>?;
      if (daily == null) return [];

      final times = daily['time'] as List<dynamic>? ?? [];
      final discharges =
          daily['river_discharge'] as List<dynamic>? ?? [];

      final alerts = <AlertEvent>[];

      for (int i = 0; i < times.length && i < discharges.length; i++) {
        final discharge = (discharges[i] as num?)?.toDouble() ?? 0;

        // High discharge threshold — rough heuristic for flood risk.
        if (discharge > 500) {
          alerts.add(AlertEvent(
            id: 'flood_${times[i]}',
            type: AlertType.flood,
            title: 'Flood Risk Alert',
            description:
                'River discharge: ${discharge.toStringAsFixed(0)} m³/s '
                'on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp:
                DateTime.tryParse(times[i] as String) ?? DateTime.now(),
            source: 'Open-Meteo',
            magnitude: discharge,
          ));
        }
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[DisasterAPI] Open-Meteo flood risk fetch failed: $e');
      return [];
    }
  }

  // ─── Open-Meteo Weather Alerts ──────────────────────────

  /// Fetch weather-based alerts for a specific location.
  ///
  /// Checks daily forecast for:
  /// - Extreme heat (>40°C)
  /// - Extreme cold (<-15°C)
  /// - Strong wind (>90 km/h)
  /// - Heavy precipitation / thunderstorm (>20mm/hr + wind >60 km/h)
  /// - Blizzard (>15cm snow/day + wind >50 km/h)
  /// - Dense fog (visibility <200m)
  /// - High UV (index >8)
  Future<List<AlertEvent>> fetchWeatherAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.openMeteoForecast).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'daily': [
            'temperature_2m_max',
            'temperature_2m_min',
            'wind_speed_10m_max',
            'precipitation_sum',
            'snowfall_sum',
            'uv_index_max',
          ].join(','),
          'hourly': 'visibility',
          'forecast_days': '3',
          'timezone': 'auto',
        },
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>?;
      final hourly = json['hourly'] as Map<String, dynamic>?;
      if (daily == null) return [];

      final times = daily['time'] as List<dynamic>? ?? [];
      final tempMax = daily['temperature_2m_max'] as List<dynamic>? ?? [];
      final tempMin = daily['temperature_2m_min'] as List<dynamic>? ?? [];
      final windMax = daily['wind_speed_10m_max'] as List<dynamic>? ?? [];
      final precip = daily['precipitation_sum'] as List<dynamic>? ?? [];
      final snow = daily['snowfall_sum'] as List<dynamic>? ?? [];
      final uvMax = daily['uv_index_max'] as List<dynamic>? ?? [];

      final alerts = <AlertEvent>[];

      for (int i = 0; i < times.length; i++) {
        final date =
            DateTime.tryParse(times[i] as String? ?? '') ?? DateTime.now();
        final maxTemp = (tempMax.length > i)
            ? (tempMax[i] as num?)?.toDouble()
            : null;
        final minTemp = (tempMin.length > i)
            ? (tempMin[i] as num?)?.toDouble()
            : null;
        final wind = (windMax.length > i)
            ? (windMax[i] as num?)?.toDouble()
            : null;
        final rain = (precip.length > i)
            ? (precip[i] as num?)?.toDouble()
            : null;
        final snowfall = (snow.length > i)
            ? (snow[i] as num?)?.toDouble()
            : null;
        final uv = (uvMax.length > i)
            ? (uvMax[i] as num?)?.toDouble()
            : null;

        // ── Extreme Heat (>40°C) ─────────────────────────
        if (maxTemp != null && maxTemp > 40) {
          alerts.add(AlertEvent(
            id: 'weather_heat_${times[i]}',
            type: AlertType.extremeHeat,
            title: 'Extreme Heat Warning',
            description:
                'Temperature forecast: ${maxTemp.toStringAsFixed(1)}°C '
                'on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: maxTemp,
          ));
        }

        // ── Extreme Cold (<-15°C) ────────────────────────
        if (minTemp != null && minTemp < -15) {
          alerts.add(AlertEvent(
            id: 'weather_cold_${times[i]}',
            type: AlertType.extremeCold,
            title: 'Extreme Cold Warning',
            description:
                'Temperature forecast: ${minTemp.toStringAsFixed(1)}°C '
                'on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: minTemp,
          ));
        }

        // ── Blizzard (snow >15cm + wind >50 km/h) ────────
        if (snowfall != null &&
            snowfall > 15 &&
            wind != null &&
            wind > 50) {
          alerts.add(AlertEvent(
            id: 'weather_blizzard_${times[i]}',
            type: AlertType.blizzard,
            title: 'Blizzard Warning',
            description:
                'Snowfall: ${snowfall.toStringAsFixed(0)}cm, '
                'Wind: ${wind.toStringAsFixed(0)} km/h on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: wind,
          ));
        }

        // ── Thunderstorm (rain >20mm + wind >60 km/h) ────
        if (rain != null &&
            rain > 20 &&
            wind != null &&
            wind > 60) {
          alerts.add(AlertEvent(
            id: 'weather_thunderstorm_${times[i]}',
            type: AlertType.thunderstorm,
            title: 'Thunderstorm Warning',
            description:
                'Precipitation: ${rain.toStringAsFixed(0)}mm, '
                'Wind: ${wind.toStringAsFixed(0)} km/h on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: wind,
          ));
        }

        // ── Strong Wind (>90 km/h) ──────────────────────
        if (wind != null && wind > 90) {
          alerts.add(AlertEvent(
            id: 'weather_wind_${times[i]}',
            type: AlertType.strongWind,
            title: 'Strong Wind Warning',
            description:
                'Wind speed: ${wind.toStringAsFixed(0)} km/h on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: wind,
          ));
        }

        // ── High UV (index >8) ──────────────────────────
        if (uv != null && uv > 8) {
          alerts.add(AlertEvent(
            id: 'weather_uv_${times[i]}',
            type: AlertType.uvRadiation,
            title: 'High UV Radiation',
            description:
                'UV index: ${uv.toStringAsFixed(1)} on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp: date,
            source: 'Open-Meteo',
            magnitude: uv,
          ));
        }
      }

      // ── Dense Fog (hourly visibility <200m) ───────────
      if (hourly != null) {
        final visTimes = hourly['time'] as List<dynamic>? ?? [];
        final visibility = hourly['visibility'] as List<dynamic>? ?? [];

        for (int i = 0; i < visTimes.length && i < visibility.length; i++) {
          final vis = (visibility[i] as num?)?.toDouble() ?? 10000;
          if (vis < 200) {
            final ts = DateTime.tryParse(
                    visTimes[i] as String? ?? '') ??
                DateTime.now();
            alerts.add(AlertEvent(
              id: 'weather_fog_${visTimes[i]}',
              type: AlertType.denseFog,
              title: 'Dense Fog Warning',
              description:
                  'Visibility: ${vis.toStringAsFixed(0)}m at ${visTimes[i]}',
              latitude: latitude,
              longitude: longitude,
              timestamp: ts,
              source: 'Open-Meteo',
              magnitude: vis,
            ));
            // Only report first fog event to avoid spamming.
            break;
          }
        }
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[DisasterAPI] Weather alerts fetch failed: $e');
      return [];
    }
  }

  // ─── Open-Meteo Air Quality ─────────────────────────────

  /// Fetch air quality alerts for a specific location.
  ///
  /// Checks for:
  /// - Hazardous air quality (European AQI >100 = very poor / hazardous)
  /// - Dust storm (PM10 >500 µg/m³)
  Future<List<AlertEvent>> fetchAirQualityAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.openMeteoAirQuality).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'hourly': 'european_aqi,pm10,pm2_5',
          'forecast_days': '2',
          'timezone': 'auto',
        },
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return [];

      final times = hourly['time'] as List<dynamic>? ?? [];
      final aqiValues = hourly['european_aqi'] as List<dynamic>? ?? [];
      final pm10Values = hourly['pm10'] as List<dynamic>? ?? [];

      final alerts = <AlertEvent>[];
      bool aqiAlerted = false;
      bool dustAlerted = false;

      for (int i = 0; i < times.length; i++) {
        final ts = DateTime.tryParse(times[i] as String? ?? '') ??
            DateTime.now();
        final aqi = (aqiValues.length > i)
            ? (aqiValues[i] as num?)?.toDouble()
            : null;
        final pm10 = (pm10Values.length > i)
            ? (pm10Values[i] as num?)?.toDouble()
            : null;

        // ── Hazardous Air Quality (European AQI >100) ────
        if (!aqiAlerted && aqi != null && aqi > 100) {
          alerts.add(AlertEvent(
            id: 'air_quality_${times[i]}',
            type: AlertType.airQuality,
            title: 'Hazardous Air Quality',
            description:
                'AQI: ${aqi.toStringAsFixed(0)} at ${times[i]}. '
                'Stay indoors and avoid exertion.',
            latitude: latitude,
            longitude: longitude,
            timestamp: ts,
            source: 'Open-Meteo',
            magnitude: aqi,
          ));
          aqiAlerted = true;
        }

        // ── Dust Storm (PM10 >500 µg/m³) ────────────────
        if (!dustAlerted && pm10 != null && pm10 > 500) {
          alerts.add(AlertEvent(
            id: 'dust_storm_${times[i]}',
            type: AlertType.dustStorm,
            title: 'Dust Storm Alert',
            description:
                'PM10: ${pm10.toStringAsFixed(0)} µg/m³ at ${times[i]}. '
                'Dangerous particulate levels.',
            latitude: latitude,
            longitude: longitude,
            timestamp: ts,
            source: 'Open-Meteo',
            magnitude: pm10,
          ));
          dustAlerted = true;
        }
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[DisasterAPI] Air quality fetch failed: $e');
      return [];
    }
  }

  // ─── NASA FIRMS Wildfire ─────────────────────────────────

  /// Fetch active wildfire hotspots near a location from NASA FIRMS.
  ///
  /// Uses MODIS/VIIRS satellite thermal detection within [radiusKm].
  /// Free API — no key needed for CSV format.
  Future<List<AlertEvent>> fetchWildfireHotspots({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
  }) async {
    try {
      // NASA FIRMS provides fire data via map key.
      // Use the open CSV endpoint for VIIRS data.
      final uri = Uri.parse(
        'https://firms.modaps.eosdis.nasa.gov/api/area/csv/'
        'b26b696f584a2b6cf8638c11b3e48612/VIIRS_SNPP_NRT/$latitude,$longitude,$radiusKm/1',
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final lines = response.body.split('\n');
      if (lines.length < 2) return [];

      // Parse CSV header.
      final headers = lines[0].split(',');
      final latIdx = headers.indexOf('latitude');
      final lngIdx = headers.indexOf('longitude');
      final dateIdx = headers.indexOf('acq_date');
      final confIdx = headers.indexOf('confidence');
      final brightIdx = headers.indexOf('bright_ti4');

      if (latIdx == -1 || lngIdx == -1) return [];

      final alerts = <AlertEvent>[];
      for (int i = 1; i < lines.length && i <= 10; i++) {
        if (lines[i].trim().isEmpty) continue;
        final cols = lines[i].split(',');
        if (cols.length <= lngIdx) continue;

        final fireLat = double.tryParse(cols[latIdx]) ?? 0;
        final fireLng = double.tryParse(cols[lngIdx]) ?? 0;
        final date = dateIdx >= 0 && cols.length > dateIdx
            ? DateTime.tryParse(cols[dateIdx])
            : null;
        final conf = confIdx >= 0 && cols.length > confIdx
            ? cols[confIdx]
            : 'unknown';
        final brightness = brightIdx >= 0 && cols.length > brightIdx
            ? double.tryParse(cols[brightIdx])
            : null;

        alerts.add(AlertEvent(
          id: 'fire_${fireLat}_${fireLng}_$i',
          type: AlertType.wildfire,
          title: 'Wildfire Detected Nearby',
          description:
              'Active fire hotspot detected by satellite. '
              'Confidence: $conf. '
              '${brightness != null ? "Brightness: ${brightness.toStringAsFixed(0)}K" : ""}',
          latitude: fireLat,
          longitude: fireLng,
          timestamp: date ?? DateTime.now(),
          source: 'NASA FIRMS',
          magnitude: brightness,
        ));
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[DisasterAPI] NASA FIRMS wildfire fetch failed: $e');
      return [];
    }
  }

  // ─── NASA EONET ─────────────────────────────────────────

  /// Fetch recent disaster events from NASA EONET (Earth Observatory).
  ///
  /// Includes wildfires, severe storms, volcanoes, sea/lake ice events.
  Future<List<AlertEvent>> fetchNasaEonetEvents() async {
    try {
      final uri = Uri.parse(
        'https://eonet.gsfc.nasa.gov/api/v3/events',
      ).replace(queryParameters: {
        'status': 'open',
        'limit': '20',
        'days': '7',
      });

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final events = json['events'] as List<dynamic>? ?? [];

      return events.map((e) {
        final event = e as Map<String, dynamic>;
        final categories = event['categories'] as List<dynamic>? ?? [];
        final catId = categories.isNotEmpty
            ? (categories[0] as Map<String, dynamic>)['id'] as String? ?? ''
            : '';
        final geometry = event['geometry'] as List<dynamic>?;
        final coords = geometry != null && geometry.isNotEmpty
            ? (geometry.last as Map<String, dynamic>)['coordinates']
                as List<dynamic>?
            : null;

        final alertType = _eonetCategoryToAlertType(catId);
        final date = geometry != null && geometry.isNotEmpty
            ? DateTime.tryParse(
                (geometry.last as Map<String, dynamic>)['date'] as String? ??
                    '')
            : null;

        return AlertEvent(
          id: event['id']?.toString(),
          type: alertType,
          title: event['title'] as String? ?? 'Natural Event',
          description: event['description'] as String?,
          longitude: coords != null ? (coords[0] as num).toDouble() : 0,
          latitude: coords != null ? (coords[1] as num).toDouble() : 0,
          timestamp: date ?? DateTime.now(),
          source: 'NASA EONET',
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] NASA EONET fetch failed: $e');
      return [];
    }
  }

  AlertType _eonetCategoryToAlertType(String categoryId) {
    return switch (categoryId) {
      'wildfires' => AlertType.wildfire,
      'volcanoes' => AlertType.volcanicEruption,
      'severeStorms' => AlertType.cyclone,
      'floods' => AlertType.flood,
      'earthquakes' => AlertType.earthquake,
      'landslides' => AlertType.landslide,
      'drought' => AlertType.drought,
      _ => AlertType.earthquake,
    };
  }

  /// Dispose HTTP client.
  void dispose() {
    _client.close();
  }
}
