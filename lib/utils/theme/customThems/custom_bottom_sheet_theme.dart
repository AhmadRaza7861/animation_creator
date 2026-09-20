import 'package:flutter/material.dart';

class CustomBottomSheetTheme {
  CustomBottomSheetTheme._();

  static const lightBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20.0),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    modalElevation: 8.0,
    modalBackgroundColor: Colors.white,
  );

  static const darkBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Color(0xFF1E293B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20.0),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    modalElevation: 8.0,
    modalBackgroundColor: Color(0xFF1E293B),
  );
}
