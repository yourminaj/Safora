/// Represents a nearby emergency point of interest (hospital, police, etc.)
///
/// Retrieved from the OpenStreetMap Overpass API.
class EmergencyPoi {
  const EmergencyPoi({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.distanceMeters,
  });

  final String name;
  final EmergencyPoiType type;
  final double latitude;
  final double longitude;
  final String? phone;
  final double? distanceMeters;

  /// Factory from Overpass JSON element.
  factory EmergencyPoi.fromOverpassElement(
    Map<String, dynamic> element,
    EmergencyPoiType type,
  ) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    final lat = (element['lat'] as num?)?.toDouble() ??
        (element['center']?['lat'] as num?)?.toDouble() ??
        0.0;
    final lon = (element['lon'] as num?)?.toDouble() ??
        (element['center']?['lon'] as num?)?.toDouble() ??
        0.0;

    return EmergencyPoi(
      name: (tags['name'] as String?) ??
          (tags['amenity'] as String?) ??
          type.label,
      type: type,
      latitude: lat,
      longitude: lon,
      phone: tags['phone'] as String?,
    );
  }

  @override
  String toString() => 'EmergencyPoi($name, $type, $latitude, $longitude)';
}

/// Types of emergency POIs.
enum EmergencyPoiType {
  hospital('Hospital'),
  policeStation('Police Station'),
  fireStation('Fire Station'),
  pharmacy('Pharmacy'),
  shelter('Emergency Shelter');

  const EmergencyPoiType(this.label);
  final String label;
}
