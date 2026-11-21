import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../package_code/paint_contents.dart';
import '../../../package_code/src/draw_path/draw_path.dart';
import '../../../package_code/src/drawing_controller.dart';
import '../../../package_code/src/paint_contents/freehand_line.dart' as brush;
import '../../../package_code/src/paint_contents/layer_data.dart';
import '../../../package_code/src/paint_contents/paint_content_decoder.dart';
import '../../../package_code/src/paint_extension/ex_offset.dart';
import '../../../package_code/src/paint_extension/ex_paint.dart';
import '../../../package_code/src/ruler/mirror_content.dart';
import '../../../package_code/src/ruler/radial_content.dart';

/// Easing curves for Auto Between frame interpolation.
enum TweenEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounce;

  String get labelKey {
    switch (this) {
      case TweenEasing.linear:
        return 'easingLinear';
      case TweenEasing.easeIn:
        return 'easingEaseIn';
      case TweenEasing.easeOut:
        return 'easingEaseOut';
      case TweenEasing.easeInOut:
        return 'easingEaseInOut';
      case TweenEasing.bounce:
        return 'easingBounce';
    }
  }

  /// Evaluates the easing curve at normalized time [u] in [0, 1].
  double transform(double u) {
    final double x = u.clamp(0.0, 1.0);
    switch (this) {
      case TweenEasing.linear:
        return x;
      case TweenEasing.easeIn:
        return x * x * x;
      case TweenEasing.easeOut:
        final double inv = 1.0 - x;
        return 1.0 - inv * inv * inv;
      case TweenEasing.easeInOut:
        return x < 0.5
            ? 4.0 * x * x * x
            : 1.0 - math.pow(-2.0 * x + 2.0, 3) / 2.0;
      case TweenEasing.bounce:
        return Curves.bounceOut.transform(x);
    }
  }
}

/// Precomputed interpolation plan between two keyframes.
///
/// Resampling and pairing are computed once upfront so evaluating any number of
/// intermediate frames (and driving the live preview) takes microseconds with
/// minimal allocations and zero GPU texture duplication.
class AutoBetweenPlan {
  AutoBetweenPlan._(
    this._layerPlans, {
    required this.matchedPairCount,
    required this.totalTrackCount,
  });

  factory AutoBetweenPlan.fromCanvases(
    DrawingController startCanvas,
    DrawingController endCanvas, {
    bool fadeUnmatched = true,
  }) {
    return AutoBetweenPlan.fromLayers(
      startCanvas.layers,
      endCanvas.layers,
      fadeUnmatched: fadeUnmatched,
    );
  }

  factory AutoBetweenPlan.fromLayers(
    List<LayerData> startLayers,
    List<LayerData> endLayers, {
    bool fadeUnmatched = true,
  }) {
    final List<LayerData> aLayers = startLayers
        .where((l) => !l.isGuide && l.name != 'Stencil Guide')
        .toList();
    final List<LayerData> bLayers = endLayers
        .where((l) => !l.isGuide && l.name != 'Stencil Guide')
        .toList();

    final List<bool> bUsed = List<bool>.filled(bLayers.length, false);
    final List<_LayerTweenPlan> layerPlans = [];
    int matchedCount = 0;
    int totalCount = 0;

    // 1. Match layers from start -> end by name first, then by index
    final List<int?> aToB = List<int?>.filled(aLayers.length, null);
    for (int i = 0; i < aLayers.length; i++) {
      final String name = aLayers[i].name;
      for (int j = 0; j < bLayers.length; j++) {
        if (!bUsed[j] && bLayers[j].name == name) {
          aToB[i] = j;
          bUsed[j] = true;
          break;
        }
      }
    }
    for (int i = 0; i < aLayers.length; i++) {
      if (aToB[i] != null) continue;
      for (int j = 0; j < bLayers.length; j++) {
        if (!bUsed[j]) {
          aToB[i] = j;
          bUsed[j] = true;
          break;
        }
      }
    }

    for (int i = 0; i < aLayers.length; i++) {
      final LayerData layerA = aLayers[i];
      final int? bIdx = aToB[i];
      if (bIdx != null) {
        final LayerData layerB = bLayers[bIdx];
        final _LayerBuildResult built = _buildLayerInterpolators(
          layerA.getEffectiveHistory(),
          layerB.getEffectiveHistory(),
          fadeUnmatched: fadeUnmatched,
        );
        matchedCount += built.matchedCount;
        totalCount += built.interpolators.length;
        layerPlans.add(
          _LayerTweenPlan(
            name: layerA.name,
            isVisible: layerA.isVisible || layerB.isVisible,
            isLocked: layerA.isLocked && layerB.isLocked,
            opacityA: layerA.opacity,
            opacityB: layerB.opacity,
            blendMode: layerA.blendMode,
            interpolators: built.interpolators,
          ),
        );
      } else if (fadeUnmatched) {
        final List<PaintContent> aItems = layerA.getEffectiveHistory();
        if (aItems.isNotEmpty) {
          final List<_ItemInterpolator> interps = aItems
              .map((item) => _FadeOutInterpolator(item))
              .toList();
          totalCount += interps.length;
          layerPlans.add(
            _LayerTweenPlan(
              name: layerA.name,
              isVisible: layerA.isVisible,
              isLocked: layerA.isLocked,
              opacityA: layerA.opacity,
              opacityB: 0.0,
              blendMode: layerA.blendMode,
              interpolators: interps,
            ),
          );
        }
      }
    }

    // 2. Any leftover unmatched layers in B fade in
    if (fadeUnmatched) {
      for (int j = 0; j < bLayers.length; j++) {
        if (bUsed[j]) continue;
        final LayerData layerB = bLayers[j];
        final List<PaintContent> bItems = layerB.getEffectiveHistory();
        if (bItems.isEmpty) continue;
        final List<_ItemInterpolator> interps = bItems
            .map((item) => _FadeInInterpolator(item))
            .toList();
        totalCount += interps.length;
        layerPlans.add(
          _LayerTweenPlan(
            name: layerB.name,
            isVisible: layerB.isVisible,
            isLocked: layerB.isLocked,
            opacityA: 0.0,
            opacityB: layerB.opacity,
            blendMode: layerB.blendMode,
            interpolators: interps,
          ),
        );
      }
    }

    if (layerPlans.isEmpty) {
      layerPlans.add(
        _LayerTweenPlan(
          name: 'Layer 1',
          isVisible: true,
          isLocked: false,
          opacityA: 1.0,
          opacityB: 1.0,
          blendMode: BlendMode.srcOver,
          interpolators: const [],
        ),
      );
    }

    return AutoBetweenPlan._(
      layerPlans,
      matchedPairCount: matchedCount,
      totalTrackCount: totalCount,
    );
  }

  final List<_LayerTweenPlan> _layerPlans;
  final int matchedPairCount;
  final int totalTrackCount;

  /// Builds interpolated [LayerData] objects at normalized eased progress [t] in [0, 1].
  ///
  /// When [cloneRasterImages] is false (used by live preview), existing `ui.Image`
  /// handles are referenced directly without incrementing GPU texture refcounts,
  /// since preview layers are transient and never passed to `dispose()`.
  List<LayerData> buildLayersAt(
    double t, {
    bool cloneRasterImages = true,
    int? frameSeed,
  }) {
    final double clampedT = t.clamp(0.0, 1.0);
    final int baseTs = DateTime.now().microsecondsSinceEpoch;
    final List<LayerData> result = [];

    for (int i = 0; i < _layerPlans.length; i++) {
      final _LayerTweenPlan lp = _layerPlans[i];
      final List<PaintContent> history = [];
      for (final _ItemInterpolator interp in lp.interpolators) {
        final PaintContent? content = interp.evaluate(
          clampedT,
          cloneRasterImages: cloneRasterImages,
        );
        if (content != null) {
          history.add(content);
        }
      }
      final double opacity =
          (ui.lerpDouble(lp.opacityA, lp.opacityB, clampedT) ?? 1.0).clamp(
            0.0,
            1.0,
          );
      result.add(
        LayerData(
          id: 'tween_${frameSeed ?? baseTs}_$i',
          name: lp.name,
          isVisible: lp.isVisible,
          isLocked: lp.isLocked,
          opacity: opacity,
          blendMode: lp.blendMode,
          history: history,
          currentIndex: history.length,
          sessionStartIndex: history.length,
        ),
      );
    }

    return result;
  }

