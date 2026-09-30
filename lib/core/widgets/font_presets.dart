import 'package:flutter/material.dart';
import '../services/runtime_font_service.dart';

class FontPreset {
  final String name;
  final String? fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final double letterSpacing;
  final String? fallbackFamily;

  const FontPreset({
    required this.name,
    this.fontFamily,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.letterSpacing = 0.0,
    this.fallbackFamily,
  });

  TextStyle getTextStyle({
    required Color color,
    required double fontSize,
    double opacity = 1.0,
    bool forceBold = false,
    bool forceItalic = false,
    bool forceUnderline = false,
  }) {
    final effectiveColor = color.withOpacity(opacity);
    final isLoaded = fontFamily == null ||
        RuntimeFontService.instance.isFontLoaded(fontFamily);

    final effectiveFamily = isLoaded ? fontFamily : (fallbackFamily ?? fontFamily);

    return TextStyle(
      color: effectiveColor,
      fontSize: fontSize,
      fontFamily: effectiveFamily,
      fontWeight: forceBold
          ? FontWeight.bold
          : (fontWeight != FontWeight.normal ? fontWeight : FontWeight.normal),
      fontStyle: forceItalic
          ? FontStyle.italic
          : (fontStyle != FontStyle.normal ? fontStyle : FontStyle.normal),
      decoration: forceUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: effectiveColor,
      letterSpacing: letterSpacing,
    );
  }
}

const List<FontPreset> fontPresets = [
  FontPreset(
    name: 'Alex Brush',
    fontFamily: 'AlexBrush',
    fontStyle: FontStyle.italic,
    fallbackFamily: 'cursive',
    letterSpacing: 1.0,
  ),
  FontPreset(
    name: 'Art Typo',
    fontFamily: 'ArtTypo',
    fontWeight: FontWeight.w900,
    fallbackFamily: 'monospace',
    letterSpacing: -0.5,
  ),
  FontPreset(
    name: 'Avara',
    fontFamily: 'Avara',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'Battlestar',
    fontFamily: 'Battlestar',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'monospace',
    letterSpacing: 2.0,
  ),
  FontPreset(
    name: 'Boom Box',
    fontFamily: 'BoomBox',
    fontWeight: FontWeight.w800,
    fallbackFamily: 'sans-serif',
    letterSpacing: 1.5,
  ),
  FontPreset(
    name: 'Cameo Antique',
    fontFamily: 'CameoAntique',
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'Charakterny',
    fontFamily: 'Charakterny',
    fontStyle: FontStyle.italic,
    fallbackFamily: 'cursive',
    letterSpacing: 0.5,
  ),
  FontPreset(
    name: 'ClearSans Bold',
    fontFamily: 'ClearSans-Bold',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'ClearSans Light',
    fontFamily: 'ClearSans-Light',
    fontWeight: FontWeight.w300,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'ClearSans Regular',
    fontFamily: 'ClearSans-Regular',
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'ComicNeue Bold',
    fontFamily: 'ComicNeue-Bold',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'ComicNeue Regular',
    fontFamily: 'ComicNeue-Regular',
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Comili Book',
    fontFamily: 'ComiliBook',
    fontWeight: FontWeight.w600,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'CooperHewitt Book',
    fontFamily: 'CooperHewittBook',
    fontWeight: FontWeight.w400,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Earwig Factory',
    fontFamily: 'EarwigFactory',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'monospace',
  ),
  FontPreset(
    name: 'Exo Bold',
    fontFamily: 'Exo-Bold',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Exo Regular',
    fontFamily: 'Exo-Regular',
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Exo Thin',
    fontFamily: 'Exo-Thin',
    fontWeight: FontWeight.w200,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Garineldo',
    fontFamily: 'Garineldo',
    fontStyle: FontStyle.italic,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'Garineldo No1',
    fontFamily: 'GarineldoNo1',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'Liner',
    fontFamily: 'Liner',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Mathilde',
    fontFamily: 'Mathilde',
    fontStyle: FontStyle.italic,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'Mirage',
    fontFamily: 'Mirage',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'New Waltograph',
    fontFamily: 'NewWaltograph',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'NumbBunny',
    fontFamily: 'NumbBunny',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'cursive',
  ),
  FontPreset(
    name: 'PRIDA61',
    fontFamily: 'PRIDA61',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'PRIDA65',
    fontFamily: 'PRIDA65',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'RocketFuel',
    fontFamily: 'RocketFuel',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'RocketFuel Outlined',
    fontFamily: 'RocketFuelOutlined',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Sadegnak No1',
    fontFamily: 'SadegnakNo1',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'serif',
  ),
  FontPreset(
    name: 'SUPER TIKI',
    fontFamily: 'SUPERTiki',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'WHYPO',
    fontFamily: 'WHYPO',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'sans-serif',
  ),
  FontPreset(
    name: 'Xolonium Bold',
    fontFamily: 'XoloniumBold',
    fontWeight: FontWeight.bold,
    fallbackFamily: 'monospace',
  ),
];

FontPreset getFontPresetByName(String? name) {
  if (name == null || name.isEmpty) return fontPresets.first;
  return fontPresets.firstWhere(
    (preset) => preset.name == name || preset.fontFamily == name,
    orElse: () => fontPresets.first,
  );
}
