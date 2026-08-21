import 'dart:math';
import 'package:flutter/material.dart';

class CustomSliderTheme {
  CustomSliderTheme._(); // Private constructor to prevent instantiation

  static const lightSliderTheme = SliderThemeData(
    // activeTrackColor: Color(0xFF866ABE),
    // Track color when slider is active
    inactiveTrackColor:Colors.white,
    // // Track color when slider is inactive
    thumbColor: Color(0xFF866ABE),
    // Thumb color
    overlayColor: Colors.transparent,
    // // Overlay color when thumb is pressed
    trackHeight: 4.0,
    // Custom track height
    thumbShape: CustomRoundSliderThumbShape(
        iconSize: 12,
        iconColor: Colors.transparent,
        enabledThumbRadius: 8,
        elevation: 3),
    // Thumb shape
    //  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
    // // Overlay shape
    trackShape:
    GradientRectSliderTrackShape(colors:[Color(0xFF866ABE),Color(0xFF866ABE)]),
    // // Tick mark shape
    activeTickMarkColor: Colors.transparent,
    // Active tick mark color
     inactiveTickMarkColor: Colors.transparent,
     // Inactive tick mark color
     valueIndicatorColor: Colors.transparent,
    // // Value indicator color
    // valueIndicatorTextStyle:
    //     TextStyle(color: Colors.white), // Value indicator text style
  );

  static const darkSliderTheme = SliderThemeData(
  // activeTrackColor: Color(0xFF866ABE),
  // Track color when slider is active
  inactiveTrackColor:Colors.white,
  // // Track color when slider is inactive
  thumbColor: Color(0xFF866ABE),
  // Thumb color
  overlayColor: Colors.transparent,
  // // Overlay color when thumb is pressed
  trackHeight: 4.0,
  // Custom track height
  thumbShape: CustomRoundSliderThumbShape(
  iconSize: 12,
  iconColor: Colors.transparent,
  enabledThumbRadius: 8,
  elevation: 3),
  // Thumb shape
  //  overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
  // // Overlay shape
  trackShape:
  GradientRectSliderTrackShape(colors:[Color(0xFF866ABE),Color(0xFF866ABE)]),
  // // Tick mark shape
  activeTickMarkColor: Colors.transparent,
  // Active tick mark color
  inactiveTickMarkColor: Colors.transparent,
  // Inactive tick mark color
  valueIndicatorColor: Colors.transparent,
// // Value indicator color
// valueIndicatorTextStyle:
//     TextStyle(color: Colors.white), // Value indicator text style

  );}

class GradientRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const GradientRectSliderTrackShape({
    required this.colors,
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
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(sliderTheme.trackHeight != null && sliderTheme.trackHeight! > 0);
    final gradient = LinearGradient(colors: colors);
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

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = darkenInactive
        ? ColorTween(
            begin: sliderTheme.disabledInactiveTrackColor,
            end: sliderTheme.inactiveTrackColor)
        : activeTrackColorTween;
    final Paint activePaint = Paint()
      ..shader = gradient.createShader(activeGradientRect)
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
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
    final Radius activeTrackRadius = Radius.circular(trackRect.height / 2 + 1);

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
      ),
      leftTrackPaint,
    );
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
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}

class CustomRoundSliderThumbShape extends SliderComponentShape {
  /// Create a slider thumb that draws a circle.
  const CustomRoundSliderThumbShape(
      {this.enabledThumbRadius = 10.0,
      this.disabledThumbRadius,
      this.elevation = 1.0,
      this.pressedElevation = 6.0,
      this.borderColor = Colors.white,
      this.iconSize = 14,
      this.iconData = Icons.code_sharp,
      this.iconColor = Colors.white});

  /// The preferred borderColor of the thumb.
  ///
  /// If it is not provided, then the Material Design default white is used.
  final Color borderColor;
  final Color iconColor;
  final IconData iconData;
  final double iconSize;

  /// The preferred radius of the round thumb shape when the slider is enabled.
  ///
  /// If it is not provided, then the Material Design default of 10 is used.
  final double enabledThumbRadius;

  /// The preferred radius of the round thumb shape when the slider is disabled.
  ///
  /// If no disabledRadius is provided, then it is equal to the
  /// [enabledThumbRadius]
  final double? disabledThumbRadius;

  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  /// The resting elevation adds shadow to the unpressed thumb.
  ///
  /// The default is 1.
  ///
  /// Use 0 for no shadow. The higher the value, the larger the shadow. For
  /// example, a value of 12 will create a very large shadow.
  ///
  final double elevation;

  /// The pressed elevation adds shadow to the pressed thumb.
  ///
  /// The default is 6.
  ///
  /// Use 0 for no shadow. The higher the value, the larger the shadow. For
  /// example, a value of 12 will create a very large shadow.
  final double pressedElevation;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled ? enabledThumbRadius : _disabledThumbRadius);
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
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final TextSpan span = TextSpan(
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: iconData.fontFamily,

          color: iconColor,
          package: iconData.fontPackage,
          fontFamilyFallback: iconData.fontFamilyFallback,

          height: 1.0,
          // Makes sure the font's body is vertically centered within the iconSize x iconSize square.
          leadingDistribution: TextLeadingDistribution.even,
        ),
        text: String.fromCharCode(iconData.codePoint));
    final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    final Offset textCenter =
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    final Color color = colorTween.evaluate(enableAnimation)!;
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
              center: center, width: 2 * radius, height: 2 * radius),
          0,
          pi * 2);

    bool paintShadows = true;
    assert(() {
      if (debugDisableShadows) {
        paintShadows = false;
      }
      return true;
    }());

    if (paintShadows) {
      canvas.drawShadow(path, Colors.black, evaluatedElevation, true);
    }
    canvas.drawCircle(center, radius, Paint()..color = borderColor);

    canvas.drawCircle(
      center,
      radius * 0.8,
      Paint()..color = color,
    );
    tp.paint(canvas, textCenter);
  }
}
