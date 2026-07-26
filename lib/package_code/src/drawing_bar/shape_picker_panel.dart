import 'package:flutter/material.dart';

import '../../paint_contents.dart';
import '../drawing_controller.dart';
import '../helper/ex_value_builder.dart';
import '../paint_contents/figures.dart';
import '../paint_contents/shapes.dart';

/// 图形分类 / Shape categories
enum ShapeCategory { basic, vehicles, stickman, flowers, birds, animals, nature }

const Map<ShapeCategory, String> kShapeCategoryLabels = <ShapeCategory, String>{
  ShapeCategory.basic: 'Basic',
  ShapeCategory.vehicles: 'Vehicles',
  ShapeCategory.stickman: 'Stickman',
  ShapeCategory.flowers: 'Flowers',
  ShapeCategory.birds: 'Birds',
  ShapeCategory.animals: 'Animals',
  ShapeCategory.nature: 'Nature',
};

/// 图形预设 / Shape preset
class ShapePreset {
  const ShapePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.create,
  });

  /// 唯一标识 / Unique identifier
  final String id;

  /// 显示名称 / Display name
  final String name;

  /// 所属分类 / Category
  final ShapeCategory category;

  /// 创建绘制内容实例 / Create the drawing-content instance
  final PaintContent Function() create;
}

/// 便捷构造：组合图形 / Helper for composite figures
ShapePreset _figure(String id, String name, ShapeCategory category) =>
    ShapePreset(id: id, name: name, category: category, create: () => FigureShape(id));

