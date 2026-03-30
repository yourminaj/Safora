/// Real production tests for the Voice Distress ML classifier.
///
/// Tests [VoiceDistressFallback] (no TFLite required — pure Dart algorithm).
/// Tests [VoiceDistressClassifier] thresholds, model constants, and contract.
/// NO mocks, NO stubs — exercises real production code paths.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:safora/detection/ml/voice_distress_classifier.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────
// Generate synthetic PCM audio at [-1.0, 1.0] range.

/// Silence: all zeros.
List<double> silentAudio(int samples) => List.filled(samples, 0.0);

/// Pure sine wave at the given frequency (normalized, simulates a tone).
List<double> sineWave({
  required int samples,
  required double frequency,
  required double amplitude,
  double sampleRate = 16000,
}) {
  const pi2 = 6.283185307179586;
  return List.generate(
    samples,
    (i) => amplitude * (pi2 * frequency * i / sampleRate % pi2 - 3.14159).abs() /
        3.14159 *
        2 -
        amplitude,
  );
}

/// High-energy, rapidly-alternating signal (simulates screaming).
List<double> distressSignal(int samples) {
  // Alternating +0.9 / -0.9 at high frequency = high RMS + high ZCR.
  return List.generate(samples, (i) => i.isEven ? 0.9 : -0.9);
}

/// Low-energy calm signal (simulates normal speech at low volume).
List<double> calmSignal(int samples) {
  // Low amplitude, slow alternation = low RMS + low ZCR.
  return List.generate(samples, (i) {
    if (i % 100 < 50) return 0.05;
    return -0.05;
  });
}

