import 'package:equatable/equatable.dart';

/// Represents a single SOS activation event in history.
class SosHistoryEntry extends Equatable {
  const SosHistoryEntry({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.address,
    required this.contactsNotified,
    required this.smsSentCount,
    required this.wasCancelled,
    this.triggerSource = SosTriggerSource.manual,
  });

  /// When the SOS was activated.
  final DateTime timestamp;

  /// GPS coordinates at time of activation.
  final double? latitude;
  final double? longitude;

  /// Reverse-geocoded address (if available).
  final String? address;

  /// Number of contacts that were meant to be notified.
  final int contactsNotified;

  /// Number of SMS messages actually sent.
  final int smsSentCount;

  /// Whether the SOS was cancelled during countdown.
  final bool wasCancelled;

  /// What triggered the SOS.
  final SosTriggerSource triggerSource;

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'contactsNotified': contactsNotified,
        'smsSentCount': smsSentCount,
        'wasCancelled': wasCancelled,
        'triggerSource': triggerSource.name,
      };

  factory SosHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SosHistoryEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address'] as String?,
      contactsNotified: map['contactsNotified'] as int? ?? 0,
      smsSentCount: map['smsSentCount'] as int? ?? 0,
      wasCancelled: map['wasCancelled'] as bool? ?? false,
      triggerSource: SosTriggerSource.values.firstWhere(
        (e) => e.name == map['triggerSource'],
        orElse: () => SosTriggerSource.manual,
      ),
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
        latitude,
        longitude,
        contactsNotified,
        smsSentCount,
        wasCancelled,
        triggerSource,
      ];
}

/// How the SOS was triggered.
enum SosTriggerSource {
  /// User pressed the SOS button manually.
  manual,

  /// Triggered by shake detection.
  shake,

  /// Triggered by crash/fall detection engine.
  crashDetection,

  /// Triggered by fall detection (elderly safety).
  fall,

  /// Triggered by phone snatch detection.
  snatch,

  /// Triggered by voice distress detection.
  voiceDistress,

  /// Triggered by anomaly movement detection.
  anomalyMovement,

  /// Triggered by Dead Man's Switch expiry.
  deadManSwitch,

  /// Triggered by geofence zone exit.
  geofenceExit,

  /// Triggered by the foreground service.
  background,
}
