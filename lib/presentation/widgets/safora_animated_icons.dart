import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

// ═══════════════════════════════════════════════════════════════════
//  SAFORA ANIMATED ICON LIBRARY
//  Custom branded icons using CustomPainter + AnimationController.
//  No Lottie dependency — pure vector rendering at 60fps.
// ═══════════════════════════════════════════════════════════════════

/// Brand colors used across all custom icons.
class _BrandPalette {
  static const shieldRed = Color(0xFFE53935);
  static const shieldRedLight = Color(0xFFFF6F60);
  static const ecgWhite = Colors.white;
  static const successGreen = Color(0xFF43A047);
  static const warningAmber = Color(0xFFFFA726);
  static const infoBlue = Color(0xFF42A5F5);
}

// ═══════════════════════════════════════════════════════════════════
//  1. SAFORA SOS ICON — Pulsing shield with heartbeat ECG
//     Used: Onboarding page 1
// ═══════════════════════════════════════════════════════════════════

class SaforaSosIcon extends StatefulWidget {
  const SaforaSosIcon({
    super.key,
    this.size = 120,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaSosIcon> createState() => _SaforaSosIconState();
}

class _SaforaSosIconState extends State<SaforaSosIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SosIconPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _SosIconPainter extends CustomPainter {
  _SosIconPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Outer pulse ring ──
    final pulseRadius = w * 0.42 + (w * 0.06 * math.sin(progress * 2 * math.pi));
    final ringPaint = Paint()
      ..color = _BrandPalette.shieldRed.withValues(
          alpha: 0.15 + 0.1 * math.sin(progress * 2 * math.pi))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawCircle(Offset(cx, cy), pulseRadius, ringPaint);

    // ── Shield shape ──
    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_BrandPalette.shieldRed, _BrandPalette.shieldRedLight],
      ).createShader(Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.7));

    final shield = _buildShieldPath(w, h);
    canvas.drawPath(shield, shieldPaint);

    // ── Shield border highlight ──
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    canvas.drawPath(shield, borderPaint);

    // ── ECG heartbeat line ──
    final ecg = _buildEcgPath(w, h, progress);
    final ecgPaint = Paint()
      ..color = _BrandPalette.ecgWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(ecg, ecgPaint);

    // ── "SOS" text ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SOS',
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.1,
          fontWeight: FontWeight.w900,
          letterSpacing: w * 0.01,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, h * 0.68),
    );
  }

  Path _buildShieldPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..cubicTo(w * 0.35, h * 0.15, w * 0.2, h * 0.18, w * 0.2, h * 0.32)
      ..lineTo(w * 0.2, h * 0.50)
      ..cubicTo(w * 0.2, h * 0.68, w * 0.34, h * 0.78, w * 0.5, h * 0.88)
      ..cubicTo(w * 0.66, h * 0.78, w * 0.8, h * 0.68, w * 0.8, h * 0.50)
      ..lineTo(w * 0.8, h * 0.32)
      ..cubicTo(w * 0.8, h * 0.18, w * 0.65, h * 0.15, w * 0.5, h * 0.15)
      ..close();
  }

  Path _buildEcgPath(double w, double h, double t) {
    final yBase = h * 0.46;
    final offset = w * 0.03 * math.sin(t * 2 * math.pi);
    return Path()
      ..moveTo(w * 0.26, yBase)
      ..lineTo(w * 0.36, yBase)
      ..lineTo(w * 0.39, yBase - h * 0.06)
      ..lineTo(w * 0.43, yBase + h * 0.04)
      ..lineTo(w * 0.47, yBase - h * 0.16 + offset)
      ..lineTo(w * 0.52, yBase + h * 0.10 - offset)
      ..lineTo(w * 0.56, yBase - h * 0.04)
      ..lineTo(w * 0.60, yBase)
      ..lineTo(w * 0.63, yBase + h * 0.03)
      ..lineTo(w * 0.66, yBase)
      ..lineTo(w * 0.74, yBase);
  }

  @override
  bool shouldRepaint(_SosIconPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  2. SAFORA LOCATION ICON — Radar sweep with location pin
//     Used: Onboarding page 2
// ═══════════════════════════════════════════════════════════════════

class SaforaLocationIcon extends StatefulWidget {
  const SaforaLocationIcon({
    super.key,
    this.size = 120,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaLocationIcon> createState() => _SaforaLocationIconState();
}

class _SaforaLocationIconState extends State<SaforaLocationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LocationIconPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _LocationIconPainter extends CustomPainter {
  _LocationIconPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.45;

    // ── Radar rings (expand outward) ──
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final radius = w * 0.1 + (w * 0.35 * ringProgress);
      final alpha = (1.0 - ringProgress) * 0.35;
      final ringPaint = Paint()
        ..color = _BrandPalette.infoBlue.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015;
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }

    // ── Map pin body ──
    final pinGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _BrandPalette.infoBlue,
          Color(0xFF1565C0),
        ],
      ).createShader(Rect.fromLTWH(w * 0.3, h * 0.2, w * 0.4, h * 0.5));

    final pin = Path()
      ..moveTo(cx, h * 0.72)
      ..cubicTo(cx - w * 0.04, h * 0.62, cx - w * 0.2, h * 0.48, cx - w * 0.2, h * 0.36)
      ..cubicTo(cx - w * 0.2, h * 0.22, cx - w * 0.12, h * 0.18, cx, h * 0.18)
      ..cubicTo(cx + w * 0.12, h * 0.18, cx + w * 0.2, h * 0.22, cx + w * 0.2, h * 0.36)
      ..cubicTo(cx + w * 0.2, h * 0.48, cx + w * 0.04, h * 0.62, cx, h * 0.72)
      ..close();

    canvas.drawPath(pin, pinGradient);

    // ── Pin highlight ──
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // ── Inner shield on pin ──
    final shieldSize = w * 0.14;
    final sx = cx - shieldSize / 2;
    final sy = cy - shieldSize * 0.6;
    final miniShield = Path()
      ..moveTo(cx, sy)
      ..cubicTo(cx - shieldSize * 0.4, sy, sx, sy + shieldSize * 0.1,
          sx, sy + shieldSize * 0.35)
      ..lineTo(sx, sy + shieldSize * 0.55)
      ..cubicTo(sx, sy + shieldSize * 0.75, cx - shieldSize * 0.2,
          sy + shieldSize * 0.85, cx, sy + shieldSize)
      ..cubicTo(cx + shieldSize * 0.2, sy + shieldSize * 0.85,
          sx + shieldSize, sy + shieldSize * 0.75, sx + shieldSize,
          sy + shieldSize * 0.55)
      ..lineTo(sx + shieldSize, sy + shieldSize * 0.35)
      ..cubicTo(sx + shieldSize, sy + shieldSize * 0.1,
          cx + shieldSize * 0.4, sy, cx, sy)
      ..close();

    canvas.drawPath(
      miniShield,
      Paint()..color = Colors.white,
    );

    // ── Drop shadow beneath pin ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.78),
        width: w * 0.18,
        height: h * 0.03,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(_LocationIconPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  3. SAFORA MEDICAL ICON — Medical cross with pulse ring
//     Used: Onboarding page 3
// ═══════════════════════════════════════════════════════════════════

class SaforaMedicalIcon extends StatefulWidget {
  const SaforaMedicalIcon({
    super.key,
    this.size = 120,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaMedicalIcon> createState() => _SaforaMedicalIconState();
}

class _SaforaMedicalIconState extends State<SaforaMedicalIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MedicalIconPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _MedicalIconPainter extends CustomPainter {
  _MedicalIconPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Pulse ring ──
    final pulsePhase = (progress * 2 * math.pi);
    final ringRadius = w * 0.38 + w * 0.04 * math.sin(pulsePhase);
    canvas.drawCircle(
      Offset(cx, cy),
      ringRadius,
      Paint()
        ..color = _BrandPalette.successGreen.withValues(
            alpha: 0.2 + 0.1 * math.sin(pulsePhase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // ── Second pulse ring (offset) ──
    final ring2Radius = w * 0.44 + w * 0.03 * math.cos(pulsePhase);
    canvas.drawCircle(
      Offset(cx, cy),
      ring2Radius,
      Paint()
        ..color = _BrandPalette.successGreen.withValues(
            alpha: 0.1 + 0.08 * math.cos(pulsePhase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // ── Main circle background ──
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.30,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            _BrandPalette.successGreen,
            Color(0xFF2E7D32),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.30),
        ),
    );

    // ── Circle highlight ──
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.30,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // ── Medical cross ──
    final crossPaint = Paint()..color = Colors.white;
    final armW = w * 0.08;
    final armH = w * 0.22;

    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: armW, height: armH),
        Radius.circular(armW * 0.4),
      ),
      crossPaint,
    );
    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: armH, height: armW),
        Radius.circular(armW * 0.4),
      ),
      crossPaint,
    );

    // ── Small heartbeat line below cross ──
    final ecgY = cy + w * 0.14;
    final ecgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ecgPath = Path()
      ..moveTo(cx - w * 0.12, ecgY)
      ..lineTo(cx - w * 0.05, ecgY)
      ..lineTo(cx - w * 0.02, ecgY - w * 0.04)
      ..lineTo(cx + w * 0.02, ecgY + w * 0.04)
      ..lineTo(cx + w * 0.05, ecgY)
      ..lineTo(cx + w * 0.12, ecgY);
    canvas.drawPath(ecgPath, ecgPaint);
  }

  @override
  bool shouldRepaint(_MedicalIconPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  4. SAFORA LOADING SPINNER — Branded arc spinner with shield
//     Used: Splash screen
// ═══════════════════════════════════════════════════════════════════

class SaforaLoadingSpinner extends StatefulWidget {
  const SaforaLoadingSpinner({
    super.key,
    this.size = 40,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<SaforaLoadingSpinner> createState() => _SaforaLoadingSpinnerState();
}

class _SaforaLoadingSpinnerState extends State<SaforaLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LoadingSpinnerPainter(
            progress: _ctrl.value,
            color: widget.color ?? Colors.white,
          ),
        );
      },
    );
  }
}

