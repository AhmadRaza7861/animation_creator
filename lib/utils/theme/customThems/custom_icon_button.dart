import 'package:flutter/material.dart';

class CustomIconButtonTheme {
  CustomIconButtonTheme._(); // Private constructor to prevent instantiation

  static final lightIconButtonTheme = IconButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade300;
        } else if (states.contains(WidgetState.pressed)) {
          return Colors.blue.shade200;
        }
        return Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        } else if (states.contains(WidgetState.pressed)) {
          return Colors.blue;
        }
        return Colors.black;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.blue.withOpacity(0.5);
        }
        return null;
      }),
    ),
  );
  static final darkIconButtonTheme = IconButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade800;
        } else if (states.contains(WidgetState.pressed)) {
          return Colors.transparent;
        }
        return Colors.black;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey;
        } else if (states.contains(WidgetState.pressed)) {
          return Colors.transparent;
        }
        return Colors.transparent;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.transparent;
        }
        return null;
      }),
    ),
  );
}
