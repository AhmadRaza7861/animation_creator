import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBarTheme {
  CustomAppBarTheme._(); // Private constructor to prevent instantiation

  static const lightAppBarTheme = AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      //Color(0xFFE9F9F9),
      systemNavigationBarColor: Colors.transparent,
      //Color(0xFFE9F9F9),
      // statusBarColor: Color(0xFFF4F8FE),
      // systemNavigationBarColor: Color(0xFFF4F8FE),
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ),
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    scrolledUnderElevation: 0,
  );

  static const darkAppBarTheme = AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        // Status bar color
        statusBarColor:
        Colors.transparent,
       // Color(0xFF2D3434),
        systemNavigationBarColor:
        Colors.transparent,
        //Color(0xFF2D3434),
        // Status bar brightness (optional)
        statusBarIconBrightness: Brightness.light, // For Android (dark icons)
        statusBarBrightness: Brightness.dark, // For iOS (dark icons)
      ),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0);
}