class _LoadingSpinnerPainter extends CustomPainter {
  _LoadingSpinnerPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = w / 2;
    final radius = w * 0.42;

    // Rotate canvas
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-cx, -cy);

    // ── Arc segments ──
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    // Main bright arc
    arcPaint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0,
      math.pi * 0.8,
      false,
      arcPaint,
    );

    // Dimmer trailing arc
    arcPaint.color = color.withValues(alpha: 0.3);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi * 1.0,
      math.pi * 0.5,
      false,
      arcPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoadingSpinnerPainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  5. SAFORA SHIELD PULSE — Breathing shield with glow
//     Used: About dialog, alert system
// ═══════════════════════════════════════════════════════════════════

class SaforaShieldPulse extends StatefulWidget {
  const SaforaShieldPulse({
    super.key,
    this.size = 80,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaShieldPulse> createState() => _SaforaShieldPulseState();
}

class _SaforaShieldPulseState extends State<SaforaShieldPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ShieldPulsePainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _ShieldPulsePainter extends CustomPainter {
  _ShieldPulsePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Glow circle ──
    final glowRadius = w * 0.44 + w * 0.04 * progress;
    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()
        ..color = _BrandPalette.shieldRed.withValues(
            alpha: 0.08 + 0.08 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Shield ──
    final scale = 0.95 + 0.05 * progress;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final shield = _buildShield(w, h);
    canvas.drawPath(
      shield,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_BrandPalette.shieldRed, _BrandPalette.shieldRedLight],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Border
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015,
    );

    // ── ECG line on shield ──
    final ecgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final yBase = h * 0.46;
    final ecg = Path()
      ..moveTo(w * 0.24, yBase)
      ..lineTo(w * 0.35, yBase)
      ..lineTo(w * 0.38, yBase - h * 0.05)
      ..lineTo(w * 0.42, yBase + h * 0.03)
      ..lineTo(w * 0.46, yBase - h * 0.14)
      ..lineTo(w * 0.52, yBase + h * 0.08)
      ..lineTo(w * 0.56, yBase - h * 0.03)
      ..lineTo(w * 0.60, yBase)
      ..lineTo(w * 0.76, yBase);
    canvas.drawPath(ecg, ecgPaint);

    canvas.restore();
  }

  Path _buildShield(double w, double h) {
    return Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..cubicTo(w * 0.35, h * 0.12, w * 0.18, h * 0.15, w * 0.18, h * 0.30)
      ..lineTo(w * 0.18, h * 0.50)
      ..cubicTo(w * 0.18, h * 0.70, w * 0.34, h * 0.80, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.66, h * 0.80, w * 0.82, h * 0.70, w * 0.82, h * 0.50)
      ..lineTo(w * 0.82, h * 0.30)
      ..cubicTo(w * 0.82, h * 0.15, w * 0.65, h * 0.12, w * 0.50, h * 0.12)
      ..close();
  }

  @override
  bool shouldRepaint(_ShieldPulsePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  6. SAFORA WARNING ICON — Animated triangle with exclamation
//     Used: Alert system
// ═══════════════════════════════════════════════════════════════════

class SaforaWarningIcon extends StatefulWidget {
  const SaforaWarningIcon({
    super.key,
    this.size = 42,
    this.animated = true,
    this.color,
  });

  final double size;
  final bool animated;
  final Color? color;

  @override
  State<SaforaWarningIcon> createState() => _SaforaWarningIconState();
}

class _SaforaWarningIconState extends State<SaforaWarningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WarningIconPainter(
            progress: _ctrl.value,
            overrideColor: widget.color,
          ),
        );
      },
    );
  }
}