  /// Paints the interpolated frame directly onto [canvas] for zero-allocation live previews.
  void paintPreview(Canvas canvas, Size canvasSize, double t) {
    final double clampedT = t.clamp(0.0, 1.0);
    for (int i = _layerPlans.length - 1; i >= 0; i--) {
      final _LayerTweenPlan lp = _layerPlans[i];
      if (!lp.isVisible) continue;
      final double opacity =
          (ui.lerpDouble(lp.opacityA, lp.opacityB, clampedT) ?? 1.0).clamp(
            0.0,
            1.0,
          );
      if (opacity <= 0.002) continue;

      final List<PaintContent> items = [];
      for (final _ItemInterpolator interp in lp.interpolators) {
        final PaintContent? item = interp.evaluate(
          clampedT,
          cloneRasterImages: false,
        );
        if (item != null) items.add(item);
      }

      final LayerData tempLayer = LayerData(
        id: 'preview_$i',
        name: lp.name,
        isVisible: true,
        opacity: opacity,
        blendMode: lp.blendMode,
        history: items,
        currentIndex: items.length,
      );

      canvas.saveLayer(
        Offset.zero & canvasSize,
        Paint()
          ..blendMode = lp.blendMode
          ..color = Colors.white.withValues(alpha: opacity),
      );
      tempLayer.drawHistory(canvas, canvasSize, false);
      canvas.restore();
    }
  }
}

class _LayerTweenPlan {
  final String name;
  final bool isVisible;
  final bool isLocked;
  final double opacityA;
  final double opacityB;
  final BlendMode blendMode;
  final List<_ItemInterpolator> interpolators;

  const _LayerTweenPlan({
    required this.name,
    required this.isVisible,
    required this.isLocked,
    required this.opacityA,
    required this.opacityB,
    required this.blendMode,
    required this.interpolators,
  });
}

class _LayerBuildResult {
  final List<_ItemInterpolator> interpolators;
  final int matchedCount;

  const _LayerBuildResult(this.interpolators, this.matchedCount);
}

class _OrderedInterpolator {
  final double orderKey;
  final _ItemInterpolator interp;

  const _OrderedInterpolator(this.orderKey, this.interp);
}

bool _isNonVisualHistoryItem(PaintContent c) =>
    c is EmptyContent ||
    c is DeleteContent ||
    c is ShapeFillContent ||
    c is StrokeRecolorContent ||
    c is Eyedropper;

_LayerBuildResult _buildLayerInterpolators(
  List<PaintContent> rawA,
  List<PaintContent> rawB, {
  required bool fadeUnmatched,
}) {
  final List<PaintContent> aItems = rawA
      .where((c) => !_isNonVisualHistoryItem(c))
      .toList();
  final List<PaintContent> bItems = rawB
      .where((c) => !_isNonVisualHistoryItem(c))
      .toList();

  final List<bool> aUsed = List<bool>.filled(aItems.length, false);
  final List<bool> bUsed = List<bool>.filled(bItems.length, false);
  final List<_OrderedInterpolator> ordered = [];
  int matchedCount = 0;

  // Map effective IDs for Pass 1
  final Map<String, List<int>> bById = <String, List<int>>{};
  for (int j = 0; j < bItems.length; j++) {
    final String eid = _effectiveMatchId(bItems[j]);
    bById.putIfAbsent(eid, () => <int>[]).add(j);
  }

  // Pass 1: Match by ID (handles duplicated / Select-moved / Lasso-moved items)
  for (int i = 0; i < aItems.length; i++) {
    final String eid = _effectiveMatchId(aItems[i]);
    final List<int>? candidates = bById[eid];
    if (candidates != null) {
      for (final int j in candidates) {
        if (!bUsed[j]) {
          aUsed[i] = true;
          bUsed[j] = true;
          matchedCount++;
          ordered.add(
            _OrderedInterpolator(
              (i + j) * 0.5,
              _createPairInterpolator(aItems[i], bItems[j]),
            ),
          );
          break;
        }
      }
    }
  }

  // Precompute bounds & translation-invariant relative centroids for remaining items
  final List<Rect?> aBounds = List<Rect?>.filled(aItems.length, null);
  final List<Rect?> bBounds = List<Rect?>.filled(bItems.length, null);
  Rect boundsA(int i) => aBounds[i] ??= getShapeBounds(aItems[i]);
  Rect boundsB(int j) => bBounds[j] ??= getShapeBounds(bItems[j]);

  final List<int> remA = [
    for (int i = 0; i < aItems.length; i++)
      if (!aUsed[i] && !_isRasterOperation(aItems[i])) i,
  ];
  final List<int> remB = [
    for (int j = 0; j < bItems.length; j++)
      if (!bUsed[j] && !_isRasterOperation(bItems[j])) j,
  ];

  Offset meanA = Offset.zero;
  if (remA.isNotEmpty) {
    for (final i in remA) {
      meanA += boundsA(i).center;
    }
    meanA /= remA.length.toDouble();
  }

  Offset meanB = Offset.zero;
  if (remB.isNotEmpty) {
    for (final j in remB) {
      meanB += boundsB(j).center;
    }
    meanB /= remB.length.toDouble();
  }

  double pairCost(int i, int j) {
    final Rect ra = boundsA(i);
    final Rect rb = boundsB(j);
    final Offset relA = ra.center - meanA;
    final Offset relB = rb.center - meanB;
    final double posDist = (relA - relB).distanceSquared;
    final double dw = ra.width - rb.width;
    final double dh = ra.height - rb.height;
    return posDist + 0.35 * (dw * dw + dh * dh);
  }

  // Pass 2: Same semantic type using optimal translation-invariant assignment
  final List<int> pass2A = remA.where((i) => !aUsed[i]).toList();
  final List<int> pass2B = remB.where((j) => !bUsed[j]).toList();
  matchedCount += _matchIndicesOptimalOrGreedy(
    pass2A,
    pass2B,
    canMatch: (i, j) => _areSameSemanticType(aItems[i], bItems[j]),
    costFn: pairCost,
    onMatched: (i, j) {
      aUsed[i] = true;
      bUsed[j] = true;
      ordered.add(
        _OrderedInterpolator(
          (i + j) * 0.5,
          _createPairInterpolator(aItems[i], bItems[j]),
        ),
      );
    },
  );

  // Pass 3: Cross-type compatible morphing (stroke <-> stroke, closed shape <-> closed shape)
  final List<int> pass3A = remA
      .where((i) => !aUsed[i] && (_isStrokeLike(aItems[i]) || _isClosedShapeLike(aItems[i])))
      .toList();
  final List<int> pass3B = remB
      .where((j) => !bUsed[j] && (_isStrokeLike(bItems[j]) || _isClosedShapeLike(bItems[j])))
      .toList();
  matchedCount += _matchIndicesOptimalOrGreedy(
    pass3A,
    pass3B,
    canMatch: (i, j) =>
        (_isStrokeLike(aItems[i]) && _isStrokeLike(bItems[j])) ||
        (_isClosedShapeLike(aItems[i]) && _isClosedShapeLike(bItems[j])),
    costFn: pairCost,
    onMatched: (i, j) {
      aUsed[i] = true;
      bUsed[j] = true;
      ordered.add(
        _OrderedInterpolator(
          (i + j) * 0.5,
          _createPairInterpolator(aItems[i], bItems[j]),
        ),
      );
    },
  );

  // Pass 4: Leftover unmatched items fade out / fade in
  if (fadeUnmatched) {
    for (int i = 0; i < aItems.length; i++) {
      if (!aUsed[i]) {
        ordered.add(_OrderedInterpolator(i.toDouble(), _FadeOutInterpolator(aItems[i])));
      }
    }
    for (int j = 0; j < bItems.length; j++) {
      if (!bUsed[j]) {
        ordered.add(_OrderedInterpolator(j.toDouble(), _FadeInInterpolator(bItems[j])));
      }
    }
  }

  ordered.sort((a, b) => a.orderKey.compareTo(b.orderKey));
  return _LayerBuildResult(
    ordered.map((e) => e.interp).toList(),
    matchedCount,
  );
}

