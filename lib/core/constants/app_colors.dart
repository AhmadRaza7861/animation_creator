import 'package:flutter/material.dart';

class ColorConstants {
  ColorConstants._();

  // Signature Brand Colors (Vibrant Amber & Sunset Orange)
  static const Color primary = Color(0xFFFF9318);
  static const Color primaryDark = Color(0xFFE67E00);
  static const Color primaryLight = Color(0xFFFFF7ED);
  static const Color primaryMuted = Color(0x1FFF9318);

  // Modern Slate Typography & Icons Hierarchy
  static const Color darkText = Color(0xFF0F172A); // Slate-900: Crisp header/label contrast
  static const Color mediumText = Color(0xFF64748B); // Slate-500: Subtitles, metadata, descriptions
  static const Color lightText = Color(0xFF94A3B8); // Slate-400: Placeholders, hints, disabled

  // Surfaces & Backdrops
  static const Color background = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color canvasWorkspaceBg = Color(0xFFF1F5F9); // Slate-100: Drawing workspace backdrop

  // Borders, Dividers & Shadows
  static const Color divider = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Selection & Accents
  static const Color accent = Color(0xFFFF9318);
  static const Color selectionBorder = Color(0xFFFF9318);
  static const Color shadow_color = Color(0x28FF9318);

  // Functional & Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color destructive = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Background Templates & Rulers
  static const Color gridPatternColor = Color(0x14000000);
  static const Color dotPatternColor = Color(0x26000000);
  static const Color rulerActive = Color(0xFFFF9318);
  static const Color rulerInactive = Color(0xFF94A3B8);

  // Legacy mappings for backwards-compatibility across existing screens
  static const Color border_color = Color(0xFFE2E8F0);
  static const Color border_color_2 = Color(0xFFF1F5F9);
  static const Color text_color = Color(0xFF0F172A);
  static const Color subTextColor = Color(0xFF64748B);
  static const Color text_sub2_color = Color(0xFF94A3B8);
  static const Color un_select_color = Color(0xFF94A3B8);
  static const Color selected_type = Color(0xFFF1F5F9);
  static const Color background_color = Colors.white;
  static const Color divider_color = Color(0xFFF1F5F9);
  static const Color shodow = Color(0x0F000000);
}
