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
  late TextEditingController _hexController;
  late FocusNode _hexFocusNode;
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

    _hexController = TextEditingController(text: _colorToHex(color, _opacity));
    _hexFocusNode = FocusNode();
    _hexFocusNode.addListener(() {
      if (!_hexFocusNode.hasFocus) {
        _updateFromHex(_hexController.text);
      }
    });
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocusNode.dispose();
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

  void _updateFromHex(String hex) {
    String cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final int? value = int.tryParse(cleanHex, radix: 16);
      if (value != null) {
        final color = Color(value);
        final hct = Hct.fromInt(color.value);
        setState(() {
          _hue = hct.hue;
          _chroma = hct.chroma.clamp(0.0, 120.0);
          _tone = hct.tone.clamp(0.0, 100.0);
          _opacity = color.opacity;
        });
      }
    }
  }

  Color get _currentColor {
    final hct = Hct.from(_hue, _chroma, _tone);
    return Color(hct.toInt()).withOpacity(_opacity);
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'HCT Color Picker',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Color Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.border_color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Color circle with checker background
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CustomPaint(
                              painter: const CheckeredPainter(),
                            ),
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: curColor,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Hex and RGB stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _hexController,
                                    focusNode: _hexFocusNode,
                                    onChanged: _updateFromHex,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstants.darkText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _copied ? Icons.check_circle : Icons.copy_all_rounded,
                                  color: _copied ? Colors.green : ColorConstants.primary,
                                  size: 24,
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _hexController.text));
                                  setState(() {
                                    _copied = true;
                                  });
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() {
                                        _copied = false;
                                      });
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'RGB: ${rgbColor.red}, ${rgbColor.green}, ${rgbColor.blue}  |  Alpha: ${(_opacity * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.mediumText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Sliders
              _buildSliderLabel('Hue (Color Family)', '${_hue.round()}°'),
              const SizedBox(height: 6),
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
                  onChanged: (val) {
                    setState(() {
                      _hue = val;
                      _hexController.text = _colorToHex(_currentColor, _opacity);
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),

              _buildSliderLabel('Chroma (Color Intensity)', '${_chroma.round()}'),
              const SizedBox(height: 6),
              _buildSliderTrack(
                gradient: LinearGradient(
                  colors: [
                    hctToColor(_hue, 0.0, _tone, 1.0),
                    hctToColor(_hue, 120.0, _tone, 1.0),
                  ],
                ),
                child: Slider(
                  value: _chroma,
                  min: 0.0,
                  max: 120.0,
                  onChanged: (val) {
                    setState(() {
                      _chroma = val;
                      _hexController.text = _colorToHex(_currentColor, _opacity);
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),

              _buildSliderLabel('Tone (Lightness)', '${_tone.round()}%'),
              const SizedBox(height: 6),
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
                  onChanged: (val) {
                    setState(() {
                      _tone = val;
                      _hexController.text = _colorToHex(_currentColor, _opacity);
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),

              _buildSliderLabel('Opacity (Alpha)', '${(_opacity * 100).round()}%'),
              const SizedBox(height: 6),
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
                  onChanged: (val) {
                    setState(() {
                      _opacity = val;
                      _hexController.text = _colorToHex(_currentColor, _opacity);
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Dynamic Tonal Palette Section
              const Text(
                'Harmonic Tonal Palette',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tones.map((t) {
                  final colorVal = corePalette.primary.get(t);
                  final toneColor = Color(colorVal);
                  return GestureDetector(
                    onTap: () {
                      final hct = Hct.fromInt(colorVal);
                      setState(() {
                        _hue = hct.hue;
                        _chroma = hct.chroma;
                        _tone = hct.tone;
                        _hexController.text = _colorToHex(_currentColor, _opacity);
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: toneColor,
                        border: Border.all(
                          color: _tone.round() == t ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (_tone.round() == t)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 4. Preset Brand Swatches
              const Text(
                'Curated Presets',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final color = _presets[index];
                  return GestureDetector(
                    onTap: () {
                      final hct = Hct.fromInt(color.value);
                      setState(() {
                        _hue = hct.hue;
                        _chroma = hct.chroma;
                        _tone = hct.tone;
                        _hexController.text = _colorToHex(_currentColor, _opacity);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1.5),
                          )
                        ],
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
          left: 12,
          right: 12,
          child: Stack(
            children: [
              if (isCheckered)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: const CheckeredPainter(),
                    ),
                  ),
                ),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
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
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            overlayColor: ColorConstants.primary.withOpacity(0.12),
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 3,
            ),
          ),
          child: child,
        ),
      ],
    );
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
