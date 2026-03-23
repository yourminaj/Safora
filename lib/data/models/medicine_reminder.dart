import 'package:equatable/equatable.dart';

/// Represents a scheduled medicine/supplement reminder.
class MedicineReminder extends Equatable {
  const MedicineReminder({
    this.id,
    required this.name,
    required this.dosage,
    required this.timeOfDay,
    this.frequency = ReminderFrequency.daily,
    this.notes,
    this.isActive = true,
    this.createdAt,
  });

  /// Unique identifier (Hive box key).
  final String? id;

  /// Medicine or supplement name.
  final String name;

  /// Dosage info (e.g., "500mg", "2 tablets").
  final String dosage;

  /// Time of day to take (stored as "HH:mm").
  final String timeOfDay;

  /// How often the reminder repeats.
  final ReminderFrequency frequency;

  /// Additional notes (e.g., "take with food").
  final String? notes;

  /// Whether this reminder is currently active.
  final bool isActive;

  /// When the reminder was created.
  final DateTime? createdAt;

  /// Parse the timeOfDay string into hour and minute.
  ({int hour, int minute}) get timeParts {
    final parts = timeOfDay.split(':');
    return (
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  MedicineReminder copyWith({
    String? id,
    String? name,
    String? dosage,
    String? timeOfDay,
    ReminderFrequency? frequency,
    String? Function()? notes,
    bool? isActive,
  }) {
    return MedicineReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      frequency: frequency ?? this.frequency,
      notes: notes != null ? notes() : this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'timeOfDay': timeOfDay,
        'frequency': frequency.name,
        'notes': notes,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory MedicineReminder.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return MedicineReminder(
      id: id,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      timeOfDay: map['timeOfDay'] as String? ?? '08:00',
      frequency: ReminderFrequency.values.firstWhere(
        (f) => f.name == (map['frequency'] as String?),
        orElse: () => ReminderFrequency.daily,
      ),
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, dosage, timeOfDay, frequency, notes, isActive];
}

/// How often a medicine reminder repeats.
enum ReminderFrequency {
  daily,
  twiceDaily,
  weekly,
  asNeeded;

  String get displayName => switch (this) {
        daily => 'Once daily',
        twiceDaily => 'Twice daily',
        weekly => 'Weekly',
        asNeeded => 'As needed',
      };
}
