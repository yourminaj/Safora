import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_contact.dart';

/// Local data source for emergency contacts using Hive.
class ContactsLocalDataSource {
  ContactsLocalDataSource(this._box);

  final Box _box;

  static const String boxName = 'emergency_contacts';
  static const int maxFreeContacts = 3;

  /// Get all saved emergency contacts.
  List<EmergencyContact> getAll() {
    final contacts = <EmergencyContact>[];
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        contacts.add(EmergencyContact.fromMap(map, id: map['_id'] as String?));
      }
    }
    // Sort: primary first, then by creation time.
    contacts.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return (a.createdAt ?? DateTime(2000))
          .compareTo(b.createdAt ?? DateTime(2000));
    });
    return contacts;
  }

  /// Add a new emergency contact. Returns the assigned ID.
  ///
  /// Throws [ContactLimitException] if the free limit is reached.
  Future<String> add(EmergencyContact contact) async {
    if (_box.length >= maxFreeContacts) {
      throw ContactLimitException(
        'Maximum $maxFreeContacts contacts allowed on the free tier.',
      );
    }
    final id = const Uuid().v4();
    final data = contact.toMap();
    data['_id'] = id;
    await _box.put(id, data);
    return id;
  }

  /// Update an existing contact by ID.
  Future<void> update(EmergencyContact contact) async {
    if (contact.id == null) {
      throw ArgumentError('Contact must have an ID to be updated.');
    }
    final data = contact.toMap();
    data['_id'] = contact.id;
    await _box.put(contact.id, data);
  }

  /// Delete a contact by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Get a single contact by ID.
  EmergencyContact? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    return EmergencyContact.fromMap(map, id: map['_id'] as String?);
  }

  /// Number of stored contacts.
  int get count => _box.length;

  /// Whether the free contact limit has been reached.
  bool get isLimitReached => _box.length >= maxFreeContacts;
}

/// Exception thrown when the user has reached the max free contacts limit.
class ContactLimitException implements Exception {
  ContactLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}
