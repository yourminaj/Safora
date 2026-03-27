import 'package:flutter/material.dart';

/// Vector-drawn Safora brand mark: Shield + Heartbeat ECG line.
///
/// Renders at any [size] and [color] — perfect for colored backgrounds.
/// Uses [CustomPainter] so it scales cleanly with no bitmap artifacts.
///
/// Usage:
/// ```dart
/// SaforaBrandMark(size: 32, color: Colors.white)  // White on red AppBar
/// SaforaBrandMark(size: 64, color: AppColors.primary)  // Red on white card
/// ```
class SaforaBrandMark extends StatelessWidget {
  const SaforaBrandMark({
    super.key,
    this.size = 32,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldHeartbeatPainter(color: color),
      ),
    );
  }
}

class _ShieldHeartbeatPainter extends CustomPainter {
  _ShieldHeartbeatPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─── Shield Shape ──────────────────────────────────────
    final shieldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shield = Path()
      // Start at top center
      ..moveTo(w * 0.5, h * 0.08)
      // Left curve to left edge
      ..cubicTo(
        w * 0.35, h * 0.08,
        w * 0.12, h * 0.12,
        w * 0.12, h * 0.28,
      )
      // Left straight edge down
      ..lineTo(w * 0.12, h * 0.50)
      // Left bottom curve to point
      ..cubicTo(
        w * 0.12, h * 0.72,
        w * 0.30, h * 0.85,
        w * 0.50, h * 0.95,
      )
      // Right bottom curve from point
      ..cubicTo(
        w * 0.70, h * 0.85,
        w * 0.88, h * 0.72,
        w * 0.88, h * 0.50,
      )
      // Right straight edge up
      ..lineTo(w * 0.88, h * 0.28)
      // Right curve to top center
      ..cubicTo(
        w * 0.88, h * 0.12,
        w * 0.65, h * 0.08,
        w * 0.50, h * 0.08,
      )
      ..close();

    canvas.drawPath(shield, shieldPaint);

    // ─── Heartbeat ECG Line ────────────────────────────────
    // White or contrasting color on the shield
    final ecgPaint = Paint()
      ..color = color == Colors.white
          ? const Color(0xFFE53935) // Red ECG on white shield
          : Colors.white            // White ECG on colored shield
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ecg = Path()
      // Flat line from left
      ..moveTo(w * 0.18, h * 0.48)
      ..lineTo(w * 0.32, h * 0.48)
      // First small bump up
      ..lineTo(w * 0.36, h * 0.40)
      ..lineTo(w * 0.40, h * 0.48)
      // Big spike up
      ..lineTo(w * 0.44, h * 0.22)
      // Big spike down
      ..lineTo(w * 0.50, h * 0.65)
      // Recovery up
      ..lineTo(w * 0.55, h * 0.38)
      // Back to baseline
      ..lineTo(w * 0.60, h * 0.48)
      // Small dip
      ..lineTo(w * 0.64, h * 0.52)
      ..lineTo(w * 0.68, h * 0.48)
      // Flat line to right
      ..lineTo(w * 0.82, h * 0.48);

    canvas.drawPath(ecg, ecgPaint);
  }

  @override
  bool shouldRepaint(_ShieldHeartbeatPainter oldDelegate) =>
      oldDelegate.color != color;
}
