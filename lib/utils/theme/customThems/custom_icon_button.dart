import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomIconButtonTheme {
  CustomIconButtonTheme._();

  static final lightIconButtonTheme = IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return ColorConstants.lightText;
        } else if (states.contains(WidgetState.pressed)) {
          return ColorConstants.primary;
        }
        return ColorConstants.darkText;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return ColorConstants.primary.withValues(alpha: 0.12);
        }
        return null;
      }),
    ),
  );

  static final darkIconButtonTheme = IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF64748B);
        } else if (states.contains(WidgetState.pressed)) {
          return ColorConstants.primary;
        }
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return ColorConstants.primary.withValues(alpha: 0.15);
        }
        return null;
      }),
    ),
  );
}
