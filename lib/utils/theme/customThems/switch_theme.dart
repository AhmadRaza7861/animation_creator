import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomSwitchTheme {
  CustomSwitchTheme._(); // Private constructor to prevent instantiation

  static final lightSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ColorConstants.mediumText.withOpacity(0.3);
      }
      if (states.contains(WidgetState.selected)) {
        return ColorConstants.primary; // Orange when selected
      }
      return const Color(0xFF94A3B8); // Slate grey when unselected
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFFE2E8F0).withOpacity(0.5);
      }
      if (states.contains(WidgetState.selected)) {
        return ColorConstants.primaryLight; // Soft peach/orange when selected
      }
      return const Color(0xFFE2E8F0); // Light grey when unselected
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      return Colors.transparent; // Borderless switch track
    }),
  );

  static final darkSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFF57A6D9).withOpacity(0.3);
      }
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF57A6D9); // Light blue when selected
      }
      return const Color(0xFF64748B); // Slate grey when unselected
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFF0B0E13).withOpacity(0.5);
      }
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF57A6D9).withOpacity(0.24); // Semi-transparent blue when selected
      }
      return const Color(0xFF1E293B); // Dark slate grey when unselected
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      return Colors.transparent;
    }),
  );
}
