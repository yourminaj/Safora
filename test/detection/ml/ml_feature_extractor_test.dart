import 'package:flutter_test/flutter_test.dart';

import 'package:safora/detection/ml/ml_feature_extractor.dart';

void main() {
  group('MlFeatureExtractor Tests', () {
    final extractor = MlFeatureExtractor(samplingRateHz: 50);

    test('Returns null for insufficient samples', () {
      final result = extractor.extract(List.generate(5, (_) => (0.0, 0.0, 9.8)));
      expect(result, isNull);
    });

    test('Extracts 12 features for valid window', () {
      final samples = List.generate(50, (_) => (0.1, 0.1, 9.8));
      final result = extractor.extract(samples);
      expect(result, isNotNull);
      expect(result!.length, equals(12));
    });

    test('Normalization: Features are within [0, 1] range', () {
      // Test with extreme values
      final samples = [
        (0.0, 0.0, 0.0), // Zero
        (100.0, 100.0, 100.0), // High impact
        (-50.0, 20.0, -10.0), // Negative components
        (0.1, 0.1, 0.1), // Near zero
      ];
      // Padding to 50 samples
      final padded = List.generate(50, (i) => samples[i % samples.length]);
      
      final result = extractor.extract(padded);
      expect(result, isNotNull);
      for (final feature in result!) {
        expect(feature, greaterThanOrEqualTo(0.0));
        expect(feature, lessThanOrEqualTo(1.0));
      }
    });

    test('Freefall Detection: Returns high freefall ratio for low SMV', () {
      // SMV < 0.3G (approx 2.94 m/s^2)
      final samples = List.generate(20, (_) => (0.1, 0.1, 0.1));
      final result = extractor.extract(samples);
      
      // Index 8 is freefall ratio
      expect(result![8], equals(1.0));
    });

    test('Stillness Detection: Returns high stillness ratio for constant signal', () {
      final samples = List.generate(50, (_) => (0.0, 0.0, 9.80665));
      final result = extractor.extract(samples);
      
      // Index 9 is stillness ratio
      expect(result![9], equals(1.0));
    });

    test('Dominant Axis: Correctly identifies single-axis dominance', () {
      // Pure Z axis
      final samples = List.generate(20, (_) => (0.0, 0.0, 10.0));
      final result = extractor.extract(samples);
      
      // Index 10 is dominant axis ratio
      expect(result![10], closeTo(1.0, 0.01));
    });
  });
}
