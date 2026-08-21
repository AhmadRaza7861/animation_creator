import 'package:flutter/material.dart';

class CustomBottomSheetTheme {
  CustomBottomSheetTheme._(); // Private constructor to prevent instantiation

  static const lightBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16.0),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    modalElevation: 5.0,
    modalBackgroundColor: Colors.white,
  );

  static const darkBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Color(0xFF1F2828),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16.0),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    modalElevation: 5.0,
    modalBackgroundColor: Color(0xFF1F2828),
  );
}
