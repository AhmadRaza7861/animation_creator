import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomDialogTheme {
  CustomDialogTheme._();

  static final lightDialogTheme = DialogThemeData(
    shadowColor: Colors.black.withValues(alpha: 0.15),
    elevation: 8,
    surfaceTintColor: Colors.transparent,
    backgroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      color: ColorConstants.darkText,
      fontSize: 18.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    contentTextStyle: const TextStyle(
      color: ColorConstants.mediumText,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18.0),
    ),
  );

  static final darkDialogTheme = DialogThemeData(
    shadowColor: Colors.black.withValues(alpha: 0.3),
    elevation: 8,
    surfaceTintColor: Colors.transparent,
    backgroundColor: const Color(0xFF1E293B),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 18.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    contentTextStyle: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18.0),
    ),
  );
}
