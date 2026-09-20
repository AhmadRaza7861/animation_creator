import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBarTheme {
  CustomAppBarTheme._(); // Private constructor to prevent instantiation

  static const lightAppBarTheme = AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ),
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
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // For Android (dark icons)
      statusBarBrightness: Brightness.dark, // For iOS (dark icons)
    ),
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
