import 'package:flutter/material.dart';

class CustomTextSelectionTheme {
  CustomTextSelectionTheme._(); // Private constructor

  static  TextSelectionThemeData lightTextSelectionTheme = TextSelectionThemeData(
    cursorColor: Color(0xFF0EA9AB),
    selectionColor: Color(0xFFE2F6F6),
    selectionHandleColor: Color(0xFF0EA9AB),
  );

  static  TextSelectionThemeData darkTextSelectionTheme = TextSelectionThemeData(
    cursorColor: Color(0xFF0EA9AB),
    selectionColor: Color(0xFF0EA9AB),
    selectionHandleColor: Color(0xFF0EA9AB),
  );
}
