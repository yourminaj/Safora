/// Real integration tests for VoiceDistressService fallback classification
/// and VoiceDistressEvent model behavior.
///
/// These tests use the REAL fallback classifier — no mocks, no stubs.
/// They verify the acoustic signal processing and distress detection
/// logic that runs when TFLite models are unavailable.
library;
import 'package:flutter_test/flutter_test.dart';

import 'package:safora/core/services/voice_distress_service.dart';
import 'package:safora/detection/ml/voice_distress_classifier.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  group('VoiceDistressEvent', () {
    test('alertType maps to voiceDistressSos', () {
      final event = VoiceDistressEvent(
        confidence: 0.85,
        source: 'tflite',
        detectedAt: DateTime.now(),
      );
      expect(event.alertType, AlertType.voiceDistressSos);
    });

    test('stores all fields correctly', () {
      final now = DateTime.now();
      final event = VoiceDistressEvent(
        confidence: 0.92,
        source: 'fallback',
        detectedAt: now,
      );
      expect(event.confidence, 0.92);
      expect(event.source, 'fallback');
      expect(event.detectedAt, now);
    });
  });

  group('VoiceDistressResult', () {
    test('isDistress true when confidence >= threshold (0.75)', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.80,
        normalConfidence: 0.20,
      );
      expect(result.isDistress, isTrue);
    });

    test('isDistress true at exact threshold boundary', () {
      const result = VoiceDistressResult(
        distressConfidence: VoiceDistressClassifier.alertThreshold,
        normalConfidence: 0.25,
      );
      expect(result.isDistress, isTrue);
    });

    test('isDistress false when below threshold', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.50,
        normalConfidence: 0.50,
      );
      expect(result.isDistress, isFalse);
    });

    test('toString contains both confidences', () {
      const result = VoiceDistressResult(
        distressConfidence: 0.815,
        normalConfidence: 0.185,
      );
      final s = result.toString();
      expect(s, contains('0.815'));
      expect(s, contains('0.185'));
      expect(s, contains('isDistress'));
    });
  });

  group('VoiceDistressFallback (real classifier, no mock)', () {
    test('empty samples return zero distress', () {
      final result = VoiceDistressFallback.classify([]);
      expect(result.distressConfidence, 0.0);
      expect(result.normalConfidence, 1.0);
      expect(result.isDistress, isFalse);
    });

    test('silence (all-zero samples) returns no distress', () {
      final silence = List<double>.filled(16000, 0.0);
      final result = VoiceDistressFallback.classify(silence);
      expect(result.distressConfidence, 0.0);
      expect(result.isDistress, isFalse);
    });

    test('low-amplitude noise does not trigger distress', () {
      // Simulate quiet background noise (amplitude 0.05)
      final noise = List<double>.generate(
        16000,
        (i) => (i % 3 == 0 ? 0.05 : -0.03),
      );
      final result = VoiceDistressFallback.classify(noise);
      expect(result.isDistress, isFalse);
    });

    test('high-energy high-ZCR signal triggers distress', () {
      // Simulate a scream: high amplitude + high-frequency oscillation
      // Alternating ±0.8 creates high ZCR + high RMS
      final scream = List<double>.generate(
        16000,
        (i) => (i.isEven ? 0.8 : -0.8),
      );
      final result = VoiceDistressFallback.classify(scream);
      expect(result.distressConfidence, greaterThan(0.0));
      // With alternating ±0.8: RMS ≈ 0.8 > 0.3 and ZCR ≈ 1.0 > 0.15
      expect(result.isDistress, isTrue);
    });

    test('high energy but low ZCR does NOT trigger (e.g., constant loud tone)', () {
      // All positive 0.5 = high RMS but zero ZCR
      final monotone = List<double>.filled(16000, 0.5);
      final result = VoiceDistressFallback.classify(monotone);
      expect(result.isDistress, isFalse);
    });

    test('low energy but high ZCR does NOT trigger (e.g., static)', () {
      // Alternating tiny values = high ZCR but low RMS
      final static_ = List<double>.generate(
        16000,
        (i) => (i.isEven ? 0.01 : -0.01),
      );
      final result = VoiceDistressFallback.classify(static_);
      expect(result.isDistress, isFalse);
    });
  });

  group('VoiceDistressClassifier constants', () {
    test('alertThreshold is 0.75', () {
      expect(VoiceDistressClassifier.alertThreshold, 0.75);
    });

    test('melBands is 40', () {
      expect(VoiceDistressClassifier.melBands, 40);
    });

    test('timeFrames is 32', () {
      expect(VoiceDistressClassifier.timeFrames, 32);
    });

    test('inputSize equals melBands * timeFrames', () {
      expect(
        VoiceDistressClassifier.inputSize,
        VoiceDistressClassifier.melBands * VoiceDistressClassifier.timeFrames,
      );
    });
  });

  group('VoiceDistressService architecture', () {
    // VoiceDistressService can't be instantiated in unit tests because
    // AudioRecorder requires native platform bindings. Instead we verify
    // the classifier's model contract and pipeline constants.
    test('model asset path is defined', () {
      expect(
        VoiceDistressClassifier.modelAssetPath,
        'assets/ml_models/voice_distress_model.tflite',
      );
    });

    test('classifier starts with no model loaded', () {
      final classifier = VoiceDistressClassifier();
      expect(classifier.isModelLoaded, isFalse);
      expect(classifier.activeModelSource, 'none');
    });

    test('classify returns null when model not loaded', () {
      final classifier = VoiceDistressClassifier();
      final features = List<double>.filled(
        VoiceDistressClassifier.inputSize,
        0.5,
      );
      expect(classifier.classify(features), isNull);
    });
  });
}