int _matchIndicesOptimalOrGreedy(
  List<int> listA,
  List<int> listB, {
  required bool Function(int i, int j) canMatch,
  required double Function(int i, int j) costFn,
  required void Function(int i, int j) onMatched,
}) {
  if (listA.isEmpty || listB.isEmpty) return 0;

  // For large counts (> 80), pair sequentially by type in O(n) to avoid lag
  if (listA.length > 80 || listB.length > 80) {
    final Set<int> usedB = <int>{};
    int count = 0;
    for (final int i in listA) {
      for (final int j in listB) {
        if (!usedB.contains(j) && canMatch(i, j)) {
          usedB.add(j);
          onMatched(i, j);
          count++;
          break;
        }
      }
    }
    return count;
  }

  // Optimal Hungarian bipartite assignment for small-to-medium frame stroke counts
  if (listA.length <= 40 && listB.length <= 40) {
    final int n = listA.length;
    final int m = listB.length;
    final int dim = math.max(n, m);
    const double forbidden = 1e14;
    final List<List<double>> cost = List.generate(
      dim,
      (_) => List<double>.filled(dim, forbidden * 0.5),
    );

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < m; c++) {
        if (canMatch(listA[r], listB[c])) {
          cost[r][c] = costFn(listA[r], listB[c]);
        } else {
          cost[r][c] = forbidden;
        }
      }
    }

    final List<double> u = List<double>.filled(dim + 1, 0.0);
    final List<double> v = List<double>.filled(dim + 1, 0.0);
    final List<int> p = List<int>.filled(dim + 1, 0);
    final List<int> way = List<int>.filled(dim + 1, 0);

    for (int r = 1; r <= dim; r++) {
      p[0] = r;
      int j0 = 0;
      final List<double> minv = List<double>.filled(dim + 1, double.infinity);
      final List<bool> used = List<bool>.filled(dim + 1, false);
      do {
        used[j0] = true;
        final int i0 = p[j0];
        double delta = double.infinity;
        int j1 = 0;
        for (int c = 1; c <= dim; c++) {
          if (!used[c]) {
            final double cur = cost[i0 - 1][c - 1] - u[i0] - v[c];
            if (cur < minv[c]) {
              minv[c] = cur;
              way[c] = j0;
            }
            if (minv[c] < delta) {
              delta = minv[c];
              j1 = c;
            }
          }
        }
        for (int c = 0; c <= dim; c++) {
          if (used[c]) {
            u[p[c]] += delta;
            v[c] -= delta;
          } else {
            minv[c] -= delta;
          }
        }
        j0 = j1;
      } while (p[j0] != 0);

      do {
        final int j1 = way[j0];
        p[j0] = p[j1];
        j0 = j1;
      } while (j0 != 0);
    }

    final List<int> rowToCol = List<int>.filled(dim, -1);
    for (int c = 1; c <= dim; c++) {
      if (p[c] > 0) {
        rowToCol[p[c] - 1] = c - 1;
      }
    }

    int matched = 0;
    for (int r = 0; r < n; r++) {
      final int c = rowToCol[r];
      if (c >= 0 && c < m && canMatch(listA[r], listB[c])) {
        onMatched(listA[r], listB[c]);
        matched++;
      }
    }
    return matched;
  }

  // Greedy translation-invariant matching for 41..80 items
  final Set<int> usedB = <int>{};
  int count = 0;
  for (final int i in listA) {
    int bestJ = -1;
    double bestCost = double.infinity;
    for (final int j in listB) {
      if (usedB.contains(j) || !canMatch(i, j)) continue;
      final double c = costFn(i, j);
      if (c < bestCost) {
        bestCost = c;
        bestJ = j;
      }
    }
    if (bestJ >= 0) {
      usedB.add(bestJ);
      onMatched(i, bestJ);
      count++;
    }
  }
  return count;
}

String _effectiveMatchId(PaintContent content) {
  if (content is ShapeStickerContent) {
    final PaintContent inner = content.child;
    if (inner is OffsetContent) {
      return inner.child.id;
    }
    return inner.id;
  }
  return content.id;
}

bool _isRasterOperation(PaintContent c) =>
    c is FillContent || c is SmudgeContent || c is BlurContent;

bool _areSameSemanticType(PaintContent a, PaintContent b) {
  if (a.contentType == b.contentType) {
    if (a is ShapeStickerContent && b is ShapeStickerContent) {
      return _unwrapOffset(a.child).contentType ==
          _unwrapOffset(b.child).contentType;
    }
    return true;
  }
  // Allow matching raw PaintContent with a Select-lifted ShapeStickerContent wrapping it
  if (a is ShapeStickerContent && b is! ShapeStickerContent) {
    return _unwrapOffset(a.child).contentType == b.contentType;
  }
  if (b is ShapeStickerContent && a is! ShapeStickerContent) {
    return _unwrapOffset(b.child).contentType == a.contentType;
  }
  return false;
}

PaintContent _unwrapOffset(PaintContent c) =>
    c is OffsetContent ? c.child : c;

PaintContent _unwrapStickerAndOffset(PaintContent c) {
  PaintContent cur = c;
  while (cur is ShapeStickerContent || cur is OffsetContent) {
    if (cur is ShapeStickerContent) {
      cur = cur.child;
    } else if (cur is OffsetContent) {
      cur = cur.child;
    }
  }
  return cur;
}

bool _isStrokeLike(PaintContent c) {
  final PaintContent u = _unwrapStickerAndOffset(c);
  return u is FreehandLine ||
      u is SmoothLine ||
      u is SimpleLine ||
      u is StraightLine ||
      u is brush.FreehandLine;
}

bool _isClosedShapeLike(PaintContent c) {
  final PaintContent u = _unwrapStickerAndOffset(c);
  return u is Circle ||
      u is Rectangle ||
      u is Triangle ||
      u is Pentagon ||
      u is Heart ||
      u is CubeShape ||
      u is CylinderShape ||
      u is DragShape;
}

// ============================================================================
// Interpolator hierarchy
// ============================================================================

abstract class _ItemInterpolator {
  PaintContent? evaluate(double t, {required bool cloneRasterImages});
}

class _FadeOutInterpolator implements _ItemInterpolator {
  _FadeOutInterpolator(this.item);
  final PaintContent item;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final double alpha = (1.0 - t).clamp(0.0, 1.0);
    if (alpha <= 0.005) return null;
    return _cloneWithAlphaScale(
      item,
      alpha,
      cloneRasterImages: cloneRasterImages,
    );
  }
}

class _FadeInInterpolator implements _ItemInterpolator {
  _FadeInInterpolator(this.item);
  final PaintContent item;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final double alpha = t.clamp(0.0, 1.0);
    if (alpha <= 0.005) return null;
    return _cloneWithAlphaScale(
      item,
      alpha,
      cloneRasterImages: cloneRasterImages,
    );
  }
}

