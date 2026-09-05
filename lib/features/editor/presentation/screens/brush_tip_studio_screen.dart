import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/helper/ex_value_builder.dart';
import '../../../../package_code/src/paint_contents/brush_stamps.dart';
import '../../../../package_code/src/paint_contents/image_tip_brush.dart';
import '../../../../package_code/src/paint_contents/tip_brush.dart';
import '../controllers/editor_controller.dart';

/// Tip item representation for vector kinds or bitmap stamps
class TipItem {
  const TipItem(this.kind, this.label, this.size, {this.hardness = 1.0, this.roundness = 1.0})
      : stampKey = null;

  const TipItem.stamp(this.stampKey, this.label, this.size)
      : kind = BrushTipKind.round,
        hardness = 1.0,
        roundness = 1.0;

  final BrushTipKind kind;
  final String? stampKey;
  final String label;
  final int size;
  final double hardness;
  final double roundness;

  bool get isStamp => stampKey != null;

  @override
  bool operator ==(Object other) => other is TipItem && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

enum TipCategory { all, basic, shapes, stars, symbols, nature, outline, glyph, textures }

const Map<TipCategory, String> kCategoryLabels = <TipCategory, String>{
  TipCategory.all: 'All',
  TipCategory.basic: 'Basic',
  TipCategory.shapes: 'Shapes',
  TipCategory.stars: 'Stars',
  TipCategory.symbols: 'Symbols',
  TipCategory.nature: 'Nature',
  TipCategory.outline: 'Outline',
  TipCategory.glyph: 'Glyphs',
  TipCategory.textures: 'Textures',
};

const Set<BrushTipKind> _kBasicKinds = <BrushTipKind>{BrushTipKind.round, BrushTipKind.square};
const Set<BrushTipKind> _kShapeKinds = <BrushTipKind>{
  BrushTipKind.diamond,
  BrushTipKind.triangle,
  BrushTipKind.pentagon,
  BrushTipKind.hexagon,
  BrushTipKind.heptagon,
  BrushTipKind.octagon,
  BrushTipKind.ring,
  BrushTipKind.squareRing,
  BrushTipKind.diamondRing,
  BrushTipKind.shield,
};
const Set<BrushTipKind> _kStarKinds = <BrushTipKind>{
  BrushTipKind.star,
  BrushTipKind.fourStar,
  BrushTipKind.sixStar,
  BrushTipKind.eightStar,
  BrushTipKind.burst,
  BrushTipKind.sun,
  BrushTipKind.pinwheel,
};
const Set<BrushTipKind> _kSymbolKinds = <BrushTipKind>{
  BrushTipKind.cross,
  BrushTipKind.heart,
  BrushTipKind.spade,
  BrushTipKind.club,
  BrushTipKind.checkmark,
  BrushTipKind.arrow,
  BrushTipKind.doubleArrow,
  BrushTipKind.lightning,
  BrushTipKind.musicNote,
  BrushTipKind.infinity,
  BrushTipKind.wave,
  BrushTipKind.ripple,
  BrushTipKind.crosshair,
  BrushTipKind.crown,
  BrushTipKind.bowtie,
  BrushTipKind.gem,
  BrushTipKind.atom,
  BrushTipKind.puzzle,
  BrushTipKind.anchor,
  BrushTipKind.rocket,
  BrushTipKind.lightbulb,
  BrushTipKind.bell,
  BrushTipKind.key,
  BrushTipKind.hourglass,
  BrushTipKind.ghost,
};
const Set<BrushTipKind> _kNatureKinds = <BrushTipKind>{
  BrushTipKind.flower,
  BrushTipKind.fivePetal,
  BrushTipKind.flowerEight,
  BrushTipKind.clover,
  BrushTipKind.leaf,
  BrushTipKind.leafScatter,
  BrushTipKind.grass,
  BrushTipKind.grassClump,
  BrushTipKind.crescent,
  BrushTipKind.snowflake,
  BrushTipKind.spiral,
  BrushTipKind.gear,
  BrushTipKind.shell,
  BrushTipKind.teardrop,
  BrushTipKind.confetti,
  BrushTipKind.flame,
  BrushTipKind.feather,
  BrushTipKind.paw,
  BrushTipKind.butterfly,
  BrushTipKind.mapleLeaf,
  BrushTipKind.fish,
  BrushTipKind.mushroom,
  BrushTipKind.cloud,
  BrushTipKind.pineTree,
};
const Set<BrushTipKind> _kOutlineKinds = <BrushTipKind>{
  BrushTipKind.outlineCircle,
  BrushTipKind.outlineSquare,
  BrushTipKind.outlineTriangle,
  BrushTipKind.outlineHexagon,
  BrushTipKind.outlineStar,
  BrushTipKind.outlineHeart,
};
const Set<BrushTipKind> _kGlyphKinds = <BrushTipKind>{
  BrushTipKind.glyphStar,
  BrushTipKind.glyphFlower,
  BrushTipKind.glyphSnow,
  BrushTipKind.glyphHeart,
  BrushTipKind.glyphNote,
  BrushTipKind.glyphClover,
};

TipCategory _categoryOf(TipItem item) {
  if (item.isStamp) return TipCategory.textures;
  if (_kBasicKinds.contains(item.kind)) return TipCategory.basic;
  if (_kShapeKinds.contains(item.kind)) return TipCategory.shapes;
  if (_kStarKinds.contains(item.kind)) return TipCategory.stars;
  if (_kSymbolKinds.contains(item.kind)) return TipCategory.symbols;
  if (_kNatureKinds.contains(item.kind)) return TipCategory.nature;
  if (_kOutlineKinds.contains(item.kind)) return TipCategory.outline;
  if (_kGlyphKinds.contains(item.kind)) return TipCategory.glyph;
  return TipCategory.textures;
}

List<TipItem> get kAllTipItems => <TipItem>[
  const TipItem(BrushTipKind.round, 'Hard Round', 30),
  const TipItem(BrushTipKind.round, 'Soft Round', 30, hardness: 0.0),
  const TipItem(BrushTipKind.round, 'Medium Round', 25, hardness: 0.5),
  const TipItem(BrushTipKind.round, 'Flat', 30, roundness: 0.35),
  const TipItem(BrushTipKind.round, 'Soft Big', 45, hardness: 0.1),
  const TipItem(BrushTipKind.square, 'Square', 25),
  const TipItem(BrushTipKind.square, 'Soft Square', 30, hardness: 0.3),
  const TipItem(BrushTipKind.diamond, 'Diamond', 28),
  const TipItem(BrushTipKind.triangle, 'Triangle', 30),
  const TipItem(BrushTipKind.pentagon, 'Pentagon', 32),
  const TipItem(BrushTipKind.hexagon, 'Hexagon', 32),
  const TipItem(BrushTipKind.heptagon, 'Heptagon', 32),
  const TipItem(BrushTipKind.octagon, 'Octagon', 32),
  const TipItem(BrushTipKind.star, 'Star', 36),
  const TipItem(BrushTipKind.fourStar, '4-Star', 34),
  const TipItem(BrushTipKind.sixStar, '6-Star', 38),
  const TipItem(BrushTipKind.cross, 'Cross', 30),
  const TipItem(BrushTipKind.ring, 'Ring', 30),
  const TipItem(BrushTipKind.heart, 'Heart', 34),
  const TipItem(BrushTipKind.flower, 'Flower', 42),
  const TipItem(BrushTipKind.leaf, 'Leaf', 30),
  const TipItem(BrushTipKind.crescent, 'Crescent', 32),
  const TipItem(BrushTipKind.grass, 'Grass', 45),
  const TipItem(BrushTipKind.confetti, 'Confetti', 42),
  const TipItem(BrushTipKind.eightStar, '8-Star', 38),
  const TipItem(BrushTipKind.pinwheel, 'Pinwheel', 36),
  const TipItem(BrushTipKind.fivePetal, 'Blossom', 40),
  const TipItem(BrushTipKind.clover, 'Clover', 34),
  const TipItem(BrushTipKind.shell, 'Shell', 34),
  const TipItem(BrushTipKind.checkmark, 'Check', 32),
  const TipItem(BrushTipKind.sun, 'Sun', 40),
  const TipItem(BrushTipKind.ripple, 'Ripple', 38),
  const TipItem(BrushTipKind.squareRing, 'Square Ring', 32),
  const TipItem(BrushTipKind.spade, 'Spade', 34),
  const TipItem(BrushTipKind.musicNote, 'Music Note', 34),
  const TipItem(BrushTipKind.doubleArrow, 'Double Arrow', 34),
  const TipItem(BrushTipKind.club, 'Club', 34),
  const TipItem(BrushTipKind.shield, 'Shield', 34),
  const TipItem(BrushTipKind.flowerEight, 'Blossom 8', 42),
  const TipItem(BrushTipKind.diamondRing, 'Diamond Ring', 32),
  const TipItem(BrushTipKind.wave, 'Wave', 38),
  const TipItem(BrushTipKind.infinity, 'Infinity', 38),
  const TipItem(BrushTipKind.flame, 'Flame', 36),
  const TipItem(BrushTipKind.feather, 'Feather', 40),
  const TipItem(BrushTipKind.crosshair, 'Crosshair', 38),
  const TipItem(BrushTipKind.paw, 'Paw', 36),
  const TipItem(BrushTipKind.crown, 'Crown', 36),
  const TipItem(BrushTipKind.bowtie, 'Bowtie', 34),
  const TipItem(BrushTipKind.butterfly, 'Butterfly', 44),
  const TipItem(BrushTipKind.mapleLeaf, 'Maple Leaf', 40),
  const TipItem(BrushTipKind.gem, 'Gem', 38),
  const TipItem(BrushTipKind.atom, 'Atom', 42),
  const TipItem(BrushTipKind.puzzle, 'Puzzle', 38),
  const TipItem(BrushTipKind.anchor, 'Anchor', 40),
  const TipItem(BrushTipKind.fish, 'Fish', 40),
  const TipItem(BrushTipKind.mushroom, 'Mushroom', 38),
  const TipItem(BrushTipKind.cloud, 'Cloud', 44),
  const TipItem(BrushTipKind.pineTree, 'Pine Tree', 40),
  const TipItem(BrushTipKind.rocket, 'Rocket', 40),
  const TipItem(BrushTipKind.lightbulb, 'Lightbulb', 38),
  const TipItem(BrushTipKind.bell, 'Bell', 38),
  const TipItem(BrushTipKind.key, 'Key', 38),
  const TipItem(BrushTipKind.hourglass, 'Hourglass', 38),
  const TipItem(BrushTipKind.ghost, 'Ghost', 40),
  const TipItem(BrushTipKind.outlineCircle, 'Circle Outline', 34),
  const TipItem(BrushTipKind.outlineSquare, 'Square Outline', 34),
  const TipItem(BrushTipKind.outlineTriangle, 'Triangle Outline', 36),
  const TipItem(BrushTipKind.outlineHexagon, 'Hexagon Outline', 36),
  const TipItem(BrushTipKind.outlineStar, 'Star Outline', 38),
  const TipItem(BrushTipKind.outlineHeart, 'Heart Outline', 36),
  const TipItem(BrushTipKind.glyphStar, 'Glyph Star', 38),
  const TipItem(BrushTipKind.glyphFlower, 'Glyph Flower', 38),
  const TipItem(BrushTipKind.glyphSnow, 'Glyph Snow', 38),
  const TipItem(BrushTipKind.glyphHeart, 'Glyph Heart', 36),
  const TipItem(BrushTipKind.glyphNote, 'Glyph Note', 36),
  const TipItem(BrushTipKind.glyphClover, 'Glyph Clover', 38),
  const TipItem(BrushTipKind.teardrop, 'Teardrop', 32),
  const TipItem(BrushTipKind.arrow, 'Arrow', 32),
  const TipItem(BrushTipKind.lightning, 'Lightning', 34),
  const TipItem(BrushTipKind.snowflake, 'Snowflake', 40),
  const TipItem(BrushTipKind.spiral, 'Spiral', 40),
  const TipItem(BrushTipKind.gear, 'Gear', 38),
  const TipItem(BrushTipKind.burst, 'Burst', 40),
  const TipItem(BrushTipKind.spatter, 'Spatter', 45),
  const TipItem(BrushTipKind.chalk, 'Chalk', 40),
  const TipItem(BrushTipKind.scatter, 'Scatter', 42),
  const TipItem(BrushTipKind.bristle, 'Bristle', 39),
  const TipItem(BrushTipKind.dryBrush, 'Dry Brush', 36),
  const TipItem(BrushTipKind.stipple, 'Stipple', 32),
  const TipItem(BrushTipKind.charcoal, 'Charcoal', 40),
  const TipItem(BrushTipKind.sponge, 'Sponge', 44),
  const TipItem(BrushTipKind.splash, 'Splash', 45),
  const TipItem(BrushTipKind.grassClump, 'Grass Clump', 46),
  const TipItem(BrushTipKind.leafScatter, 'Leaf Scatter', 48),
  for (final BrushStamp stamp in kBrushStamps)
    TipItem.stamp(stamp.key, stamp.label, stamp.defaultSize),
];

/// A dedicated, modern full-screen studio for customizing brush tip shapes and parameters.
class BrushTipStudioScreen extends StatefulWidget {
  const BrushTipStudioScreen({
    super.key,
    required this.drawingController,
    this.editorController,
  });

