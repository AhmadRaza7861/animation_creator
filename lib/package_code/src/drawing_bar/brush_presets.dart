import 'package:dummy/package_code/src/paint_contents/dashed_line.dart';
import 'package:dummy/package_code/src/paint_contents/dotted_line.dart';
import 'package:dummy/package_code/src/paint_contents/highlighter_line.dart';
import 'package:dummy/package_code/src/paint_contents/image_tip_brush.dart';
import 'package:dummy/package_code/src/paint_contents/shape_brush_line.dart';
import 'package:dummy/package_code/src/paint_contents/tip_brush.dart';
import 'package:flutter/material.dart';

import '../../paint_contents.dart';
import '../paint_contents/preset_strokes.dart';
import '../paint_contents/stroke_styles.dart';

/// 笔刷预设
///
/// 描述一个可选择的笔刷：唯一 id、显示名称、图标，以及创建绘制内容实例的工厂。
/// 多个预设可以共用同一个内容类型（只是参数不同），因此选中状态以 [id] 区分。
///
/// Brush Preset
///
/// Describes a selectable brush: a unique id, display name, icon and a factory
/// that builds a fresh drawing-content instance. Several presets may share one
/// content type with different parameters, so selection is tracked by [id].
class BrushPreset {
  const BrushPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.create,
    this.description = '',
  });

  /// 唯一标识 / Unique identifier
  final String id;

  /// 显示名称 / Display name
  final String name;

  /// 图标 / Icon
  final IconData icon;

  /// 简短说明 / Short description
  final String description;

  /// 创建一个全新的绘制内容实例 / Create a fresh drawing-content instance
  final PaintContent Function() create;
}

