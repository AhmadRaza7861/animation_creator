import 'package:dummy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import '../constants/app_colors.dart';
import 'primary_button.dart';

class ColorPickerScreen extends StatefulWidget {
  final Color initialColor;
  final double initialOpacity;
  final void Function(Color color, double opacity) onColorChanged;

  const ColorPickerScreen({
    super.key,
    required this.initialColor,
    required this.initialOpacity,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  late double _hue;
  late double _chroma;
  late double _tone;
  late double _opacity;
  late double _saturation;
  late double _value;
  late TextEditingController _hexController;
  late TextEditingController _opacityController;
  late FocusNode _hexFocusNode;
  late FocusNode _opacityFocusNode;
  bool _copied = false;

  final List<Color> _presets = [
    const Color(0xFFFF9214), // Primary Orange
    const Color(0xFFE53935), // Red
    const Color(0xFFD81B60), // Pink
    const Color(0xFF8E24AA), // Purple
    const Color(0xFF5E35B1), // Deep Purple
    const Color(0xFF3949AB), // Indigo
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF039BE5), // Light Blue
    const Color(0xFF00ACC1), // Cyan
    const Color(0xFF00897B), // Teal
    const Color(0xFF43A047), // Green
    const Color(0xFF7CB342), // Light Green
    const Color(0xFFC0CA33), // Lime
    const Color(0xFFFDD835), // Yellow
    const Color(0xFFFFB300), // Amber
    const Color(0xFFF4511E), // Deep Orange
    const Color(0xFF795548), // Brown
    const Color(0xFF757575), // Grey
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF000000), // Black
    const Color(0xFFFFFFFF), // White
  ];

  @override
  void initState() {
    super.initState();
    final color = widget.initialColor;
    final hct = Hct.fromInt(color.value);
    _hue = hct.hue;
    _chroma = hct.chroma;
    _tone = hct.tone;
    _opacity = widget.initialOpacity;

    final hsv = HSVColor.fromColor(color);
    _saturation = hsv.saturation;
    _value = hsv.value;

    _hexController = TextEditingController(text: _colorToHex(color, _opacity));
    _opacityController = TextEditingController(text: '${(_opacity * 100).round()}%');

    _hexFocusNode = FocusNode();
    _hexFocusNode.addListener(() {
      if (!_hexFocusNode.hasFocus) {
        _updateFromHex(_hexController.text);
      }
    });

    _opacityFocusNode = FocusNode();
    _opacityFocusNode.addListener(() {
      if (!_opacityFocusNode.hasFocus) {
        _updateFromOpacityText(_opacityController.text);
      }
    });
  }

  @override
  void dispose() {
    _hexController.dispose();
    _opacityController.dispose();
    _hexFocusNode.dispose();
    _opacityFocusNode.dispose();
    super.dispose();
  }

  String _colorToHex(Color color, double opacity) {
    final int alpha = (opacity * 255).round();
    final String alphaHex = alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String redHex = color.red.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String greenHex = color.green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final String blueHex = color.blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$alphaHex$redHex$greenHex$blueHex';
  }

  void _updateColorState({
    double? hue,
    double? chroma,
    double? tone,
    double? saturation,
    double? value,
    double? opacity,
  }) {
    setState(() {
      if (opacity != null) {
        _opacity = opacity;
      }

      if (hue != null) {
        _hue = hue;
      }

      if (saturation != null && value != null) {
        _saturation = saturation;
        _value = value;

        final newColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
        final hct = Hct.fromInt(newColor.value);
        _chroma = hct.chroma;
        _tone = hct.tone;
      } else {
        if (chroma != null) _chroma = chroma;
        if (tone != null) _tone = tone;

        final hct = Hct.from(_hue, _chroma, _tone);
        final rgbColor = Color(hct.toInt());
        
        final hsv = HSVColor.fromColor(rgbColor);
        _saturation = hsv.saturation;
        _value = hsv.value;
      }

      _hexController.text = _colorToHex(_currentColor, _opacity);
      _opacityController.text = '${(_opacity * 100).round()}%';
    });
  }