class _CrossFadeInterpolator implements _ItemInterpolator {
  _CrossFadeInterpolator(this.a, this.b);
  final PaintContent a;
  final PaintContent b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final double alphaA = (1.0 - t).clamp(0.0, 1.0);
    final double alphaB = t.clamp(0.0, 1.0);
    final List<PaintContent> children = [];
    if (alphaA > 0.005) {
      children.add(
        _cloneWithAlphaScale(a, alphaA, cloneRasterImages: cloneRasterImages),
      );
    }
    if (alphaB > 0.005) {
      children.add(
        _cloneWithAlphaScale(b, alphaB, cloneRasterImages: cloneRasterImages),
      );
    }
    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;
    return GroupContent(children: children);
  }
}

_ItemInterpolator _createPairInterpolator(PaintContent a, PaintContent b) {
  // 1. Handle ShapeStickerContent (including raw <-> ShapeStickerContent promotion)
  if (a is ShapeStickerContent || b is ShapeStickerContent) {
    final ShapeStickerContent stickerA = a is ShapeStickerContent
        ? a
        : _promoteToShapeSticker(a);
    final ShapeStickerContent stickerB = b is ShapeStickerContent
        ? b
        : _promoteToShapeSticker(b);
    return _ShapeStickerInterpolator(stickerA, stickerB);
  }

  // 2. TextContent
  if (a is TextContent && b is TextContent) {
    return _TextInterpolator(a, b);
  }

  // 3. ImageContent
  if (a is ImageContent && b is ImageContent) {
    return _ImageInterpolator(a, b);
  }

  // 4. Straight / Simple 2-point lines
  if (a is SimpleLine && b is SimpleLine) {
    return _SimpleLineInterpolator(a, b);
  }
  if (a is StraightLine && b is StraightLine) {
    return _StraightLineInterpolator(a, b);
  }

  // 5. Same-type geometric shapes
  if (a is Circle && b is Circle) {
    return _CircleInterpolator(a, b);
  }
  if (a is Rectangle && b is Rectangle) {
    return _TwoPointShapeInterpolator<Rectangle>(
      a: a,
      b: b,
      startA: a.startPoint ?? Offset.zero,
      endA: a.endPoint ?? Offset.zero,
      startB: b.startPoint ?? Offset.zero,
      endB: b.endPoint ?? Offset.zero,
      builder: (s, e, p, f, id) => Rectangle.data(
        startPoint: s,
        endPoint: e,
        paint: p,
        fillColor: f,
        id: id,
      ),
    );
  }
  if (a is Triangle && b is Triangle) {
    return _TriangleInterpolator(a, b);
  }
  if (a is Pentagon && b is Pentagon) {
    return _TwoPointShapeInterpolator<Pentagon>(
      a: a,
      b: b,
      startA: a.startPoint ?? Offset.zero,
      endA: a.endPoint ?? Offset.zero,
      startB: b.startPoint ?? Offset.zero,
      endB: b.endPoint ?? Offset.zero,
      builder: (s, e, p, f, id) => Pentagon.data(
        startPoint: s,
        endPoint: e,
        paint: p,
        fillColor: f,
        id: id,
      ),
    );
  }
  if (a is Heart && b is Heart) {
    return _TwoPointShapeInterpolator<Heart>(
      a: a,
      b: b,
      startA: a.startPoint ?? Offset.zero,
      endA: a.endPoint ?? Offset.zero,
      startB: b.startPoint ?? Offset.zero,
      endB: b.endPoint ?? Offset.zero,
      builder: (s, e, p, f, id) => Heart.data(
        startPoint: s,
        endPoint: e,
        paint: p,
        fillColor: f,
        id: id,
      ),
    );
  }
  if (a is CubeShape && b is CubeShape) {
    return _TwoPointShapeInterpolator<CubeShape>(
      a: a,
      b: b,
      startA: a.startPoint ?? Offset.zero,
      endA: a.endPoint ?? Offset.zero,
      startB: b.startPoint ?? Offset.zero,
      endB: b.endPoint ?? Offset.zero,
      builder: (s, e, p, f, id) => CubeShape.data(
        startPoint: s,
        endPoint: e,
        paint: p,
        fillColor: f,
        id: id,
      ),
    );
  }
  if (a is CylinderShape && b is CylinderShape) {
    return _TwoPointShapeInterpolator<CylinderShape>(
      a: a,
      b: b,
      startA: a.startPoint ?? Offset.zero,
      endA: a.endPoint ?? Offset.zero,
      startB: b.startPoint ?? Offset.zero,
      endB: b.endPoint ?? Offset.zero,
      builder: (s, e, p, f, id) => CylinderShape.data(
        startPoint: s,
        endPoint: e,
        paint: p,
        fillColor: f,
        id: id,
      ),
    );
  }
  if (a is DragShape && b is DragShape && a.contentType == b.contentType) {
    return _DragShapeInterpolator(a, b);
  }

  // 6. SmoothLine <-> SmoothLine (with dynamic strokeWidthList)
  if (a is SmoothLine && b is SmoothLine) {
    return _SmoothLineInterpolator(a, b);
  }

  // 7. Same-type brush.FreehandLine subclasses (DashedLine, TipBrush, PresetStroke, etc.)
  if (a is brush.FreehandLine &&
      b is brush.FreehandLine &&
      a.contentType == b.contentType) {
    return _BrushStrokeInterpolator(a, b);
  }

  // 8. FreehandLine <-> FreehandLine (or any compatible stroke pair!)
  if (_isStrokeLike(a) && _isStrokeLike(b)) {
    return _PolylineStrokeInterpolator(a, b);
  }

  // 9. Cross-type closed shape morphing (e.g., Circle <-> Rectangle <-> StarShape)
  if (_isClosedShapeLike(a) && _isClosedShapeLike(b)) {
    return _ClosedShapeMorphInterpolator(a, b);
  }

  // 10. Structural wrappers
  if (a is OffsetContent && b is OffsetContent) {
    return _OffsetContentInterpolator(a, b);
  }
  if (a is GroupContent && b is GroupContent) {
    return _GroupContentInterpolator(a, b);
  }
  if (a is MirrorContent && b is MirrorContent) {
    return _MirrorInterpolator(a, b);
  }
  if (a is QuadMirrorContent && b is QuadMirrorContent) {
    return _QuadMirrorInterpolator(a, b);
  }
  if (a is RadialContent && b is RadialContent) {
    return _RadialInterpolator(a, b);
  }

  // 11. Eraser / EraserHole
  if (a is Eraser && b is Eraser) {
    return _PathMorphInterpolator(
      a.getPath(),
      b.getPath(),
      a.paint,
      b.paint,
      isHole: false,
    );
  }
  if (a is EraserHole && b is EraserHole) {
    return _PathMorphInterpolator(
      a.path.path,
      b.path.path,
      a.paint,
      b.paint,
      isHole: true,
    );
  }

  // 12. Fallback cross-fade
  return _CrossFadeInterpolator(a, b);
}

ShapeStickerContent _promoteToShapeSticker(PaintContent raw) {
  final Rect bounds = getShapeBounds(raw);
  final double w = math.max(bounds.width, 10.0);
  final double h = math.max(bounds.height, 10.0);
  return ShapeStickerContent.data(
    child: OffsetContent(raw.copy(), -bounds.topLeft),
    offset: bounds.center,
    scale: 1.0,
    rotation: 0.0,
    size: Size(w, h),
    paint: raw.paint.copyWith(),
    id: raw.id,
    fillColor: raw.fillColor,
  );
}

class _ShapeStickerInterpolator implements _ItemInterpolator {
  _ShapeStickerInterpolator(this.a, this.b)
      : _childInterp = _buildChildInterp(a, b);

  final ShapeStickerContent a;
  final ShapeStickerContent b;
  final _ItemInterpolator? _childInterp;

