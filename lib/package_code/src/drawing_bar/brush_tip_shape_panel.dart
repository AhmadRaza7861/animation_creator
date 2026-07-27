import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../drawing_controller.dart';
import '../paint_contents/brush_stamps.dart';
import '../paint_contents/freehand_line.dart';
import '../paint_contents/image_tip_brush.dart';
import '../paint_contents/tip_brush.dart';

/// 笔尖形状网格项 / A brush tip thumbnail entry
///
/// 既可表示矢量形状笔尖（[kind]），也可表示图像纹理笔尖（[stampKey]）。
///
/// Represents either a vector shape tip ([kind]) or an image texture tip
/// ([stampKey]).
class _TipItem {
  const _TipItem(this.kind, this.label, this.size, {this.hardness = 1.0, this.roundness = 1.0})
      : stampKey = null;

  const _TipItem.stamp(this.stampKey, this.label, this.size)
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

  // 以内容而非实例判断相等，选中状态不依赖对象标识
  // Compare by value, so selection does not depend on object identity
  @override
  bool operator ==(Object other) =>
      other is _TipItem &&
      other.kind == kind &&
      other.stampKey == stampKey &&
      other.size == size &&
      other.hardness == hardness &&
      other.roundness == roundness;

  @override
  int get hashCode => Object.hash(kind, stampKey, size, hardness, roundness);
}

/// 笔尖分类（顶部标签用）/ Tip categories (for the top tabs)
enum _TipCategory { all, basic, shapes, stars, symbols, nature, outline, glyph, textures }

const Map<_TipCategory, String> _kCategoryLabels = <_TipCategory, String>{
  _TipCategory.all: 'All',
  _TipCategory.basic: 'Basic',
  _TipCategory.shapes: 'Shapes',
  _TipCategory.stars: 'Stars',
  _TipCategory.symbols: 'Symbols',
  _TipCategory.nature: 'Nature',
  _TipCategory.outline: 'Outline',
  _TipCategory.glyph: 'Glyphs',
  _TipCategory.textures: 'Textures',
};

/// 空心轮廓类 / Outline (hollow) tips
const Set<BrushTipKind> _kOutlineKinds = <BrushTipKind>{
  BrushTipKind.outlineCircle,
  BrushTipKind.outlineSquare,
  BrushTipKind.outlineTriangle,
  BrushTipKind.outlineHexagon,
  BrushTipKind.outlineStar,
  BrushTipKind.outlineHeart,
};

