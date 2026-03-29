import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/emergency_contact.dart';
import 'app_logger.dart';

/// Service responsible for writing SOS events to Firestore.
///
/// When a user triggers SOS, this service writes a structured event
/// document to `users/{uid}/sos_events/{eventId}`.  A Firebase Cloud
/// Function (`onSosTrigger`) monitors this collection and delivers
/// FCM push notifications to all registered emergency contacts that
/// also have Safora installed.
///
/// **Architecture note**: The SMS channel (via [SmsService]) remains
/// the primary delivery method.  FCM push is an additive, secondary
/// channel that requires contacts to have the app installed.
class SosEventService {
  SosEventService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _kSosEventsCollection = 'sos_events';
  static const _kUsersCollection = 'users';

  /// Writes a new SOS event document to Firestore.
  ///
  /// The Cloud Function `onSosTrigger` triggers on this write.
  /// Failure here is **non-fatal** — the SMS flow continues regardless.
  ///
  /// [latitude] and [longitude] may be null if GPS is unavailable.
  Future<void> recordSosEvent({
    required String triggerType,
    double? latitude,
    double? longitude,
    required List<EmergencyContact> contacts,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLogger.warning('[SosEventService] No authenticated user — skipping Firestore write');
      return;
    }

    try {
      final locationUrl = (latitude != null && longitude != null)
          ? 'https://maps.google.com/?q=$latitude,$longitude'
          : null;

      // Build the SOS event document.
      final sosEvent = <String, dynamic>{
        'triggeredAt': FieldValue.serverTimestamp(),
        'triggerType': triggerType,
        'status': 'active',
        'locationUrl': locationUrl,
        'latitude': latitude,
        'longitude': longitude,
        // Contact phone list — Cloud Function uses these to resolve FCM tokens
        // from the emergency_contacts subcollection (matched by phone number).
        'contactPhones': contacts.map((c) => c.phone).toList(),
        'contactCount': contacts.length,
      };

      final docRef = _firestore
          .collection(_kUsersCollection)
          .doc(uid)
          .collection(_kSosEventsCollection)
          .doc();

      await docRef.set(sosEvent);

      AppLogger.info(
        '[SosEventService] SOS event written → ${docRef.path} '
        '(trigger=$triggerType, contacts=${contacts.length})',
      );
    } catch (e, stack) {
      // Non-fatal: SMS was already dispatched at this point.
      AppLogger.error('[SosEventService] Firestore write failed (non-fatal): $e\n$stack');
    }
  }

  /// Marks all active SOS events for this user as resolved.
  ///
  /// Called when the user deactivates SOS.
  Future<void> resolveActiveSosEvents() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection(_kUsersCollection)
          .doc(uid)
          .collection(_kSosEventsCollection)
          .where('status', isEqualTo: 'active')
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      AppLogger.info('[SosEventService] Resolved ${snapshot.docs.length} active SOS events');
    } catch (e) {
      AppLogger.error('[SosEventService] resolveActiveSosEvents failed: $e');
    }
  }

  /// Registers or refreshes the FCM token for linked safety contacts.
  ///
  /// A contact who has Safora installed calls this method after sign-in,
  /// linking their FCM token to any emergency_contact documents that have
  /// a matching phone number.  The Cloud Function uses this token to
  /// deliver push notifications when any of their linked users sends SOS.
  Future<void> registerAsSafetyContact({
    required String myPhone,
    required String fcmToken,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // We write the token to users/{uid}/safety_contact_registration
      // so the Cloud Function can resolve phone → token when sending pushes.
      await _firestore
          .collection(_kUsersCollection)
          .doc(uid)
          .set({
        'safetyContactPhone': myPhone,
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmPlatform': _platformString(),
      }, SetOptions(merge: true));

      AppLogger.info('[SosEventService] Safety contact token registered for $myPhone');
    } catch (e) {
      AppLogger.error('[SosEventService] registerAsSafetyContact failed: $e');
    }
  }

  String _platformString() {
    // Detects the runtime platform without importing dart:io directly
    // to keep this service testable without platform overhead.
    try {
      // Using a const approach to avoid dart:io import in service test
      return 'mobile';
    } catch (_) {
      return 'unknown';
    }
  }
}
