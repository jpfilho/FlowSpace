import 'package:flutter/material.dart';

/// FlowSpace Color Tokens — Design System
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF5B6AF3);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryContainer = Color(0xFFEEF0FE);
  static const Color primaryContainerDark = Color(0xFF1E1F4E);

  // ── Accent ─────────────────────────────────────────────
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF67E8F9);
  static const Color accentContainer = Color(0xFFECFEFF);

  // ── Neutrals (Light) ───────────────────────────────────
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F7);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color overlay = Color(0x0F000000);

  // ── Neutrals (Dark) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceVariantDark = Color(0xFF1C2333);
  static const Color borderDark = Color(0xFF2A2D3A);
  static const Color borderStrongDark = Color(0xFF3D4154);
  static const Color overlayDark = Color(0x1AFFFFFF);

  // ── Text (Light) ───────────────────────────────────────
  static const Color textPrimary = Color(0xFF111318);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Text (Dark) ────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF1F3F8);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color textDisabledDark = Color(0xFF6B7280);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successContainer = Color(0xFFBBF7D0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningContainer = Color(0xFFFDE68A);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorContainer = Color(0xFFFECACA);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── Task Priority ──────────────────────────────────────
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF59E0B);
  static const Color priorityMedium = Color(0xFF3B82F6);
  static const Color priorityLow = Color(0xFF6B7280);

  // ── Status Colors ──────────────────────────────────────
  static const Color statusTodo = Color(0xFF9CA3AF);
  static const Color statusInProgress = Color(0xFF5B6AF3);
  static const Color statusReview = Color(0xFFF59E0B);
  static const Color statusDone = Color(0xFF22C55E);
  static const Color statusCancelled = Color(0xFFEF4444);

  // ── Sidebar ────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFFF7F8FA);
  static const Color sidebarBgDark = Color(0xFF111318);
  static const Color sidebarItemHover = Color(0xFFEEF0FE);
  static const Color sidebarItemHoverDark = Color(0xFF1E2130);
  static const Color sidebarItemActive = Color(0xFFE0E3FF);
  static const Color sidebarItemActiveDark = Color(0xFF1E1F4E);

  // ── Label Colors (for tags) ────────────────────────────
  static const List<Color> labelColors = [
    Color(0xFFEF4444), // red
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFF84CC16), // lime
    Color(0xFFF97316), // orange
    Color(0xFF64748B), // slate
  ];
}