  static _ItemInterpolator? _buildChildInterp(
    ShapeStickerContent stickerA,
    ShapeStickerContent stickerB,
  ) {
    final PaintContent ca = stickerA.child;
    final PaintContent cb = stickerB.child;
    if (ca is OffsetContent &&
        cb is OffsetContent &&
        ca.child is! ClippedHistoryContent &&
        cb.child is! ClippedHistoryContent) {
      return _createPairInterpolator(ca, cb);
    }
    final PaintContent ua = _unwrapOffset(ca);
    final PaintContent ub = _unwrapOffset(cb);
    if (ua is ClippedHistoryContent ||
        ub is ClippedHistoryContent ||
        ua is GroupContent ||
        ub is GroupContent) {
      return null;
    }
    if (ca.contentType == cb.contentType && ca is! OffsetContent) {
      return _createPairInterpolator(ca, cb);
    }
    if (ca is! OffsetContent &&
        cb is! OffsetContent &&
        _isClosedShapeLike(ua) &&
        _isClosedShapeLike(ub)) {
      return _ClosedShapeMorphInterpolator(
        ca,
        cb,
        overrideFillA: ca.fillColor ?? stickerA.fillColor,
        overrideFillB: cb.fillColor ?? stickerB.fillColor,
      );
    }
    if (ca is! OffsetContent &&
        cb is! OffsetContent &&
        _isStrokeLike(ua) &&
        _isStrokeLike(ub)) {
      return _PolylineStrokeInterpolator(ca, cb);
    }
    return null;
  }

  static void _propagateStyle(
    PaintContent target,
    Paint paint,
    Color? fillColor,
  ) {
    target.paint = paint.copyWith();
    if (fillColor != null) {
      target.fillColor = fillColor;
    }
    if (target is OffsetContent) {
      _propagateStyle(target.child, paint, fillColor);
    }
  }

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final PaintContent child = _childInterp != null
        ? (_childInterp.evaluate(t, cloneRasterImages: cloneRasterImages) ??
              _cloneSafe(a.child, cloneRasterImages: cloneRasterImages))
        : _cloneSafe(
            t < 0.5 ? a.child : b.child,
            cloneRasterImages: cloneRasterImages,
          );

    // Sync child paint color/strokeWidth if no child interpolator ran
    if (_childInterp == null && child is! ClippedHistoryContent && child is! GroupContent) {
      final Paint lerpedPaint = _lerpPaint(a.paint, b.paint, t);
      final Color? lerpedFill = (a.fillColor != null || b.fillColor != null)
          ? Color.lerp(
              a.fillColor ?? Colors.transparent,
              b.fillColor ?? Colors.transparent,
              t,
            )
          : null;
      _propagateStyle(child, lerpedPaint, lerpedFill);
    }

    return ShapeStickerContent.data(
      child: child,
      offset: Offset.lerp(a.offset, b.offset, t) ?? a.offset,
      scale: ui.lerpDouble(a.scale, b.scale, t) ?? a.scale,
      rotation: _lerpAngle(a.rotation, b.rotation, t),
      size: Size.lerp(a.size, b.size, t) ?? a.size,
      flipX: t < 0.5 ? a.flipX : b.flipX,
      flipY: t < 0.5 ? a.flipY : b.flipY,
      topLeftOffset:
          Offset.lerp(a.topLeftOffset, b.topLeftOffset, t) ?? a.topLeftOffset,
      topRightOffset:
          Offset.lerp(a.topRightOffset, b.topRightOffset, t) ??
          a.topRightOffset,
      bottomRightOffset:
          Offset.lerp(a.bottomRightOffset, b.bottomRightOffset, t) ??
          a.bottomRightOffset,
      bottomLeftOffset:
          Offset.lerp(a.bottomLeftOffset, b.bottomLeftOffset, t) ??
          a.bottomLeftOffset,
      paint: _lerpPaint(a.paint, b.paint, t),
      fillColor: (a.fillColor != null || b.fillColor != null)
          ? Color.lerp(
              a.fillColor ?? Colors.transparent,
              b.fillColor ?? Colors.transparent,
              t,
            )
          : null,
    );
  }
}