  void _updateFromHex(String hex) {
    String cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final int? val = int.tryParse(cleanHex, radix: 16);
      if (val != null) {
        final color = Color(val);
        final hct = Hct.fromInt(color.value);
        final hsv = HSVColor.fromColor(color);
        setState(() {
          _hue = hct.hue;
          _chroma = hct.chroma.clamp(0.0, 120.0);
          _tone = hct.tone.clamp(0.0, 100.0);
          _opacity = color.opacity;
          _saturation = hsv.saturation;
          _value = hsv.value;
          _hexController.text = _colorToHex(_currentColor, _opacity);
          _opacityController.text = '${(_opacity * 100).round()}%';
        });
      }
    }
  }

  void _updateFromOpacityText(String text) {
    final String cleanText = text.replaceAll('%', '').trim();
    final int? val = int.tryParse(cleanText);
    if (val != null) {
      _updateColorState(opacity: (val.clamp(0, 100) / 100.0));
    }
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor().withOpacity(_opacity);
  }

  Color hctToColor(double h, double c, double t, double o) {
    final hct = Hct.from(h, c, t);
    return Color(hct.toInt()).withOpacity(o);
  }

  @override
  Widget build(BuildContext context) {
    final curColor = _currentColor;
    final rgbColor = Color.fromARGB(255, curColor.red, curColor.green, curColor.blue);
    final corePalette = CorePalette.of(Hct.from(_hue, _chroma, _tone).toInt());
    final tones = [10, 30, 50, 70, 90, 95];

    // Compute active hue color for the SV area background
    final hueColor = HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title:  Text(
          StringConstants.color_picker,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: ColorConstants.darkText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Saturation-Value 2D Area
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  const double height = 150.0;

                  final double thumbX = _saturation * width;
                  final double thumbY = (1.0 - _value) * height;

                  void handleGesture(Offset localPosition) {
                    final double s = (localPosition.dx / width).clamp(0.0, 1.0);
                    final double v = (1.0 - (localPosition.dy / height)).clamp(0.0, 1.0);
                    _updateColorState(saturation: s, value: v);
                  }

                  return GestureDetector(
                    onPanDown: (details) => handleGesture(details.localPosition),
                    onPanUpdate: (details) => handleGesture(details.localPosition),
                    onTapDown: (details) => handleGesture(details.localPosition),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          // SV Gradient Box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: CustomPaint(
                                painter: SaturationValuePainter(hueColor: hueColor),
                              ),
                            ),
                          ),
                          // Drag Thumb
                          Positioned(
                            left: thumbX - 9,
                            top: thumbY - 9,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.24),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1.5),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              // 2. Sliders (Hue, Chroma, Tone, Opacity)
              _buildSliderLabel(StringConstants.hue, '${_hue.round()}°'),
             // const SizedBox(height: 4),
              _buildSliderTrack(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000), // Red
                    Color(0xFFFFB700), // Orange/Yellow
                    Color(0xFF00FF00), // Green
                    Color(0xFF00FFFF), // Cyan
                    Color(0xFF0000FF), // Blue
                    Color(0xFFFF00FF), // Magenta
                    Color(0xFFFF0000), // Red
                  ],
                ),
                child: Slider(
                  value: _hue,
                  min: 0.0,
                  max: 360.0,
                  onChanged: (val) => _updateColorState(hue: val),
                ),
              ),
              //const SizedBox(height: 10),

              _buildSliderLabel(StringConstants.tone, '${_tone.round()}%'),
              //const SizedBox(height: 4),
              _buildSliderTrack(
                gradient: LinearGradient(
                  colors: [
                    hctToColor(_hue, _chroma, 0.0, 1.0),
                    hctToColor(_hue, _chroma, 50.0, 1.0),
                    hctToColor(_hue, _chroma, 100.0, 1.0),
                  ],
                ),
                child: Slider(
                  value: _tone,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (val) => _updateColorState(tone: val),
                ),
              ),
             // const SizedBox(height: 10),

              _buildSliderLabel(StringConstants.opacity, '${(_opacity * 100).round()}%'),
             // const SizedBox(height: 4),
              _buildSliderTrack(
                isCheckered: true,
                gradient: LinearGradient(
                  colors: [
                    rgbColor.withOpacity(0.0),
                    rgbColor.withOpacity(1.0),
                  ],
                ),
                child: Slider(
                  value: _opacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) => _updateColorState(opacity: val),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Formatted inputs with Selected Color Preview Box
              Row(
                children: [
                  // Active Color Preview Box (with Checkerboard Background)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: const CheckeredPainter(),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              color: curColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Hex Dropdown Selector
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hex',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.mediumText,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Hex Input Field
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _hexController,
                        focusNode: _hexFocusNode,
                        onChanged: _updateFromHex,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: ColorConstants.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Opacity Percentage Input Field
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _opacityController,
                        focusNode: _opacityFocusNode,
                        onChanged: (text) => _updateFromOpacityText(text),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: ColorConstants.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Dynamic Tonal Palette Section
              const Text(
                'Harmonic Tonal Palette',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tones.map((t) {
                  final colorVal = corePalette.primary.get(t);
                  final toneColor = Color(colorVal);
                  final isSelected = _tone.round() == t;
                  return GestureDetector(
                    onTap: () {
                      final hct = Hct.fromInt(colorVal);
                      _updateColorState(
                        hue: hct.hue,
                        chroma: hct.chroma,
                        tone: hct.tone,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? ColorConstants.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: toneColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 5. Preset Brand Swatches
              const Text(
                'Curated Presets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final color = _presets[index];
                  final isPresetSelected = rgbColor.red == color.red &&
                                           rgbColor.green == color.green &&
                                           rgbColor.blue == color.blue;
                  return GestureDetector(
                    onTap: () {
                      final hct = Hct.fromInt(color.value);
                      _updateColorState(
                        hue: hct.hue,
                        chroma: hct.chroma,
                        tone: hct.tone,
                      );
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPresetSelected ? ColorConstants.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1.0),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: PrimaryButton(
            text: 'Apply Color',
            onPressed: () {
              widget.onColorChanged(rgbColor, _opacity);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorConstants.darkText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ColorConstants.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTrack({
    required Gradient gradient,
    required Widget child,
    bool isCheckered = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Track Background
        Positioned(
          left: 10,
          right: 10,
          child: Stack(
            children: [
              if (isCheckered)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      painter: const CheckeredPainter(),
                    ),
                  ),
                ),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: gradient,
                  border: isCheckered ? Border.all(color: Colors.grey.shade300, width: 0.5) : null,
                ),
              ),
            ],
          ),
        ),
        // Slider on top
        SliderTheme(
          data: SliderThemeData(
            trackShape: const RectangularSliderTrackShape(),
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            overlayColor: ColorConstants.primary.withValues(alpha: 0.12),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 2,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class SaturationValuePainter extends CustomPainter {
  final Color hueColor;

  const SaturationValuePainter({required this.hueColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Horizontal Gradient (White to Hue Color)
    final horizontalGradient = LinearGradient(
      colors: [Colors.white, hueColor],
    );
    final horizontalPaint = Paint()
      ..shader = horizontalGradient.createShader(rect);
    canvas.drawRect(rect, horizontalPaint);

    // 2. Vertical Gradient (Transparent to Black)
    final verticalGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    final verticalPaint = Paint()
      ..shader = verticalGradient.createShader(rect)
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(rect, verticalPaint);
  }

  @override
  bool shouldRepaint(covariant SaturationValuePainter oldDelegate) {
    return oldDelegate.hueColor != hueColor;
  }
}

class CheckeredPainter extends CustomPainter {
  const CheckeredPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade200;
    const double squareSize = 6.0;
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        if ((x / squareSize).floor() % 2 == (y / squareSize).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
