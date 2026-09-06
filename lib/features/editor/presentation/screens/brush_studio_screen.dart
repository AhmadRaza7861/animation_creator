import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_bar/brush_presets.dart';
import 'brush_tip_studio_screen.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/helper/ex_value_builder.dart';
import '../controllers/editor_controller.dart';

/// A comprehensive, dedicated Brush Studio screen allowing users to explore,
/// test in real-time, adjust stroke properties, and select brush presets.
class BrushStudioScreen extends StatefulWidget {
  const BrushStudioScreen({
    super.key,
    required this.drawingController,
    required this.editorController,
    this.presets,
  });

  final DrawingController drawingController;
  final EditorController editorController;
  final List<BrushPreset>? presets;

  static Future<void> open(
    BuildContext context, {
    required DrawingController drawingController,
    required EditorController editorController,
    List<BrushPreset>? presets,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrushStudioScreen(
          drawingController: drawingController,
          editorController: editorController,
          presets: presets,
        ),
      ),
    );
  }

  @override
  State<BrushStudioScreen> createState() => _BrushStudioScreenState();
}

class _BrushStudioScreenState extends State<BrushStudioScreen> {
  static double _lastGridScrollOffset = 0.0;
  static double _lastCategoryScrollOffset = 0.0;
  static String _lastCategory = 'All';

  late final ScrollController _gridScrollController;
  late final ScrollController _categoryScrollController;

  late List<BrushPreset> _allPresets;
  BrushPreset? _selectedPreset;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Test Scratchpad state
  final List<PaintContent> _scratchpadStrokes = <PaintContent>[];
  PaintContent? _currentDrawingStroke;

  late double _strokeWidth;

  final List<String> _categories = const [
    'All',
    'Artistic & Inks',
    'Pencils & Sketch',
    'Brushes & Spray',
    'Magic & Glow',
    'Nature & Elements',
    'Stamps & Shapes',
    'Textures & FX',
    'Patterns & 3D',
  ];

  @override
  void initState() {
    super.initState();
    _allPresets = widget.presets ?? kDefaultBrushPresets;
    _strokeWidth = widget.drawingController.drawConfig.value.strokeWidth;
    final String? presetId = widget.drawingController.activeBrushPresetId;
    if (presetId != null) {
      _selectedPreset = _allPresets.cast<BrushPreset?>().firstWhere(
        (p) => p?.id == presetId,
        orElse: () => null,
      );
    }
    _selectedCategory = _lastCategory;

    _gridScrollController = ScrollController(
      initialScrollOffset: _lastGridScrollOffset,
    );
    _categoryScrollController = ScrollController(
      initialScrollOffset: _lastCategoryScrollOffset,
    );

    _gridScrollController.addListener(() {
      if (_gridScrollController.hasClients) {
        _lastGridScrollOffset = _gridScrollController.offset;
      }
    });

    _categoryScrollController.addListener(() {
      if (_categoryScrollController.hasClients) {
        _lastCategoryScrollOffset = _categoryScrollController.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedPresetOrSavedPosition();
    });
  }

  void _scrollToSelectedPresetOrSavedPosition() {
    if (!_gridScrollController.hasClients) return;

    if (_lastGridScrollOffset > 0) {
      final double maxScroll = _gridScrollController.position.maxScrollExtent;
      _gridScrollController.jumpTo(_lastGridScrollOffset.clamp(0.0, maxScroll));
      return;
    }

    if (_selectedPreset != null) {
      final presets = _filteredPresets;
      final int index = presets.indexWhere((p) => p.id == _selectedPreset!.id);
      if (index >= 0) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double availableWidth = screenWidth - 32.0;
        final int crossAxisCount = (availableWidth / 180.0).ceil().clamp(1, 4);
        final int rowIndex = index ~/ crossAxisCount;
        const double rowHeight = 132.0 + 12.0;
        final double targetOffset = (rowIndex * rowHeight - 40.0).clamp(
          0.0,
          _gridScrollController.position.maxScrollExtent,
        );
        _gridScrollController.jumpTo(targetOffset);
        _lastGridScrollOffset = targetOffset;
      }
    }
  }

