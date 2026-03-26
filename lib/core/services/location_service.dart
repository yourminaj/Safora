import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/api_endpoints.dart';
import 'app_logger.dart';

/// Service for GPS location tracking and geocoding.
///
/// Handles permission requests, current position, reverse geocoding,
/// and Google Maps link generation for emergency SMS.
class LocationService {
  /// Current cached position (null until first fetch).
  Position? _lastPosition;

  /// Get the last known position without making a new request.
  Position? get lastPosition => _lastPosition;

  /// Check and request location permissions.
  ///
  /// Returns `true` if permission is granted.
  Future<bool> ensurePermission() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;

      // On Android 10+, request background location for SOS when app is minimized.
      if (permission == LocationPermission.whileInUse) {
        final bgPermission = await Geolocator.requestPermission();
        // Even if background is denied, foreground still works — just can't
        // get location when app is fully backgrounded.
        if (bgPermission == LocationPermission.always) {
          AppLogger.info('[Location] Background location granted');
        }
      }

      return true;
    } catch (e) {
      AppLogger.warning('[Location] Permission check failed: $e');
      return false;
    }
  }

  /// Get the current GPS position.
  ///
  /// Falls back to last known position if high-accuracy fails.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return _lastPosition;

    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _lastPosition;
    } catch (_) {
      // Fall back to last known.
      try {
        _lastPosition =
            await Geolocator.getLastKnownPosition() ?? _lastPosition;
      } catch (_) {
        // Ignore — keep whatever we have.
      }
      return _lastPosition;
    }
  }

  /// Reverse geocode a position to a human-readable address.
  Future<String?> getAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty);
        return parts.join(', ');
      }
    } catch (_) {
      // Geocoding failed — return null.
    }
    return null;
  }

  /// Generate a Google Maps link for the given position.
  String generateMapsLink(Position position) {
    return ApiEndpoints.googleMapsLink(position.latitude, position.longitude);
  }

  /// Build a full emergency location message.
  ///
  /// Example: "Location: Dhaka, Bangladesh\nhttps://maps.google.com/?q=23.81,90.41"
  Future<String> buildLocationMessage() async {
    final position = await getCurrentPosition();
    if (position == null) {
      return 'Location unavailable.';
    }

    final mapsLink = generateMapsLink(position);
    final address = await getAddress(position);

    if (address != null) {
      return 'Location: $address\n$mapsLink';
    }
    return 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n$mapsLink';
  }
}
