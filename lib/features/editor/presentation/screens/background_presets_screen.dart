import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_back_button.dart';

class BackgroundPresetsScreen extends StatefulWidget {
  final String? initialPattern;

  const BackgroundPresetsScreen({super.key, this.initialPattern});

  @override
  State<BackgroundPresetsScreen> createState() => _BackgroundPresetsScreenState();
}

class _BackgroundPresetsScreenState extends State<BackgroundPresetsScreen> {
  String? _selectedPattern;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Paper & Grid',
    'Animation',
    'Perspective',
    'Manga & Comic',
    'Aesthetic & Dark',
  ];

  final List<Map<String, dynamic>> _presets = [
    // --- ORIGINAL PRESETS (AT THE START) ---
    {'name': 'Plain', 'value': null, 'desc': 'Clean solid white canvas', 'category': 'Paper & Grid'},
    {'name': 'Grid Paper', 'value': 'grid', 'desc': 'Standard square grid', 'category': 'Paper & Grid'},
    {'name': 'Dot Paper', 'value': 'dots', 'desc': 'Spacing dotted layout', 'category': 'Paper & Grid'},
    {'name': 'Lined Paper', 'value': 'lines', 'desc': 'Notebook lines with margin', 'category': 'Paper & Grid'},
    {'name': 'Checkerboard', 'value': 'checkboard', 'desc': 'Alternating checker grid', 'category': 'Paper & Grid'},
    {'name': 'Isometric Grid', 'value': 'isometric', 'desc': '3D perspective grid', 'category': 'Perspective'},
    {'name': 'Blueprint', 'value': 'blueprint', 'desc': 'Architectural grid', 'category': 'Aesthetic & Dark'},
    {'name': 'Graph Paper', 'value': 'graph', 'desc': 'Technical layout paper', 'category': 'Paper & Grid'},
    {'name': 'Polar Grid', 'value': 'polar', 'desc': 'Radial polar layout', 'category': 'Manga & Comic'},
    {'name': 'Brick Wall', 'value': 'brick', 'desc': 'Offset brick wall guide', 'category': 'Paper & Grid'},
    {'name': 'Music Staff', 'value': 'music', 'desc': 'Music staff lines guide', 'category': 'Paper & Grid'},
    {'name': 'Honeycomb Hex', 'value': 'hex', 'desc': 'Hexagonal honeycomb grid', 'category': 'Paper & Grid'},
    {'name': 'Cross Grid', 'value': 'cross', 'desc': 'Cross mark guide nodes', 'category': 'Paper & Grid'},

    // --- NEW CREATIVE & ATTRACTIVE PRESETS (ADDED AT THE END) ---
    {
      'name': '12-Field Chart',
      'value': 'animation_field',
      'desc': 'Classic animation camera safe guide',
      'category': 'Animation',
      'badge': 'Pro',
    },
    {
      'name': 'Storyboard 6-Panel',
      'value': 'storyboard',
      'desc': 'Comic & film storyboard panels',
      'category': 'Animation',
      'badge': 'Film',
    },
    {
      'name': 'Rule of Thirds',
      'value': 'rule_of_thirds',
      'desc': '3x3 composition & power points',
      'category': 'Animation',
      'badge': 'Guide',
    },
    {
      'name': '1-Point Perspective',
      'value': 'perspective_1p',
      'desc': 'Horizon & vanishing point depth guide',
      'category': 'Perspective',
      'badge': '3D',
    },
    {
      'name': '2-Point Perspective',
      'value': 'perspective_2p',
      'desc': 'Dual horizon points for rooms & streets',
      'category': 'Perspective',
      'badge': '3D',
    },
    {
      'name': '3-Point Perspective',
      'value': 'perspective_3p',
      'desc': 'Dynamic dramatic camera angle guide',
      'category': 'Perspective',
      'badge': 'Dynamic',
    },
    {
      'name': '3D Isometric Cubes',
      'value': 'iso_cubes',
      'desc': 'Geometric cube wireframe guide',
      'category': 'Perspective',
      'badge': 'Voxel',
    },
    {
      'name': 'Manga Speed Lines',
      'value': 'speed_lines',
      'desc': 'Dynamic anime action burst focus',
      'category': 'Manga & Comic',
      'badge': 'Action',
    },
    {
      'name': 'Comic Screentone',
      'value': 'halftone',
      'desc': '45° manga halftone dot matrix',
      'category': 'Manga & Comic',
      'badge': 'Manga',
    },
    {
      'name': 'Pixel Art Grid',
      'value': 'pixel_grid',
      'desc': '8-bit micro grid with 8x8 character blocks',
      'category': 'Paper & Grid',
      'badge': '8-Bit',
    },
    {
      'name': 'Dark Cyber Neon',
      'value': 'dark_cyber',
      'desc': 'Sleek obsidian matrix with cyan neon glow',
      'category': 'Aesthetic & Dark',
      'badge': 'Neon',
    },
    {
      'name': 'Vintage Parchment',
      'value': 'parchment',
      'desc': 'Warm antique manuscript with border',
      'category': 'Aesthetic & Dark',
      'badge': 'Retro',
    },
    {
      'name': 'Chalkboard Slate',
      'value': 'chalkboard',
      'desc': 'Deep blackboard with soft chalk lines',
      'category': 'Aesthetic & Dark',
      'badge': 'Slate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.initialPattern;
  }

  List<Map<String, dynamic>> get _filteredPresets {
    if (_selectedCategory == 'All') {
      return _presets;
    }
    return _presets.where((p) => p['category'] == _selectedCategory).toList();
  }

  String _getCategoryLabel(BuildContext context, String cat) {
    switch (cat) {
      case 'All':
        return context.tr('categoryAll');
      case 'Paper & Grid':
        return context.tr('bgCatPaperGrid');
      case 'Animation':
        return context.tr('bgCatAnimation');
      case 'Perspective':
        return context.tr('bgCatPerspective');
      case 'Manga & Comic':
        return context.tr('bgCatMangaComic');
      case 'Aesthetic & Dark':
        return context.tr('bgCatAestheticDark');
      default:
        return cat;
    }
  }

  String _getPresetName(BuildContext context, Map<String, dynamic> preset) {
    final String val = preset['value'] == null ? 'plain' : '${preset['value']}';
    final String key = 'bg_${val}_name';
    final String tr = context.tr(key);
    return tr == key ? (preset['name'] as String) : tr;
  }

  String _getPresetDesc(BuildContext context, Map<String, dynamic> preset) {
    final String val = preset['value'] == null ? 'plain' : '${preset['value']}';
    final String key = 'bg_${val}_desc';
    final String tr = context.tr(key);
    return tr == key ? (preset['desc'] as String) : tr;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPresets;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: Text(
          context.tr('backgroundPresets'),
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Chips
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isCatSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCatSelected ? ColorConstants.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isCatSelected
                            ? [
                                BoxShadow(
                                  color: ColorConstants.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _getCategoryLabel(context, cat),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCatSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isCatSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Presets Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final preset = filtered[index];
                  final isSelected = _selectedPattern == preset['value'];
                  final String? patternValue = preset['value'] as String?;
                  final Color baseColor = PatternBackgroundHelper.getBaseColor(patternValue);
                  final String? badge = preset['badge'] as String?;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPattern = patternValue;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? ColorConstants.primary : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? ColorConstants.primary.withOpacity(0.12)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Preset Preview Area
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                    child: Container(
                                      color: baseColor,
                                      child: patternValue == null
                                          ? const SizedBox()
                                          : CustomPaint(
                                              painter: PreviewPatternPainter(patternValue),
                                            ),
                                    ),
                                  ),
                                ),
                                if (badge != null)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: ColorConstants.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Preset Label & Description
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPresetName(context, preset),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected ? ColorConstants.primary : ColorConstants.darkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getPresetDesc(context, preset),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade500,
                                    height: 1.2,
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

            // Bottom Select Preset Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: PrimaryButton(
                text: context.tr('selectPreset'),
                onPressed: () {
                  Navigator.pop(context, {'pattern': _selectedPattern});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
