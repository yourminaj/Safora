import 'package:equatable/equatable.dart';

/// Represents an emergency contact who will be alerted during SOS.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
    this.createdAt,
  });

  /// Unique identifier (Firestore document ID).
  final String? id;

  /// Full name of the contact.
  final String name;

  /// Phone number (with country code, e.g. +8801XXXXXXXXX).
  final String phone;

  /// Relationship to the user (e.g. Mother, Brother, Friend).
  final String? relationship;

  /// Whether this is the primary contact (called first).
  final bool isPrimary;

  /// Timestamp when the contact was added.
  final DateTime? createdAt;

  /// Creates a copy with modified fields.
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Creates an instance from a Firestore document map.
  factory EmergencyContact.fromMap(Map<String, dynamic> map, {String? id}) {
    return EmergencyContact(
      id: id,
      name: map['name'] as String,
      phone: map['phone'] as String,
      relationship: map['relationship'] as String?,
      isPrimary: map['isPrimary'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, relationship, isPrimary];
}
