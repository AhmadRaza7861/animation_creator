import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomTextSelectionTheme {
  CustomTextSelectionTheme._();

  static const TextSelectionThemeData lightTextSelectionTheme = TextSelectionThemeData(
    cursorColor: ColorConstants.primary,
    selectionColor: Color(0x33FF9318),
    selectionHandleColor: ColorConstants.primary,
  );

  static const TextSelectionThemeData darkTextSelectionTheme = TextSelectionThemeData(
    cursorColor: ColorConstants.primary,
    selectionColor: Color(0x4DFF9318),
    selectionHandleColor: ColorConstants.primary,
  );
}
