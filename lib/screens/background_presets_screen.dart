import 'dart:math';
import 'package:flutter/material.dart';

class BackgroundPresetsScreen extends StatefulWidget {
  final String? initialPattern;

  const BackgroundPresetsScreen({super.key, this.initialPattern});

  @override
  State<BackgroundPresetsScreen> createState() => _BackgroundPresetsScreenState();
}

class _BackgroundPresetsScreenState extends State<BackgroundPresetsScreen> {
  String? _selectedPattern;

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Plain', 'value': null, 'desc': 'Clean solid white canvas'},
    {'name': 'Grid Paper', 'value': 'grid', 'desc': 'Standard square grid'},
    {'name': 'Dot Paper', 'value': 'dots', 'desc': 'Spacing dotted layout'},
    {'name': 'Lined Paper', 'value': 'lines', 'desc': 'Notebook lines with margin'},
    {'name': 'Checkerboard', 'value': 'checkboard', 'desc': 'Alternating checker grid'},
    {'name': 'Isometric Grid', 'value': 'isometric', 'desc': '3D perspective grid'},
    {'name': 'Blueprint', 'value': 'blueprint', 'desc': 'Architectural grid'},
    {'name': 'Graph Paper', 'value': 'graph', 'desc': 'Technical layout paper'},
    {'name': 'Polar Grid', 'value': 'polar', 'desc': 'Radial polar layout'},
    {'name': 'Brick Wall', 'value': 'brick', 'desc': 'Offset brick wall guide'},
    {'name': 'Music Staff', 'value': 'music', 'desc': 'Music staff lines guide'},
    {'name': 'Honeycomb Hex', 'value': 'hex', 'desc': 'Hexagonal honeycomb grid'},
    {'name': 'Cross Grid', 'value': 'cross', 'desc': 'Cross mark guide nodes'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.initialPattern;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF3C3043)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Background Presets',
          style: TextStyle(
            color: Color(0xFF3C3043),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  final isSelected = _selectedPattern == preset['value'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPattern = preset['value'] as String?;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF9114) : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Container(
                                color: preset['value'] == 'blueprint'
                                    ? const Color(0xFF1E3D59)
                                    : (preset['value'] == 'graph' ? const Color(0xFFF1F8F6) : const Color(0xFFFAF9F6)),
                                child: CustomPaint(
                                  painter: _PresetPreviewPainter(preset['value'] as String?),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        preset['name'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? const Color(0xFFFF9114) : const Color(0xFF3C3043),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFFF9114),
                                        size: 16,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9114),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {'pattern': _selectedPattern});
                  },
                  child: const Text(
                    'Select Preset',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetPreviewPainter extends CustomPainter {
  final String? pattern;

  _PresetPreviewPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == null) return;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    if (pattern == 'grid') {
      const double spacing = 15.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 15.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 18.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        const Offset(25, 0),
        Offset(25, size.height),
        marginPaint,
      );
    } else if (pattern == 'checkboard') {
      const double spacing = 20.0;
      final cellPaint = Paint()..color = Colors.black.withOpacity(0.04);
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          if (((x / spacing).floor() + (y / spacing).floor()) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(x, y, spacing, spacing), cellPaint);
          }
        }
      }
    } else if (pattern == 'isometric') {
      const double spacing = 16.0;
      final double h = spacing * 0.866025;
      for (double x = 0; x < size.width + spacing; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      final double slope = 0.57735;
      for (double y = -size.width * slope; y < size.height; y += h * 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * slope), paint);
        canvas.drawLine(Offset(0, y + size.width * slope), Offset(size.width, y), paint);
      }
    } else if (pattern == 'blueprint') {
      final bpPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 1.0;
      const double spacing = 16.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bpPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bpPaint);
      }
    } else if (pattern == 'graph') {
      final minorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.08)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.2)
        ..strokeWidth = 1.0;
      const double minorSpacing = 6.0;
      const double majorSpacing = 30.0;
      for (double x = 0; x < size.width; x += minorSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % majorSpacing == 0) ? majorPaint : minorPaint);
      }
      for (double y = 0; y < size.height; y += minorSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), (y % majorSpacing == 0) ? majorPaint : minorPaint);
      }
    } else if (pattern == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
      for (double r = 20.0; r < maxRadius; r += 20.0) {
        canvas.drawCircle(center, r, paint);
      }
      for (int angle = 0; angle < 360; angle += 30) {
        final rad = angle * pi / 180;
        final end = center + Offset(cos(rad) * maxRadius, sin(rad) * maxRadius);
        canvas.drawLine(center, end, paint);
      }
    } else if (pattern == 'brick') {
      const double brickW = 30.0;
      const double brickH = 15.0;
      int rowIndex = 0;
      for (double y = 0; y < size.height + brickH; y += brickH) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        final double offset = (rowIndex % 2 == 0) ? 0 : brickW / 2;
        for (double x = -offset; x < size.width + brickW; x += brickW) {
          canvas.drawLine(Offset(x, y), Offset(x, y + brickH), paint);
        }
        rowIndex++;
      }
    } else if (pattern == 'music') {
      const double lineSpacing = 6.0;
      const double groupSpacing = 28.0;
      double y = 15.0;
      while (y < size.height - 20.0) {
        for (int i = 0; i < 5; i++) {
          final double py = y + i * lineSpacing;
          canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
        }
        y += 4 * lineSpacing + groupSpacing;
      }
    } else if (pattern == 'hex') {
      const double r = 12.0;
      final double h = r * sin(pi / 3);
      final path = Path();
      for (double x = 0; x < size.width + r * 2; x += r * 3) {
        int col = 0;
        for (double y = 0; y < size.height + r * 2; y += h) {
          final double ox = (col % 2 == 0) ? 0 : r * 1.5;
          path.moveTo(ox + x, y);
          path.lineTo(ox + x + r / 2, y + h);
          path.lineTo(ox + x + r * 1.5, y + h);
          path.lineTo(ox + x + r * 2, y);
          col++;
        }
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    } else if (pattern == 'cross') {
      const double spacing = 18.0;
      const double crossSize = 2.0;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), paint);
          canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PresetPreviewPainter oldDelegate) =>
      oldDelegate.pattern != pattern;
}
