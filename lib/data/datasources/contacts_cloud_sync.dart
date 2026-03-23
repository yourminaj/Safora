import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/auth_service.dart';
import '../models/emergency_contact.dart';

/// Syncs emergency contacts between local Hive storage and Cloud Firestore.
///
/// Each user gets their own contacts subcollection:
///   `users/{uid}/emergency_contacts/{contactId}`
class ContactsCloudSync {
  ContactsCloudSync({
    required AuthService authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  /// Whether the user is authenticated (sync requires auth).
  bool get _canSync => _authService.isSignedIn;

  /// Get the user's contacts collection reference.
  CollectionReference<Map<String, dynamic>>? get _contactsRef {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('emergency_contacts');
  }

  /// Upload all local contacts to Firestore (overwrite cloud).
  Future<void> syncToCloud(List<EmergencyContact> localContacts) async {
    if (!_canSync) {
      AppLogger.warning('[CloudSync] Not authenticated, skipping upload');
      return;
    }

    final ref = _contactsRef;
    if (ref == null) return;

    try {
      // Use a batch write for atomicity.
      final batch = _firestore.batch();

      // Delete all existing cloud contacts first.
      final existing = await ref.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Write all local contacts.
      for (final contact in localContacts) {
        final docRef = ref.doc(contact.id ?? contact.phone);
        batch.set(docRef, {
          ...contact.toMap(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      AppLogger.info('[CloudSync] Uploaded ${localContacts.length} contacts');
    } catch (e) {
      AppLogger.error('[CloudSync] Upload failed: $e');
    }
  }

  /// Download all contacts from Firestore.
  Future<List<EmergencyContact>> syncFromCloud() async {
    if (!_canSync) return [];

    final ref = _contactsRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.orderBy('syncedAt').get();
      final contacts = snapshot.docs.map((doc) {
        return EmergencyContact.fromMap(doc.data(), id: doc.id);
      }).toList();

      AppLogger.info('[CloudSync] Downloaded ${contacts.length} contacts');
      return contacts;
    } catch (e) {
      AppLogger.error('[CloudSync] Download failed: $e');
      return [];
    }
  }
}
