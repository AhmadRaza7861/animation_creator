import 'package:flutter/material.dart';

class CustomTextFieldTheme {
  CustomTextFieldTheme._(); // Private constructor to prevent instantiation

  static const lightTextFieldTheme = InputDecorationTheme(
    // filled: true,
    // fillColor: Colors.white,
    // border: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.blue),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF323D59), width: 1.0), // Color when focused
    ),
    enabledBorder:UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFEBEEF4)), // Color when unfocused
    ),
    // errorBorder: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.red),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    // focusedErrorBorder: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.red),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
  //  labelStyle: TextStyle(color: Colors.blue),
    hintStyle: TextStyle(color: Color(0xFFBCC1CE),
    fontSize:16,
    fontWeight:FontWeight.w400
    ),
  );

  static const darkTextFieldTheme = InputDecorationTheme(
    // filled: true,
    // fillColor: Colors.grey[800],
    // border: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.blue),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white,width: 2),
    //  borderRadius: BorderRadius.circular(10.0),
    ),
    // enabledBorder: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.white),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    // errorBorder: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.red),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    // focusedErrorBorder: OutlineInputBorder(
    //   borderSide: BorderSide(color: Colors.red),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    // labelStyle: TextStyle(color: Colors.blue),
    hintStyle: TextStyle(color: Color(0xFFAAB3BF)),
  );


  /// Use this in your ThemeData for light mode
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      inputDecorationTheme: lightTextFieldTheme,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF323D59), // 👈 Cursor color for light theme
      ),
    );
  }

  /// Use this in your ThemeData for dark mode
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      inputDecorationTheme: darkTextFieldTheme,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white, // 👈 Cursor color for dark theme
      ),
    );
  }
}
