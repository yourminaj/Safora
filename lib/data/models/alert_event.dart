import 'package:equatable/equatable.dart';
import '../../core/constants/alert_types.dart';

/// Represents a single alert/incident event.
///
/// Every alert answers 4 questions:
/// 1. What is happening? → [type] + [title]
/// 2. How serious is it for me? → [riskScore] + [distanceKm]
/// 3. What should I do now? → [actionAdvice]
/// 4. How sure are you? → [confidenceLevel]
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
    this.confidenceLevel,
    this.expiresAt,
    this.actionAdvice,
    this.distanceKm,
    this.riskScore,
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

  /// Confidence level of the alert source (0.0 = unknown, 1.0 = verified).
  final double? confidenceLevel;

  /// When this alert auto-expires (e.g. road closure for 45 minutes).
  final DateTime? expiresAt;

  /// Actionable advice: "Avoid Route A for 45 minutes".
  final String? actionAdvice;

  /// Distance in km from user's current position.
  final double? distanceKm;

  /// Composite risk score 0-100. Computed by RiskScoreEngine.
  final int? riskScore;

  /// Whether this alert has expired based on [expiresAt].
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Human-readable confidence label.
  String get confidenceLabel {
    final c = confidenceLevel ?? 0.0;
    if (c >= 0.8) return 'High confidence';
    if (c >= 0.5) return 'Medium confidence';
    if (c >= 0.3) return 'Low confidence';
    return 'Unverified';
  }

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
    double? confidenceLevel,
    DateTime? expiresAt,
    String? actionAdvice,
    double? distanceKm,
    int? riskScore,
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
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      expiresAt: expiresAt ?? this.expiresAt,
      actionAdvice: actionAdvice ?? this.actionAdvice,
      distanceKm: distanceKm ?? this.distanceKm,
      riskScore: riskScore ?? this.riskScore,
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
      'confidenceLevel': confidenceLevel,
      'expiresAt': expiresAt?.toIso8601String(),
      'actionAdvice': actionAdvice,
      'distanceKm': distanceKm,
      'riskScore': riskScore,
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
      confidenceLevel: (map['confidenceLevel'] as num?)?.toDouble(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      actionAdvice: map['actionAdvice'] as String?,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      riskScore: map['riskScore'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, latitude, longitude, timestamp, riskScore];
}