/// 默认笔刷预设列表
///
/// 覆盖完整的笔刷清单：钢笔、铅笔、蜡笔、喷枪、网点、排线、渐变、立体、
/// 多彩装饰与波形笔迹等。
///
/// Default brush preset list — the full brush lineup: pens, pencils, crayon,
/// airbrush, halftone, hatching, gradient, 3D, decorative multi-color and
/// waveform strokes.
/// 以 getter 暴露：顶层惰性变量热重载时不会重建，结构变化后会读到过时实例。
///
/// Exposed as a getter: lazy top-level variables are not rebuilt on hot reload,
/// which would leave stale instances behind after the class shape changes.
List<BrushPreset> get kDefaultBrushPresets => <BrushPreset>[
  // ---- 钢笔 / Pens ----
  BrushPreset(
    id: 'pen',
    name: 'Pen',
    description: 'Smooth solid line',
    icon: Icons.edit,
    create: () => SimpleLine(),
  ),
  BrushPreset(
    id: 'penSoft',
    name: 'Pen (Soft)',
    description: 'Soft feathered edge',
    icon: Icons.blur_on,
    create: () => SoftRoundBrush(spacingRatio: 0.08, softness: 0.6),
  ),
  BrushPreset(
    id: 'penChoppy',
    name: 'Pen (Choppy)',
    description: 'Scalloped rippling edge',
    icon: Icons.waves,
    create: () => ChoppyLine(),
  ),
  BrushPreset(
    id: 'roughPen',
    name: 'Rough Pen',
    description: 'Ragged broken edge',
    icon: Icons.gesture,
    create: () => RoughPenLine(),
  ),
  BrushPreset(
    id: 'ink',
    name: 'Ink',
    description: 'Tapered ink line',
    icon: Icons.create,
    create: () => InkLine(),
  ),
  BrushPreset(
    id: 'dipPen',
    name: 'Dip Pen',
    description: 'Ink blob start, tapered end',
    icon: Icons.brush,
    create: () => InkLine(startBlob: true, endTaper: 0.85),
  ),
  BrushPreset(
    id: 'calligraphy',
    name: 'Caligraphy',
    description: 'Angled chisel nib',
    icon: Icons.draw,
    create: () => CalligraphyBrush(),
  ),

  // ---- 素描 / 铅笔 / Sketch and pencils ----
  BrushPreset(
    id: 'sketch',
    name: 'Sketch',
    description: 'Scratchy hand-drawn pass',
    icon: Icons.mode_edit_outline,
    create: () => SketchLine(),
  ),
  BrushPreset(
    id: 'crayon',
    name: 'Crayon',
    description: 'Waxy coarse grain',
    icon: Icons.color_lens_outlined,
    create: () => PencilLine(density: 14, opacity: 0.85, spread: 1.1, speck: 0.16),
  ),
  BrushPreset(
    id: 'pencil',
    name: 'Pencil',
    description: 'Graphite grain',
    icon: Icons.edit_outlined,
    create: () => PencilLine(),
  ),
  BrushPreset(
    id: 'pencilH',
    name: 'Pencil H',
    description: 'Hard, light graphite',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 7, opacity: 0.3, spread: 0.9, speck: 0.07),
  ),
  BrushPreset(
    id: 'pencilHB',
    name: 'Pencil HB',
    description: 'Medium graphite',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 11, opacity: 0.6, spread: 1.0, speck: 0.09),
  ),
  BrushPreset(
    id: 'pencil6B',
    name: 'Pencil 6B',
    description: 'Soft, dark graphite',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 16, opacity: 0.9, spread: 1.2, speck: 0.11),
  ),
  BrushPreset(
    id: 'grain',
    name: 'Grain',
    description: 'Fine speckled grain',
    icon: Icons.grain,
    create: () => PencilLine(density: 18, opacity: 0.35, spread: 1.3, speck: 0.06),
  ),

  // ---- 画笔 / 喷枪 / Brushes and airbrush ----
  BrushPreset(
    id: 'brush',
    name: 'Brush',
    description: 'Tapered pressure brush',
    icon: Icons.brush,
    create: () => SmoothLine(),
  ),
  BrushPreset(
    id: 'highlighter',
    name: 'Highlighter',
    description: 'Translucent marker',
    icon: Icons.highlight,
    create: () => HighlighterLine(),
  ),
  BrushPreset(
    id: 'airbrush',
    name: 'Airbrush',
    description: 'Soft diffuse spray',
    icon: Icons.blur_circular,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.1, hardness: 0.6),
  ),
  BrushPreset(
    id: 'airbrushDark',
    name: 'Airbrush (Darker)',
    description: 'Dense soft spray',
    icon: Icons.blur_circular,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.05, hardness: 0.8),
  ),
  BrushPreset(
    id: 'spray',
    name: 'Spray',
    description: 'Spattered spray can',
    icon: Icons.air,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.28),
  ),
  BrushPreset(
    id: 'stipple',
    name: 'Stipple',
    description: 'Fine dotted texture',
    icon: Icons.more_horiz,
    create: () => TipBrush(kind: BrushTipKind.stipple, spacing: 0.3),
  ),

  // ---- 像素 / 马赛克 / Pixel and mosaic ----
  BrushPreset(
    id: 'pixel',
    name: 'Pixel',
    description: 'Grid-snapped blocks',
    icon: Icons.grid_on,
    create: () => PixelLine(),
  ),
  BrushPreset(
    id: 'mosaic',
    name: 'Mosaic',
    description: 'Tiles with varied shade',
    icon: Icons.dashboard,
    create: () => MosaicLine(),
  ),

  // ---- 网点 / 排线 / Halftone and hatching ----
  BrushPreset(
    id: 'halftone',
    name: 'Halftone',
    description: 'Dot grid band',
    icon: Icons.blur_linear,
    create: () => HalftoneLine(),
  ),
  BrushPreset(
    id: 'halftoneRight',
    name: 'Halftone Right Hatch',
    description: 'Diagonal "/" hatching',
    icon: Icons.text_rotation_angleup,
    create: () => HatchLine(),
  ),
  BrushPreset(
    id: 'halftoneLeft',
    name: 'Halftone Left Hatch',
    description: 'Diagonal "\\" hatching',
    icon: Icons.text_rotation_angledown,
    create: () => HatchLine(rightward: false),
  ),

  // ---- 渐变 / 立体 / Gradient and 3D ----
  BrushPreset(
    id: 'gradient',
    name: 'Gradient',
    description: 'Color ramp along stroke',
    icon: Icons.gradient,
    create: () => GradientLine(),
  ),
  BrushPreset(
    id: 'brush3d',
    name: '3D Brush',
    description: 'Shaded round tube',
    icon: Icons.view_in_ar,
    create: () => TubeLine(),
  ),
  BrushPreset(
    id: 'candyCane',
    name: '3D Candy Cane',
    description: 'Striped 3D tube',
    icon: Icons.view_in_ar_outlined,
    create: () => CandyCaneLine(),
  ),

  // ---- 装饰 / 纹理 / Decorative and textures ----
  BrushPreset(
    id: 'sparkles',
    name: 'Sparkles',
    description: 'Scattered star glints',
    icon: Icons.auto_awesome,
    create: () => SparklesLine(),
  ),
  BrushPreset(
    id: 'leaves',
    name: 'Leaves',
    description: 'Scattered leaves',
    icon: Icons.eco,
    create: () => TipBrush(kind: BrushTipKind.leafScatter, spacing: 0.8),
  ),
  BrushPreset(
    id: 'hair',
    name: 'Hair',
    description: 'Parallel thin strands',
    icon: Icons.waves,
    create: () => HairLine(),
  ),
  BrushPreset(
    id: 'fur',
    name: 'Fur',
    description: 'Dense radiating hairs',
    icon: Icons.pets,
    create: () => ImageTipBrush(stampKey: 'fur', spacing: 0.15),
  ),
  BrushPreset(
    id: 'grunge',
    name: 'Grunge',
    description: 'Rough grungy texture',
    icon: Icons.texture,
    create: () => ImageTipBrush(stampKey: 'grunge', spacing: 0.2),
  ),
  BrushPreset(
    id: 'orange',
    name: 'Orange',
    description: 'Orange-peel dimples',
    icon: Icons.circle_outlined,
    create: () => ImageTipBrush(stampKey: 'orangePeel', spacing: 0.2),
  ),

  // ---- 多彩 / Multi-color ----
  BrushPreset(
    id: 'sprinkles',
    name: 'Sprinkles',
    description: 'Colorful scattered dashes',
    icon: Icons.celebration,
    create: () => SprinklesLine(),
  ),
  BrushPreset(
    id: 'static',
    name: 'Static',
    description: 'Random colored blocks',
    icon: Icons.blur_off,
    create: () => StaticLine(),
  ),

  // ---- 图形重复 / Repeating marks ----
  BrushPreset(
    id: 'dots',
    name: 'Dots',
    description: 'Spaced round dots',
    icon: Icons.circle,
    create: () => DottedLine(spacingRatio: 1.2),
  ),
  BrushPreset(
    id: 'squares',
    name: 'Squares',
    description: 'Spaced square stamps',
    icon: Icons.crop_square,
    create: () => SquareBrush(spacingRatio: 1.2),
  ),
  BrushPreset(
    id: 'dash',
    name: 'Dash',
    description: 'Dashed line',
    icon: Icons.more_horiz,
    create: () => DashedLine(),
  ),

  // ---- 波形 / Waveforms ----
  BrushPreset(
    id: 'saw',
    name: 'Saw',
    description: 'Sawtooth wave',
    icon: Icons.show_chart,
    create: () => SawLine(),
  ),
  BrushPreset(
    id: 'gear',
    name: 'Gear',
    description: 'Square wave teeth',
    icon: Icons.settings_ethernet,
    create: () => GearLine(),
  ),
  BrushPreset(
    id: 'heartbeat',
    name: 'Heartbeat',
    description: 'ECG pulse line',
    icon: Icons.monitor_heart_outlined,
    create: () => HeartbeatLine(),
  ),
];
