import 'package:flutter/material.dart';

class CustomDialogTheme {
  CustomDialogTheme._(); // Private constructor to prevent instantiation

  static final lightDialogTheme = DialogThemeData(
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    backgroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
  );

  static final darkDialogTheme = DialogThemeData(
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    backgroundColor:Color(0xFF1C1D21),
    //const Color(0xFF1C1D21),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
  );
}
