import 'dart:math';
import 'signal_processor.dart';

/// Extracts a 12-feature vector from a window of raw accelerometer samples.
///
/// Features are designed for TFLite-based crash/fall classification and are
/// derived from established research (SisFall, MobiAct, IEEE WreckWatch).
///
/// ## Feature Vector (12 elements, Float32)
///
/// | Index | Feature                  | Description                              |
/// |-------|--------------------------|------------------------------------------|
/// | 0     | SMV mean                 | Average acceleration magnitude           |
/// | 1     | SMV max                  | Peak acceleration in window              |
/// | 2     | SMV min                  | Minimum acceleration in window           |
/// | 3     | SMV variance             | Spread of acceleration values            |
/// | 4     | SMV range                | max - min                                |
/// | 5     | SMA                      | Signal Magnitude Area (energy)           |
/// | 6     | Jerk mean                | Average rate of acceleration change      |
/// | 7     | Jerk max                 | Peak sudden acceleration spike           |
/// | 8     | Freefall ratio           | Fraction of window with SMV < 0.3G       |
/// | 9     | Stillness ratio          | Fraction of window with low variance     |
/// | 10    | Dominant axis ratio      | Max axis energy / total energy           |
/// | 11    | Zero-crossing rate       | Oscillation frequency indicator          |
///
/// Each feature is normalized to approximately [0, 1] using physically-sensible
/// scaling constants derived from research datasets.
class MlFeatureExtractor {
  MlFeatureExtractor({this.samplingRateHz = 50});

  /// Sensor sampling rate used for time-domain calculations.
  final int samplingRateHz;

  /// Number of features in the output vector.
  static const int featureCount = 12;

  /// Gravity constant (m/s²).
  static const double _gravity = 9.80665;

  /// Freefall threshold: SMV < 0.3 G.
  static const double _freefallThreshold = 0.3 * _gravity;

  /// Low-variance threshold for stillness (m/s²)².
  static const double _stillnessVarianceThreshold = 0.5;

  /// Extracts a 12-element feature vector from raw accelerometer samples.
  ///
  /// [samples] is a list of (ax, ay, az) tuples in m/s² with at least 10
  /// samples. Returns `null` if the window is too small.
  List<double>? extract(List<(double, double, double)> samples) {
    if (samples.length < 10) return null;

    final n = samples.length;
    final dt = 1.0 / samplingRateHz;

    // ── Compute per-sample SMV ──────────────────────────────
    final smvValues = <double>[];
    for (final (ax, ay, az) in samples) {
      smvValues.add(SignalProcessor.computeSmv(ax, ay, az));
    }

    // ── Basic statistics ────────────────────────────────────
    double smvSum = 0, smvMax = -double.infinity, smvMin = double.infinity;
    for (final v in smvValues) {
      smvSum += v;
      if (v > smvMax) smvMax = v;
      if (v < smvMin) smvMin = v;
    }
    final smvMean = smvSum / n;

    double varianceSum = 0;
    for (final v in smvValues) {
      varianceSum += (v - smvMean) * (v - smvMean);
    }
    final smvVariance = varianceSum / n;
    final smvRange = smvMax - smvMin;

    // ── SMA (Signal Magnitude Area) ─────────────────────────
    double sma = 0;
    for (final (ax, ay, az) in samples) {
      sma += (ax.abs() + ay.abs() + az.abs()) * dt;
    }

    // ── Jerk (rate of acceleration change) ──────────────────
    final jerkValues = <double>[];
    for (int i = 1; i < n; i++) {
      final (ax0, ay0, az0) = samples[i - 1];
      final (ax1, ay1, az1) = samples[i];
      final jx = (ax1 - ax0) / dt;
      final jy = (ay1 - ay0) / dt;
      final jz = (az1 - az0) / dt;
      jerkValues.add(sqrt(jx * jx + jy * jy + jz * jz));
    }
    double jerkMean = 0, jerkMax = 0;
    for (final j in jerkValues) {
      jerkMean += j;
      if (j > jerkMax) jerkMax = j;
    }
    jerkMean = jerkValues.isEmpty ? 0 : jerkMean / jerkValues.length;

    // ── Freefall ratio ──────────────────────────────────────
    int freefallCount = 0;
    for (final v in smvValues) {
      if (v < _freefallThreshold) freefallCount++;
    }
    final freefallRatio = freefallCount / n;

    // ── Stillness ratio (using sliding sub-windows of 10 samples) ─
    int stillnessCount = 0;
    const subWindowSize = 10;
    for (int i = 0; i <= n - subWindowSize; i++) {
      double subMean = 0;
      for (int j = i; j < i + subWindowSize; j++) {
        subMean += smvValues[j];
      }
      subMean /= subWindowSize;
      double subVar = 0;
      for (int j = i; j < i + subWindowSize; j++) {
        subVar += (smvValues[j] - subMean) * (smvValues[j] - subMean);
      }
      subVar /= subWindowSize;
      if (subVar < _stillnessVarianceThreshold) stillnessCount++;
    }
    final totalSubWindows = max(1, n - subWindowSize + 1);
    final stillnessRatio = stillnessCount / totalSubWindows;

    // ── Dominant axis ratio ─────────────────────────────────
    double energyX = 0, energyY = 0, energyZ = 0;
    for (final (ax, ay, az) in samples) {
      energyX += ax * ax;
      energyY += ay * ay;
      energyZ += az * az;
    }
    final totalEnergy = energyX + energyY + energyZ;
    final dominantAxisRatio =
        totalEnergy > 0 ? max(energyX, max(energyY, energyZ)) / totalEnergy : 0.33;

    // ── Zero-crossing rate ──────────────────────────────────
    int zeroCrossings = 0;
    for (int i = 1; i < smvValues.length; i++) {
      final prev = smvValues[i - 1] - smvMean;
      final curr = smvValues[i] - smvMean;
      if ((prev < 0 && curr >= 0) || (prev >= 0 && curr < 0)) {
        zeroCrossings++;
      }
    }
    final zeroCrossingRate = zeroCrossings / max(1, n - 1);

    // ── Normalize & return feature vector ───────────────────
    return [
      (smvMean / (10 * _gravity)).clamp(0.0, 1.0),      // 0: SMV mean
      (smvMax / (10 * _gravity)).clamp(0.0, 1.0),        // 1: SMV max
      (smvMin / (10 * _gravity)).clamp(0.0, 1.0),        // 2: SMV min
      (smvVariance / (100.0)).clamp(0.0, 1.0),           // 3: SMV variance
      (smvRange / (10 * _gravity)).clamp(0.0, 1.0),      // 4: SMV range
      (sma / (n * _gravity * dt * 3)).clamp(0.0, 1.0),   // 5: SMA
      (jerkMean / 1000.0).clamp(0.0, 1.0),               // 6: Jerk mean
      (jerkMax / 5000.0).clamp(0.0, 1.0),                // 7: Jerk max
      freefallRatio,                                       // 8: Freefall ratio
      stillnessRatio,                                      // 9: Stillness ratio
      dominantAxisRatio,                                   // 10: Dominant axis
      zeroCrossingRate,                                    // 11: ZCR
    ];
  }
}
