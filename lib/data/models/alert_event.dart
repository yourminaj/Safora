import 'package:equatable/equatable.dart';
import '../../core/constants/alert_types.dart';

/// Represents a single alert/incident event.
class AlertEvent extends Equatable {
  const AlertEvent({
    this.id,
    required this.type,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.source,
    this.magnitude,
    this.isActive = true,
    this.isUserTriggered = false,
  });

  final String? id;
  final AlertType type;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? source; // e.g. 'USGS', 'BMD', 'user'
  final double? magnitude; // Earthquake magnitude, wind speed, etc.
  final bool isActive;
  final bool isUserTriggered;

  AlertEvent copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? source,
    double? magnitude,
    bool? isActive,
    bool? isUserTriggered,
  }) {
    return AlertEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      magnitude: magnitude ?? this.magnitude,
      isActive: isActive ?? this.isActive,
      isUserTriggered: isUserTriggered ?? this.isUserTriggered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'magnitude': magnitude,
      'isActive': isActive,
      'isUserTriggered': isUserTriggered,
    };
  }

  factory AlertEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return AlertEvent(
      id: id,
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.manualSos,
      ),
      title: map['title'] as String,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      source: map['source'] as String?,
      magnitude: (map['magnitude'] as num?)?.toDouble(),
      isActive: map['isActive'] as bool? ?? true,
      isUserTriggered: map['isUserTriggered'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, type, title, latitude, longitude, timestamp];
}