class _TextInterpolator implements _ItemInterpolator {
  _TextInterpolator(this.a, this.b);
  final TextContent a;
  final TextContent b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final TextContent ref = t < 0.5 ? a : b;
    return TextContent.data(
      offset: Offset.lerp(a.offset, b.offset, t) ?? a.offset,
      text: ref.text,
      scale: ui.lerpDouble(a.scale, b.scale, t) ?? a.scale,
      rotation: _lerpAngle(a.rotation, b.rotation, t),
      fontSize: ui.lerpDouble(a.fontSize, b.fontSize, t) ?? a.fontSize,
      isBold: ref.isBold,
      isItalic: ref.isItalic,
      isUnderline: ref.isUnderline,
      textAlign: ref.textAlign,
      opacity: (ui.lerpDouble(a.opacity, b.opacity, t) ?? 1.0).clamp(0.0, 1.0),
      fontFamily: ref.fontFamily,
      flipX: ref.flipX,
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _ImageInterpolator implements _ItemInterpolator {
  _ImageInterpolator(this.a, this.b);
  final ImageContent a;
  final ImageContent b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final ImageContent ref = t < 0.5 ? a : b;
    return ImageContent.data(
      startPoint: Offset.lerp(a.startPoint, b.startPoint, t) ?? a.startPoint,
      size: Offset.lerp(a.size, b.size, t) ?? a.size,
      image: _safeImageRef(ref.image, ref.imageUrl, cloneRasterImages),
      imageUrl: ref.imageUrl,
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _SimpleLineInterpolator implements _ItemInterpolator {
  _SimpleLineInterpolator(this.a, this.b);
  final SimpleLine a;
  final SimpleLine b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    return SimpleLine.data(
      startPoint: Offset.lerp(
        a.startPoint ?? Offset.zero,
        b.startPoint ?? Offset.zero,
        t,
      ),
      endPoint: Offset.lerp(
        a.endPoint ?? Offset.zero,
        b.endPoint ?? Offset.zero,
        t,
      ),
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _StraightLineInterpolator implements _ItemInterpolator {
  _StraightLineInterpolator(this.a, this.b);
  final StraightLine a;
  final StraightLine b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    return StraightLine.data(
      startPoint: Offset.lerp(
        a.startPoint ?? Offset.zero,
        b.startPoint ?? Offset.zero,
        t,
      ),
      endPoint: Offset.lerp(
        a.endPoint ?? Offset.zero,
        b.endPoint ?? Offset.zero,
        t,
      ),
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _CircleInterpolator implements _ItemInterpolator {
  _CircleInterpolator(this.a, this.b);
  final Circle a;
  final Circle b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    return Circle.data(
      isEllipse: a.isEllipse || b.isEllipse,
      startFromCenter: t < 0.5 ? a.startFromCenter : b.startFromCenter,
      center: Offset.lerp(a.center, b.center, t) ?? a.center,
      radius: ui.lerpDouble(a.radius, b.radius, t) ?? a.radius,
      startPoint: Offset.lerp(a.startPoint, b.startPoint, t) ?? a.startPoint,
      endPoint: Offset.lerp(a.endPoint, b.endPoint, t) ?? a.endPoint,
      paint: _lerpPaint(a.paint, b.paint, t),
      fillColor: _lerpOptionalColor(a.fillColor, b.fillColor, t),
    );
  }
}

class _TriangleInterpolator implements _ItemInterpolator {
  _TriangleInterpolator(this.a, this.b);
  final Triangle a;
  final Triangle b;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    return Triangle.data(
      startPoint: Offset.lerp(a.startPoint, b.startPoint, t) ?? a.startPoint,
      A: Offset.lerp(a.A, b.A, t) ?? a.A,
      B: Offset.lerp(a.B, b.B, t) ?? a.B,
      C: Offset.lerp(a.C, b.C, t) ?? a.C,
      paint: _lerpPaint(a.paint, b.paint, t),
      fillColor: _lerpOptionalColor(a.fillColor, b.fillColor, t),
    );
  }
}

class _TwoPointShapeInterpolator<T extends PaintContent>
    implements _ItemInterpolator {
  _TwoPointShapeInterpolator({
    required this.a,
    required this.b,
    required this.startA,
    required this.endA,
    required this.startB,
    required this.endB,
    required this.builder,
  });

  final T a;
  final T b;
  final Offset startA;
  final Offset endA;
  final Offset startB;
  final Offset endB;
  final T Function(
    Offset start,
    Offset end,
    Paint paint,
    Color? fillColor,
    String? id,
  ) builder;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    return builder(
      Offset.lerp(startA, startB, t) ?? startA,
      Offset.lerp(endA, endB, t) ?? endA,
      _lerpPaint(a.paint, b.paint, t),
      _lerpOptionalColor(a.fillColor, b.fillColor, t),
      null,
    );
  }
}

class _DragShapeInterpolator implements _ItemInterpolator {
  _DragShapeInterpolator(this.a, this.b)
      : _template = a.toJson();

  final DragShape a;
  final DragShape b;
  final Map<String, dynamic> _template;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final Offset s = Offset.lerp(
          a.startPoint ?? Offset.zero,
          b.startPoint ?? Offset.zero,
          t,
        ) ??
        Offset.zero;
    final Offset e = Offset.lerp(
          a.endPoint ?? Offset.zero,
          b.endPoint ?? Offset.zero,
          t,
        ) ??
        Offset.zero;
    final Paint p = _lerpPaint(a.paint, b.paint, t);
    final Color? fill = _lerpOptionalColor(a.fillColor, b.fillColor, t);

    final Map<String, dynamic> map = Map<String, dynamic>.from(_template);
    map.remove('id');
    map['startPoint'] = s.toJson();
    map['endPoint'] = e.toJson();
    map['paint'] = p.toJson();
    if (fill != null) {
      map['fillColor'] = fill.toARGB32();
    } else {
      map.remove('fillColor');
    }
    return decodePaintContent(a.contentType, map);
  }
}

class _SmoothLineInterpolator implements _ItemInterpolator {
  factory _SmoothLineInterpolator(SmoothLine a, SmoothLine b) {
    final int targetCount = math.max(a.points.length, b.points.length).clamp(12, 64);
    final List<Offset> ptsA = _resamplePolyline(a.points, targetCount);
    List<Offset> ptsB = _resamplePolyline(b.points, targetCount);
    final List<double> wA = _resampleValues(a.strokeWidthList, targetCount);
    List<double> wB = _resampleValues(b.strokeWidthList, targetCount);

    if (_shouldReverseOrder(ptsA, ptsB)) {
      ptsB = ptsB.reversed.toList();
      wB = wB.reversed.toList();
    }
    return _SmoothLineInterpolator._(a, b, ptsA, ptsB, wA, wB);
  }

  _SmoothLineInterpolator._(
    this.a,
    this.b,
    this.ptsA,
    this.ptsB,
    this.wA,
    this.wB,
  );

  final SmoothLine a;
  final SmoothLine b;
  final List<Offset> ptsA;
  final List<Offset> ptsB;
  final List<double> wA;
  final List<double> wB;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final int len = ptsA.length;
    final List<Offset> pts = List<Offset>.generate(
      len,
      (i) => Offset.lerp(ptsA[i], ptsB[i], t) ?? ptsA[i],
    );
    final List<double> widths = List<double>.generate(
      len,
      (i) => ui.lerpDouble(wA[i], wB[i], t) ?? wA[i],
    );
    return SmoothLine.data(
      brushPrecision: a.brushPrecision,
      minPointDistance: a.minPointDistance,
      useBezierCurve: a.useBezierCurve,
      smoothLevel: a.smoothLevel,
      points: pts,
      strokeWidthList: widths,
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _BrushStrokeInterpolator implements _ItemInterpolator {
  factory _BrushStrokeInterpolator(
    brush.FreehandLine a,
    brush.FreehandLine b,
  ) {
    final int targetCount = math.max(a.points.length, b.points.length).clamp(12, 64);
    final List<Offset> ptsA = _resamplePolyline(a.points, targetCount);
    List<Offset> ptsB = _resamplePolyline(b.points, targetCount);
    if (_shouldReverseOrder(ptsA, ptsB)) {
      ptsB = ptsB.reversed.toList();
    }
    return _BrushStrokeInterpolator._(a, b, ptsA, ptsB, a.toJson());
  }

  _BrushStrokeInterpolator._(
    this.a,
    this.b,
    this.ptsA,
    this.ptsB,
    this._template,
  );

  final brush.FreehandLine a;
  final brush.FreehandLine b;
  final List<Offset> ptsA;
  final List<Offset> ptsB;
  final Map<String, dynamic> _template;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final List<Map<String, dynamic>> ptsJson = List<Map<String, dynamic>>.generate(
      ptsA.length,
      (i) => (Offset.lerp(ptsA[i], ptsB[i], t) ?? ptsA[i]).toJson(),
    );
    final Map<String, dynamic> map = Map<String, dynamic>.from(_template);
    map.remove('id');
    map['points'] = ptsJson;
    map['paint'] = _lerpPaint(a.paint, b.paint, t).toJson();
    return decodePaintContent(a.contentType, map);
  }
}

class _PolylineStrokeInterpolator implements _ItemInterpolator {
  factory _PolylineStrokeInterpolator(PaintContent a, PaintContent b) {
    final List<Offset> rawA = _extractStrokePoints(a);
    final List<Offset> rawB = _extractStrokePoints(b);
    final int targetCount = math.max(rawA.length, rawB.length).clamp(12, 64);
    final List<Offset> ptsA = _resamplePolyline(rawA, targetCount);
    List<Offset> ptsB = _resamplePolyline(rawB, targetCount);
    if (_shouldReverseOrder(ptsA, ptsB)) {
      ptsB = ptsB.reversed.toList();
    }
    return _PolylineStrokeInterpolator._(a, b, ptsA, ptsB);
  }

  _PolylineStrokeInterpolator._(this.a, this.b, this.ptsA, this.ptsB);

  final PaintContent a;
  final PaintContent b;
  final List<Offset> ptsA;
  final List<Offset> ptsB;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final List<Offset> pts = List<Offset>.generate(
      ptsA.length,
      (i) => Offset.lerp(ptsA[i], ptsB[i], t) ?? ptsA[i],
    );
    return FreehandLine.data(
      points: pts,
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _ClosedShapeMorphInterpolator implements _ItemInterpolator {
  factory _ClosedShapeMorphInterpolator(
    PaintContent a,
    PaintContent b, {
    Color? overrideFillA,
    Color? overrideFillB,
  }) {
    const int targetCount = 48;
    final List<Offset> ptsA = _extractPathPoints(a.getPath(), targetCount: targetCount);
    final List<Offset> rawB = _extractPathPoints(b.getPath(), targetCount: targetCount);
    final List<Offset> ptsB = _alignClosedLoop(ptsA, rawB);
    return _ClosedShapeMorphInterpolator._(
      a,
      b,
      ptsA,
      ptsB,
      overrideFillA ?? a.fillColor,
      overrideFillB ?? b.fillColor,
    );
  }

  _ClosedShapeMorphInterpolator._(
    this.a,
    this.b,
    this.ptsA,
    this.ptsB,
    this.fillA,
    this.fillB,
  );

  final PaintContent a;
  final PaintContent b;
  final List<Offset> ptsA;
  final List<Offset> ptsB;
  final Color? fillA;
  final Color? fillB;

  static List<Offset> _alignClosedLoop(
    List<Offset> ref,
    List<Offset> target,
  ) {
    final int n = ref.length;
    if (n < 3 || target.length != n) return target;

    double signedArea(List<Offset> pts) {
      double area = 0.0;
      for (int i = 0; i < pts.length; i++) {
        final Offset p1 = pts[i];
        final Offset p2 = pts[(i + 1) % pts.length];
        area += (p1.dx * p2.dy) - (p2.dx * p1.dy);
      }
      return area;
    }

    List<Offset> aligned = target;
    if (signedArea(ref) * signedArea(target) < 0) {
      aligned = target.reversed.toList(growable: false);
    }

    Offset centroid(List<Offset> pts) {
      double sx = 0, sy = 0;
      for (final p in pts) {
        sx += p.dx;
        sy += p.dy;
      }
      return Offset(sx / pts.length, sy / pts.length);
    }

    final Offset ca = centroid(ref);
    final Offset cb = centroid(aligned);
    double bestCost = double.infinity;
    int bestShift = 0;
    for (int shift = 0; shift < n; shift++) {
      double cost = 0.0;
      for (int i = 0; i < n; i++) {
        final Offset da = ref[i] - ca;
        final Offset db = aligned[(i + shift) % n] - cb;
        final double dx = da.dx - db.dx;
        final double dy = da.dy - db.dy;
        cost += dx * dx + dy * dy;
      }
      if (cost < bestCost) {
        bestCost = cost;
        bestShift = shift;
      }
    }
    if (bestShift == 0) return aligned;
    return List<Offset>.generate(
      n,
      (i) => aligned[(i + bestShift) % n],
      growable: false,
    );
  }

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final List<Offset> pts = List<Offset>.generate(
      ptsA.length,
      (i) => Offset.lerp(ptsA[i], ptsB[i], t) ?? ptsA[i],
    );
    if (pts.isNotEmpty) {
      pts.add(pts.first); // close loop
    }
    final Paint strokePaint = _lerpPaint(a.paint, b.paint, t);
    final Color? fillColor = _lerpOptionalColor(fillA, fillB, t);
    if (fillColor != null) {
      final FreehandLine fillLine = FreehandLine.data(
        points: pts,
        paint: Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor
          ..isAntiAlias = true,
      );
      final FreehandLine strokeLine = FreehandLine.data(
        points: pts,
        paint: strokePaint,
      );
      return GroupContent(children: [fillLine, strokeLine]);
    }
    return FreehandLine.data(
      points: pts,
      paint: strokePaint,
    );
  }
}

class _OffsetContentInterpolator implements _ItemInterpolator {
  _OffsetContentInterpolator(this.a, this.b)
      : _childInterp = _createPairInterpolator(a.child, b.child);

  final OffsetContent a;
  final OffsetContent b;
  final _ItemInterpolator _childInterp;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final PaintContent? child = _childInterp.evaluate(
      t,
      cloneRasterImages: cloneRasterImages,
    );
    if (child == null) return null;
    final Offset shift = Offset.lerp(a.shiftOffset, b.shiftOffset, t) ?? a.shiftOffset;
    return OffsetContent(child, shift);
  }
}

class _GroupContentInterpolator implements _ItemInterpolator {
  _GroupContentInterpolator(this.a, this.b)
      : _inner = _buildLayerInterpolators(
          a.children,
          b.children,
          fadeUnmatched: true,
        ).interpolators;

  final GroupContent a;
  final GroupContent b;
  final List<_ItemInterpolator> _inner;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final List<PaintContent> children = [];
    for (final _ItemInterpolator interp in _inner) {
      final PaintContent? c = interp.evaluate(
        t,
        cloneRasterImages: cloneRasterImages,
      );
      if (c != null) children.add(c);
    }
    if (children.isEmpty) return null;
    return GroupContent(
      children: children,
      boundsOffset:
          Offset.lerp(a.boundsOffset, b.boundsOffset, t) ?? a.boundsOffset,
      paint: _lerpPaint(a.paint, b.paint, t),
    );
  }
}

class _MirrorInterpolator implements _ItemInterpolator {
  _MirrorInterpolator(this.a, this.b)
      : _childInterp = _createPairInterpolator(a.child, b.child);

  final MirrorContent a;
  final MirrorContent b;
  final _ItemInterpolator _childInterp;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final PaintContent? child = _childInterp.evaluate(
      t,
      cloneRasterImages: cloneRasterImages,
    );
    if (child == null) return null;
    return MirrorContent(
      child,
      Offset.lerp(a.mirrorCenter, b.mirrorCenter, t) ?? a.mirrorCenter,
      _lerpAngle(a.mirrorAngle, b.mirrorAngle, t),
    );
  }
}

class _QuadMirrorInterpolator implements _ItemInterpolator {
  _QuadMirrorInterpolator(this.a, this.b)
      : _childInterp = _createPairInterpolator(a.child, b.child);

  final QuadMirrorContent a;
  final QuadMirrorContent b;
  final _ItemInterpolator _childInterp;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final PaintContent? child = _childInterp.evaluate(
      t,
      cloneRasterImages: cloneRasterImages,
    );
    if (child == null) return null;
    return QuadMirrorContent(
      child,
      Offset.lerp(a.mirrorCenter, b.mirrorCenter, t) ?? a.mirrorCenter,
      _lerpAngle(a.mirrorAngle, b.mirrorAngle, t),
    );
  }
}

class _RadialInterpolator implements _ItemInterpolator {
  _RadialInterpolator(this.a, this.b)
      : _childInterp = _createPairInterpolator(a.child, b.child);

  final RadialContent a;
  final RadialContent b;
  final _ItemInterpolator _childInterp;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    final PaintContent? child = _childInterp.evaluate(
      t,
      cloneRasterImages: cloneRasterImages,
    );
    if (child == null) return null;
    return RadialContent(
      child,
      Offset.lerp(a.center, b.center, t) ?? a.center,
      t < 0.5 ? a.sectors : b.sectors,
      _lerpAngle(a.startAngle, b.startAngle, t),
    );
  }
}

class _PathMorphInterpolator implements _ItemInterpolator {
  _PathMorphInterpolator(
    Path pathA,
    Path pathB,
    this.paintA,
    this.paintB, {
    required this.isHole,
  })  : ptsA = _extractPathPoints(pathA, targetCount: 32),
        ptsB = _extractPathPoints(pathB, targetCount: 32);