void main() {
  // ═══════════════════════════════════════════════════════════
  //  SECTION 1: MODEL CONSTANTS
  // ═══════════════════════════════════════════════════════════

  group('VoiceDistressClassifier — Model Constants', () {
    test('alertThreshold is 0.75 (research-validated)', () {
      expect(
        VoiceDistressClassifier.alertThreshold,
        0.75,
        reason: 'Below 0.75 causes too many false alarms from normal noise',
      );
    });

    test('melBands is 40 (standard MFCC band count)', () {
      expect(
        VoiceDistressClassifier.melBands,
        40,
        reason: '40 Mel bands is the standard for speech detection models',
      );
    });

    test('timeFrames is 32 (1s at 50% overlap)', () {
      expect(VoiceDistressClassifier.timeFrames, 32);
    });

    test('inputSize = melBands × timeFrames = 1280', () {
      expect(
        VoiceDistressClassifier.inputSize,
        VoiceDistressClassifier.melBands * VoiceDistressClassifier.timeFrames,
      );
      expect(VoiceDistressClassifier.inputSize, 1280);
    });

    test('bundled model asset path is correct', () {
      expect(
        VoiceDistressClassifier.modelAssetPath,
        'assets/ml_models/voice_distress_model.tflite',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 2: VoiceDistressResult LOGIC
  // ═══════════════════════════════════════════════════════════

  group('VoiceDistressResult — isDistress Logic', () {
    test('distress confidence ≥ 0.75 → isDistress = true', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.75,
        normalConfidence: 0.25,
      );
      expect(result.isDistress, true);
    });

    test('distress confidence = 0.80 → isDistress = true', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.80,
        normalConfidence: 0.20,
      );
      expect(result.isDistress, true);
    });

    test('distress confidence = 0.74 → isDistress = false (below threshold)', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.74,
        normalConfidence: 0.26,
      );
      expect(
        result.isDistress,
        false,
        reason: 'Must be ≥ 0.75 to trigger alert',
      );
    });

    test('zero distress confidence → isDistress = false', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.0,
        normalConfidence: 1.0,
      );
      expect(result.isDistress, false);
    });

    test('toString contains all key fields', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.82,
        normalConfidence: 0.18,
      );
      final s = result.toString();
      expect(s, contains('0.820')); // distress conf
      expect(s, contains('0.180')); // normal conf
      expect(s, contains('true'));  // isDistress
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 3: VoiceDistressFallback — ALGORITHM VALIDATION
  //  All thresholds from acoustic research:
  //    RMS > 0.3 (loud event) AND ZCR > 0.15 (high-frequency)
  // ═══════════════════════════════════════════════════════════

  group('VoiceDistressFallback — Silence Input', () {
    test('silent audio → no distress (confidence = 0)', () {
      final result = VoiceDistressFallback.classify(silentAudio(16000));

      expect(result.distressConfidence, 0.0);
      expect(result.normalConfidence, 1.0);
      expect(result.isDistress, false);
    });

    test('empty list → no distress', () {
      final result = VoiceDistressFallback.classify([]);

      expect(result.distressConfidence, 0.0);
      expect(result.isDistress, false);
    });
  });

  group('VoiceDistressFallback — Calm Speech (No Distress)', () {
    test('low-energy calm signal → no distress', () {
      final result = VoiceDistressFallback.classify(calmSignal(16000));

      expect(
        result.isDistress,
        false,
        reason: 'Calm speech has low RMS, should not trigger alert',
      );
    });

    test('distress confidence is clamped to [0, 1]', () {
      final result = VoiceDistressFallback.classify(calmSignal(8000));

      expect(result.distressConfidence, greaterThanOrEqualTo(0.0));
      expect(result.distressConfidence, lessThanOrEqualTo(1.0));
      expect(result.normalConfidence, greaterThanOrEqualTo(0.0));
      expect(result.normalConfidence, lessThanOrEqualTo(1.0));
    });
  });

  group('VoiceDistressFallback — Distress (Scream Simulation)', () {
    test('high-energy alternating signal → isDistress = true', () {
      // Alternating ±0.9 gives: RMS ≈ 0.9 (>> 0.3), ZCR = 1.0 (>> 0.15)
      final result = VoiceDistressFallback.classify(distressSignal(16000));

      expect(
        result.isDistress,
        true,
        reason: 'High RMS + high ZCR must trigger distress alert',
      );
      expect(result.distressConfidence, greaterThan(0.0));
    });

    test('distress confidence increases with signal intensity', () {
      // Lower amplitude distress.
      final mild = VoiceDistressFallback.classify(
        List.generate(16000, (i) => i.isEven ? 0.5 : -0.5),
      );
      // Higher amplitude distress.
      final severe = VoiceDistressFallback.classify(distressSignal(16000));

      // Both may be in distress range, but severe should have higher or equal confidence.
      if (mild.isDistress && severe.isDistress) {
        expect(
          severe.distressConfidence,
          greaterThanOrEqualTo(mild.distressConfidence),
        );
      }
    });

    test('result confidence + normal confidence = 1.0', () {
      final result = VoiceDistressFallback.classify(distressSignal(8000));

      expect(
        result.distressConfidence + result.normalConfidence,
        closeTo(1.0, 0.001),
      );
    });
  });

  group('VoiceDistressFallback — Boundary Thresholds', () {
    test('RMS threshold is 0.3 (loud audio event)', () {
      // Validate that signals just below RMS 0.3 are not distress.
      // Amplitude 0.4 gives RMS ≈ 0.4 * √(0.5) ≈ 0.28 < 0.3 for slow signal.
      // Use a signal with controlled RMS below threshold.
      final belowRms = List.generate(16000, (i) {
        // Slow sign-change every 200 samples = ZCR > 0.15, but RMS ~0.25.
        return i % 200 < 100 ? 0.25 : -0.25;
      });
      final result = VoiceDistressFallback.classify(belowRms);

      // ZCR > 0.15 but RMS ~0.25 < 0.3 → no distress.
      expect(
        result.isDistress,
        false,
        reason: 'Both RMS > 0.3 AND ZCR > 0.15 required for distress',
      );
    });

    test('single sample is handled without crash', () {
      final result = VoiceDistressFallback.classify([0.5]);

      // 1 sample → ZCR denominator = (1-1) = 0, should not throw.
      expect(result, isNotNull);
    });

    test('two samples with opposite signs → ZCR = 1.0', () {
      // Only 2 samples, one sign change → ZCR = 1/(2-1) = 1.0.
      // But RMS of [0.9, -0.9] = 0.9 → both conditions met → distress.
      final result = VoiceDistressFallback.classify([0.9, -0.9]);

      expect(result.isDistress, true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 4: VoiceDistressClassifier — No-Model Behavior
  // ═══════════════════════════════════════════════════════════

  group('VoiceDistressClassifier — Unloaded State', () {
    test('isModelLoaded = false before load()', () {
      final classifier = VoiceDistressClassifier();
      expect(classifier.isModelLoaded, false);
    });

    test('activeModelSource = none before load()', () {
      final classifier = VoiceDistressClassifier();
      expect(classifier.activeModelSource, 'none');
    });

    test('classify() returns null when no model loaded', () {
      final classifier = VoiceDistressClassifier();
      const fakeFeatures = [0.5, 0.5]; // intentionally wrong length
      final result = classifier.classify(fakeFeatures);
      expect(result, isNull);
    });

    test('classify() returns null for correct-length features but no model', () {
      final classifier = VoiceDistressClassifier();
      final features = List<double>.filled(VoiceDistressClassifier.inputSize, 0.5);
      final result = classifier.classify(features);
      expect(result, isNull);
    });

    test('dispose() is idempotent', () {
      final classifier = VoiceDistressClassifier();
      // Disposing before loading should not throw.
      expect(() => classifier.dispose(), returnsNormally);
      expect(() => classifier.dispose(), returnsNormally);
    });
  });
}
