import 'package:flutter/material.dart';

class CustomTextTheme {
  CustomTextTheme._(); // Private constructor to prevent instantiation

  static const lightTextTheme = TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w500,
      fontSize: 18,
    ),
    titleSmall: TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    labelLarge: TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    bodyMedium:  TextStyle(
      color: Color(0xFF323D59),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
  );
  static const darkTextTheme = TextTheme(
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFAAB3BF),
      fontWeight: FontWeight.w500,
      fontSize: 18,
    ),
    titleSmall: TextStyle(
      color: Colors.white,
      //Color(0xFF2E81B7),
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
  );
}