  final List<Offset> ptsA;
  final List<Offset> ptsB;
  final Paint paintA;
  final Paint paintB;
  final bool isHole;

  @override
  PaintContent? evaluate(double t, {required bool cloneRasterImages}) {
    if (ptsA.isEmpty || ptsB.isEmpty) return null;
    final DrawPath dp = DrawPath();
    final Offset p0 = Offset.lerp(ptsA.first, ptsB.first, t) ?? ptsA.first;
    dp.moveTo(p0.dx, p0.dy);
    for (int i = 1; i < ptsA.length; i++) {
      final Offset pt = Offset.lerp(ptsA[i], ptsB[i], t) ?? ptsA[i];
      dp.lineTo(pt.dx, pt.dy);
    }
    final Paint p = _lerpPaint(paintA, paintB, t);
    return isHole
        ? EraserHole(path: dp, paint: p)
        : Eraser.data(drawPath: dp, paint: p);
  }
}

// ============================================================================
// Geometry & paint math helpers
// ============================================================================

double _lerpAngle(double a, double b, double t) {
  double diff = (b - a) % (2.0 * math.pi);
  if (diff > math.pi) diff -= 2.0 * math.pi;
  if (diff < -math.pi) diff += 2.0 * math.pi;
  return a + diff * t;
}

Paint _lerpPaint(Paint a, Paint b, double t) {
  final Paint ref = (t < 0.5 ? a : b).copyWith();
  ref.color = Color.lerp(a.color, b.color, t) ?? a.color;
  ref.strokeWidth = ui.lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? a.strokeWidth;
  return ref;
}

Color? _lerpOptionalColor(Color? a, Color? b, double t) {
  if (a == null && b == null) return null;
  return Color.lerp(
    a ?? Colors.transparent,
    b ?? Colors.transparent,
    t,
  );
}

ui.Image? _safeImageRef(
  ui.Image? image,
  String? imageUrl,
  bool cloneRasterImages,
) {
  if (image == null) return null;
  // If backed by a URL/file path, returning null lets EditorController's lazy
  // hydration load & evict images within its 6-frame window without holding
  // extra GPU textures across dozens of generated frames.
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return cloneRasterImages ? null : image;
  }
  return cloneRasterImages ? image.clone() : image;
}

