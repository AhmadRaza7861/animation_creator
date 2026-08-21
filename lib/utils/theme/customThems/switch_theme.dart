import 'package:flutter/material.dart';

class CustomSwitchTheme {
  CustomSwitchTheme._(); // Private constructor to prevent instantiation

  static final lightSwitchTheme = SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFAAB3BF);
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFAAB3BF); // Color when switch is on
        }
        return const Color(0xFFAAB3BF);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? const Color(0xFFF4F6F8)
              : const Color(0xFFF4F6F8)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent));

  static final darkSwitchTheme = SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF57A6D9);
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF57A6D9); // Color when switch is on
        }
        return const Color(0xFF57A6D9);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? const Color(0xFF0B0E13)
              : const Color(0xFF0B0E13)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent));
}
