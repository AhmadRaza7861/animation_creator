import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomTextFieldTheme {
  CustomTextFieldTheme._();

  static const lightTextFieldTheme = InputDecorationTheme(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.primary, width: 1.5),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
    ),
    errorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.destructive, width: 1.0),
    ),
    focusedErrorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.destructive, width: 1.5),
    ),
    hintStyle: TextStyle(
      color: ColorConstants.lightText,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: ColorConstants.mediumText,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  static const darkTextFieldTheme = InputDecorationTheme(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.primary, width: 1.5),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF334155)),
    ),
    errorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.destructive, width: 1.0),
    ),
    focusedErrorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: ColorConstants.destructive, width: 1.5),
    ),
    hintStyle: TextStyle(
      color: Color(0xFF64748B),
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      inputDecorationTheme: lightTextFieldTheme,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ColorConstants.primary,
        selectionColor: ColorConstants.primaryLight,
        selectionHandleColor: ColorConstants.primary,
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      inputDecorationTheme: darkTextFieldTheme,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ColorConstants.primary,
        selectionColor: Color(0x33FF9318),
        selectionHandleColor: ColorConstants.primary,
      ),
    );
  }
}
