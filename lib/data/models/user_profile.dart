import 'package:equatable/equatable.dart';

/// User's medical profile — shown to first responders during emergencies.
class UserProfile extends Equatable {
  const UserProfile({
    this.id,
    required this.fullName,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.medications = const [],
    this.emergencyNotes,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.organDonor = false,
  });

  final String? id;
  final String fullName;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> medications;
  final String? emergencyNotes;
  final DateTime? dateOfBirth;
  final double? weight; // in kg
  final double? height; // in cm
  final bool organDonor;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? medications,
    String? emergencyNotes,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    bool? organDonor,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      organDonor: organDonor ?? this.organDonor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'medications': medications,
      'emergencyNotes': emergencyNotes,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'weight': weight,
      'height': height,
      'organDonor': organDonor,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserProfile(
      id: id,
      fullName: map['fullName'] as String,
      bloodType: map['bloodType'] as String?,
      allergies: List<String>.from(map['allergies'] as List? ?? []),
      medicalConditions:
          List<String>.from(map['medicalConditions'] as List? ?? []),
      medications: List<String>.from(map['medications'] as List? ?? []),
      emergencyNotes: map['emergencyNotes'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      organDonor: map['organDonor'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        bloodType,
        allergies,
        medicalConditions,
        medications,
        organDonor,
      ];
}