/// 内置图形列表 / Built-in shapes
///
/// 使用 getter 而非顶层 `final`：顶层惰性变量只会初始化一次，热重载时不会重建，
/// 一旦 [ShapePreset] 结构变化就会读到过时实例。getter 每次都返回最新数据。
///
/// Exposed as a getter rather than a top-level `final`: lazy top-level variables
/// initialize only once and are not rebuilt on hot reload, so a changed
/// [ShapePreset] shape would leave stale instances behind. A getter always
/// rebuilds with the current definition.
List<ShapePreset> get kDefaultShapes => <ShapePreset>[
  // ---- 基础图形 / Basic ----
  ShapePreset(id: 'line', name: 'Line', category: ShapeCategory.basic, create: () => StraightLine()),
  ShapePreset(id: 'arrow', name: 'Arrow', category: ShapeCategory.basic, create: () => ArrowShape()),
  ShapePreset(
      id: 'doubleArrow',
      name: 'Double Arrow',
      category: ShapeCategory.basic,
      create: () => ArrowShape(doubleHeaded: true)),
  ShapePreset(
      id: 'rectangle', name: 'Rectangle', category: ShapeCategory.basic, create: () => Rectangle()),
  ShapePreset(
      id: 'roundedRect',
      name: 'Rounded Rect',
      category: ShapeCategory.basic,
      create: () => RoundedRectShape()),
  ShapePreset(id: 'circle', name: 'Circle', category: ShapeCategory.basic, create: () => Circle()),
  ShapePreset(
      id: 'ellipse', name: 'Ellipse', category: ShapeCategory.basic, create: () => EllipseShape()),
  ShapePreset(
      id: 'triangle', name: 'Triangle', category: ShapeCategory.basic, create: () => TriangleShape()),
  ShapePreset(
      id: 'rightTriangle',
      name: 'Right Triangle',
      category: ShapeCategory.basic,
      create: () => RightTriangleShape()),
  ShapePreset(
      id: 'diamond', name: 'Diamond', category: ShapeCategory.basic, create: () => DiamondShape()),
  ShapePreset(
      id: 'pentagon', name: 'Pentagon', category: ShapeCategory.basic, create: () => PentagonShape()),
  ShapePreset(
      id: 'hexagon', name: 'Hexagon', category: ShapeCategory.basic, create: () => HexagonShape()),
  ShapePreset(id: 'star', name: 'Star', category: ShapeCategory.basic, create: () => StarShape()),
  ShapePreset(
      id: 'parallelogram',
      name: 'Parallelogram',
      category: ShapeCategory.basic,
      create: () => ParallelogramShape()),
  ShapePreset(
      id: 'trapezoid',
      name: 'Trapezoid',
      category: ShapeCategory.basic,
      create: () => TrapezoidShape()),
  ShapePreset(id: 'cross', name: 'Cross', category: ShapeCategory.basic, create: () => CrossShape()),
  ShapePreset(id: 'heart', name: 'Heart', category: ShapeCategory.basic, create: () => HeartShape()),
  ShapePreset(
      id: 'lightning',
      name: 'Lightning',
      category: ShapeCategory.basic,
      create: () => LightningShape()),
  ShapePreset(
      id: 'speech',
      name: 'Speech Bubble',
      category: ShapeCategory.basic,
      create: () => SpeechBubbleShape()),
  ShapePreset(id: 'cloud', name: 'Cloud', category: ShapeCategory.basic, create: () => CloudShape()),

  // ---- 交通工具 / Vehicles ----
  _figure('car', 'Car', ShapeCategory.vehicles),
  _figure('bus', 'Bus', ShapeCategory.vehicles),
  _figure('truck', 'Truck', ShapeCategory.vehicles),
  _figure('airplane', 'Airplane', ShapeCategory.vehicles),
  _figure('sailboat', 'Sailboat', ShapeCategory.vehicles),
  _figure('rocketShip', 'Rocket', ShapeCategory.vehicles),
  _figure('bicycle', 'Bicycle', ShapeCategory.vehicles),

  // ---- 火柴人 / Stickman ----
  _figure('stickStanding', 'Standing', ShapeCategory.stickman),
  _figure('stickWalking', 'Walking', ShapeCategory.stickman),
  _figure('stickRunning', 'Running', ShapeCategory.stickman),
  _figure('stickWaving', 'Waving', ShapeCategory.stickman),
  _figure('stickJumping', 'Jumping', ShapeCategory.stickman),

  // ---- 花卉 / Flowers ----
  _figure('tulip', 'Tulip', ShapeCategory.flowers),
  _figure('daisy', 'Daisy', ShapeCategory.flowers),
  _figure('sunflower', 'Sunflower', ShapeCategory.flowers),
  _figure('rose', 'Rose', ShapeCategory.flowers),

  // ---- 鸟类 / Birds ----
  _figure('seagull', 'Seagull', ShapeCategory.birds),
  _figure('bird', 'Bird', ShapeCategory.birds),
  _figure('owl', 'Owl', ShapeCategory.birds),
  _figure('duck', 'Duck', ShapeCategory.birds),

  // ---- 动物 / Animals ----
  _figure('cat', 'Cat', ShapeCategory.animals),
  _figure('fishFigure', 'Fish', ShapeCategory.animals),

  // ---- 自然 / Nature ----
  _figure('tree', 'Tree', ShapeCategory.nature),
  _figure('house', 'House', ShapeCategory.nature),
  _figure('sun', 'Sun', ShapeCategory.nature),
  _figure('mountain', 'Mountain', ShapeCategory.nature),
];

/// 图形选择面板
///
/// 网格展示全部可拖拽绘制的图形，每格用该图形自身绘制一个预览，并显示名称。
/// 选中后在画板上按住拖动即可绘制对应图形；底部可切换描边 / 填充。
///
/// Shape picker panel.
///
/// Shows every drag-to-draw shape in a grid; each cell previews the shape by
/// drawing it with its own painter, with its name below. After picking one,
/// press and drag on the board to draw it. A stroke / fill toggle sits at the
/// bottom.
class ShapePickerPanel extends StatefulWidget {
  const ShapePickerPanel({
    super.key,
    required this.controller,
    this.shapes,
    this.onSelected,
    this.title = 'Shapes',
  });

  final DrawingController controller;
  final List<ShapePreset>? shapes;
  final void Function(ShapePreset shape)? onSelected;
  final String title;

