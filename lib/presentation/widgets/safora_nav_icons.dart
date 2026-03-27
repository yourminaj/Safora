import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

// ═══════════════════════════════════════════════════════════════════
//  SAFORA CUSTOM NAVIGATION ICONS
//  Brand-consistent vector-drawn icons for the bottom nav bar.
//  Each icon has an active (filled) and inactive (outline) state.
// ═══════════════════════════════════════════════════════════════════

/// Custom nav icon that renders via CustomPainter.
class SaforaNavIcon extends StatelessWidget {
  const SaforaNavIcon({
    super.key,
    required this.type,
    this.isActive = false,
    this.color,
    this.size = 24,
  });

  final SaforaNavIconType type;
  final bool isActive;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isActive ? AppColors.primary : AppColors.textSecondary);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NavIconPainter(
          type: type,
          isActive: isActive,
          color: effectiveColor,
        ),
      ),
    );
  }
}

enum SaforaNavIconType { home, alerts, contacts, map, more }

class _NavIconPainter extends CustomPainter {
  _NavIconPainter({
    required this.type,
    required this.isActive,
    required this.color,
  });

  final SaforaNavIconType type;
  final bool isActive;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case SaforaNavIconType.home:
        _paintHome(canvas, size);
      case SaforaNavIconType.alerts:
        _paintAlerts(canvas, size);
      case SaforaNavIconType.contacts:
        _paintContacts(canvas, size);
      case SaforaNavIconType.map:
        _paintMap(canvas, size);
      case SaforaNavIconType.more:
        _paintMore(canvas, size);
    }
  }

  /// HOME — Shield shape (brand signature)
  void _paintHome(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shield = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..cubicTo(w * 0.33, h * 0.08, w * 0.12, h * 0.12, w * 0.12, h * 0.28)
      ..lineTo(w * 0.12, h * 0.50)
      ..cubicTo(w * 0.12, h * 0.72, w * 0.30, h * 0.84, w * 0.50, h * 0.95)
      ..cubicTo(w * 0.70, h * 0.84, w * 0.88, h * 0.72, w * 0.88, h * 0.50)
      ..lineTo(w * 0.88, h * 0.28)
      ..cubicTo(w * 0.88, h * 0.12, w * 0.67, h * 0.08, w * 0.50, h * 0.08)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = w * 0.07;

    canvas.drawPath(shield, paint);

    // Small ECG line if active
    if (isActive) {
      final ecgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final yBase = h * 0.45;
      final ecg = Path()
        ..moveTo(w * 0.22, yBase)
        ..lineTo(w * 0.35, yBase)
        ..lineTo(w * 0.40, yBase - h * 0.10)
        ..lineTo(w * 0.48, yBase + h * 0.10)
        ..lineTo(w * 0.55, yBase - h * 0.04)
        ..lineTo(w * 0.60, yBase)
        ..lineTo(w * 0.78, yBase);
      canvas.drawPath(ecg, ecgPaint);
    }
  }

  /// ALERTS — Bell with pulse wave
  void _paintAlerts(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Bell body
    final bell = Path()
      ..moveTo(w * 0.2, h * 0.65)
      ..cubicTo(w * 0.2, h * 0.55, w * 0.22, h * 0.35, w * 0.3, h * 0.28)
      ..cubicTo(w * 0.35, h * 0.22, w * 0.42, h * 0.18, cx, h * 0.16)
      ..cubicTo(w * 0.58, h * 0.18, w * 0.65, h * 0.22, w * 0.7, h * 0.28)
      ..cubicTo(w * 0.78, h * 0.35, w * 0.8, h * 0.55, w * 0.8, h * 0.65)
      ..lineTo(w * 0.85, h * 0.72)
      ..lineTo(w * 0.15, h * 0.72)
      ..close();

    canvas.drawPath(bell, Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = w * 0.06);

    // Bell clapper
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.82), width: w * 0.22, height: h * 0.1),
      Paint()
        ..color = color
        ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = w * 0.05,
    );

    // Top nub
    canvas.drawCircle(
      Offset(cx, h * 0.12),
      w * 0.04,
      Paint()..color = color,
    );

    // Pulse waves (right side only, when active)
    if (isActive) {
      final wavePaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.82, h * 0.35), width: w * 0.2, height: h * 0.2),
        -0.8, 1.6, false, wavePaint,
      );
    }
  }

  /// CONTACTS — Person silhouette with shield badge
  void _paintContacts(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Head
    canvas.drawCircle(
      Offset(cx - w * 0.06, h * 0.28),
      w * 0.16,
      Paint()
        ..color = color
        ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = w * 0.06,
    );

    // Body (shoulders arc)
    final body = Path()
      ..moveTo(w * 0.05, h * 0.88)
      ..cubicTo(w * 0.05, h * 0.60, w * 0.2, h * 0.50, cx - w * 0.06, h * 0.48)
      ..cubicTo(w * 0.55, h * 0.50, w * 0.68, h * 0.60, w * 0.68, h * 0.88);

    canvas.drawPath(body, Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = w * 0.06);

    // Small shield badge (bottom right)
    if (isActive) {
      final bx = w * 0.78;
      final by = h * 0.62;
      final bs = w * 0.22;
      final badge = Path()
        ..moveTo(bx, by)
        ..cubicTo(bx - bs * 0.4, by, bx - bs / 2, by + bs * 0.1,
            bx - bs / 2, by + bs * 0.3)
        ..lineTo(bx - bs / 2, by + bs * 0.5)
        ..cubicTo(bx - bs / 2, by + bs * 0.7, bx - bs * 0.15,
            by + bs * 0.8, bx, by + bs * 0.9)
        ..cubicTo(bx + bs * 0.15, by + bs * 0.8, bx + bs / 2,
            by + bs * 0.7, bx + bs / 2, by + bs * 0.5)
        ..lineTo(bx + bs / 2, by + bs * 0.3)
        ..cubicTo(bx + bs / 2, by + bs * 0.1, bx + bs * 0.4,
            by, bx, by)
        ..close();
      canvas.drawPath(badge, Paint()..color = color);
    }
  }

  /// MAP — Location pin with shield center
  void _paintMap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Pin shape
    final pin = Path()
      ..moveTo(cx, h * 0.92)
      ..cubicTo(cx - w * 0.05, h * 0.72, w * 0.18, h * 0.50, w * 0.18, h * 0.36)
      ..cubicTo(w * 0.18, h * 0.14, w * 0.32, h * 0.08, cx, h * 0.08)
      ..cubicTo(w * 0.68, h * 0.08, w * 0.82, h * 0.14, w * 0.82, h * 0.36)
      ..cubicTo(w * 0.82, h * 0.50, cx + w * 0.05, h * 0.72, cx, h * 0.92)
      ..close();

    canvas.drawPath(pin, Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = w * 0.06);

    // Inner dot or shield
    if (isActive) {
      canvas.drawCircle(
        Offset(cx, h * 0.34),
        w * 0.12,
        Paint()..color = Colors.white,
      );
    } else {
      canvas.drawCircle(
        Offset(cx, h * 0.34),
        w * 0.08,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  /// MORE — 3×3 grid dots
  void _paintMore(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dotRadius = w * 0.07;
    final paint = Paint()..color = color;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = w * (0.25 + col * 0.25);
        final y = h * (0.25 + row * 0.25);
        canvas.drawCircle(
          Offset(x, y),
          isActive ? dotRadius * 1.15 : dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.type != type || old.isActive != isActive || old.color != color;
}
