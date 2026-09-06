import 'package:flutter/material.dart';

class FontPreset {
  final String name;
  final String? fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final double letterSpacing;

  const FontPreset({
    required this.name,
    this.fontFamily,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.letterSpacing = 0.0,
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
    return TextStyle(
      color: effectiveColor,
      fontSize: fontSize,
      fontFamily: fontFamily,
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
  FontPreset(name: 'Default', fontFamily: null),
  FontPreset(
    name: 'Alex Brush',
    fontFamily: 'serif',
    fontStyle: FontStyle.italic,
    letterSpacing: 1.0,
  ),
  FontPreset(
    name: 'Art Typo',
    fontFamily: 'monospace',
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
  ),
  FontPreset(name: 'Avara', fontFamily: 'serif', fontWeight: FontWeight.bold),
  FontPreset(
    name: 'Battlestar',
    fontFamily: 'monospace',
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
  ),
  FontPreset(
    name: 'Boom Box',
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  ),
  FontPreset(
    name: 'Cameo Antique',
    fontFamily: 'serif',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w300,
  ),
  FontPreset(name: 'Charakterny', fontFamily: 'cursive', letterSpacing: 0.5),
  FontPreset(
    name: 'ClearSans Bold',
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.bold,
  ),
  FontPreset(
    name: 'ClearSans Light',
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w300,
  ),
  FontPreset(name: 'ClearSans Regular', fontFamily: 'sans-serif'),
  FontPreset(
    name: 'ComicNeue Bold',
    fontFamily: 'sans-serif',
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
  ),
];

FontPreset getFontPresetByName(String? name) {
  if (name == null) return fontPresets.first;
  return fontPresets.firstWhere(
    (preset) => preset.name == name,
    orElse: () => fontPresets.first,
  );
}
