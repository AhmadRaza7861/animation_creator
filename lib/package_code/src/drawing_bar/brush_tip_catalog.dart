import '../paint_contents/tip_brush.dart';

/// Which tab a tip appears under in the tip pickers.
enum BrushTipGroup { shapes, stars, symbols, nature, textures }

/// One entry in a tip picker grid.
class BrushTipDef {
  const BrushTipDef(this.kind, this.label, this.size, this.group, this.labelKey);

  final BrushTipKind kind;

  /// English label (also the fallback if a translation is missing).
  final String label;

  /// Default preview size shown on the thumbnail.
  final int size;

  final BrushTipGroup group;

  /// Translation key for [label].
  final String labelKey;
}

/// Tips added after the original set. Shared by Brush Tip Studio and the
/// Brush Tip Shape panel so both pickers always list the same tips.
const List<BrushTipDef> kExtraBrushTips = <BrushTipDef>[
  // Shapes
  BrushTipDef(BrushTipKind.roundedSquare, 'Rounded Square', 30, BrushTipGroup.shapes, 'tip_rounded_square_label'),
  BrushTipDef(BrushTipKind.semicircle, 'Semicircle', 32, BrushTipGroup.shapes, 'tip_semicircle_label'),
  BrushTipDef(BrushTipKind.capsule, 'Capsule', 32, BrushTipGroup.shapes, 'tip_capsule_label'),
  BrushTipDef(BrushTipKind.parallelogram, 'Parallelogram', 32, BrushTipGroup.shapes, 'tip_parallelogram_label'),
  BrushTipDef(BrushTipKind.trapezoid, 'Trapezoid', 32, BrushTipGroup.shapes, 'tip_trapezoid_label'),
  // Stars
  BrushTipDef(BrushTipKind.sparkle, 'Sparkle', 38, BrushTipGroup.stars, 'tip_sparkle_label'),
  BrushTipDef(BrushTipKind.compassStar, 'Compass Star', 40, BrushTipGroup.stars, 'tip_compass_star_label'),
  // Symbols
  BrushTipDef(BrushTipKind.smiley, 'Smiley', 38, BrushTipGroup.symbols, 'tip_smiley_label'),
  BrushTipDef(BrushTipKind.speechBubble, 'Speech Bubble', 40, BrushTipGroup.symbols, 'tip_speech_bubble_label'),
  BrushTipDef(BrushTipKind.eye, 'Eye', 38, BrushTipGroup.symbols, 'tip_eye_label'),
  BrushTipDef(BrushTipKind.house, 'House', 38, BrushTipGroup.symbols, 'tip_house_label'),
  BrushTipDef(BrushTipKind.mapPin, 'Map Pin', 38, BrushTipGroup.symbols, 'tip_map_pin_label'),
  BrushTipDef(BrushTipKind.chevron, 'Chevron', 34, BrushTipGroup.symbols, 'tip_chevron_label'),
  // Nature
  BrushTipDef(BrushTipKind.bird, 'Bird', 40, BrushTipGroup.nature, 'tip_bird_label'),
  BrushTipDef(BrushTipKind.mountain, 'Mountain', 42, BrushTipGroup.nature, 'tip_mountain_label'),
  BrushTipDef(BrushTipKind.roundTree, 'Round Tree', 40, BrushTipGroup.nature, 'tip_round_tree_label'),
  BrushTipDef(BrushTipKind.tulip, 'Tulip', 40, BrushTipGroup.nature, 'tip_tulip_label'),
  BrushTipDef(BrushTipKind.apple, 'Apple', 38, BrushTipGroup.nature, 'tip_apple_label'),
  BrushTipDef(BrushTipKind.bone, 'Bone', 38, BrushTipGroup.nature, 'tip_bone_label'),
  // Pattern textures
  BrushTipDef(BrushTipKind.hatch, 'Hatch', 40, BrushTipGroup.textures, 'tip_hatch_label'),
  BrushTipDef(BrushTipKind.crossHatch, 'Cross Hatch', 40, BrushTipGroup.textures, 'tip_cross_hatch_label'),
  BrushTipDef(BrushTipKind.halftone, 'Halftone', 42, BrushTipGroup.textures, 'tip_halftone_label'),
  BrushTipDef(BrushTipKind.scales, 'Scales', 42, BrushTipGroup.textures, 'tip_scales_label'),
  BrushTipDef(BrushTipKind.bricks, 'Bricks', 42, BrushTipGroup.textures, 'tip_bricks_label'),
  BrushTipDef(BrushTipKind.zigzag, 'Zigzag', 38, BrushTipGroup.textures, 'tip_zigzag_label'),
  BrushTipDef(BrushTipKind.stitch, 'Stitch', 30, BrushTipGroup.textures, 'tip_stitch_label'),
  // Scatter textures
  BrushTipDef(BrushTipKind.rain, 'Rain', 44, BrushTipGroup.textures, 'tip_rain_label'),
  BrushTipDef(BrushTipKind.bubbles, 'Bubbles', 46, BrushTipGroup.textures, 'tip_bubbles_label'),
  BrushTipDef(BrushTipKind.glitter, 'Glitter', 44, BrushTipGroup.textures, 'tip_glitter_label'),
  BrushTipDef(BrushTipKind.fur, 'Fur', 42, BrushTipGroup.textures, 'tip_fur_label'),
  BrushTipDef(BrushTipKind.starfield, 'Starfield', 46, BrushTipGroup.textures, 'tip_starfield_label'),
  BrushTipDef(BrushTipKind.snowfall, 'Snowfall', 46, BrushTipGroup.textures, 'tip_snowfall_label'),
  BrushTipDef(BrushTipKind.petals, 'Petals', 46, BrushTipGroup.textures, 'tip_petals_label'),
  BrushTipDef(BrushTipKind.heartScatter, 'Heart Scatter', 46, BrushTipGroup.textures, 'tip_heart_scatter_label'),
];

/// Group of an extra tip, or null for original tips.
BrushTipGroup? extraTipGroupOf(BrushTipKind kind) {
  for (final BrushTipDef d in kExtraBrushTips) {
    if (d.kind == kind) return d.group;
  }
  return null;
}
