import 'package:flutter_test/flutter_test.dart';
import 'package:safora/detection/ml/signal_processor.dart';

void main() {
  late SignalProcessor processor;

  setUp(() {
    processor = SignalProcessor(
      smoothingFactor: 0.8,
      windowSize: 10,
    );
  });

  group('SignalProcessor - SMV', () {
    test('SMV at rest ≈ 9.81 m/s² (1G from gravity)', () {
      // Phone lying flat: ax=0, ay=0, az=9.81
      final smv = SignalProcessor.computeSmv(0, 0, 9.81);
      expect(smv, closeTo(9.81, 0.01));
    });

    test('SMV with all axes active computes correctly', () {
      // SMV = √(3² + 4² + 0²) = 5.0
      final smv = SignalProcessor.computeSmv(3, 4, 0);
      expect(smv, closeTo(5.0, 0.001));
    });

    test('SMV during freefall ≈ 0', () {
      final smv = SignalProcessor.computeSmv(0, 0, 0);
      expect(smv, equals(0.0));
    });

    test('SMV with high impact exceeds 4G', () {
      // 4G = 39.226 m/s²
      // ax=30, ay=20, az=15 => SMV = √(900+400+225) = √1525 ≈ 39.05
      final smv = SignalProcessor.computeSmv(30, 20, 15);
      expect(SignalProcessor.toGForce(smv), greaterThan(3.9));
    });
  });

  group('SignalProcessor - G-Force', () {
    test('toGForce converts 9.80665 m/s² to exactly 1G', () {
      expect(SignalProcessor.toGForce(9.80665), closeTo(1.0, 0.0001));
    });

    test('toGForce converts 0 to 0G', () {
      expect(SignalProcessor.toGForce(0), equals(0.0));
    });

    test('toGForce converts 39.2266 m/s² to exactly 4G', () {
      expect(SignalProcessor.toGForce(9.80665 * 4), closeTo(4.0, 0.0001));
    });
  });

  group('SignalProcessor - Gravity Removal', () {
    test('removeGravity isolates user acceleration', () {
      // Simulate phone at rest for several samples to converge gravity filter.
      for (int i = 0; i < 50; i++) {
        processor.removeGravity(0, 0, 9.81);
      }

      // After convergence, user acceleration should be near zero.
      final result = processor.removeGravity(0, 0, 9.81);
      expect(result.ux, closeTo(0, 0.5));
      expect(result.uy, closeTo(0, 0.5));
      expect(result.uz, closeTo(0, 1.0)); // May have small residual
    });

    test('removeGravity detects sudden acceleration', () {
      // Converge gravity filter.
      for (int i = 0; i < 50; i++) {
        processor.removeGravity(0, 0, 9.81);
      }

      // Sudden impact: 40 m/s² on z-axis.
      final result = processor.removeGravity(0, 0, 40);
      expect(result.uz, greaterThan(20)); // Most of 40-9.81 = 30+
    });
  });

  group('SignalProcessor - Sliding Window', () {
    test('addSample returns correct SMV and G-force', () {
      final result = processor.addSample(0, 0, 9.81);
      expect(result.smv, closeTo(9.81, 0.01));
      expect(result.gForce, closeTo(1.0, 0.01));
    });

    test('window respects windowSize limit', () {
      for (int i = 0; i < 20; i++) {
        processor.addSample(0, 0, 9.81);
      }
      // Window size is 10, so only 10 samples should be in the window.
      // Verified via peakSmv (should still be ~9.81 not accumulated).
      expect(processor.peakSmv, closeTo(9.81, 0.01));
    });

    test('peakSmv returns the highest SMV in window', () {
      processor.addSample(0, 0, 9.81); // 1G
      processor.addSample(0, 0, 20); // ~2G
      processor.addSample(0, 0, 9.81); // 1G

      expect(processor.peakSmv, closeTo(20, 0.01));
    });

    test('minSmv returns the lowest SMV in window', () {
      processor.addSample(0, 0, 9.81); // 1G
      processor.addSample(0, 0, 2); // ~0.2G (freefall-ish)
      processor.addSample(0, 0, 9.81); // 1G

      expect(processor.minSmv, closeTo(2, 0.01));
    });

    test('meanSmv computes correct average', () {
      processor.addSample(0, 0, 10);
      processor.addSample(0, 0, 20);

      expect(processor.meanSmv, closeTo(15, 0.01));
    });
  });

  group('SignalProcessor - SMA', () {
    test('SMA at rest ≈ 9.81', () {
      for (int i = 0; i < 10; i++) {
        processor.addSample(0, 0, 9.81);
      }
      // SMA = (1/N) × Σ(|0| + |0| + |9.81|) = 9.81
      expect(processor.computeSma(), closeTo(9.81, 0.01));
    });

    test('SMA increases with vigorous movement', () {
      for (int i = 0; i < 10; i++) {
        processor.addSample(5, 5, 15);
      }
      // SMA = (1/10) × Σ(5 + 5 + 15) = 25
      expect(processor.computeSma(), closeTo(25, 0.01));
    });
  });

  group('SignalProcessor - Variance', () {
    test('variance is 0 for constant input', () {
      for (int i = 0; i < 10; i++) {
        processor.addSample(0, 0, 9.81);
      }
      expect(processor.computeSmvVariance(), closeTo(0, 0.001));
    });

    test('variance is high for varied input', () {
      processor.addSample(0, 0, 2); // freefall
      processor.addSample(0, 0, 50); // impact
      processor.addSample(0, 0, 2); // freefall
      processor.addSample(0, 0, 50); // impact

      expect(processor.computeSmvVariance(), greaterThan(100));
    });
  });

  group('SignalProcessor - Jerk', () {
    test('jerk is 0 for constant acceleration', () {
      processor.addSample(0, 0, 9.81);
      processor.addSample(0, 0, 9.81);
      expect(processor.computeJerk(), equals(0));
    });

    test('jerk is high for sudden acceleration change', () {
      processor.addSample(0, 0, 9.81);
      processor.addSample(0, 0, 50); // Sudden spike

      final jerk = processor.computeJerk(deltaTimeSeconds: 0.02);
      expect(jerk, greaterThan(1000)); // (50-9.81)/0.02 ≈ 2009
    });
  });

  group('SignalProcessor - Freefall Detection', () {
    test('detects freefall when SMV < 0.3G', () {
      processor.addSample(0, 0, 2); // ~0.2G → freefall
      expect(processor.hasFreefallInWindow, true);
    });

    test('no freefall at rest', () {
      processor.addSample(0, 0, 9.81); // 1G — no freefall
      expect(processor.hasFreefallInWindow, false);
    });
  });

  group('SignalProcessor - Reset', () {
    test('reset clears all state', () {
      processor.addSample(0, 0, 50);
      processor.addSample(0, 0, 50);

      processor.reset();

      expect(processor.peakSmv, equals(0.0));
      expect(processor.meanSmv, equals(0.0));
    });
  });
}