  @override
  void dispose() {
    if (_gridScrollController.hasClients) {
      _lastGridScrollOffset = _gridScrollController.offset;
    }
    if (_categoryScrollController.hasClients) {
      _lastCategoryScrollOffset = _categoryScrollController.offset;
    }
    _lastCategory = _selectedCategory;
    _gridScrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BrushPreset> get _filteredPresets {
    return _allPresets.where((preset) {
      // Category filter
      if (_selectedCategory != 'All') {
        final id = preset.id.toLowerCase();
        switch (_selectedCategory) {
          case 'Artistic & Inks':
            if (!id.contains('ink') &&
                !id.contains('dip') &&
                !id.contains('calligraphy') &&
                !id.contains('rough') &&
                !id.contains('soft') &&
                !id.contains('choppy') &&
                !id.contains('watercolor') &&
                !id.contains('charcoal') &&
                !id.contains('chalk') &&
                !id.contains('bristle') &&
                !id.contains('dry') &&
                !id.contains('sponge') &&
                !id.contains('splash') &&
                !id.contains('splatter') &&
                !id.contains('spatter') &&
                !id.contains('rake')) {
              return false;
            }
            break;
          case 'Pencils & Sketch':
            if (!id.contains('pencil') &&
                !id.contains('sketch') &&
                !id.contains('crayon') &&
                !id.contains('grain') &&
                !id.contains('sand') &&
                !id.contains('scratches')) {
              return false;
            }
            break;
          case 'Brushes & Spray':
            if (!id.contains('brush') &&
                !id.contains('spray') &&
                !id.contains('stipple') &&
                !id.contains('highlighter') &&
                !id.contains('smoke') &&
                !id.contains('bokeh')) {
              return false;
            }
            break;
          case 'Magic & Glow':
            if (!id.contains('neon') &&
                !id.contains('rainbow') &&
                !id.contains('ribbon') &&
                !id.contains('constellation') &&
                !id.contains('electric') &&
                !id.contains('bubble') &&
                !id.contains('chain') &&
                !id.contains('audio') &&
                !id.contains('stitch') &&
                !id.contains('galaxy') &&
                !id.contains('embers') &&
                !id.contains('glitter') &&
                !id.contains('starglow') &&
                !id.contains('bubbles') &&
                !id.contains('crackle') &&
                !id.contains('sparkles') &&
                !id.contains('circuit')) {
              return false;
            }
            break;
          case 'Nature & Elements':
            if (!id.contains('leaves') &&
                !id.contains('petals') &&
                !id.contains('blossom') &&
                !id.contains('pinetree') &&
                !id.contains('grass') &&
                !id.contains('cloud') &&
                !id.contains('snow') &&
                !id.contains('rain') &&
                !id.contains('flame') &&
                !id.contains('feather') &&
                !id.contains('ripple') &&
                !id.contains('sun') &&
                !id.contains('crescent')) {
              return false;
            }
            break;
          case 'Stamps & Shapes':
            if (!id.contains('butterfly') &&
                !id.contains('paw') &&
                !id.contains('fish') &&
                !id.contains('heart') &&
                !id.contains('star') &&
                !id.contains('crown') &&
                !id.contains('gem') &&
                !id.contains('lightning') &&
                !id.contains('music') &&
                !id.contains('confetti') &&
                !id.contains('ghost') &&
                !id.contains('rocket') &&
                !id.contains('atom') &&
                !id.contains('puzzle') &&
                !id.contains('anchor') &&
                !id.contains('hourglass') &&
                !id.contains('lightbulb') &&
                !id.contains('bell') &&
                !id.contains('key') &&
                !id.contains('bowtie') &&
                !id.contains('crosshair') &&
                !id.contains('outline') &&
                !id.contains('ring') &&
                !id.contains('diamond') &&
                !id.contains('triangle') &&
                !id.contains('hexagon') &&
                !id.contains('octagon') &&
                !id.contains('shield') &&
                !id.contains('spiral') &&
                !id.contains('teardrop')) {
              return false;
            }
            break;
          case 'Textures & FX':
            if (!id.contains('marble') &&
                !id.contains('honeycomb') &&
                !id.contains('lace') &&
                !id.contains('weave') &&
                !id.contains('cobweb') &&
                !id.contains('cells') &&
                !id.contains('fur') &&
                !id.contains('hair') &&
                !id.contains('grunge') &&
                !id.contains('orange') &&
                !id.contains('static') &&
                !id.contains('sprinkles')) {
              return false;
            }
            break;
          case 'Patterns & 3D':
            if (!id.contains('dots') &&
                !id.contains('squares') &&
                !id.contains('dash') &&
                !id.contains('pixel') &&
                !id.contains('mosaic') &&
                !id.contains('halftone') &&
                !id.contains('hatch') &&
                !id.contains('gradient') &&
                !id.contains('3d') &&
                !id.contains('candy') &&
                !id.contains('saw') &&
                !id.contains('gear') &&
                !id.contains('heartbeat') &&
                !id.contains('stitch') &&
                !id.contains('audio') &&
                !id.contains('chain')) {
              return false;
            }
            break;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = preset.name.toLowerCase().contains(query);
        final matchesDesc = preset.description.toLowerCase().contains(query);
        if (!matchesName && !matchesDesc) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _selectPreset(BrushPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _scratchpadStrokes.clear();
      _currentDrawingStroke = null;
    });
    if (_gridScrollController.hasClients) {
      _lastGridScrollOffset = _gridScrollController.offset;
    }
  }

  void _applyAndClose() {
    if (_gridScrollController.hasClients) {
      _lastGridScrollOffset = _gridScrollController.offset;
    }
    if (_categoryScrollController.hasClients) {
      _lastCategoryScrollOffset = _categoryScrollController.offset;
    }
    _lastCategory = _selectedCategory;
    if (_selectedPreset != null) {
      widget.editorController.activeCategory = 'Brush';
      widget.drawingController.activeBrushPresetId = _selectedPreset!.id;
      widget.drawingController.setPaintContent(_selectedPreset!.create());
      widget.editorController.globalStrokeWidth = _strokeWidth;
      widget.drawingController.setStyle(strokeWidth: _strokeWidth);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = ColorConstants.accent;

    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.drawingController.drawConfig,
      shouldRebuild: (p, n) =>
          p.color != n.color || p.strokeWidth != n.strokeWidth,
      builder: (context, config, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: _buildAppBar(context, accent),
          body: Column(
            children: [
              // Interactive Test Scratchpad & Live Stroke Preview Banner
              _buildScratchpadBanner(config, accent),

              // Search Bar & Category Chips
              _buildFilterSection(accent),

              // Presets Grid
              Expanded(child: _buildPresetsGrid(config, accent)),

              // Bottom Action & Apply Bar
              _buildBottomBar(config, accent),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color accent) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF2D3139),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Brush Studio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2024),
            ),
          ),
          Text(
            'Select and test custom brush presets',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888E9B),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: accent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text(
              'Customize Tip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final applied = await BrushTipStudioScreen.open(
                context,
                drawingController: widget.drawingController,
                editorController: widget.editorController,
              );
              if (applied == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScratchpadBanner(DrawConfig config, Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedPreset?.icon ?? Icons.brush_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPreset != null
                        ? '${_selectedPreset!.name} Preview'
                        : 'Interactive Test Scratchpad',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22252A),
                    ),
                  ),
                ],
              ),
              if (_scratchpadStrokes.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _scratchpadStrokes.clear();
                      _currentDrawingStroke = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Clear Pad',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Interactive Drawing Pad
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onPanStart: (details) {
                  final preset = _selectedPreset ?? _allPresets.first;
                  final stroke = preset.create()
                    ..paint = (Paint()
                      ..color = config.color
                      ..strokeWidth = _strokeWidth
                      ..style = PaintingStyle.stroke
                      ..strokeCap = StrokeCap.round
                      ..strokeJoin = StrokeJoin.round
                      ..isAntiAlias = true);

                  stroke.startDraw(details.localPosition);
                  setState(() {
                    _currentDrawingStroke = stroke;
                  });
                },
                onPanUpdate: (details) {
                  if (_currentDrawingStroke != null) {
                    _currentDrawingStroke!.drawing(details.localPosition);
                    setState(() {});
                  }
                },
                onPanEnd: (_) {
                  if (_currentDrawingStroke != null) {
                    setState(() {
                      _scratchpadStrokes.add(_currentDrawingStroke!);
                      _currentDrawingStroke = null;
                    });
                  }
                },
                child: CustomPaint(
                  painter: _ScratchpadPainter(
                    strokes: _scratchpadStrokes,
                    currentStroke: _currentDrawingStroke,
                    preset: _selectedPreset,
                    color: config.color,
                    strokeWidth: _strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Stroke Thickness Quick Slider
          Row(
            children: [
              const Icon(
                Icons.line_weight_rounded,
                size: 16,
                color: Color(0xFF888E9B),
              ),
              const SizedBox(width: 8),
              Text(
                'Size: ${_strokeWidth.toInt()}px',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                    thumbColor: accent,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    trackHeight: 3,
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: _strokeWidth.clamp(1.0, 50.0),
                    min: 1.0,
                    max: 50.0,
                    onChanged: (val) {
                      setState(() {
                        _strokeWidth = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(Color accent) {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E2024)),
              decoration: InputDecoration(
                hintText: 'Search brushes by name...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        // Category Pills List
        Container(
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.separated(
            controller: _categoryScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;

              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = cat;
                    _lastCategory = cat;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_gridScrollController.hasClients) return;
                    if (_selectedPreset != null && _filteredPresets.any((p) => p.id == _selectedPreset!.id)) {
                      _scrollToSelectedPresetOrSavedPosition();
                    } else {
                      _gridScrollController.jumpTo(0.0);
                      _lastGridScrollOffset = 0.0;
                    }
                  });
                },
                selectedColor: accent,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? accent : Colors.grey.shade200,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsGrid(DrawConfig config, Color accent) {
    final presets = _filteredPresets;

    if (presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.brush_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No brushes found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your search or category filter',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _gridScrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 132,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isSelected = preset.id == _selectedPreset?.id;

        return _StudioBrushCard(
          preset: preset,
          color: config.color,
          isSelected: isSelected,
          accent: accent,
          onTap: () => _selectPreset(preset),
        );
      },
    );
  }

  Widget _buildBottomBar(DrawConfig config, Color accent) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Current Selection Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Icon(
              _selectedPreset?.icon ?? Icons.brush_rounded,
              size: 22,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),

          // Selected Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedPreset?.name ?? 'No brush selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                Text(
                  _selectedPreset?.description ?? 'Pick a brush to apply',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888E9B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Apply Button
          ElevatedButton.icon(
            onPressed: _applyAndClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Apply Brush',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Card Component for individual brushes
class _StudioBrushCard extends StatelessWidget {
  const _StudioBrushCard({
    required this.preset,
    required this.color,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final BrushPreset preset;
  final Color color;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live sample stroke canvas
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomPaint(
                        painter: _StudioPreviewPainter(
                          preset: preset,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),

                // Brush Name & Description
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? accent : const Color(0xFF1F2937),
                        ),
                      ),
                      if (preset.description.isNotEmpty)
                        Text(
                          preset.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Selection Checkmark Badge
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the live stroke inside each brush card
class _StudioPreviewPainter extends CustomPainter {
  _StudioPreviewPainter({required this.preset, required this.color});

  final BrushPreset preset;
  final Color color;

  static const double _previewWidth = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = _sampleStroke(size);
    if (points.isEmpty) return;

    final PaintContent content = preset.create()
      ..paint = (Paint()
        ..color = color
        ..strokeWidth = _previewWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true);

    content.startDraw(points.first);
    for (int i = 1; i < points.length; i++) {
      content.drawing(points[i]);
    }
    content.draw(canvas, size, false);
  }

  List<Offset> _sampleStroke(Size size) {
    final List<Offset> points = <Offset>[];
    final double padX = size.width * 0.12;
    final double usableW = size.width - padX * 2;
    final double midY = size.height / 2;
    final double amp = size.height * 0.22;
    const int segments = 48;

    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = padX + usableW * t;
      final double y = midY - sin(t * pi * 2) * amp;
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _StudioPreviewPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.preset != preset;
}

/// Custom painter for the interactive scratchpad banner
class _ScratchpadPainter extends CustomPainter {
  _ScratchpadPainter({
    required this.strokes,
    required this.currentStroke,
    required this.preset,
    required this.color,
    required this.strokeWidth,
  });

  final List<PaintContent> strokes;
  final PaintContent? currentStroke;
  final BrushPreset? preset;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // If no user strokes drawn yet, render default sine stroke guide
    if (strokes.isEmpty && currentStroke == null && preset != null) {
      final List<Offset> sample = _sampleStroke(size);
      if (sample.isNotEmpty) {
        final PaintContent demo = preset!.create()
          ..paint = (Paint()
            ..color = color
            ..strokeWidth = strokeWidth.clamp(3.0, 30.0)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true);

        demo.startDraw(sample.first);
        for (int i = 1; i < sample.length; i++) {
          demo.drawing(sample[i]);
        }
        demo.draw(canvas, size, false);
      }

      // Draw helper text overlay
      final TextPainter tp = TextPainter(
        text: TextPainter(
          text: const TextSpan(
            text: '✨ Doodle here to test brush feel & pressure',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        ).text,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 20));
      return;
    }

    // Draw all user-completed strokes
    for (final s in strokes) {
      s.draw(canvas, size, false);
    }

    // Draw current active stroke
    if (currentStroke != null) {
      currentStroke!.draw(canvas, size, false);
    }
  }

  List<Offset> _sampleStroke(Size size) {
    final List<Offset> points = <Offset>[];
    final double padX = size.width * 0.15;
    final double usableW = size.width - padX * 2;
    final double midY = size.height * 0.42;
    final double amp = size.height * 0.22;
    const int segments = 56;

    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = padX + usableW * t;
      final double y = midY - sin(t * pi * 2) * amp;
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _ScratchpadPainter oldDelegate) => true;
}