/// 字符类 / Glyph tips
const Set<BrushTipKind> _kGlyphKinds = <BrushTipKind>{
  BrushTipKind.glyphStar,
  BrushTipKind.glyphFlower,
  BrushTipKind.glyphSnow,
  BrushTipKind.glyphHeart,
  BrushTipKind.glyphNote,
  BrushTipKind.glyphClover,
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

_TipCategory _categoryOf(_TipItem item) {
  if (item.isStamp) {
    return _TipCategory.textures;
  }
  if (_kBasicKinds.contains(item.kind)) {
    return _TipCategory.basic;
  }
  if (_kShapeKinds.contains(item.kind)) {
    return _TipCategory.shapes;
  }
  if (_kStarKinds.contains(item.kind)) {
    return _TipCategory.stars;
  }
  if (_kSymbolKinds.contains(item.kind)) {
    return _TipCategory.symbols;
  }
  if (_kNatureKinds.contains(item.kind)) {
    return _TipCategory.nature;
  }
  if (_kOutlineKinds.contains(item.kind)) {
    return _TipCategory.outline;
  }
  if (_kGlyphKinds.contains(item.kind)) {
    return _TipCategory.glyph;
  }
  return _TipCategory.textures; // spatter / chalk / scatter / bristle 等纹理笔尖
}

/// 缩略图网格数据：涵盖全部笔尖形状及若干硬度/圆度变体
///
/// Thumbnail grid data: covers every tip shape plus a few hardness/roundness
/// variants, so the grid reads like Photoshop's Brush Tip Shape presets.
/// 以 getter 暴露，避免热重载后读到过时实例
///
/// Exposed as a getter so hot reload never leaves stale instances behind
List<_TipItem> get _kTipItems => <_TipItem>[
  _TipItem(BrushTipKind.round, 'Hard Round', 30),
  _TipItem(BrushTipKind.round, 'Soft Round', 30, hardness: 0.0),
  _TipItem(BrushTipKind.round, 'Medium Round', 25, hardness: 0.5),
  _TipItem(BrushTipKind.round, 'Flat', 30, roundness: 0.35),
  _TipItem(BrushTipKind.round, 'Soft Big', 45, hardness: 0.1),
  _TipItem(BrushTipKind.square, 'Square', 25),
  _TipItem(BrushTipKind.square, 'Soft Square', 30, hardness: 0.3),
  _TipItem(BrushTipKind.diamond, 'Diamond', 28),
  _TipItem(BrushTipKind.triangle, 'Triangle', 30),
  _TipItem(BrushTipKind.pentagon, 'Pentagon', 32),
  _TipItem(BrushTipKind.hexagon, 'Hexagon', 32),
  _TipItem(BrushTipKind.heptagon, 'Heptagon', 32),
  _TipItem(BrushTipKind.octagon, 'Octagon', 32),
  _TipItem(BrushTipKind.star, 'Star', 36),
  _TipItem(BrushTipKind.fourStar, '4-Star', 34),
  _TipItem(BrushTipKind.sixStar, '6-Star', 38),
  _TipItem(BrushTipKind.cross, 'Cross', 30),
  _TipItem(BrushTipKind.ring, 'Ring', 30),
  _TipItem(BrushTipKind.heart, 'Heart', 34),
  _TipItem(BrushTipKind.flower, 'Flower', 42),
  _TipItem(BrushTipKind.leaf, 'Leaf', 30),
  _TipItem(BrushTipKind.crescent, 'Crescent', 32),
  _TipItem(BrushTipKind.grass, 'Grass', 45),
  _TipItem(BrushTipKind.confetti, 'Confetti', 42),
  _TipItem(BrushTipKind.eightStar, '8-Star', 38),
  _TipItem(BrushTipKind.pinwheel, 'Pinwheel', 36),
  _TipItem(BrushTipKind.fivePetal, 'Blossom', 40),
  _TipItem(BrushTipKind.clover, 'Clover', 34),
  _TipItem(BrushTipKind.shell, 'Shell', 34),
  _TipItem(BrushTipKind.checkmark, 'Check', 32),
  _TipItem(BrushTipKind.sun, 'Sun', 40),
  _TipItem(BrushTipKind.ripple, 'Ripple', 38),
  _TipItem(BrushTipKind.squareRing, 'Square Ring', 32),
  _TipItem(BrushTipKind.spade, 'Spade', 34),
  _TipItem(BrushTipKind.musicNote, 'Music Note', 34),
  _TipItem(BrushTipKind.doubleArrow, 'Double Arrow', 34),
  _TipItem(BrushTipKind.club, 'Club', 34),
  _TipItem(BrushTipKind.shield, 'Shield', 34),
  _TipItem(BrushTipKind.flowerEight, 'Blossom 8', 42),
  _TipItem(BrushTipKind.diamondRing, 'Diamond Ring', 32),
  _TipItem(BrushTipKind.wave, 'Wave', 38),
  _TipItem(BrushTipKind.infinity, 'Infinity', 38),
  _TipItem(BrushTipKind.flame, 'Flame', 36),
  _TipItem(BrushTipKind.feather, 'Feather', 40),
  _TipItem(BrushTipKind.crosshair, 'Crosshair', 38),
  _TipItem(BrushTipKind.paw, 'Paw', 36),
  _TipItem(BrushTipKind.crown, 'Crown', 36),
  _TipItem(BrushTipKind.bowtie, 'Bowtie', 34),
  _TipItem(BrushTipKind.butterfly, 'Butterfly', 44),
  _TipItem(BrushTipKind.mapleLeaf, 'Maple Leaf', 40),
  _TipItem(BrushTipKind.gem, 'Gem', 38),
  _TipItem(BrushTipKind.atom, 'Atom', 42),
  _TipItem(BrushTipKind.puzzle, 'Puzzle', 38),
  _TipItem(BrushTipKind.anchor, 'Anchor', 40),
  _TipItem(BrushTipKind.fish, 'Fish', 40),
  _TipItem(BrushTipKind.mushroom, 'Mushroom', 38),
  _TipItem(BrushTipKind.cloud, 'Cloud', 44),
  _TipItem(BrushTipKind.pineTree, 'Pine Tree', 40),
  _TipItem(BrushTipKind.rocket, 'Rocket', 40),
  _TipItem(BrushTipKind.lightbulb, 'Lightbulb', 38),
  _TipItem(BrushTipKind.bell, 'Bell', 38),
  _TipItem(BrushTipKind.key, 'Key', 38),
  _TipItem(BrushTipKind.hourglass, 'Hourglass', 38),
  _TipItem(BrushTipKind.ghost, 'Ghost', 40),
  // 空心轮廓 / Outline family
  _TipItem(BrushTipKind.outlineCircle, 'Circle Outline', 34),
  _TipItem(BrushTipKind.outlineSquare, 'Square Outline', 34),
  _TipItem(BrushTipKind.outlineTriangle, 'Triangle Outline', 36),
  _TipItem(BrushTipKind.outlineHexagon, 'Hexagon Outline', 36),
  _TipItem(BrushTipKind.outlineStar, 'Star Outline', 38),
  _TipItem(BrushTipKind.outlineHeart, 'Heart Outline', 36),
  // 字符笔尖 / Glyph family
  _TipItem(BrushTipKind.glyphStar, 'Glyph Star', 38),
  _TipItem(BrushTipKind.glyphFlower, 'Glyph Flower', 38),
  _TipItem(BrushTipKind.glyphSnow, 'Glyph Snow', 38),
  _TipItem(BrushTipKind.glyphHeart, 'Glyph Heart', 36),
  _TipItem(BrushTipKind.glyphNote, 'Glyph Note', 36),
  _TipItem(BrushTipKind.glyphClover, 'Glyph Clover', 38),
  _TipItem(BrushTipKind.teardrop, 'Teardrop', 32),
  _TipItem(BrushTipKind.arrow, 'Arrow', 32),
  _TipItem(BrushTipKind.lightning, 'Lightning', 34),
  _TipItem(BrushTipKind.snowflake, 'Snowflake', 40),
  _TipItem(BrushTipKind.spiral, 'Spiral', 40),
  _TipItem(BrushTipKind.gear, 'Gear', 38),
  _TipItem(BrushTipKind.burst, 'Burst', 40),
  _TipItem(BrushTipKind.spatter, 'Spatter', 45),
  _TipItem(BrushTipKind.spatter, 'Spatter', 24),
  _TipItem(BrushTipKind.spatter, 'Spatter', 60),
  _TipItem(BrushTipKind.chalk, 'Chalk', 40),
  _TipItem(BrushTipKind.chalk, 'Chalk', 27),
  _TipItem(BrushTipKind.chalk, 'Chalk', 55),
  _TipItem(BrushTipKind.scatter, 'Scatter', 42),
  _TipItem(BrushTipKind.scatter, 'Scatter', 63),
  _TipItem(BrushTipKind.bristle, 'Bristle', 39),
  _TipItem(BrushTipKind.bristle, 'Bristle', 55),
  _TipItem(BrushTipKind.dryBrush, 'Dry Brush', 36),
  _TipItem(BrushTipKind.dryBrush, 'Dry Brush', 58),
  _TipItem(BrushTipKind.stipple, 'Stipple', 32),
  _TipItem(BrushTipKind.stipple, 'Stipple', 48),
  _TipItem(BrushTipKind.charcoal, 'Charcoal', 40),
  _TipItem(BrushTipKind.charcoal, 'Charcoal', 60),
  _TipItem(BrushTipKind.sponge, 'Sponge', 44),
  _TipItem(BrushTipKind.sponge, 'Sponge', 66),
  _TipItem(BrushTipKind.splash, 'Splash', 45),
  _TipItem(BrushTipKind.splash, 'Splash', 63),
  _TipItem(BrushTipKind.grassClump, 'Grass Clump', 46),
  _TipItem(BrushTipKind.grassClump, 'Grass Clump', 63),
  _TipItem(BrushTipKind.leafScatter, 'Leaf Scatter', 48),
  _TipItem(BrushTipKind.leafScatter, 'Leaf Scatter', 66),
  // 图像纹理笔尖（真实位图质感）/ Image texture tips (real bitmap feel)
  for (final BrushStamp stamp in kBrushStamps) _TipItem.stamp(stamp.key, stamp.label, stamp.defaultSize),
];

/// 笔尖形状面板（仿 Photoshop 的 “Brush Tip Shape”）
///
/// 深色主题，顶部为密集的笔尖缩略图网格（每格带尺寸数字），下方为与 PS 对应
/// 的参数控件：Size、Flip X/Y、Angle、Roundness、Hardness、Spacing，最底部为
/// 实时笔迹预览。任意改动都会即时应用到画板当前笔刷。
///
/// Brush Tip Shape panel (mimics Photoshop's "Brush Tip Shape").
///
/// Dark themed. A dense grid of tip thumbnails (each with a size number) on top,
/// with the PS-matching controls below — Size, Flip X/Y, Angle, Roundness,
/// Hardness, Spacing — and a live stroke preview at the bottom. Every change is
/// applied to the board's current brush instantly.
class BrushTipShapePanel extends StatefulWidget {
  const BrushTipShapePanel({super.key, required this.controller});

  final DrawingController controller;

  /// 以底部弹窗形式展示 / Show as a modal bottom sheet
  static Future<void> show(BuildContext context, DrawingController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: BrushTipShapePanel(controller: controller),
          ),
        );
      },
    );
  }

  @override
  State<BrushTipShapePanel> createState() => _BrushTipShapePanelState();
}

