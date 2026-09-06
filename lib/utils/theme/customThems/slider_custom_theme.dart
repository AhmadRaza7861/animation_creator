import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

class CustomSliderTheme {
  CustomSliderTheme._(); // Private constructor to prevent instantiation

  static const lightSliderTheme = SliderThemeData(
    activeTrackColor: ColorConstants.primary,
    inactiveTrackColor: Color(0xFFE2E8F0),
    disabledActiveTrackColor: Color(0x66FF9318),
    disabledInactiveTrackColor: Color(0x66E2E8F0),
    thumbColor: ColorConstants.primary,
    disabledThumbColor: Color(0x66FF9318),
    overlayColor: Color(0x1FFF9318),
    trackHeight: 4.0,
    thumbShape: CustomRoundSliderThumbShape(
      iconSize: 0,
      iconColor: Colors.transparent,
      enabledThumbRadius: 8.5,
      elevation: 2.5,
      pressedElevation: 4.5,
      borderColor: Colors.white,
    ),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 18.0),
    trackShape: GradientRectSliderTrackShape(
      colors: [ColorConstants.primary, Color(0xFFFFA726)],
    ),
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
    valueIndicatorColor: ColorConstants.primary,
    valueIndicatorTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    valueIndicatorShape: RectangularSliderValueIndicatorShape(),
    showValueIndicator: ShowValueIndicator.onDrag,
    rangeThumbShape: RoundRangeSliderThumbShape(
      enabledThumbRadius: 8.0,
      elevation: 2.5,
      pressedElevation: 4.5,
    ),
    rangeTrackShape: RoundedRectRangeSliderTrackShape(),
    rangeValueIndicatorShape: RectangularRangeSliderValueIndicatorShape(),
  );

  static const darkSliderTheme = SliderThemeData(
    activeTrackColor: ColorConstants.primary,
    inactiveTrackColor: Color(0xFF374151),
    disabledActiveTrackColor: Color(0x66FF9318),
    disabledInactiveTrackColor: Color(0x66374151),
    thumbColor: ColorConstants.primary,
    disabledThumbColor: Color(0x66FF9318),
    overlayColor: Color(0x29FF9318),
    trackHeight: 4.0,
    thumbShape: CustomRoundSliderThumbShape(
      iconSize: 0,
      iconColor: Colors.transparent,
      enabledThumbRadius: 8.5,
      elevation: 2.5,
      pressedElevation: 4.5,
      borderColor: Colors.white,
    ),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 18.0),
    trackShape: GradientRectSliderTrackShape(
      colors: [ColorConstants.primary, Color(0xFFFFA726)],
    ),
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
    valueIndicatorColor: ColorConstants.primary,
    valueIndicatorTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    valueIndicatorShape: RectangularSliderValueIndicatorShape(),
    showValueIndicator: ShowValueIndicator.onDrag,
    rangeThumbShape: RoundRangeSliderThumbShape(
      enabledThumbRadius: 8.0,
      elevation: 2.5,
      pressedElevation: 4.5,
    ),
    rangeTrackShape: RoundedRectRangeSliderTrackShape(),
    rangeValueIndicatorShape: RectangularRangeSliderValueIndicatorShape(),
  );
}

class GradientRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const GradientRectSliderTrackShape({
    this.colors = const [ColorConstants.primary, Color(0xFFFFA726)],
    this.darkenInactive = true,
  });

  final List<Color> colors;
  final bool darkenInactive;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    Offset? secondaryOffset,
    double additionalActiveTrackHeight = 1.0,
  }) {
    final Color activeColor =
        sliderTheme.activeTrackColor ?? ColorConstants.primary;
    final Color inactiveColor =
        sliderTheme.inactiveTrackColor ?? const Color(0xFFE2E8F0);
    final Color disabledActiveColor = sliderTheme.disabledActiveTrackColor ??
        activeColor.withValues(alpha: 0.4);
    final Color disabledInactiveColor = sliderTheme.disabledInactiveTrackColor ??
        inactiveColor.withValues(alpha: 0.4);

    final List<Color> activeColors =
        colors.isNotEmpty ? colors : [activeColor, activeColor];
    final gradient = LinearGradient(colors: activeColors);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeGradientRect = Rect.fromLTRB(
      trackRect.left,
      (textDirection == TextDirection.ltr)
          ? trackRect.top - (additionalActiveTrackHeight / 2)
          : trackRect.top,
      thumbCenter.dx,
      (textDirection == TextDirection.ltr)
          ? trackRect.bottom + (additionalActiveTrackHeight / 2)
          : trackRect.bottom,
    );

    final ColorTween activeTrackColorTween = ColorTween(
      begin: disabledActiveColor,
      end: activeColor,
    );
    final ColorTween inactiveTrackColorTween = darkenInactive
        ? ColorTween(
            begin: disabledInactiveColor,
            end: inactiveColor,
          )
        : activeTrackColorTween;

    final Paint activePaint = Paint()
      ..shader = (activeColors.length > 1)
          ? gradient.createShader(activeGradientRect)
          : null
      ..color = activeTrackColorTween.evaluate(enableAnimation) ?? activeColor;
    final Paint inactivePaint = Paint()
      ..color =
          inactiveTrackColorTween.evaluate(enableAnimation) ?? inactiveColor;

    final Paint leftTrackPaint;
    final Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    // Left track segment
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        topRight: (textDirection == TextDirection.ltr)
            ? Radius.zero
            : activeTrackRadius,
        bottomRight: (textDirection == TextDirection.ltr)
            ? Radius.zero
            : activeTrackRadius,
      ),
      leftTrackPaint,
    );

    // Right track segment
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        (textDirection == TextDirection.rtl)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        trackRect.right,
        (textDirection == TextDirection.rtl)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        topLeft: (textDirection == TextDirection.rtl)
            ? Radius.zero
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.rtl)
            ? Radius.zero
            : trackRadius,
      ),
      rightTrackPaint,
    );
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}

class CustomRoundSliderThumbShape extends SliderComponentShape {
  /// Create a slider thumb that draws a circle with an outer border and subtle shadow.
  const CustomRoundSliderThumbShape({
    this.enabledThumbRadius = 8.5,
    this.disabledThumbRadius,
    this.elevation = 2.0,
    this.pressedElevation = 4.5,
    this.borderColor = Colors.white,
    this.iconSize = 0,
    this.iconData = Icons.circle,
    this.iconColor = Colors.transparent,
  });

  /// The preferred borderColor of the thumb.
  final Color borderColor;
  final Color iconColor;
  final IconData iconData;
  final double iconSize;

  /// The preferred radius of the round thumb shape when the slider is enabled.
  final double enabledThumbRadius;

  /// The preferred radius of the round thumb shape when the slider is disabled.
  final double? disabledThumbRadius;

  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  /// The resting elevation adds shadow to the unpressed thumb.
  final double elevation;

  /// The pressed elevation adds shadow to the pressed thumb.
  final double pressedElevation;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
      isEnabled ? enabledThumbRadius : _disabledThumbRadius,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final Color thumbColor =
        sliderTheme.thumbColor ?? ColorConstants.primary;
    final Color disabledThumbColor = sliderTheme.disabledThumbColor ??
        thumbColor.withValues(alpha: 0.4);
    final ColorTween colorTween = ColorTween(
      begin: disabledThumbColor,
      end: thumbColor,
    );

    final Color color = colorTween.evaluate(enableAnimation) ?? thumbColor;
    final double radius = radiusTween.evaluate(enableAnimation);

    final Tween<double> elevationTween = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    );

    final double evaluatedElevation =
        elevationTween.evaluate(activationAnimation);
    final Path path = Path()
      ..addArc(
        Rect.fromCenter(
          center: center,
          width: 2 * radius,
          height: 2 * radius,
        ),
        0,
        pi * 2,
      );

    if (evaluatedElevation > 0) {
      canvas.drawShadow(
        path,
        Colors.black.withValues(alpha: 0.3),
        evaluatedElevation,
        true,
      );
    }

    // Outer border (white ring)
    canvas.drawCircle(center, radius, Paint()..color = borderColor);

    // Inner primary circle
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()..color = color,
    );

    if (iconSize > 0 && iconColor != Colors.transparent) {
      final TextSpan span = TextSpan(
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: iconData.fontFamily,
          color: iconColor,
          package: iconData.fontPackage,
          fontFamilyFallback: iconData.fontFamilyFallback,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        text: String.fromCharCode(iconData.codePoint),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final Offset textCenter =
          Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));
      tp.paint(canvas, textCenter);
    }
  }
}
