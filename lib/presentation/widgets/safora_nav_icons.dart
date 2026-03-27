import 'package:flutter/material.dart';

/// Icon types used in the bottom navigation bar.
enum SaforaNavIconType { home, alerts, contacts, map, more }

/// Renders a custom-painted Safora branded navigation icon.
///
/// No Material icon dependency — pure vector rendering for a unique brand
/// identity that cannot be confused with any other app.
class SaforaNavIcon extends StatelessWidget {
  const SaforaNavIcon({
    super.key,
    required this.type,
    required this.isActive,
    this.color,
    this.size = 22,
  });

  final SaforaNavIconType type;
  final bool isActive;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NavIconPainter(
        type: type,
        isActive: isActive,
        color: color ?? (isActive ? const Color(0xFFE53935) : const Color(0xFF9CA3AF)),
      ),
    );
  }
}

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

  /// ── Home: Shield outline with small house inside ──
  void _paintHome(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final strokePaint = Paint()
      ..color = color
      ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Simple house outline: roof + walls
    final path = Path()
      ..moveTo(cx, h * 0.12) // Roof peak
      ..lineTo(w * 0.12, h * 0.45) // Left roof
      ..lineTo(w * 0.12, h * 0.82) // Left wall
      ..lineTo(w * 0.88, h * 0.82) // Bottom right
      ..lineTo(w * 0.88, h * 0.45) // Right wall
      ..close();

    if (isActive) {
      final fillPaint = Paint()..color = color.withValues(alpha: 0.15);
      canvas.drawPath(path, fillPaint);
    }
    strokePaint.style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // Door
    final doorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, h * 0.68), width: w * 0.22, height: h * 0.26),
      doorPaint,
    );
  }

  /// ── Alerts: Bell shape ──
  void _paintAlerts(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Bell body
    final bell = Path()
      ..moveTo(w * 0.15, h * 0.58)
      ..cubicTo(w * 0.15, h * 0.22, w * 0.30, h * 0.10, cx, h * 0.10)
      ..cubicTo(w * 0.70, h * 0.10, w * 0.85, h * 0.22, w * 0.85, h * 0.58)
      ..lineTo(w * 0.92, h * 0.68)
      ..lineTo(w * 0.08, h * 0.68)
      ..close();

    if (isActive) {
      final fillPaint = Paint()..color = color.withValues(alpha: 0.15);
      canvas.drawPath(bell, fillPaint);
    }
    canvas.drawPath(bell, paint);

    // Clapper line
    canvas.drawLine(
      Offset(cx - w * 0.08, h * 0.78),
      Offset(cx + w * 0.08, h * 0.78),
      paint..strokeWidth = w * 0.06,
    );

    // Ring on top
    canvas.drawCircle(
      Offset(cx, h * 0.06),
      w * 0.04,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  /// ── Contacts: Person silhouette (head + shoulders) ──
  void _paintContacts(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08;

    // Head circle
    final headRadius = w * 0.16;
    canvas.drawCircle(Offset(cx, h * 0.28), headRadius, paint);
    if (isActive) {
      canvas.drawCircle(
        Offset(cx, h * 0.28),
        headRadius,
        Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill,
      );
    }

    // Shoulders arc
    final shoulders = Path()
      ..moveTo(w * 0.10, h * 0.88)
      ..cubicTo(w * 0.10, h * 0.56, w * 0.30, h * 0.50, cx, h * 0.50)
      ..cubicTo(w * 0.70, h * 0.50, w * 0.90, h * 0.56, w * 0.90, h * 0.88);

    if (isActive) {
      final closeShoulders = Path.from(shoulders)..close();
      canvas.drawPath(
        closeShoulders,
        Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(shoulders, paint);
  }

  /// ── Map: Location pin ──
  void _paintMap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeJoin = StrokeJoin.round;

    // Pin body
    final pin = Path()
      ..moveTo(cx, h * 0.90) // Point at bottom
      ..cubicTo(w * 0.30, h * 0.52, w * 0.12, h * 0.35, w * 0.12, h * 0.30)
      ..cubicTo(w * 0.12, h * 0.08, w * 0.30, h * 0.04, cx, h * 0.04)
      ..cubicTo(w * 0.70, h * 0.04, w * 0.88, h * 0.08, w * 0.88, h * 0.30)
      ..cubicTo(w * 0.88, h * 0.35, w * 0.70, h * 0.52, cx, h * 0.90);

    if (isActive) {
      canvas.drawPath(
        pin,
        Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(pin, paint);

    // Inner circle
    canvas.drawCircle(
      Offset(cx, h * 0.28),
      w * 0.12,
      Paint()
        ..color = color
        ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = w * 0.06,
    );
  }

  /// ── More: Three horizontal lines (hamburger) ──
  void _paintMore(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final leftX = w * 0.18;
    final rightX = w * 0.82;

    // Three lines
    canvas.drawLine(Offset(leftX, h * 0.25), Offset(rightX, h * 0.25), paint);
    canvas.drawLine(Offset(leftX, h * 0.50), Offset(rightX, h * 0.50), paint);
    canvas.drawLine(Offset(leftX, h * 0.75), Offset(rightX, h * 0.75), paint);

    // Active dot on the right
    if (isActive) {
      canvas.drawCircle(
        Offset(rightX + w * 0.04, h * 0.25),
        w * 0.05,
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) =>
      type != oldDelegate.type ||
      isActive != oldDelegate.isActive ||
      color != oldDelegate.color;
}
