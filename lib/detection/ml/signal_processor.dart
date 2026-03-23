import 'dart:math';

/// Real-time signal processing utilities for accelerometer/gyroscope data.
///
/// Implements research-backed algorithms:
/// - **SMV** (Signal Magnitude Vector): Combines 3-axis acceleration into
///   a single scalar representing total acceleration magnitude.
/// - **SMA** (Signal Magnitude Area): Accumulated area under the SMV curve,
///   indicating total energy over a window.
/// - **Low-pass filter**: Exponential smoothing to separate gravity from
///   user acceleration.
///
/// References:
/// - Biomedical Research (2017): SMV for fall detection
/// - IEEE (2020): Threshold-based + ML crash detection
class SignalProcessor {
  SignalProcessor({
    this.smoothingFactor = 0.8,
    this.windowSize = 50,
  });

  /// Smoothing factor for the exponential low-pass filter (0–1).
  /// Higher = more smoothing (slower response). 0.8 is standard for
  /// separating gravity from user acceleration at 50 Hz.
  final double smoothingFactor;

  /// Sliding window size (number of samples) for SMA and variance.
  final int windowSize;

  // Low-pass filter state (gravity estimate).
  double _gravityX = 0;
  double _gravityY = 0;
  double _gravityZ = 0;

  /// Sliding window of recent SMV values.
  final List<double> _smvWindow = [];

  /// Sliding window of recent raw acceleration tuples.
  final List<(double, double, double)> _rawWindow = [];

  /// Compute the Signal Magnitude Vector (SMV).
  ///
  /// SMV = √(ax² + ay² + az²)
  ///
  /// This is the standard metric used in accelerometer-based impact detection.
  /// At rest the SMV ≈ 9.81 m/s² (1 G) due to gravity.
  static double computeSmv(double ax, double ay, double az) {
    return sqrt(ax * ax + ay * ay + az * az);
  }

  /// Convert acceleration in m/s² to G-force.
  ///
  /// 1 G = 9.80665 m/s².
  static double toGForce(double accelerationMs2) {
    return accelerationMs2 / 9.80665;
  }

  /// Apply exponential low-pass filter to isolate gravity component.
  ///
  /// Returns the **user acceleration** (total – gravity) for each axis.
  /// This removes the constant gravitational pull so we detect only
  /// motion-induced acceleration.
  ({double ux, double uy, double uz}) removeGravity(
    double ax,
    double ay,
    double az,
  ) {
    _gravityX = smoothingFactor * _gravityX + (1 - smoothingFactor) * ax;
    _gravityY = smoothingFactor * _gravityY + (1 - smoothingFactor) * ay;
    _gravityZ = smoothingFactor * _gravityZ + (1 - smoothingFactor) * az;

    return (
      ux: ax - _gravityX,
      uy: ay - _gravityY,
      uz: az - _gravityZ,
    );
  }

  /// Process a new raw accelerometer sample and update the sliding window.
  ///
  /// Returns the current SMV and G-force values.
  ({double smv, double gForce}) addSample(double ax, double ay, double az) {
    final smv = computeSmv(ax, ay, az);
    final gForce = toGForce(smv);

    _smvWindow.add(smv);
    _rawWindow.add((ax, ay, az));

    // Keep window bounded.
    if (_smvWindow.length > windowSize) {
      _smvWindow.removeAt(0);
      _rawWindow.removeAt(0);
    }

    return (smv: smv, gForce: gForce);
  }

  /// Compute the Signal Magnitude Area (SMA) over the current window.
  ///
  /// SMA = (1/N) × Σ(|ax_i| + |ay_i| + |az_i|)
  ///
  /// Higher SMA indicates more overall movement energy, useful for
  /// distinguishing intentional activity from sudden impacts.
  double computeSma() {
    if (_rawWindow.isEmpty) return 0;
    double sum = 0;
    for (final (ax, ay, az) in _rawWindow) {
      sum += ax.abs() + ay.abs() + az.abs();
    }
    return sum / _rawWindow.length;
  }

  /// Compute variance of SMV over the current window.
  ///
  /// High variance after a spike indicates chaotic motion (crash).
  /// Low variance after a spike indicates stillness (fall → lying).
  double computeSmvVariance() {
    if (_smvWindow.length < 2) return 0;

    final mean = _smvWindow.reduce((a, b) => a + b) / _smvWindow.length;
    double sumSqDiff = 0;
    for (final v in _smvWindow) {
      sumSqDiff += (v - mean) * (v - mean);
    }
    return sumSqDiff / (_smvWindow.length - 1);
  }

  /// Get the peak SMV in the current window.
  double get peakSmv {
    if (_smvWindow.isEmpty) return 0;
    return _smvWindow.reduce(max);
  }

  /// Get the minimum SMV in the current window.
  ///
  /// A very low minimum (< 1 G) suggests freefall, which precedes impacts.
  double get minSmv {
    if (_smvWindow.isEmpty) return 0;
    return _smvWindow.reduce(min);
  }

  /// Get the mean SMV over the current window.
  double get meanSmv {
    if (_smvWindow.isEmpty) return 0;
    return _smvWindow.reduce((a, b) => a + b) / _smvWindow.length;
  }

  /// Compute the jerk magnitude (rate of change of acceleration).
  ///
  /// Jerk = |a(t) - a(t-1)| / Δt
  ///
  /// High jerk indicates a sudden change in acceleration (impact onset).
  /// Returns 0 if not enough samples.
  double computeJerk({double deltaTimeSeconds = 0.02}) {
    if (_smvWindow.length < 2) return 0;
    final current = _smvWindow.last;
    final previous = _smvWindow[_smvWindow.length - 2];
    return (current - previous).abs() / deltaTimeSeconds;
  }

  /// Check if the current window shows a freefall pattern.
  ///
  /// Freefall: SMV drops below 0.3 G (near-zero gravity).
  /// This precedes impact in both falls and vehicle crashes.
  bool get hasFreefallInWindow {
    return _smvWindow.any((smv) => toGForce(smv) < 0.3);
  }

  /// Check if the window shows post-impact stillness.
  ///
  /// Post-impact stillness: SMV variance < threshold AND mean ≈ 1 G.
  /// Indicates the person/phone is stationary after impact.
  bool get hasPostImpactStillness {
    if (_smvWindow.length < windowSize ~/ 2) return false;

    // Check the latter half of the window for stillness.
    final latterHalf = _smvWindow.sublist(_smvWindow.length ~/ 2);
    final mean = latterHalf.reduce((a, b) => a + b) / latterHalf.length;
    final meanG = toGForce(mean);

    double variance = 0;
    for (final v in latterHalf) {
      variance += (v - mean) * (v - mean);
    }
    variance /= latterHalf.length;

    // Stillness: mean ≈ 1G (0.7–1.3G) and low variance.
    return meanG > 0.7 && meanG < 1.3 && variance < 2.0;
  }

  /// Reset all internal state.
  void reset() {
    _gravityX = 0;
    _gravityY = 0;
    _gravityZ = 0;
    _smvWindow.clear();
    _rawWindow.clear();
  }
}
