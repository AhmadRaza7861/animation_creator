import 'package:dummy/package_code/src/paint_contents/dashed_line.dart';
import 'package:dummy/package_code/src/paint_contents/dotted_line.dart';
import 'package:dummy/package_code/src/paint_contents/highlighter_line.dart';
import 'package:dummy/package_code/src/paint_contents/shape_brush_line.dart';
import 'package:flutter/material.dart';
import '../../paint_contents.dart';

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

/// 默认笔刷预设列表 (110+ 预设)
///
/// 覆盖完整的艺术笔刷清单：艺术墨水、传统画笔、素描铅笔、喷枪水彩、
/// 魔法辉光、自然元素、创意印章、轮廓几何、丰富纹理与 3D 笔触等。
///
/// Default brush preset list — comprehensive lineup of artistic inks, natural media,
/// pencils, airbrushes, glowing magic, elements, stamps, outlines, textures, and 3D strokes.
List<BrushPreset> get kDefaultBrushPresets => <BrushPreset>[
  // =========================================================================
  // 1. 艺术墨水 / Inks & Artistic Pens
  // =========================================================================
  BrushPreset(
    id: 'ink',
    name: 'Ink Pen',
    description: 'Tapered flowing ink line',
    icon: Icons.create,
    create: () => InkLine(),
  ),
  BrushPreset(
    id: 'dipPen',
    name: 'Dip Pen',
    description: 'Ink blob start with fine tapered end',
    icon: Icons.brush,
    create: () => InkLine(startBlob: true, endTaper: 0.85),
  ),
  BrushPreset(
    id: 'calligraphy',
    name: 'Calligraphy Nib',
    description: 'Angled flat chisel nib',
    icon: Icons.draw,
    create: () => CalligraphyBrush(),
  ),
  BrushPreset(
    id: 'roughPen',
    name: 'Rough Pen',
    description: 'Ragged textured broken edge',
    icon: Icons.gesture,
    create: () => RoughPenLine(),
  ),
  BrushPreset(
    id: 'penSoft',
    name: 'Soft Feather Pen',
    description: 'Soft feathered translucent edge',
    icon: Icons.blur_on,
    create: () => SoftRoundBrush(spacingRatio: 0.08, softness: 0.6),
  ),
  BrushPreset(
    id: 'penChoppy',
    name: 'Choppy Ripple',
    description: 'Scalloped undulating rhythm',
    icon: Icons.waves,
    create: () => ChoppyLine(),
  ),
  BrushPreset(
    id: 'watercolor',
    name: 'Watercolor Wash',
    description: 'Soft layered pigment wash',
    icon: Icons.water_drop_outlined,
    create: () => ImageTipBrush(stampKey: 'watercolor', spacing: 0.12, hardness: 0.5),
  ),
  BrushPreset(
    id: 'charcoal',
    name: 'Charcoal Stick',
    description: 'Rich dark powdery charcoal',
    icon: Icons.brush_outlined,
    create: () => TipBrush(kind: BrushTipKind.charcoal, spacing: 0.18),
  ),
  BrushPreset(
    id: 'chalk',
    name: 'Chalk Pastel',
    description: 'Dry grainy chalk stick',
    icon: Icons.edit_note,
    create: () => TipBrush(kind: BrushTipKind.chalk, spacing: 0.15),
  ),
  BrushPreset(
    id: 'chalkStamp',
    name: 'Chalkboard Dust',
    description: 'Textured dusty board stroke',
    icon: Icons.border_color,
    create: () => ImageTipBrush(stampKey: 'chalk', spacing: 0.14),
  ),
  BrushPreset(
    id: 'bristle',
    name: 'Bristle Brush',
    description: 'Fine hair streaks in oil medium',
    icon: Icons.format_paint,
    create: () => TipBrush(kind: BrushTipKind.bristle, spacing: 0.12),
  ),
  BrushPreset(
    id: 'bristleTex',
    name: 'Heavy Oil Bristles',
    description: 'Dense impasto paint texture',
    icon: Icons.brush,
    create: () => ImageTipBrush(stampKey: 'bristleTex', spacing: 0.1),
  ),
  BrushPreset(
    id: 'dryBrush',
    name: 'Dry Brush',
    description: 'Scraped dry canvas stroke',
    icon: Icons.brush_sharp,
    create: () => TipBrush(kind: BrushTipKind.dryBrush, spacing: 0.18),
  ),
  BrushPreset(
    id: 'sponge',
    name: 'Sea Sponge',
    description: 'Porous organic dabs',
    icon: Icons.bubble_chart,
    create: () => TipBrush(kind: BrushTipKind.sponge, spacing: 0.3),
  ),
  BrushPreset(
    id: 'splash',
    name: 'Ink Splash',
    description: 'Dynamic fluid ink droplets',
    icon: Icons.opacity,
    create: () => TipBrush(kind: BrushTipKind.splash, spacing: 0.4),
  ),
  BrushPreset(
    id: 'splatter',
    name: 'Ink Splatter',
    description: 'Expressive spattered pigment',
    icon: Icons.water_drop,
    create: () => ImageTipBrush(stampKey: 'splatter', spacing: 0.35),
  ),
  BrushPreset(
    id: 'spatter',
    name: 'Fine Spatter',
    description: 'Scattered microscopic flecks',
    icon: Icons.grain,
    create: () => TipBrush(kind: BrushTipKind.spatter, spacing: 0.32),
  ),
  BrushPreset(
    id: 'inkDrops',
    name: 'Ink Drops',
    description: 'Wet dripping ink beads',
    icon: Icons.colorize,
    create: () => ImageTipBrush(stampKey: 'inkDrops', spacing: 0.38),
  ),
  BrushPreset(
    id: 'rake',
    name: 'Rake Comb',
    description: 'Parallel multi-prong comb',
    icon: Icons.reorder,
    create: () => ImageTipBrush(stampKey: 'rake', spacing: 0.12),
  ),

  // =========================================================================
  // 2. 素描与铅笔 / Pencils & Sketch
  // =========================================================================
  BrushPreset(
    id: 'sketch',
    name: 'Rough Sketch',
    description: 'Scratchy freehand construction lines',
    icon: Icons.mode_edit_outline,
    create: () => SketchLine(),
  ),
  BrushPreset(
    id: 'crayon',
    name: 'Wax Crayon',
    description: 'Waxy coarse textured grain',
    icon: Icons.color_lens_outlined,
    create: () => PencilLine(density: 14, opacity: 0.85, spread: 1.1, speck: 0.16),
  ),
  BrushPreset(
    id: 'pencil',
    name: 'Graphite Pencil',
    description: 'Standard natural pencil grain',
    icon: Icons.edit_outlined,
    create: () => PencilLine(),
  ),
  BrushPreset(
    id: 'pencilH',
    name: 'Hard Pencil (H)',
    description: 'Crisp, light mechanical lead',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 7, opacity: 0.3, spread: 0.9, speck: 0.07),
  ),
  BrushPreset(
    id: 'pencilHB',
    name: 'Medium Pencil (HB)',
    description: 'Balanced everyday sketching pencil',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 11, opacity: 0.6, spread: 1.0, speck: 0.09),
  ),
  BrushPreset(
    id: 'pencil6B',
    name: 'Soft Pencil (6B)',
    description: 'Deep, dark velvety graphite',
    icon: Icons.edit_outlined,
    create: () => PencilLine(density: 16, opacity: 0.9, spread: 1.2, speck: 0.11),
  ),
  BrushPreset(
    id: 'grain',
    name: 'Speckled Grain',
    description: 'Fine speckled noise shading',
    icon: Icons.grain,
    create: () => PencilLine(density: 18, opacity: 0.35, spread: 1.3, speck: 0.06),
  ),
  BrushPreset(
    id: 'sand',
    name: 'Desert Sand',
    description: 'Fine granular sand dust',
    icon: Icons.grain_outlined,
    create: () => ImageTipBrush(stampKey: 'sand', spacing: 0.15),
  ),
  BrushPreset(
    id: 'scratches',
    name: 'Etched Scratches',
    description: 'Distressed surface lines',
    icon: Icons.linear_scale,
    create: () => ImageTipBrush(stampKey: 'scratches', spacing: 0.18),
  ),

  // =========================================================================
  // 3. 画笔与喷枪 / Brushes & Spray
  // =========================================================================
  BrushPreset(
    id: 'brush',
    name: 'Smooth Brush',
    description: 'Tapered pressure-sensitive stroke',
    icon: Icons.brush,
    create: () => SmoothLine(),
  ),
  BrushPreset(
    id: 'highlighter',
    name: 'Highlighter',
    description: 'Translucent fluorescent marker',
    icon: Icons.highlight,
    create: () => HighlighterLine(),
  ),
  BrushPreset(
    id: 'airbrush',
    name: 'Soft Airbrush',
    description: 'Diffuse aerosol spray fade',
    icon: Icons.blur_circular,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.1, hardness: 0.6),
  ),
  BrushPreset(
    id: 'airbrushDark',
    name: 'Dense Airbrush',
    description: 'Deep saturated aerosol coat',
    icon: Icons.blur_circular,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.05, hardness: 0.8),
  ),
  BrushPreset(
    id: 'spray',
    name: 'Spray Paint Can',
    description: 'Grungy graffiti spatter spray',
    icon: Icons.air,
    create: () => ImageTipBrush(stampKey: 'spray', spacing: 0.28),
  ),
  BrushPreset(
    id: 'stipple',
    name: 'Stipple Texture',
    description: 'Clustered micro-dots shading',
    icon: Icons.more_horiz,
    create: () => TipBrush(kind: BrushTipKind.stipple, spacing: 0.3),
  ),
  BrushPreset(
    id: 'smoke',
    name: 'Misty Smoke',
    description: 'Soft rolling atmospheric vapor',
    icon: Icons.cloud_queue,
    create: () => ImageTipBrush(stampKey: 'smoke', spacing: 0.22, hardness: 0.4),
  ),
  BrushPreset(
    id: 'bokeh',
    name: 'Bokeh Orbs',
    description: 'Photographic glowing light spheres',
    icon: Icons.lens_blur_rounded,
    create: () => ImageTipBrush(stampKey: 'bokeh', spacing: 0.35),
  ),

  // =========================================================================
  // 4. 魔法与辉光 / Magic & Glow
  // =========================================================================
  BrushPreset(
    id: 'neonGlow',
    name: 'Neon Glow',
    description: 'Radiant vibrant neon lighting with white core',
    icon: Icons.light_mode_rounded,
    create: () => NeonGlowLine(),
  ),
  BrushPreset(
    id: 'rainbow',
    name: 'Rainbow Flow',
    description: 'Smooth multi-color spectrum gradient',
    icon: Icons.looks_rounded,
    create: () => RainbowLine(),
  ),
  BrushPreset(
    id: 'ribbon',
    name: 'Silk Ribbon',
    description: 'Twisting dual-edge flowing ribbon',
    icon: Icons.gesture,
    create: () => RibbonLine(),
  ),
  BrushPreset(
    id: 'constellation',
    name: 'Constellations',
    description: 'Connected star cluster nodes',
    icon: Icons.scatter_plot_rounded,
    create: () => ConstellationLine(),
  ),
  BrushPreset(
    id: 'electricArc',
    name: 'Plasma Arc',
    description: 'High-voltage branching electric arcs',
    icon: Icons.flash_auto_rounded,
    create: () => ElectricArcLine(),
  ),
  BrushPreset(
    id: 'bubbleTrail',
    name: 'Bubble Trail',
    description: 'Shaded 3D transparent floating bubbles',
    icon: Icons.bubble_chart_rounded,
    create: () => BubbleTrailLine(),
  ),
  BrushPreset(
    id: 'chain',
    name: 'Iron Chain',
    description: 'Interlocking metal chain links',
    icon: Icons.link_rounded,
    create: () => ChainLine(),
  ),
  BrushPreset(
    id: 'audioSpectrum',
    name: 'Audio Soundwave',
    description: 'Equalizer rhythm frequency bars',
    icon: Icons.graphic_eq_rounded,
    create: () => AudioSpectrumLine(),
  ),
  BrushPreset(
    id: 'stitch',
    name: 'Cross Stitch',
    description: 'Hand-sewn textile embroidery X-stitch',
    icon: Icons.close_rounded,
    create: () => StitchLine(),
  ),
  BrushPreset(
    id: 'galaxy',
    name: 'Cosmic Galaxy',
    description: 'Deep celestial nebula stardust',
    icon: Icons.auto_awesome,
    create: () => ImageTipBrush(stampKey: 'galaxy', spacing: 0.25),
  ),
  BrushPreset(
    id: 'embers',
    name: 'Fire Embers',
    description: 'Glowing warm cinder particles',
    icon: Icons.local_fire_department,
    create: () => ImageTipBrush(stampKey: 'embers', spacing: 0.22),
  ),
  BrushPreset(
    id: 'glitter',
    name: 'Glitter Dust',
    description: 'Shimmering metallic specks',
    icon: Icons.stars_rounded,
    create: () => ImageTipBrush(stampKey: 'glitter', spacing: 0.24),
  ),
  BrushPreset(
    id: 'starGlow',
    name: 'Star Glow',
    description: 'Radiant shining star core',
    icon: Icons.wb_sunny_outlined,
    create: () => ImageTipBrush(stampKey: 'starGlow', spacing: 0.3),
  ),
  BrushPreset(
    id: 'bubbles',
    name: 'Soap Bubbles',
    description: 'Floating luminous iridescent spheres',
    icon: Icons.circle_outlined,
    create: () => ImageTipBrush(stampKey: 'bubbles', spacing: 0.32),
  ),
  BrushPreset(
    id: 'crackle',
    name: 'Lightning Crackle',
    description: 'Electric plasma fissure branches',
    icon: Icons.flash_on,
    create: () => ImageTipBrush(stampKey: 'crackle', spacing: 0.2),
  ),
  BrushPreset(
    id: 'sparkles',
    name: 'Sparkle Glints',
    description: 'Scattered 4-point twinkle bursts',
    icon: Icons.auto_awesome_outlined,
    create: () => SparklesLine(),
  ),
  BrushPreset(
    id: 'circuit',
    name: 'Cyber Circuit',
    description: 'High-tech printed circuit traces',
    icon: Icons.memory,
    create: () => ImageTipBrush(stampKey: 'circuit', spacing: 0.25),
  ),

  // =========================================================================
  // 5. 自然与元素 / Nature & Elements
  // =========================================================================
  BrushPreset(
    id: 'leaves',
    name: 'Autumn Leaves',
    description: 'Drifting autumn foliage leaves',
    icon: Icons.eco,
    create: () => TipBrush(kind: BrushTipKind.leafScatter, spacing: 0.75),
  ),
  BrushPreset(
    id: 'petals',
    name: 'Floating Petals',
    description: 'Gentle windblown flower petals',
    icon: Icons.filter_vintage,
    create: () => ImageTipBrush(stampKey: 'petals', spacing: 0.3),
  ),
  BrushPreset(
    id: 'blossom',
    name: 'Cherry Blossoms',
    description: '5-petal sakura flower stamps',
    icon: Icons.local_florist_rounded,
    create: () => TipBrush(kind: BrushTipKind.fivePetal, spacing: 0.65),
  ),
  BrushPreset(
    id: 'flowerEight',
    name: 'Daisy Flowers',
    description: '8-petal blooming daisy flowers',
    icon: Icons.yard_rounded,
    create: () => TipBrush(kind: BrushTipKind.flowerEight, spacing: 0.65),
  ),
  BrushPreset(
    id: 'mapleLeaf',
    name: 'Maple Leaf',
    description: 'Vibrant autumn maple foliage',
    icon: Icons.spa_rounded,
    create: () => TipBrush(kind: BrushTipKind.mapleLeaf, spacing: 0.7),
  ),
  BrushPreset(
    id: 'pineTree',
    name: 'Pine Trees',
    description: 'Evergreen alpine forest stamps',
    icon: Icons.park,
    create: () => TipBrush(kind: BrushTipKind.pineTree, spacing: 0.6),
  ),
  BrushPreset(
    id: 'grass',
    name: 'Garden Grass',
    description: 'Tufts of wild lawn grass',
    icon: Icons.grass_rounded,
    create: () => TipBrush(kind: BrushTipKind.grassClump, spacing: 0.45),
  ),
  BrushPreset(
    id: 'cloud',
    name: 'Puffy Clouds',
    description: 'Soft cumulus cloud puffs',
    icon: Icons.cloud_rounded,
    create: () => TipBrush(kind: BrushTipKind.cloud, spacing: 0.55),
  ),
  BrushPreset(
    id: 'snowflake',
    name: 'Ice Crystals',
    description: 'Detailed winter snowflakes',
    icon: Icons.ac_unit_rounded,
    create: () => TipBrush(kind: BrushTipKind.snowflake, spacing: 0.7),
  ),
  BrushPreset(
    id: 'snowDots',
    name: 'Blizzard Snowfall',
    description: 'Dense swirling winter snow dots',
    icon: Icons.grain,
    create: () => ImageTipBrush(stampKey: 'snowDots', spacing: 0.22),
  ),
  BrushPreset(
    id: 'rainStreaks',
    name: 'Rain Shower',
    description: 'Downward falling rain streaks',
    icon: Icons.water,
    create: () => ImageTipBrush(stampKey: 'rainStreaks', spacing: 0.2),
  ),
  BrushPreset(
    id: 'flame',
    name: 'Blazing Flame',
    description: 'Hot dynamic fire tongues',
    icon: Icons.whatshot,
    create: () => TipBrush(kind: BrushTipKind.flame, spacing: 0.5),
  ),
  BrushPreset(
    id: 'feather',
    name: 'Plumage Feathers',
    description: 'Soft drifting bird feathers',
    icon: Icons.air,
    create: () => TipBrush(kind: BrushTipKind.feather, spacing: 0.6),
  ),
  BrushPreset(
    id: 'ripples',
    name: 'Water Waves',
    description: 'Concentric water ripple waves',
    icon: Icons.waves,
    create: () => ImageTipBrush(stampKey: 'ripplesTex', spacing: 0.25),
  ),
  BrushPreset(
    id: 'sun',
    name: 'Radiant Sun',
    description: 'Bright solar starburst rays',
    icon: Icons.wb_sunny_rounded,
    create: () => TipBrush(kind: BrushTipKind.sun, spacing: 0.65),
  ),
  BrushPreset(
    id: 'crescent',
    name: 'Crescent Moons',
    description: 'Serene night sky crescents',
    icon: Icons.nightlight_round,
    create: () => TipBrush(kind: BrushTipKind.crescent, spacing: 0.6),
  ),
  BrushPreset(
    id: 'clover',
    name: 'Lucky Clovers',
    description: 'Four-leaf clover meadow',
    icon: Icons.eco_outlined,
    create: () => TipBrush(kind: BrushTipKind.clover, spacing: 0.65),
  ),
  BrushPreset(
    id: 'mushroom',
    name: 'Wild Mushrooms',
    description: 'Forest mushroom cap stamps',
    icon: Icons.nature_rounded,
    create: () => TipBrush(kind: BrushTipKind.mushroom, spacing: 0.65),
  ),
  BrushPreset(
    id: 'shell',
    name: 'Ocean Shells',
    description: 'Nautical sea clam shells',
    icon: Icons.water_drop,
    create: () => TipBrush(kind: BrushTipKind.shell, spacing: 0.65),
  ),

  // =========================================================================
  // 6. 印章与符号 / Stamps & Symbols
  // =========================================================================
  BrushPreset(
    id: 'butterfly',
    name: 'Butterflies',
    description: 'Fluttering winged butterfly trail',
    icon: Icons.cruelty_free,
    create: () => TipBrush(kind: BrushTipKind.butterfly, spacing: 0.65),
  ),
  BrushPreset(
    id: 'paw',
    name: 'Paw Tracks',
    description: 'Cute puppy and kitten paw prints',
    icon: Icons.pets_rounded,
    create: () => TipBrush(kind: BrushTipKind.paw, spacing: 0.6),
  ),
  BrushPreset(
    id: 'fish',
    name: 'Ocean Fish',
    description: 'School of swimming fish',
    icon: Icons.set_meal,
    create: () => TipBrush(kind: BrushTipKind.fish, spacing: 0.6),
  ),
  BrushPreset(
    id: 'hearts',
    name: 'Sweet Hearts',
    description: 'Romantic floating heart ribbon',
    icon: Icons.favorite_rounded,
    create: () => TipBrush(kind: BrushTipKind.heart, spacing: 0.65),
  ),
  BrushPreset(
    id: 'heartsTex',
    name: 'Textured Hearts',
    description: 'Soft textured heart stamps',
    icon: Icons.favorite_border,
    create: () => ImageTipBrush(stampKey: 'hearts', spacing: 0.3),
  ),
  BrushPreset(
    id: 'stars',
    name: 'Golden Stars',
    description: 'Gleaming 5-point star trail',
    icon: Icons.star_rate_rounded,
    create: () => TipBrush(kind: BrushTipKind.star, spacing: 0.6),
  ),
  BrushPreset(
    id: 'fourStar',
    name: 'Diamond 4-Stars',
    description: 'Sharp 4-point sparkle stars',
    icon: Icons.star_rounded,
    create: () => TipBrush(kind: BrushTipKind.fourStar, spacing: 0.6),
  ),
  BrushPreset(
    id: 'eightStar',
    name: 'Radiant 8-Stars',
    description: 'Eight-pointed compass starbursts',
    icon: Icons.flare_rounded,
    create: () => TipBrush(kind: BrushTipKind.eightStar, spacing: 0.65),
  ),
  BrushPreset(
    id: 'crown',
    name: 'Royal Crowns',
    description: 'Majestic king and queen crowns',
    icon: Icons.workspace_premium,
    create: () => TipBrush(kind: BrushTipKind.crown, spacing: 0.65),
  ),
  BrushPreset(
    id: 'gem',
    name: 'Cut Gems',
    description: 'Sparkling brilliant cut diamonds',
    icon: Icons.diamond_rounded,
    create: () => TipBrush(kind: BrushTipKind.gem, spacing: 0.6),
  ),
  BrushPreset(
    id: 'lightning',
    name: 'Lightning Bolts',
    description: 'Electric high-voltage storm zaps',
    icon: Icons.bolt_rounded,
    create: () => TipBrush(kind: BrushTipKind.lightning, spacing: 0.6),
  ),
  BrushPreset(
    id: 'musicNotes',
    name: 'Music Melody',
    description: 'Melodic musical note trail',
    icon: Icons.music_note_rounded,
    create: () => TipBrush(kind: BrushTipKind.musicNote, spacing: 0.65),
  ),
  BrushPreset(
    id: 'confetti',
    name: 'Party Confetti',
    description: 'Celebratory festival burst',
    icon: Icons.celebration_rounded,
    create: () => TipBrush(kind: BrushTipKind.confetti, spacing: 0.7),
  ),
  BrushPreset(
    id: 'confettiTex',
    name: 'Festive Streamers',
    description: 'Multi-shape textured confetti',
    icon: Icons.party_mode_rounded,
    create: () => ImageTipBrush(stampKey: 'confettiTex', spacing: 0.3),
  ),
  BrushPreset(
    id: 'ghost',
    name: 'Spooky Ghosts',
    description: 'Playful floating spirit shapes',
    icon: Icons.mood,
    create: () => TipBrush(kind: BrushTipKind.ghost, spacing: 0.65),
  ),
  BrushPreset(
    id: 'rocket',
    name: 'Space Rockets',
    description: 'Retro spacecraft rocket trail',
    icon: Icons.rocket_launch_rounded,
    create: () => TipBrush(kind: BrushTipKind.rocket, spacing: 0.65),
  ),
  BrushPreset(
    id: 'atom',
    name: 'Atomic Orbit',
    description: 'Quantum electron orbital rings',
    icon: Icons.blur_circular,
    create: () => TipBrush(kind: BrushTipKind.atom, spacing: 0.65),
  ),
  BrushPreset(
    id: 'puzzle',
    name: 'Jigsaw Puzzle',
    description: 'Interlocking puzzle pieces',
    icon: Icons.extension,
    create: () => TipBrush(kind: BrushTipKind.puzzle, spacing: 0.6),
  ),
  BrushPreset(
    id: 'anchor',
    name: 'Nautical Anchors',
    description: 'Maritime iron anchor stamps',
    icon: Icons.anchor,
    create: () => TipBrush(kind: BrushTipKind.anchor, spacing: 0.6),
  ),
  BrushPreset(
    id: 'hourglass',
    name: 'Vintage Hourglass',
    description: 'Antique sand timer instruments',
    icon: Icons.hourglass_full,
    create: () => TipBrush(kind: BrushTipKind.hourglass, spacing: 0.6),
  ),
  BrushPreset(
    id: 'lightbulb',
    name: 'Idea Lightbulbs',
    description: 'Bright glowing idea bulbs',
    icon: Icons.lightbulb_outline_rounded,
    create: () => TipBrush(kind: BrushTipKind.lightbulb, spacing: 0.65),
  ),
  BrushPreset(
    id: 'bell',
    name: 'Golden Bells',
    description: 'Jingle bell holiday stamps',
    icon: Icons.notifications_none_rounded,
    create: () => TipBrush(kind: BrushTipKind.bell, spacing: 0.65),
  ),
  BrushPreset(
    id: 'key',
    name: 'Antique Keys',
    description: 'Vintage skeleton key stamps',
    icon: Icons.key_rounded,
    create: () => TipBrush(kind: BrushTipKind.key, spacing: 0.65),
  ),
  BrushPreset(
    id: 'bowtie',
    name: 'Dapper Bowties',
    description: 'Formal gentleman bowtie stamps',
    icon: Icons.style,
    create: () => TipBrush(kind: BrushTipKind.bowtie, spacing: 0.65),
  ),
  BrushPreset(
    id: 'crosshair',
    name: 'Crosshairs',
    description: 'Precision target crosshairs',
    icon: Icons.filter_center_focus,
    create: () => TipBrush(kind: BrushTipKind.crosshair, spacing: 0.65),
  ),

  // =========================================================================
  // 7. 几何与轮廓 / Shapes & Outlines
  // =========================================================================
  BrushPreset(
    id: 'outlineStar',
    name: 'Outline Stars',
    description: 'Clean hollow star stamps',
    icon: Icons.star_border_rounded,
    create: () => TipBrush(kind: BrushTipKind.outlineStar, spacing: 0.65),
  ),
  BrushPreset(
    id: 'outlineHeart',
    name: 'Outline Hearts',
    description: 'Clean hollow heart stamps',
    icon: Icons.favorite_border_rounded,
    create: () => TipBrush(kind: BrushTipKind.outlineHeart, spacing: 0.65),
  ),
  BrushPreset(
    id: 'outlineCircle',
    name: 'Outline Circles',
    description: 'Hollow round ring stamps',
    icon: Icons.panorama_fish_eye_rounded,
    create: () => TipBrush(kind: BrushTipKind.outlineCircle, spacing: 0.55),
  ),
  BrushPreset(
    id: 'outlineSquare',
    name: 'Outline Squares',
    description: 'Hollow square frame stamps',
    icon: Icons.crop_square_rounded,
    create: () => TipBrush(kind: BrushTipKind.outlineSquare, spacing: 0.55),
  ),
  BrushPreset(
    id: 'outlineTriangle',
    name: 'Outline Triangles',
    description: 'Hollow triangle geometric frames',
    icon: Icons.change_history_rounded,
    create: () => TipBrush(kind: BrushTipKind.outlineTriangle, spacing: 0.6),
  ),
  BrushPreset(
    id: 'outlineHexagon',
    name: 'Outline Hexagons',
    description: 'Hollow 6-sided polygon frames',
    icon: Icons.hexagon_outlined,
    create: () => TipBrush(kind: BrushTipKind.outlineHexagon, spacing: 0.6),
  ),
  BrushPreset(
    id: 'ring',
    name: 'Halo Rings',
    description: 'Concentric circular rings',
    icon: Icons.radio_button_unchecked_rounded,
    create: () => TipBrush(kind: BrushTipKind.ring, spacing: 0.45),
  ),
  BrushPreset(
    id: 'squareRing',
    name: 'Square Rings',
    description: 'Concentric square frames',
    icon: Icons.crop_square,
    create: () => TipBrush(kind: BrushTipKind.squareRing, spacing: 0.48),
  ),
  BrushPreset(
    id: 'diamondRing',
    name: 'Diamond Rings',
    description: 'Jeweled diamond halo rings',
    icon: Icons.adjust,
    create: () => TipBrush(kind: BrushTipKind.diamondRing, spacing: 0.5),
  ),
  BrushPreset(
    id: 'diamond',
    name: 'Solid Diamonds',
    description: 'Rhombus geometric stamps',
    icon: Icons.square_foot,
    create: () => TipBrush(kind: BrushTipKind.diamond, spacing: 0.5),
  ),
  BrushPreset(
    id: 'triangle',
    name: 'Solid Triangles',
    description: 'Equilateral triangle stamps',
    icon: Icons.details,
    create: () => TipBrush(kind: BrushTipKind.triangle, spacing: 0.5),
  ),
  BrushPreset(
    id: 'hexagon',
    name: 'Solid Hexagons',
    description: 'Regular 6-sided polygon stamps',
    icon: Icons.hexagon,
    create: () => TipBrush(kind: BrushTipKind.hexagon, spacing: 0.52),
  ),
  BrushPreset(
    id: 'octagon',
    name: 'Solid Octagons',
    description: '8-sided polygon stamps',
    icon: Icons.stop_rounded,
    create: () => TipBrush(kind: BrushTipKind.octagon, spacing: 0.55),
  ),
  BrushPreset(
    id: 'shield',
    name: 'Knight Shields',
    description: 'Medieval heraldic shield crests',
    icon: Icons.shield_outlined,
    create: () => TipBrush(kind: BrushTipKind.shield, spacing: 0.6),
  ),
  BrushPreset(
    id: 'spiral',
    name: 'Spiral Coils',
    description: 'Hypnotic Archimedean spirals',
    icon: Icons.all_inclusive,
    create: () => TipBrush(kind: BrushTipKind.spiral, spacing: 0.6),
  ),
  BrushPreset(
    id: 'teardrop',
    name: 'Teardrop Beads',
    description: 'Fluid droplet bead stamps',
    icon: Icons.water_drop,
    create: () => TipBrush(kind: BrushTipKind.teardrop, spacing: 0.5),
  ),

  // =========================================================================
  // 8. 材质与纹理 / Textures & FX
  // =========================================================================
  BrushPreset(
    id: 'marble',
    name: 'Marble Veins',
    description: 'Polished natural stone veins',
    icon: Icons.layers,
    create: () => ImageTipBrush(stampKey: 'marble', spacing: 0.2),
  ),
  BrushPreset(
    id: 'honeycomb',
    name: 'Honeycomb Grid',
    description: 'Hexagonal honeycomb cell pattern',
    icon: Icons.grid_view_rounded,
    create: () => ImageTipBrush(stampKey: 'honeycomb', spacing: 0.25),
  ),
  BrushPreset(
    id: 'lace',
    name: 'Embroidered Lace',
    description: 'Intricate ornate lace border',
    icon: Icons.all_inclusive,
    create: () => ImageTipBrush(stampKey: 'lace', spacing: 0.2),
  ),
  BrushPreset(
    id: 'weave',
    name: 'Woven Fabric',
    description: 'Textile linen weave threads',
    icon: Icons.grid_goldenratio,
    create: () => ImageTipBrush(stampKey: 'weave', spacing: 0.18),
  ),
  BrushPreset(
    id: 'mesh',
    name: 'Wire Mesh',
    description: 'Diagonal metallic wire screen',
    icon: Icons.grid_4x4,
    create: () => ImageTipBrush(stampKey: 'mesh', spacing: 0.2),
  ),
  BrushPreset(
    id: 'cobweb',
    name: 'Spider Web',
    description: 'Fine spun silk cobwebs',
    icon: Icons.grain,
    create: () => ImageTipBrush(stampKey: 'cobweb', spacing: 0.22),
  ),
  BrushPreset(
    id: 'cells',
    name: 'Bio Cells',
    description: 'Organic microscopic cell clusters',
    icon: Icons.bubble_chart_outlined,
    create: () => ImageTipBrush(stampKey: 'cells', spacing: 0.22),
  ),
  BrushPreset(
    id: 'fur',
    name: 'Animal Fur',
    description: 'Dense soft radiating hair pelt',
    icon: Icons.pets,
    create: () => ImageTipBrush(stampKey: 'fur', spacing: 0.15),
  ),
  BrushPreset(
    id: 'hair',
    name: 'Hair Strands',
    description: 'Flowing parallel hair strands',
    icon: Icons.waves,
    create: () => HairLine(),
  ),
  BrushPreset(
    id: 'grunge',
    name: 'Grungy Distress',
    description: 'Distressed vintage wall patina',
    icon: Icons.texture,
    create: () => ImageTipBrush(stampKey: 'grunge', spacing: 0.2),
  ),
  BrushPreset(
    id: 'orange',
    name: 'Orange Peel',
    description: 'Fine dimpled pore texture',
    icon: Icons.circle_outlined,
    create: () => ImageTipBrush(stampKey: 'orangePeel', spacing: 0.2),
  ),
  BrushPreset(
    id: 'staticNoise',
    name: 'TV Static',
    description: 'Random analog noise grain',
    icon: Icons.blur_off,
    create: () => ImageTipBrush(stampKey: 'staticNoise', spacing: 0.15),
  ),
  BrushPreset(
    id: 'sprinkles',
    name: 'Color Sprinkles',
    description: 'Joyful multicolored sugar dashes',
    icon: Icons.celebration,
    create: () => SprinklesLine(),
  ),
  BrushPreset(
    id: 'static',
    name: 'Color Mosaic Blocks',
    description: 'Random colored pixel tiles',
    icon: Icons.blur_linear,
    create: () => StaticLine(),
  ),

  // =========================================================================
  // 9. 图案、网点与 3D / Patterns, Halftone & 3D
  // =========================================================================
  BrushPreset(
    id: 'dots',
    name: 'Round Polka Dots',
    description: 'Clean evenly spaced round dots',
    icon: Icons.circle,
    create: () => DottedLine(spacingRatio: 1.2),
  ),
  BrushPreset(
    id: 'squares',
    name: 'Square Blocks',
    description: 'Evenly spaced square marks',
    icon: Icons.crop_square,
    create: () => SquareBrush(spacingRatio: 1.2),
  ),
  BrushPreset(
    id: 'dash',
    name: 'Dashed Stroke',
    description: 'Rhythmic uniform dashes',
    icon: Icons.more_horiz,
    create: () => DashedLine(),
  ),
  BrushPreset(
    id: 'pixel',
    name: 'Pixel Art',
    description: 'Grid-snapped retro 8-bit blocks',
    icon: Icons.grid_on,
    create: () => PixelLine(),
  ),
  BrushPreset(
    id: 'mosaic',
    name: 'Mosaic Glass',
    description: 'Shaded tessellated mosaic tiles',
    icon: Icons.dashboard,
    create: () => MosaicLine(),
  ),
  BrushPreset(
    id: 'halftone',
    name: 'Halftone Screen',
    description: 'Comic printing dot screen',
    icon: Icons.blur_linear,
    create: () => HalftoneLine(),
  ),
  BrushPreset(
    id: 'halftoneTex',
    name: 'Halftone Stamp',
    description: 'Textured newsprint halftone',
    icon: Icons.grain,
    create: () => ImageTipBrush(stampKey: 'halftone', spacing: 0.2),
  ),
  BrushPreset(
    id: 'hatch',
    name: 'Cross Hatching',
    description: 'Intricate cross-hatched engraving lines',
    icon: Icons.texture,
    create: () => ImageTipBrush(stampKey: 'hatch', spacing: 0.18),
  ),
  BrushPreset(
    id: 'halftoneRight',
    name: 'Right Diagonal Hatch',
    description: 'Clean "/" forward slant hatching',
    icon: Icons.text_rotation_angleup,
    create: () => HatchLine(),
  ),
  BrushPreset(
    id: 'halftoneLeft',
    name: 'Left Diagonal Hatch',
    description: 'Clean "\\" backward slant hatching',
    icon: Icons.text_rotation_angledown,
    create: () => HatchLine(rightward: false),
  ),
  BrushPreset(
    id: 'gradient',
    name: 'Color Gradient',
    description: 'Smooth rainbow color shift along path',
    icon: Icons.gradient,
    create: () => GradientLine(),
  ),
  BrushPreset(
    id: 'brush3d',
    name: '3D Glossy Tube',
    description: 'Shaded volumetric cylindrical tube',
    icon: Icons.view_in_ar,
    create: () => TubeLine(),
  ),
  BrushPreset(
    id: 'candyCane',
    name: '3D Candy Cane',
    description: 'Spiral striped festive 3D cylinder',
    icon: Icons.view_in_ar_outlined,
    create: () => CandyCaneLine(),
  ),
  BrushPreset(
    id: 'saw',
    name: 'Sawtooth Wave',
    description: 'Sharp zigzag oscillating waveform',
    icon: Icons.show_chart,
    create: () => SawLine(),
  ),
  BrushPreset(
    id: 'gear',
    name: 'Square Pulse Wave',
    description: 'Rectangular digital pulse wave',
    icon: Icons.settings_ethernet,
    create: () => GearLine(),
  ),
  BrushPreset(
    id: 'heartbeat',
    name: 'Heartbeat ECG',
    description: 'Medical cardiac monitor rhythm pulse',
    icon: Icons.monitor_heart_outlined,
    create: () => HeartbeatLine(),
  ),
];
