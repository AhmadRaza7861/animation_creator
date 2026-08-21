import 'package:flutter/material.dart';

class CustomRadioTheme {
  CustomRadioTheme._(); // Private constructor to prevent instantiation

  static final lightRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFFAAB3BF);
      } else if (states.contains(WidgetState.selected)) {
        return const Color(0xFF57A6D9);
      }
      return const Color(0xFFAAB3BF);
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.blue
            .withOpacity(0.5); // Example overlay color when pressed
      }
      return null; // No overlay color by default
    }),
  );

  static final darkRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFFAAB3BF);
      } else if (states.contains(WidgetState.selected)) {
        return const Color(0xFF57A6D9);
      }
      return const Color(0xFFAAB3BF);
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.blue.withOpacity(0.5);
      }
      return null;
    }),
  );
}