  /// 以底部弹窗形式展示 / Show as a modal bottom sheet
  static Future<void> show(
    BuildContext context,
    DrawingController controller, {
    List<ShapePreset>? shapes,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: ShapePickerPanel(controller: controller, shapes: shapes),
          ),
        );
      },
    );
  }

  @override
  State<ShapePickerPanel> createState() => _ShapePickerPanelState();
}

class _ShapePickerPanelState extends State<ShapePickerPanel> {
  ShapePreset? _selected;
  ShapeCategory _category = ShapeCategory.basic;

  List<ShapePreset> get _all => widget.shapes ?? kDefaultShapes;

  List<ShapePreset> get _shapes =>
      _all.where((ShapePreset s) => s.category == _category).toList();

  void _select(ShapePreset shape) {
    setState(() => _selected = shape);
    widget.controller.setPaintContent(shape.create());
    widget.onSelected?.call(shape);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) =>
          p.color != n.color || p.strokeWidth != n.strokeWidth || p.style != n.style,
      builder: (BuildContext context, DrawConfig config, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: <Widget>[
                  for (final ShapeCategory cat in ShapeCategory.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                      child: _CategoryChip(
                        label: kShapeCategoryLabels[cat]!,
                        selected: cat == _category,
                        accent: theme.colorScheme.primary,
                        onTap: () => setState(() => _category = cat),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  mainAxisExtent: 100,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _shapes.length,
                itemBuilder: (BuildContext context, int index) {
                  final ShapePreset shape = _shapes[index];
                  return _ShapeCell(
                    shape: shape,
                    color: config.color,
                    style: config.style,
                    selected: shape.id == _selected?.id,
                    accent: theme.colorScheme.primary,
                    onTap: () => _select(shape),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _StyleToggle(controller: widget.controller, style: config.style),
          ],
        );
      },
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
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 单个图形格子 / A single shape cell
class _ShapeCell extends StatelessWidget {
  const _ShapeCell({
    required this.shape,
    required this.color,
    required this.style,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final ShapePreset shape;
  final Color color;
  final PaintingStyle style;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ShapePreviewPainter(shape: shape, color: color, style: style),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              child: Text(
                shape.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? accent : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图形预览绘制器
///
/// 模拟一次从左上到右下的拖拽，用图形自身的绘制逻辑生成预览
///
/// Previews a shape by simulating a drag from the top-left to the bottom-right
/// of the cell and letting the shape paint itself.
class _ShapePreviewPainter extends CustomPainter {
  _ShapePreviewPainter({required this.shape, required this.color, required this.style});

  final ShapePreset shape;
  final Color color;
  final PaintingStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final PaintContent content = shape.create()
      ..paint = (Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = style
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true);

    content.startDraw(Offset(size.width * 0.1, size.height * 0.12));
    content.drawing(Offset(size.width * 0.9, size.height * 0.88));
    content.draw(canvas, size, false);
  }

  @override
  bool shouldRepaint(covariant _ShapePreviewPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.style != style ||
      oldDelegate.shape.id != shape.id;
}

/// 描边 / 填充切换 / Stroke vs fill toggle
class _StyleToggle extends StatelessWidget {
  const _StyleToggle({required this.controller, required this.style});

  final DrawingController controller;
  final PaintingStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: <Widget>[
          const Text('Style', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: SegmentedButton<PaintingStyle>(
              segments: const <ButtonSegment<PaintingStyle>>[
                ButtonSegment<PaintingStyle>(
                  value: PaintingStyle.stroke,
                  label: Text('Outline'),
                  icon: Icon(Icons.crop_square, size: 18),
                ),
                ButtonSegment<PaintingStyle>(
                  value: PaintingStyle.fill,
                  label: Text('Fill'),
                  icon: Icon(Icons.square_rounded, size: 18),
                ),
              ],
              selected: <PaintingStyle>{style},
              showSelectedIcon: false,
              onSelectionChanged: (Set<PaintingStyle> s) =>
                  controller.setStyle(style: s.first),
            ),
          ),
        ],
      ),
    );
  }
}
