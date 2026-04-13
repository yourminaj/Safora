import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_logger.dart';

/// UMP (User Messaging Platform) consent management for GDPR/CCPA compliance.
///
/// Wraps the Google UMP SDK to handle:
/// - Consent information updates on every app launch
/// - Consent form display when required (EEA/UK users)
/// - Privacy options for settings screen (consent revocation)
/// - Consent-gated ad loading (`canRequestAds`)
///
/// Must be initialized before any ad requests are made.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  bool _canRequestAds = false;

  /// Whether the UMP SDK allows ad requests (consent obtained or not required).
  bool get canRequestAds => _canRequestAds;

  /// Initialize consent: request consent info update, then show form if needed.
  ///
  /// Returns `true` if ads can be requested after consent resolution.
  /// In debug mode with [debugEea] = true, simulates EEA geography for testing.
  Future<bool> initialize({bool debugEea = false}) async {
    final completer = Completer<bool>();

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: debugEea
                  ? DebugGeography.debugGeographyEea
                  : DebugGeography.debugGeographyDisabled,
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        // Consent info updated — load and show form if required.
        ConsentForm.loadAndShowConsentFormIfRequired(
          (formError) async {
            if (formError != null) {
              AppLogger.warning(
                '[ConsentService] Form error: ${formError.message}',
              );
            }
            _canRequestAds =
                await ConsentInformation.instance.canRequestAds();
            AppLogger.info(
              '[ConsentService] Consent resolved — canRequestAds: $_canRequestAds',
            );
            if (!completer.isCompleted) completer.complete(_canRequestAds);
          },
        );
      },
      (error) async {
        AppLogger.warning(
          '[ConsentService] Consent info update failed: ${error.message}',
        );
        // On failure, check if we can still request ads (e.g. previously consented).
        _canRequestAds =
            await ConsentInformation.instance.canRequestAds();
        if (!completer.isCompleted) completer.complete(_canRequestAds);
      },
    );

    return completer.future;
  }

  /// Whether a privacy options entry point is required (for settings screen).
  Future<bool> get isPrivacyOptionsRequired async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Show the privacy options form (consent revocation / modification).
  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((formError) async {
      if (formError != null) {
        AppLogger.warning(
          '[ConsentService] Privacy options form error: ${formError.message}',
        );
      }
      // Re-check consent state after user modifies privacy choices.
      _canRequestAds =
          await ConsentInformation.instance.canRequestAds();
      AppLogger.info(
        '[ConsentService] Privacy options closed — canRequestAds: $_canRequestAds',
      );
    });
  }

  /// Reset consent state for testing.
  ///
  /// Only resets the in-memory flag. Does NOT call
  /// `ConsentInformation.instance.reset()` to avoid platform channel
  /// errors in unit tests.
  @visibleForTesting
  void resetForTesting() {
    _canRequestAds = false;
  }
}
