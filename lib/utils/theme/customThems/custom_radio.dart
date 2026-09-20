import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomRadioTheme {
  CustomRadioTheme._();

  static final lightRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return ColorConstants.lightText.withValues(alpha: 0.5);
      } else if (states.contains(WidgetState.selected)) {
        return ColorConstants.primary;
      }
      return ColorConstants.lightText;
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return ColorConstants.primary.withValues(alpha: 0.12);
      }
      return null;
    }),
  );

  static final darkRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFF64748B).withValues(alpha: 0.5);
      } else if (states.contains(WidgetState.selected)) {
        return ColorConstants.primary;
      }
      return const Color(0xFF64748B);
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return ColorConstants.primary.withValues(alpha: 0.15);
      }
      return null;
    }),
  );
}
