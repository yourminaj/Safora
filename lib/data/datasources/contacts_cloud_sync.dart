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

  /// Upload all local contacts to Firestore using an atomic upsert strategy.
  ///
  /// Unlike the old delete-then-write approach, this never destroys data
  /// mid-operation. Each contact is written with [SetOptions.merge] so that
  /// only fields present in [localContacts] are updated.  Contacts that no
  /// longer exist locally are explicitly deleted in the same batch so the
  /// cloud state remains in sync.
  Future<void> syncToCloud(List<EmergencyContact> localContacts) async {
    if (!_canSync) {
      AppLogger.warning('[CloudSync] Not authenticated, skipping upload');
      return;
    }

    final ref = _contactsRef;
    if (ref == null) return;

    try {
      // Build a map of local contacts by their stable Firestore doc ID.
      final localById = <String, EmergencyContact>{
        for (final c in localContacts) (c.id ?? c.phone): c,
      };

      // Fetch existing cloud doc IDs so we can identify stale ones.
      final existing = await ref.get();
      final cloudIds = existing.docs.map((d) => d.id).toSet();

      final batch = _firestore.batch();

      // Upsert every local contact — merge:true means we never blank a
      // contact that may have been updated on another device mid-sync.
      for (final entry in localById.entries) {
        batch.set(
          ref.doc(entry.key),
          {
            ...entry.value.toMap(),
            'syncedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Delete cloud contacts that were removed locally.
      for (final cloudId in cloudIds) {
        if (!localById.containsKey(cloudId)) {
          batch.delete(ref.doc(cloudId));
        }
      }

      await batch.commit();
      AppLogger.info('[CloudSync] Upserted ${localById.length} contacts '
          '(removed ${cloudIds.difference(localById.keys.toSet()).length})');
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
      // No orderBy — 'syncedAt' may not exist on first write and would
      // throw an index error.  Local ordering is handled by the Hive layer.
      final snapshot = await ref.get();
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