class _WarningIconPainter extends CustomPainter {
  _WarningIconPainter({required this.progress, this.overrideColor});
  final double progress;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final baseColor = overrideColor ?? _BrandPalette.warningAmber;

    // Warning triangle
    final triPath = Path()
      ..moveTo(cx, h * 0.12)
      ..lineTo(w * 0.9, h * 0.85)
      ..lineTo(w * 0.1, h * 0.85)
      ..close();

    canvas.drawPath(
      triPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseColor, baseColor.withValues(alpha: 0.8)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Border
    canvas.drawPath(
      triPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Exclamation mark ──
    final exclColor = Colors.white.withValues(
        alpha: 0.7 + 0.3 * progress);
    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.48),
          width: w * 0.065,
          height: h * 0.22,
        ),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = exclColor,
    );
    // Dot
    canvas.drawCircle(
      Offset(cx, h * 0.70),
      w * 0.04,
      Paint()..color = exclColor,
    );
  }

  @override
  bool shouldRepaint(_WarningIconPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  7. SAFORA SUCCESS ICON — Animated checkmark with circle fill
//     Used: Success states
// ═══════════════════════════════════════════════════════════════════

class SaforaSuccessIcon extends StatefulWidget {
  const SaforaSuccessIcon({
    super.key,
    this.size = 60,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaSuccessIcon> createState() => _SaforaSuccessIconState();
}

class _SaforaSuccessIconState extends State<SaforaSuccessIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.animated) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SuccessIconPainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _SuccessIconPainter extends CustomPainter {
  _SuccessIconPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = w / 2;
    final radius = w * 0.40;

    // ── Circle fill (expands in) ──
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      radius * circleProgress,
      Paint()
        ..shader = const RadialGradient(
          colors: [_BrandPalette.successGreen, Color(0xFF2E7D32)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
    );

    // ── Circle border ──
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = _BrandPalette.successGreen.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    // ── Checkmark (draws in after circle) ──
    final checkProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    if (checkProgress > 0) {
      final checkPath = Path()
        ..moveTo(w * 0.28, cy)
        ..lineTo(w * 0.42, w * 0.62)
        ..lineTo(w * 0.72, w * 0.35);

      final metric = checkPath.computeMetrics().first;
      final extractedPath = metric.extractPath(0, metric.length * checkProgress);

      canvas.drawPath(
        extractedPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessIconPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  8. SAFORA EMPTY STATE — Shield outline with question mark
//     Used: Empty lists
// ═══════════════════════════════════════════════════════════════════

class SaforaEmptyState extends StatefulWidget {
  const SaforaEmptyState({
    super.key,
    this.size = 80,
    this.animated = true,
  });

  final double size;
  final bool animated;

  @override
  State<SaforaEmptyState> createState() => _SaforaEmptyStateState();
}

class _SaforaEmptyStateState extends State<SaforaEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _EmptyStatePainter(progress: _ctrl.value),
        );
      },
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  _EmptyStatePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Dashed shield outline ──
    final dashAlpha = 0.25 + 0.15 * math.sin(progress * math.pi);
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..cubicTo(w * 0.33, h * 0.10, w * 0.15, h * 0.14, w * 0.15, h * 0.30)
      ..lineTo(w * 0.15, h * 0.52)
      ..cubicTo(w * 0.15, h * 0.72, w * 0.33, h * 0.82, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.67, h * 0.82, w * 0.85, h * 0.72, w * 0.85, h * 0.52)
      ..lineTo(w * 0.85, h * 0.30)
      ..cubicTo(w * 0.85, h * 0.14, w * 0.67, h * 0.10, w * 0.50, h * 0.10)
      ..close();

    canvas.drawPath(
      shield,
      Paint()
        ..color = AppColors.textDisabled.withValues(alpha: dashAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );

    // ── Question mark ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: AppColors.textDisabled.withValues(
              alpha: 0.4 + 0.2 * math.sin(progress * math.pi)),
          fontSize: w * 0.30,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, h * 0.35),
    );
  }

  @override
  bool shouldRepaint(_EmptyStatePainter old) => old.progress != progress;
}
