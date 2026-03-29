/**
 * Safora Safety Platform — Firebase Cloud Functions
 *
 * onSosTrigger:
 *   Triggered when a new SOS event is created in
 *   `users/{uid}/sos_events/{eventId}`.
 *
 *   Flow:
 *   1. Read the SOS event payload (location, triggerType, contactPhones)
 *   2. For each contact phone number, look up the matching Safora user
 *      who has registered as a safety contact (users collection, safetyContactPhone match)
 *   3. Send FCM push notification to all resolved tokens
 *   4. Update the SOS event document with fcmDeliveryCount for audit purposes
 *
 * onFcmTokenRefresh [Callable]:
 *   Called from the Flutter app when a user's FCM token refreshes.
 *   Writes the fresh token to users/{uid}.fcmToken.
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import * as messaging from "firebase-admin/messaging";

admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

// ──────────────────────────────────────────────────────────────────────────────
// TYPE DEFINITIONS
// ──────────────────────────────────────────────────────────────────────────────

interface SosEventPayload {
  triggeredAt: admin.firestore.Timestamp;
  triggerType: string;
  status: string;
  locationUrl: string | null;
  latitude: number | null;
  longitude: number | null;
  contactPhones: string[];
  contactCount: number;
}

interface UserRecord {
  fcmToken?: string;
  fcmPlatform?: string;
  safetyContactPhone?: string;
  displayName?: string;
  fcmTokenUpdatedAt?: admin.firestore.Timestamp;
}

// ──────────────────────────────────────────────────────────────────────────────
// N1: onSosTrigger — Firestore-triggered FCM push to safety contacts
// ──────────────────────────────────────────────────────────────────────────────

export const onSosTrigger = onDocumentCreated(
  {
    document: "users/{uid}/sos_events/{eventId}",
    region: "us-central1",
    timeoutSeconds: 60,
  },
  async (event) => {
    const uid = event.params.uid;
    const eventId = event.params.eventId;
    const sosData = event.data?.data() as SosEventPayload | undefined;

    if (!sosData) {
      logger.error(`[onSosTrigger] No data for event ${eventId}`);
      return;
    }

    logger.info(`[onSosTrigger] SOS fired by uid=${uid}, trigger=${sosData.triggerType}`);

    // 1. Get the sender's display name for the notification message.
    const senderDoc = await db.collection("users").doc(uid).get();
    const senderData = senderDoc.data() as UserRecord | undefined;
    const senderName = senderData?.displayName ?? "Your contact";

    // 2. Resolve contact phone numbers → FCM tokens.
    //    Each phone number in contactPhones is matched against all Safora
    //    users who have registered with that phone as their safetyContactPhone.
    const contactPhones: string[] = sosData.contactPhones ?? [];
    if (contactPhones.length === 0) {
      logger.info(`[onSosTrigger] No contact phones listed — skipping FCM`);
      return;
    }

    const tokenMap = new Map<string, string>(); // token → phone (for dedup)

    // Firestore 'in' supports max 30 values per query.
    const chunks = chunkArray(contactPhones, 30);

    for (const chunk of chunks) {
      const snap = await db
        .collection("users")
        .where("safetyContactPhone", "in", chunk)
        .get();

      for (const doc of snap.docs) {
        const data = doc.data() as UserRecord;
        if (data.fcmToken && data.fcmToken.length > 10) {
          // Avoid stale tokens older than 120 days
          const updatedAt = data.fcmTokenUpdatedAt?.toDate();
          const ageMs = updatedAt ? Date.now() - updatedAt.getTime() : 0;
          const staleCutoffMs = 120 * 24 * 60 * 60 * 1000;
          if (ageMs < staleCutoffMs) {
            tokenMap.set(data.fcmToken, data.safetyContactPhone ?? "");
          } else {
            logger.warn(`[onSosTrigger] Skipping stale FCM token for ${data.safetyContactPhone}`);
          }
        }
      }
    }

    const tokens = Array.from(tokenMap.keys());
    logger.info(`[onSosTrigger] Resolved ${tokens.length} FCM tokens from ${contactPhones.length} phones`);

    if (tokens.length === 0) {
      // No contacts have Safora installed — SMS is the fallback (handled by app).
      await db
        .collection("users")
        .doc(uid)
        .collection("sos_events")
        .doc(eventId)
        .update({ fcmDeliveryCount: 0, fcmStatus: "no_tokens" });
      return;
    }

    // 3. Build FCM message payload.
    const locationUrl = sosData.locationUrl ?? "Location unavailable";
    const messageBody =
      sosData.latitude != null
        ? `Emergency! ${senderName} needs help.\n📍 ${locationUrl}`
        : `Emergency! ${senderName} needs help. GPS location unavailable.`;

    // 4. Send FCM in batches of 500 (FCM API limit).
    let successCount = 0;
    let failureCount = 0;
    const tokenBatches = chunkArray(tokens, 500);

    for (const batch of tokenBatches) {
      const multicastMessage: messaging.MulticastMessage = {
        tokens: batch,
        notification: {
          title: `🚨 SOS — ${senderName} needs help!`,
          body: messageBody,
        },
        data: {
          type: "sos_alert",
          senderUid: uid,
          locationUrl: locationUrl,
          triggerType: sosData.triggerType,
          triggeredAt: sosData.triggeredAt.toDate().toISOString(),
          eventId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "sos_alerts",
            priority: "max",
            defaultSound: true,
            defaultVibrateTimings: true,
            notificationCount: 1,
            tag: `sos_${uid}`,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "sos_siren.caf",
              badge: 1,
              "content-available": 1,
              "mutable-content": 1,
            },
          },
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
        },
      };

      const batchResponse = await fcm.sendEachForMulticast(multicastMessage);
      successCount += batchResponse.successCount;
      failureCount += batchResponse.failureCount;

      // Log individual failures for monitoring.
      batchResponse.responses.forEach((resp, idx) => {
        if (!resp.success) {
          logger.warn(
            `[onSosTrigger] FCM failed for token[${idx}]: ${resp.error?.code} — ${resp.error?.message}`
          );
          // Handle invalid token cleanup
          if (
            resp.error?.code === "messaging/registration-token-not-registered" ||
            resp.error?.code === "messaging/invalid-registration-token"
          ) {
            const staleToken = batch[idx];
            cleanupStaleToken(staleToken).catch((e) =>
              logger.error(`[onSosTrigger] Token cleanup failed: ${e}`)
            );
          }
        }
      });
    }

    logger.info(
      `[onSosTrigger] FCM delivery complete — success=${successCount}, failed=${failureCount}`
    );

    // 5. Update the SOS event doc with delivery stats for audit.
    await db
      .collection("users")
      .doc(uid)
      .collection("sos_events")
      .doc(eventId)
      .update({
        fcmDeliveryCount: successCount,
        fcmFailureCount: failureCount,
        fcmStatus: successCount > 0 ? "delivered" : "failed",
        fcmDeliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// onFcmTokenRefresh — Callable: registers a fresh FCM token for the authed user
// ──────────────────────────────────────────────────────────────────────────────

export const onFcmTokenRefresh = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in to register FCM token");
    }

    const uid = request.auth.uid;
    const { fcmToken, safetyContactPhone, platform } = request.data as {
      fcmToken: string;
      safetyContactPhone?: string;
      platform?: string;
    };

    if (!fcmToken || fcmToken.length < 20) {
      throw new HttpsError("invalid-argument", "fcmToken is required and must be a valid token");
    }

    const updateData: Record<string, unknown> = {
      fcmToken,
      fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmPlatform: platform ?? "unknown",
    };

    if (safetyContactPhone) {
      updateData.safetyContactPhone = safetyContactPhone;
    }

    await db.collection("users").doc(uid).set(updateData, { merge: true });

    logger.info(`[onFcmTokenRefresh] Token updated for uid=${uid}, phone=${safetyContactPhone ?? "not set"}`);
    return { success: true };
  }
);

// ──────────────────────────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────────────────────────

/** Splits an array into fixed-size chunks. */
function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

/** Removes a stale FCM token from all user documents that have it. */
async function cleanupStaleToken(staleToken: string): Promise<void> {
  const snap = await db
    .collection("users")
    .where("fcmToken", "==", staleToken)
    .get();

  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      fcmToken: admin.firestore.FieldValue.delete(),
    });
  }
  if (!snap.empty) {
    await batch.commit();
    logger.info(`[cleanupStaleToken] Removed stale token from ${snap.size} user(s)`);
  }
}
