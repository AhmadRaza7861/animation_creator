import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBarTheme {
  CustomAppBarTheme._(); // Private constructor to prevent instantiation

  static const lightSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android status bar icons (dark)
    statusBarBrightness: Brightness.light, // iOS status bar icons (dark)
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark, // Android navigation bar icons (dark)
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static const darkSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android status bar icons (light)
    statusBarBrightness: Brightness.dark, // iOS status bar icons (light)
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light, // Android navigation bar icons (light)
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static const lightAppBarTheme = AppBarTheme(
    systemOverlayStyle: lightSystemUiOverlayStyle,
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: Color(0xFF1E2024),
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: "Roboto",
    ),
  );

  static const darkAppBarTheme = AppBarTheme(
    systemOverlayStyle: darkSystemUiOverlayStyle,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    centerTitle: true,
    backgroundColor: Colors.transparent,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: "Roboto",
    ),
  );
}
