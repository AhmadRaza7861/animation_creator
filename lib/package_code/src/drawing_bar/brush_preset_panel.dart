import 'dart:math';

import 'package:flutter/material.dart';

import '../drawing_controller.dart';
import '../helper/ex_value_builder.dart';
import '../paint_contents/paint_content.dart';
import 'brush_presets.dart';
import 'brush_tip_shape_panel.dart';

/// 笔刷预设面板
///
/// 以网格形式展示全部笔刷，每个格子都会用该笔刷实时绘制一段示例笔迹并显示名称，
/// 让用户一眼看懂点选后会画出什么。底部提供 “主直径”（画笔粗细）滑块，
/// 当前选中的笔刷会高亮显示。
///
/// Brush Preset Panel
///
/// Shows every brush in a grid. Each cell paints a live sample stroke with that
/// brush and shows its name, so users can see exactly what a brush draws before
/// picking it. A "Master Diameter" (stroke width) slider sits at the bottom and
/// the selected brush is highlighted.
class BrushPresetPanel extends StatefulWidget {
  const BrushPresetPanel({
    super.key,
    required this.controller,
    this.presets,
    this.onSelected,
    this.title = 'Brushes',
  });

  /// 绘制控制器 / Drawing controller
  final DrawingController controller;

  /// 笔刷预设列表，默认使用 [kDefaultBrushPresets]
  ///
  /// Brush preset list, defaults to [kDefaultBrushPresets]
  final List<BrushPreset>? presets;

  /// 选中某个笔刷后的回调 / Called after a brush is selected
  final void Function(BrushPreset preset)? onSelected;

  /// 面板标题 / Panel title
  final String title;

  /// 以底部弹窗形式展示面板 / Show the panel as a modal bottom sheet
  static Future<void> show(
    BuildContext context,
    DrawingController controller, {
    List<BrushPreset>? presets,
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
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: BrushPresetPanel(
              controller: controller,
              presets: presets,
              onSelected: (_) {
                Navigator.pop(ctx);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<BrushPresetPanel> createState() => _BrushPresetPanelState();
}

class _BrushPresetPanelState extends State<BrushPresetPanel> {
  BrushPreset? _selected;

  List<BrushPreset> get _presets => widget.presets ?? kDefaultBrushPresets;

  @override
  void initState() {
    super.initState();
    final presetId = widget.controller.activeBrushPresetId;
    if (presetId != null) {
      _selected = _presets.cast<BrushPreset?>().firstWhere(
        (p) => p?.id == presetId,
        orElse: () => null,
      );
    } else {
      _selected = null;
    }
  }

  void _select(BrushPreset preset) {
    setState(() => _selected = preset);
    widget.controller.activeBrushPresetId = preset.id;
    widget.controller.setPaintContent(preset.create());
    widget.onSelected?.call(preset);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.controller.drawConfig,
      // 颜色与粗细变化时刷新预览
      shouldRebuild: (DrawConfig p, DrawConfig n) =>
          p.color != n.color || p.strokeWidth != n.strokeWidth,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C3043),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9114),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Customize Tip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(context);
                      BrushTipShapePanel.show(context, widget.controller);
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisExtent: 108,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _presets.length,
                itemBuilder: (BuildContext context, int index) {
                  final BrushPreset preset = _presets[index];
                  return _BrushCell(
                    preset: preset,
                    color: config.color,
                    selected: preset.id == _selected?.id,
                    accent: theme.colorScheme.primary,
                    onTap: () => _select(preset),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 单个笔刷格子 / A single brush cell
class _BrushCell extends StatelessWidget {
  const _BrushCell({
    required this.preset,
    required this.color,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final BrushPreset preset;
  final Color color;
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BrushPreviewPainter(preset: preset, color: color),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              child: Text(
                preset.name,
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

/// 笔刷示例笔迹绘制器
///
/// 用对应笔刷在格子里实时画出一段 S 形示例笔迹
///
/// Paints a live S-shaped sample stroke of the given brush inside the cell
class _BrushPreviewPainter extends CustomPainter {
  _BrushPreviewPainter({required this.preset, required this.color});

  final BrushPreset preset;
  final Color color;

  /// 预览用的固定笔触粗细 / Fixed preview stroke width
  static const double _previewWidth = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = _sampleStroke(size);
    if (points.isEmpty) {
      return;
    }

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

  /// 生成一段横跨格子的正弦示例笔迹
  ///
  /// Build a sine-shaped sample stroke spanning the cell
  List<Offset> _sampleStroke(Size size) {
    final List<Offset> points = <Offset>[];
    final double padX = size.width * 0.12;
    final double usableW = size.width - padX * 2;
    final double midY = size.height / 2;
    final double amp = size.height * 0.24;
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
  bool shouldRepaint(covariant _BrushPreviewPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.preset != preset;
}
