# Flutter-specific ProGuard rules for Safora release builds.
# These prevent R8 from stripping classes used via reflection.

# ─── Flutter Engine ─────────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Hive (local storage) ──────────────────────────────────────
# Hive uses reflection for TypeAdapters; stripping breaks deserialization.
-keep class * extends com.hive.** { *; }
-keep class ** implements io.hive.** { *; }

# ─── flutter_local_notifications ───────────────────────────────
# Notification callbacks are resolved by class name at runtime.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ─── audioplayers ──────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }

# ─── Geolocator ───────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ─── url_launcher ─────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ─── connectivity_plus ────────────────────────────────────────
-keep class dev.fluttercommunity.plus.** { *; }

# ─── Google Fonts (HTTP downloads at runtime) ─────────────────
-keep class io.flutter.plugins.googlemobileads.** { *; }

# ─── General: keep Kotlin metadata (needed by some plugins) ───
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# ─── TFLite Flutter (ML crash/fall detection) ─────────────────
# Prevents R8 from stripping JNI bindings used by tflite_flutter plugin.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# ─── RevenueCat (in-app purchases & subscriptions) ────────────
# RevenueCat uses reflection for billing communication with Google Play.
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
-keep class com.android.vending.billing.** { *; }

# ─── Meta Audience Network (Facebook Ads) ─────────────────────
# Meta SDK references internal annotation classes not bundled in the SDK.
# These are compile-time annotations safe to suppress at runtime.
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode
-dontwarn com.facebook.infer.annotation.Nullsafe
-dontwarn com.facebook.infer.annotation.**
