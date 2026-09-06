import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';
import 'customThems/app_bar_theme.dart';
import 'customThems/custom_bottom_sheet_theme.dart';
import 'customThems/custom_radio.dart';
import 'customThems/custom_text_field.dart';
import 'customThems/custom_text_selection_theme.dart';
import 'customThems/dialog_theme.dart';
import 'customThems/elevated_button_theme.dart';
import 'customThems/slider_custom_theme.dart';
import 'customThems/switch_theme.dart';
import 'customThems/text_theme.dart';

class AppTheme {
  AppTheme._();
  static ThemeData lightTheme = ThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    brightness: Brightness.light,
    primaryColor: ColorConstants.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorConstants.primary,
      primary: ColorConstants.primary,
      brightness: Brightness.light,
    ),
    primarySwatch: Colors.orange,
    dialogTheme: CustomDialogTheme.lightDialogTheme,
    elevatedButtonTheme: CustomElevatedButtonTheme.lightElevatedButtonTheme,
    textTheme: CustomTextTheme.lightTextTheme,
    inputDecorationTheme: CustomTextFieldTheme.lightTextFieldTheme,
    fontFamily: "Roboto",
    radioTheme: CustomRadioTheme.lightRadioTheme,
    appBarTheme: CustomAppBarTheme.lightAppBarTheme,
    sliderTheme: CustomSliderTheme.lightSliderTheme,
    switchTheme: CustomSwitchTheme.lightSwitchTheme,
    textSelectionTheme: CustomTextSelectionTheme.lightTextSelectionTheme,
    bottomSheetTheme: CustomBottomSheetTheme.lightBottomSheetTheme,
  );

  static ThemeData darkTheme = ThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    useMaterial3: true,
    brightness: Brightness.dark,
    dialogTheme: CustomDialogTheme.darkDialogTheme,
    primaryColor: ColorConstants.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorConstants.primary,
      primary: ColorConstants.primary,
      brightness: Brightness.dark,
    ),
    elevatedButtonTheme: CustomElevatedButtonTheme.darkElevatedButtonTheme,
    textTheme: CustomTextTheme.darkTextTheme,
    inputDecorationTheme: CustomTextFieldTheme.darkTextFieldTheme,
    fontFamily: "Roboto",
    radioTheme: CustomRadioTheme.darkRadioTheme,
    appBarTheme: CustomAppBarTheme.darkAppBarTheme,
    switchTheme: CustomSwitchTheme.darkSwitchTheme,
    sliderTheme: CustomSliderTheme.darkSliderTheme,
    textSelectionTheme: CustomTextSelectionTheme.darkTextSelectionTheme,
    bottomSheetTheme: CustomBottomSheetTheme.darkBottomSheetTheme,
  );
}
