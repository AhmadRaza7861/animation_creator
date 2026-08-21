import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';

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
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Background Presets',
          style: TextStyle(
            color: AppColors.darkText,
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
                          color: isSelected ? AppColors.primary : Colors.transparent,
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
                                child: preset['value'] == null
                                    ? const SizedBox()
                                    : CustomPaint(
                                        painter: PreviewPatternPainter(preset['value'] as String),
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
                                          color: isSelected ? AppColors.primary : AppColors.darkText,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
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
                    backgroundColor: AppColors.primary,
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