PaintContent _cloneSafe(
  PaintContent content, {
  required bool cloneRasterImages,
}) {
  if (content is ImageContent) {
    return ImageContent.data(
      startPoint: content.startPoint,
      size: content.size,
      image: _safeImageRef(content.image, content.imageUrl, cloneRasterImages),
      imageUrl: content.imageUrl,
      paint: content.paint.copyWith(),
    );
  }
  if (content is FillContent) {
    final ui.Image? safeImg = (content.cachedBase64Image != null &&
            content.cachedBase64Image!.isNotEmpty)
        ? (cloneRasterImages ? null : content.image)
        : (cloneRasterImages ? content.image?.clone() : content.image);
    return FillContent.data(
      image: safeImg,
      paint: content.paint.copyWith(),
      isUnderneath: content.isUnderneath,
    )..cachedBase64Image = content.cachedBase64Image;
  }
  if (content is ShapeStickerContent) {
    return ShapeStickerContent.data(
      child: _cloneSafe(content.child, cloneRasterImages: cloneRasterImages),
      offset: content.offset,
      scale: content.scale,
      rotation: content.rotation,
      size: content.size,
      flipX: content.flipX,
      flipY: content.flipY,
      topLeftOffset: content.topLeftOffset,
      topRightOffset: content.topRightOffset,
      bottomRightOffset: content.bottomRightOffset,
      bottomLeftOffset: content.bottomLeftOffset,
      paint: content.paint.copyWith(),
      fillColor: content.fillColor,
    );
  }
  if (content is OffsetContent) {
    return OffsetContent(
      _cloneSafe(content.child, cloneRasterImages: cloneRasterImages),
      content.shiftOffset,
    );
  }
  if (content is GroupContent) {
    return GroupContent(
      children: content.children
          .map((c) => _cloneSafe(c, cloneRasterImages: cloneRasterImages))
          .toList(),
      boundsOffset: content.boundsOffset,
      paint: content.paint.copyWith(),
    );
  }
  return content.copy();
}

PaintContent _cloneWithAlphaScale(
  PaintContent content,
  double factor, {
  required bool cloneRasterImages,
}) {
  final PaintContent cloned = _cloneSafe(
    content,
    cloneRasterImages: cloneRasterImages,
  );
  _applyAlphaScaleInPlace(cloned, factor.clamp(0.0, 1.0));
  return cloned;
}

void _applyAlphaScaleInPlace(PaintContent content, double factor) {
  content.paint.color = content.paint.color.withValues(
    alpha: (content.paint.color.a * factor).clamp(0.0, 1.0),
  );
  if (content.fillColor != null) {
    content.fillColor = content.fillColor!.withValues(
      alpha: (content.fillColor!.a * factor).clamp(0.0, 1.0),
    );
  }
  if (content is TextContent) {
    content.opacity = (content.opacity * factor).clamp(0.0, 1.0);
  } else if (content is ShapeStickerContent) {
    _applyAlphaScaleInPlace(content.child, factor);
  } else if (content is OffsetContent) {
    _applyAlphaScaleInPlace(content.child, factor);
  } else if (content is GroupContent) {
    for (final child in content.children) {
      _applyAlphaScaleInPlace(child, factor);
    }
  } else if (content is MirrorContent) {
    _applyAlphaScaleInPlace(content.child, factor);
  } else if (content is QuadMirrorContent) {
    _applyAlphaScaleInPlace(content.child, factor);
  } else if (content is RadialContent) {
    _applyAlphaScaleInPlace(content.child, factor);
  }
}

List<Offset> _extractStrokePoints(PaintContent content) {
  if (content is FreehandLine) {
    if (content.points != null && content.points!.isNotEmpty) {
      return content.points!;
    }
    return _extractPathPoints(content.path.path, targetCount: 32);
  }
  if (content is SmoothLine) {
    return content.points;
  }
  if (content is brush.FreehandLine) {
    return content.points;
  }
  if (content is SimpleLine) {
    return [
      content.startPoint ?? Offset.zero,
      content.endPoint ?? content.startPoint ?? Offset.zero,
    ];
  }
  if (content is StraightLine) {
    return [
      content.startPoint ?? Offset.zero,
      content.endPoint ?? content.startPoint ?? Offset.zero,
    ];
  }
  return _extractPathPoints(content.getPath(), targetCount: 32);
}

List<Offset> _extractPathPoints(Path path, {int targetCount = 32}) {
  final List<Offset> raw = [];
  for (final ui.PathMetric metric in path.computeMetrics()) {
    final double len = metric.length;
    if (len <= 0.001) continue;
    final int steps = math.max(4, math.min(targetCount, (len / 4.0).ceil()));
    for (int i = 0; i <= steps; i++) {
      final ui.Tangent? tangent = metric.getTangentForOffset(len * i / steps);
      if (tangent != null) {
        raw.add(tangent.position);
      }
    }
  }
  if (raw.isEmpty) {
    final Rect bounds = path.getBounds();
    return List<Offset>.filled(targetCount, bounds.center);
  }
  return _resamplePolyline(raw, targetCount);
}

List<Offset> _resamplePolyline(List<Offset> points, int targetCount) {
  if (points.isEmpty) {
    return List<Offset>.filled(targetCount, Offset.zero);
  }
  if (points.length == 1) {
    return List<Offset>.filled(targetCount, points.first);
  }
  if (targetCount <= 1) {
    return [points.first];
  }

  final List<double> cumDist = List<double>.filled(points.length, 0.0);
  double total = 0.0;
  for (int i = 1; i < points.length; i++) {
    total += (points[i] - points[i - 1]).distance;
    cumDist[i] = total;
  }

  if (total <= 1e-4) {
    return List<Offset>.filled(targetCount, points.first);
  }

  final List<Offset> out = List<Offset>.filled(targetCount, points.first);
  int seg = 0;
  for (int k = 0; k < targetCount; k++) {
    final double targetDist = (k / (targetCount - 1)) * total;
    while (seg < points.length - 2 && cumDist[seg + 1] < targetDist) {
      seg++;
    }
    final double segStart = cumDist[seg];
    final double segEnd = cumDist[seg + 1];
    final double segLen = segEnd - segStart;
    if (segLen <= 1e-6) {
      out[k] = points[seg];
    } else {
      final double localT = ((targetDist - segStart) / segLen).clamp(0.0, 1.0);
      out[k] = Offset.lerp(points[seg], points[seg + 1], localT) ?? points[seg];
    }
  }
  return out;
}

List<double> _resampleValues(List<double> values, int targetCount) {
  if (values.isEmpty) {
    return List<double>.filled(targetCount, 4.0);
  }
  if (values.length == 1 || targetCount <= 1) {
    return List<double>.filled(targetCount, values.first);
  }
  return List<double>.generate(targetCount, (i) {
    final double pos = (i / (targetCount - 1)) * (values.length - 1);
    final int idx = pos.floor().clamp(0, values.length - 2);
    final double frac = pos - idx;
    return ui.lerpDouble(values[idx], values[idx + 1], frac) ?? values[idx];
  });
}

bool _shouldReverseOrder(List<Offset> a, List<Offset> b) {
  if (a.length != b.length || a.length < 2) return false;
  double forwardCost = 0.0;
  double reverseCost = 0.0;
  final int n = a.length;
  for (int i = 0; i < n; i++) {
    forwardCost += (a[i] - b[i]).distanceSquared;
    reverseCost += (a[i] - b[n - 1 - i]).distanceSquared;
  }
  return reverseCost < forwardCost;
}