  final DrawingController drawingController;
  final EditorController? editorController;

  static Future<bool?> open(
    BuildContext context, {
    required DrawingController drawingController,
    EditorController? editorController,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BrushTipStudioScreen(
          drawingController: drawingController,
          editorController: editorController,
        ),
      ),
    );
  }

  @override
  State<BrushTipStudioScreen> createState() => _BrushTipStudioScreenState();
}

class _BrushTipStudioScreenState extends State<BrushTipStudioScreen> {
  static double _lastGridScrollOffset = 0.0;
  static double _lastCategoryScrollOffset = 0.0;
  static TipCategory _lastCategory = TipCategory.all;

  late final ScrollController _tipGridScrollController;
  late final ScrollController _tipCategoryScrollController;

  late BrushTipKind _kind;
  late double _size;
  late double _angle;
  late double _roundness;
  late double _hardness;
  late double _spacing;
  bool _flipX = false;
  bool _flipY = false;
  TipItem? _selectedItem;
  TipCategory _category = TipCategory.all;
  String? _stampKey;

  // Scratchpad interactive state
  final List<PaintContent> _scratchpadStrokes = <PaintContent>[];
  PaintContent? _currentDrawingStroke;

  @override
  void initState() {
    super.initState();
    final DrawConfig config = widget.drawingController.drawConfig.value;
    _size = config.strokeWidth.clamp(1, 100).toDouble();

    final currentContent = widget.drawingController.currentContent;
    if (currentContent is TipBrush) {
      _kind = currentContent.kind;
      _angle = currentContent.angle;
      _roundness = currentContent.roundness;
      _hardness = currentContent.hardness;
      _spacing = currentContent.spacing;
      _flipX = currentContent.flipX;
      _flipY = currentContent.flipY;
    } else if (currentContent is ImageTipBrush) {
      _stampKey = currentContent.stampKey;
      _kind = BrushTipKind.round;
      _angle = currentContent.angle;
      _roundness = 1.0;
      _hardness = currentContent.hardness;
      _spacing = currentContent.spacing;
      _flipX = currentContent.flipX;
      _flipY = currentContent.flipY;
    } else {
      final TipItem first = kAllTipItems.first;
      _kind = first.kind;
      _angle = 0;
      _roundness = first.roundness;
      _hardness = first.hardness;
      _spacing = 0.25;
    }

    final String? tipLabel = widget.drawingController.activeTipLabel;
    if (tipLabel != null) {
      _selectedItem = kAllTipItems.cast<TipItem?>().firstWhere(
            (t) => t?.label == tipLabel,
            orElse: () => kAllTipItems.first,
          );
      if (_selectedItem != null) {
        _stampKey = _selectedItem!.stampKey;
        _kind = _selectedItem!.kind;
        _hardness = _selectedItem!.hardness;
        _roundness = _selectedItem!.roundness;
      }
    } else {
      _selectedItem = _matchItem();
    }

    _category = _lastCategory;

    _tipGridScrollController = ScrollController(
      initialScrollOffset: _lastGridScrollOffset,
    );
    _tipCategoryScrollController = ScrollController(
      initialScrollOffset: _lastCategoryScrollOffset,
    );

    _tipGridScrollController.addListener(() {
      if (_tipGridScrollController.hasClients) {
        _lastGridScrollOffset = _tipGridScrollController.offset;
      }
    });

    _tipCategoryScrollController.addListener(() {
      if (_tipCategoryScrollController.hasClients) {
        _lastCategoryScrollOffset = _tipCategoryScrollController.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedItemOrSavedPosition();
    });
  }

  void _scrollToSelectedItemOrSavedPosition() {
    if (!_tipGridScrollController.hasClients) return;

    if (_lastGridScrollOffset > 0) {
      final double maxScroll = _tipGridScrollController.position.maxScrollExtent;
      _tipGridScrollController.jumpTo(_lastGridScrollOffset.clamp(0.0, maxScroll));
      return;
    }

    if (_selectedItem != null) {
      final List<TipItem> items = _category == TipCategory.all
          ? kAllTipItems
          : kAllTipItems.where((TipItem t) => _categoryOf(t) == _category).toList();
      final int index = items.indexOf(_selectedItem!);
      if (index >= 0) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double availableWidth = screenWidth - 52.0;
        final int crossAxisCount = (availableWidth / 68.0).ceil().clamp(1, 8);
        final int rowIndex = index ~/ crossAxisCount;
        const double rowHeight = 68.0 + 8.0;
        final double targetOffset = (rowIndex * rowHeight - 20.0).clamp(
          0.0,
          _tipGridScrollController.position.maxScrollExtent,
        );
        _tipGridScrollController.jumpTo(targetOffset);
        _lastGridScrollOffset = targetOffset;
      }
    }
  }

