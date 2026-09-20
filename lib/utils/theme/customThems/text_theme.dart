import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomTextTheme {
  CustomTextTheme._();

  static const lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    titleSmall: TextStyle(
      color: ColorConstants.mediumText,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    bodyLarge: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    bodyMedium: TextStyle(
      color: ColorConstants.mediumText,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: ColorConstants.lightText,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: ColorConstants.darkText,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    labelMedium: TextStyle(
      color: ColorConstants.mediumText,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    labelSmall: TextStyle(
      color: ColorConstants.lightText,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    ),
  );

  static const darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    titleSmall: TextStyle(
      color: Color(0xFF94A3B8),
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    bodyLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFF94A3B8),
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
  );
}
