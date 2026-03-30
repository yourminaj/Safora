/// External API endpoint URLs for disaster and weather data.
abstract final class ApiEndpoints {
  /// USGS GeoJSON API — returns earthquakes for past hour/day.
  static const String usgsEarthquakeHour =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson';
  static const String usgsEarthquakeDay =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  static const String usgsSignificantDay =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_day.geojson';

  /// Free weather API — no API key needed.
  static const String openMeteoForecast =
      'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoFlood =
      'https://flood-api.open-meteo.com/v1/flood';
  static const String openMeteoAirQuality =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  /// Global Disaster Alerting Coordination System.
  static const String gdacsFeed =
      'https://www.gdacs.org/xml/rss.xml';
  static const String gdacsJson =
      'https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH';

  /// Bangladesh Meteorological Department.
  static const String bmdBase = 'https://live2.bmd.gov.bd';

  /// Flood Forecasting & Warning Centre.
  /// NOTE: HTTP (not HTTPS) is intentional — this Bangladesh government site
  /// does not support TLS. Add NSAppTransportSecurity exception in iOS
  /// Info.plist and android:usesCleartextTraffic in AndroidManifest if needed.
  static const String ffwcBase = 'http://www.ffwc.gov.bd';

  /// Requires API key (free tier: 60 calls/min).
  static const String openWeatherCurrent =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String openWeatherForecast =
      'https://api.openweathermap.org/data/2.5/forecast';
  static const String openWeatherAirPollution =
      'https://api.openweathermap.org/data/2.5/air_pollution';

  /// Used for location sharing link in SMS.
  static String googleMapsLink(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';
}