  @override
  void dispose() {
    if (_tipGridScrollController.hasClients) {
      _lastGridScrollOffset = _tipGridScrollController.offset;
    }
    if (_tipCategoryScrollController.hasClients) {
      _lastCategoryScrollOffset = _tipCategoryScrollController.offset;
    }
    _lastCategory = _category;
    _tipGridScrollController.dispose();
    _tipCategoryScrollController.dispose();
    super.dispose();
  }

  TipItem? _matchItem() {
    for (final TipItem t in kAllTipItems) {
      if (_stampKey != null) {
        if (t.stampKey == _stampKey) return t;
      } else if (!t.isStamp && t.kind == _kind) {
        return t;
      }
    }
    return kAllTipItems.first;
  }

  void _selectItem(TipItem item) {
    setState(() {
      _selectedItem = item;
      _stampKey = item.stampKey;
      _kind = item.kind;
      _hardness = item.hardness;
      _roundness = item.roundness;
      _size = item.size.toDouble();
      _scratchpadStrokes.clear();
      _currentDrawingStroke = null;
    });
    if (_tipGridScrollController.hasClients) {
      _lastGridScrollOffset = _tipGridScrollController.offset;
    }
  }

  void _applyAndClose() {
    if (_tipGridScrollController.hasClients) {
      _lastGridScrollOffset = _tipGridScrollController.offset;
    }
    if (_tipCategoryScrollController.hasClients) {
      _lastCategoryScrollOffset = _tipCategoryScrollController.offset;
    }
    _lastCategory = _category;
    if (_stampKey != null) {
      widget.drawingController.setPaintContent(
        ImageTipBrush(
          stampKey: _stampKey!,
          spacing: _spacing,
          angle: _angle,
          hardness: _hardness,
          flipX: _flipX,
          flipY: _flipY,
        ),
      );
    } else {
      widget.drawingController.setPaintContent(
        TipBrush(
          kind: _kind,
          angle: _angle,
          roundness: _roundness,
          hardness: _hardness,
          spacing: _spacing,
          flipX: _flipX,
          flipY: _flipY,
        ),
      );
    }

    widget.drawingController.setStyle(strokeWidth: _size);
    widget.drawingController.activeTipLabel = _selectedItem?.label;
    widget.drawingController.activeBrushPresetId = 'custom_tip';

    if (widget.editorController != null) {
      widget.editorController!.activeCategory = 'Brush';
      widget.editorController!.globalStrokeWidth = _size;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = ColorConstants.accent;

    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.drawingController.drawConfig,
      shouldRebuild: (p, n) => p.color != n.color || p.strokeWidth != n.strokeWidth,
      builder: (context, config, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: _buildAppBar(context, accent),
          body: Column(
            children: [
              // Interactive Test Scratchpad & Live Preview
              _buildLiveScratchpad(config, accent),

              // Category Pills
              _buildCategoryTabs(accent),

              // Main Content (Tip Grid & Sliders)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Tip Shapes Grid
                      _buildTipShapesGrid(config.color, accent),

                      // Parameter Sliders Card
                      _buildParameterControls(accent),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Apply Bar
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
            'Customize Brush Tip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2024),
            ),
          ),
          Text(
            'Fine-tune tip shape, spacing, and angle',
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
              foregroundColor: const Color(0xFF6B7280),
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text(
              'Reset',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              setState(() {
                if (_selectedItem != null) {
                  _hardness = _selectedItem!.hardness;
                  _roundness = _selectedItem!.roundness;
                  _size = _selectedItem!.size.toDouble();
                }
                _angle = 0;
                _spacing = 0.25;
                _flipX = false;
                _flipY = false;
                _scratchpadStrokes.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveScratchpad(DrawConfig config, Color accent) {
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
                      Icons.gesture_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedItem?.label ?? 'Tip'} Preview',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22252A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_size.toInt()}px • ${(_spacing * 100).toInt()}% Spacing',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF6B7280)),
                        SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Test Pad Canvas
          Container(
            height: 80,
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
                  final PaintContent brush = _stampKey != null
                      ? ImageTipBrush(
                          stampKey: _stampKey!,
                          spacing: _spacing,
                          angle: _angle,
                          hardness: _hardness,
                          flipX: _flipX,
                          flipY: _flipY,
                        )
                      : TipBrush(
                          kind: _kind,
                          angle: _angle,
                          roundness: _roundness,
                          hardness: _hardness,
                          spacing: _spacing,
                          flipX: _flipX,
                          flipY: _flipY,
                        );

                  brush.paint = (Paint()
                    ..color = config.color
                    ..strokeWidth = _size
                    ..style = PaintingStyle.stroke
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round
                    ..isAntiAlias = true);

                  brush.startDraw(details.localPosition);
                  setState(() {
                    _currentDrawingStroke = brush;
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
                  painter: _CustomTipScratchpadPainter(
                    strokes: _scratchpadStrokes,
                    currentStroke: _currentDrawingStroke,
                    stampKey: _stampKey,
                    kind: _kind,
                    angle: _angle,
                    roundness: _roundness,
                    hardness: _hardness,
                    spacing: _spacing,
                    flipX: _flipX,
                    flipY: _flipY,
                    color: config.color,
                    strokeWidth: _size,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Color accent) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        controller: _tipCategoryScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: TipCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = TipCategory.values[index];
          final isSelected = _category == cat;

          return ChoiceChip(
            label: Text(kCategoryLabels[cat]!),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _category = cat;
                _lastCategory = cat;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !_tipGridScrollController.hasClients) return;
                _scrollToSelectedItemOrSavedPosition();
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildTipShapesGrid(Color dabColor, Color accent) {
    final List<TipItem> items = _category == TipCategory.all
        ? kAllTipItems
        : kAllTipItems.where((TipItem t) => _categoryOf(t) == _category).toList();

    return Container(
      height: 180,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GridView.builder(
          controller: _tipGridScrollController,
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 68,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = item == _selectedItem;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectItem(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.08) : const Color(0xFFF9FAFC),
                  border: Border.all(
                    color: isSelected ? accent : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: CustomPaint(
                          painter: _TipDabPainter(item: item, color: dabColor),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      bottom: 2,
                      child: Text(
                        '${item.size}',
                        style: TextStyle(
                          color: isSelected ? accent : const Color(0xFF9CA3AF),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParameterControls(Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tip Properties',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2024),
                ),
              ),
              Row(
                children: [
                  _buildFlipToggle('Flip X', _flipX, (v) => setState(() => _flipX = v), accent),
                  const SizedBox(width: 12),
                  _buildFlipToggle('Flip Y', _flipY, (v) => setState(() => _flipY = v), accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Size Slider
          _buildParamSlider('Size', '${_size.toInt()}px', _size, 1, 100, (v) {
            setState(() => _size = v);
          }, accent),

          // Spacing Slider
          _buildParamSlider('Spacing', '${(_spacing * 100).round()}%', _spacing, 0.05, 2, (v) {
            setState(() => _spacing = v);
          }, accent),

          // Hardness Slider
          _buildParamSlider('Hardness', '${(_hardness * 100).round()}%', _hardness, 0, 1, (v) {
            setState(() => _hardness = v);
          }, accent),

          // Roundness Slider
          _buildParamSlider('Roundness', '${(_roundness * 100).round()}%', _roundness, 0.05, 1, (v) {
            setState(() => _roundness = v);
          }, accent),

          // Angle Slider with Dial
          _buildParamSlider('Angle', '${_angle.round()}°', _angle, 0, 360, (v) {
            setState(() => _angle = v);
          }, accent),
        ],
      ),
    );
  }

  Widget _buildParamSlider(
    String label,
    String valueText,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: accent,
                inactiveTrackColor: const Color(0xFFE5E7EB),
                thumbColor: accent,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: current.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipToggle(String label, bool value, ValueChanged<bool> onChanged, Color accent) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? accent.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: value ? accent : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                color: value ? accent : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
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
            child: _selectedItem != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CustomPaint(
                      painter: _TipDabPainter(item: _selectedItem!, color: config.color),
                    ),
                  )
                : Icon(Icons.brush_rounded, size: 22, color: accent),
          ),
          const SizedBox(width: 12),

          // Selected Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedItem?.label ?? 'Custom Tip',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                Text(
                  'Size: ${_size.toInt()}px • Spacing: ${(_spacing * 100).toInt()}%',
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
              'Apply Tip Shape',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the single tip stamp/dab in a thumbnail
class _TipDabPainter extends CustomPainter {
  _TipDabPainter({required this.item, required this.color});

  final TipItem item;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide * 0.42;

    if (item.isStamp) {
      final ui.Image image = BrushStampLibrary.instance.get(item.stampKey!);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
        Paint()
          ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium,
      );
      return;
    }

    final double sigma = radius * (1 - item.hardness) * 0.9;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..maskFilter = sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null;

    TipBrush.paintDab(
      canvas,
      center,
      radius,
      kind: item.kind,
      paint: paint,
      roundness: item.roundness,
      seed: item.size + item.kind.index,
    );
  }

  @override
  bool shouldRepaint(covariant _TipDabPainter oldDelegate) =>
      oldDelegate.item != item || oldDelegate.color != color;
}

/// Custom painter for the interactive scratchpad banner in Tip Studio
class _CustomTipScratchpadPainter extends CustomPainter {
  _CustomTipScratchpadPainter({
    required this.strokes,
    required this.currentStroke,
    required this.stampKey,
    required this.kind,
    required this.angle,
    required this.roundness,
    required this.hardness,
    required this.spacing,
    required this.flipX,
    required this.flipY,
    required this.color,
    required this.strokeWidth,
  });

  final List<PaintContent> strokes;
  final PaintContent? currentStroke;
  final String? stampKey;
  final BrushTipKind kind;
  final double angle;
  final double roundness;
  final double hardness;
  final double spacing;
  final bool flipX;
  final bool flipY;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty && currentStroke == null) {
      final Paint strokePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      final PaintContent brush = stampKey != null
          ? (ImageTipBrush(
              stampKey: stampKey!,
              spacing: spacing,
              angle: angle,
              hardness: hardness,
              flipX: flipX,
              flipY: flipY,
            )..paint = strokePaint)
          : (TipBrush(
              kind: kind,
              angle: angle,
              roundness: roundness,
              hardness: hardness,
              spacing: spacing,
              flipX: flipX,
              flipY: flipY,
            )..paint = strokePaint);

      final double midY = size.height / 2;
      final double padX = size.width * 0.12;
      final double usableW = size.width - padX * 2;
      const int segments = 56;

      brush.startDraw(Offset(padX, midY));
      for (int i = 1; i <= segments; i++) {
        final double t = i / segments;
        final double x = padX + usableW * t;
        final double y = midY - (size.height * 0.28) * _sinLike(t);
        brush.drawing(Offset(x, y));
      }
      brush.draw(canvas, size, false);

      final TextPainter tp = TextPainter(
        text: const TextSpan(
          text: '✨ Doodle here to test custom tip feel',
          style: TextStyle(
            fontSize: 10.5,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 18));
      return;
    }

    for (final s in strokes) {
      s.draw(canvas, size, false);
    }

    if (currentStroke != null) {
      currentStroke!.draw(canvas, size, false);
    }
  }

  double _sinLike(double t) {
    final double x = t * 2 - 1;
    return (1 - x * x) * (x >= 0 ? 1 : -1);
  }

  @override
  bool shouldRepaint(covariant _CustomTipScratchpadPainter oldDelegate) => true;
}