class _BrushTipShapePanelState extends State<BrushTipShapePanel> {
  // 面板背景/控件配色 / Panel palette
  static const Color _bg = Colors.white;
  static const Color _cell = Color(0xFFF7F8FA);
  static const Color _cellSel = Color(0xFFFFF2E5);
  static const Color _accent = Color(0xFFFF9114);
  static const Color _text = Color(0xFF3C3043);
  static const Color _dab = Color(0xFF3C3043);

  late BrushTipKind _kind;
  late double _size;
  late double _angle; // degrees
  late double _roundness; // 0..1
  late double _hardness; // 0..1
  late double _spacing; // fraction of diameter
  bool _flipX = false;
  bool _flipY = false;
  _TipItem? _selected;
  _TipCategory _category = _TipCategory.all;
  String? _stampKey; // 非空表示当前为图像纹理笔尖 / non-null => image texture tip

  @override
  void initState() {
    super.initState();
    final DrawConfig config = widget.controller.drawConfig.value;
    _size = config.strokeWidth.clamp(1, 100).toDouble();

    // 读取当前笔刷参数继续编辑
    final currentContent = widget.controller.currentContent;
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
      final _TipItem first = _kTipItems.first;
      _kind = first.kind;
      _angle = 0;
      _roundness = first.roundness;
      _hardness = first.hardness;
      _spacing = 0.25;
    }
    _selected = _matchItem();
  }

  _TipItem? _matchItem() {
    for (final _TipItem t in _kTipItems) {
      if (_stampKey != null) {
        if (t.stampKey == _stampKey) {
          return t;
        }
      } else if (!t.isStamp &&
          t.kind == _kind &&
          t.hardness == _hardness &&
          t.roundness == _roundness) {
        return t;
      }
    }
    return null;
  }

  void _apply() {
    if (_stampKey != null) {
      widget.controller.setPaintContent(
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
      widget.controller.setPaintContent(
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
  }

  void _selectItem(_TipItem item) {
    setState(() {
      _selected = item;
      _stampKey = item.stampKey;
      _kind = item.kind;
      _hardness = item.hardness;
      _roundness = item.roundness;
      _size = item.size.toDouble();
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      color: _bg,
      child: Column(
        children: <Widget>[
          _header(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _tabs(),
          Expanded(child: _grid()),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _controls(),
          _previewStrip(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.brush, size: 18, color: _text),
          const SizedBox(width: 8),
          const Text(
            'Brush Tip Shape',
            style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: _text),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: <Widget>[
          for (final _TipCategory cat in _TipCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: _CategoryChip(
                label: _kCategoryLabels[cat]!,
                selected: cat == _category,
                accent: _accent,
                onTap: () => setState(() => _category = cat),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid() {
    final List<_TipItem> items = _category == _TipCategory.all
        ? _kTipItems
        : _kTipItems.where((_TipItem t) => _categoryOf(t) == _category).toList();

    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 62,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final _TipItem item = items[index];
        final bool selected = item == _selected;
        return _TipCell(
          item: item,
          selected: selected,
          dabColor: _dab,
          cell: selected ? _cellSel : _cell,
          accent: _accent,
          onTap: () => _selectItem(item),
        );
      },
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _flipCheck('Flip X', _flipX, (bool v) {
                setState(() => _flipX = v);
                _apply();
              }),
              const SizedBox(width: 24),
              _flipCheck('Flip Y', _flipY, (bool v) {
                setState(() => _flipY = v);
                _apply();
              }),
              const Spacer(),
              _AngleRoundnessDial(angle: _angle, roundness: _roundness, accent: _accent),
            ],
          ),
          _slider('Angle', '${_angle.round()}°', _angle, 0, 360, (double v) {
            setState(() => _angle = v);
            _apply();
          }),
          _slider('Roundness', '${(_roundness * 100).round()}%', _roundness, 0.05, 1, (double v) {
            setState(() => _roundness = v);
            _apply();
          }),
          _slider('Hardness', '${(_hardness * 100).round()}%', _hardness, 0, 1, (double v) {
            setState(() => _hardness = v);
            _apply();
          }),
          _slider('Spacing', '${(_spacing * 100).round()}%', _spacing, 0.05, 2, (double v) {
            setState(() => _spacing = v);
            _apply();
          }),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 82,
          child: Text(label, style: const TextStyle(color: _text, fontSize: 12.5)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: _accent,
              inactiveTrackColor: const Color(0xFFE5E5E5),
              thumbColor: _text,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: current.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _flipCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (bool? v) => onChanged(v ?? false),
              side: const BorderSide(color: _text),
              activeColor: _accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _text, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _previewStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TipStrokePainter(
          stampKey: _stampKey,
          kind: _kind,
          angle: _angle,
          roundness: _roundness,
          hardness: _hardness,
          spacing: _spacing,
          flipX: _flipX,
          flipY: _flipY,
          color: widget.controller.drawConfig.value.color,
        ),
      ),
    );
  }
}

/// 分类标签 / Category tab chip
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF666666),
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 单个笔尖缩略图 / A single tip thumbnail
class _TipCell extends StatelessWidget {
  const _TipCell({
    required this.item,
    required this.selected,
    required this.dabColor,
    required this.cell,
    required this.accent,
    required this.onTap,
  });

  final _TipItem item;
  final bool selected;
  final Color dabColor;
  final Color cell;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cell,
          border: Border.all(color: selected ? accent : const Color(0xFFEEEEEE), width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CustomPaint(
                  painter: _TipDabPainter(item: item, color: dabColor),
                ),
              ),
            ),
            Positioned(
              left: 2,
              bottom: 1,
              child: Text(
                '${item.size}',
                style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 缩略图中的单个笔尖“盖章” / A single tip dab in a thumbnail
class _TipDabPainter extends CustomPainter {
  _TipDabPainter({required this.item, required this.color});

  final _TipItem item;
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

/// 底部实时笔迹预览 / Live stroke preview at the bottom
class _TipStrokePainter extends CustomPainter {
  _TipStrokePainter({
    required this.stampKey,
    required this.kind,
    required this.angle,
    required this.roundness,
    required this.hardness,
    required this.spacing,
    required this.flipX,
    required this.flipY,
    required this.color,
  });

  final String? stampKey;
  final BrushTipKind kind;
  final double angle;
  final double roundness;
  final double hardness;
  final double spacing;
  final bool flipX;
  final bool flipY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final FreehandLine brush = stampKey != null
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
    final double padX = size.width * 0.08;
    final double usableW = size.width - padX * 2;
    const int segments = 60;

    brush.startDraw(Offset(padX, midY));
    for (int i = 1; i <= segments; i++) {
      final double t = i / segments;
      final double x = padX + usableW * t;
      final double y = midY - (size.height * 0.28) * _sinLike(t);
      brush.drawing(Offset(x, y));
    }
    brush.draw(canvas, size, false);
  }

  double _sinLike(double t) {
    // 无需 dart:math，用多项式近似一个起伏波形
    // Polynomial-ish wave, avoids importing dart:math here
    final double x = t * 2 - 1; // -1..1
    return (1 - x * x) * (x >= 0 ? 1 : -1);
  }

  @override
  bool shouldRepaint(covariant _TipStrokePainter oldDelegate) =>
      oldDelegate.stampKey != stampKey ||
      oldDelegate.kind != kind ||
      oldDelegate.angle != angle ||
      oldDelegate.roundness != roundness ||
      oldDelegate.hardness != hardness ||
      oldDelegate.spacing != spacing ||
      oldDelegate.flipX != flipX ||
      oldDelegate.flipY != flipY ||
      oldDelegate.color != color;
}

/// 角度 / 圆度指示盘（只读，模仿 PS 右侧的小圆盘）
///
/// Angle / roundness indicator dial (read-only, mimics PS's small dial)
class _AngleRoundnessDial extends StatelessWidget {
  const _AngleRoundnessDial({required this.angle, required this.roundness, required this.accent});

  final double angle;
  final double roundness;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(painter: _DialPainter(angle: angle, roundness: roundness, accent: accent)),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.angle, required this.roundness, required this.accent});

  final double angle;
  final double roundness;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 2;

    final Paint ring = Paint()
      ..color = const Color(0xFF777777)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r, ring);

    // 圆度：把圆压扁表示 / roundness squashes the ellipse
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle * 3.1415926535 / 180);
    final Paint ell = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2 * roundness),
      ell,
    );
    // 角度指针 / angle pointer
    final Paint pointer = Paint()
      ..color = accent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset.zero, Offset(r, 0), pointer);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.roundness != roundness;
}
