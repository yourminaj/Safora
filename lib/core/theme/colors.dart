import 'package:flutter/material.dart';

/// Safora SOS brand color palette.
///
/// Emergency-focused with bold reds, calming blues, and status colors.
abstract final class AppColors {
  // ─── Brand Primary ───────────────────────────────────────
  static const Color primary = Color(0xFFE53935); // Bold Emergency Red
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFF6F60);

  // ─── Brand Secondary ─────────────────────────────────────
  static const Color secondary = Color(0xFF1E88E5); // Trust Blue
  static const Color secondaryDark = Color(0xFF1565C0);
  static const Color secondaryLight = Color(0xFF64B5F6);

  // ─── Accent ──────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6F00); // Urgent Amber
  static const Color accentLight = Color(0xFFFFB74D);

  // ─── Alert Priority Colors ───────────────────────────────
  static const Color critical = Color(0xFFD32F2F); // 🔴 Critical
  static const Color high = Color(0xFFF57C00); // 🟠 High
  static const Color medium = Color(0xFFFBC02D); // 🟡 Medium
  static const Color low = Color(0xFF388E3C); // 🟢 Low

  // ─── Status Colors ───────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // ─── Safe / Active States ────────────────────────────────
  static const Color safe = Color(0xFF43A047); // Everything OK
  static const Color danger = Color(0xFFE53935); // Danger detected
  static const Color sosActive = Color(0xFFB71C1C); // SOS in progress

  // ─── Neutral / Surface ───────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ─── Dark Theme ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Color(0xFFE6E1E5);

  // ─── Text Colors ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF625B71);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Gradient Presets ────────────────────────────────────
  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFFF6F60)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
