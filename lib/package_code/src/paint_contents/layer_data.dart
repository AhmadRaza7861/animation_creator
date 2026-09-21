import 'dart:ui';
import 'package:flutter/material.dart';

import 'blur.dart';
import 'fill.dart';
import 'paint_content.dart';
import 'smudge.dart';

/// Represents a single drawing layer.
class LayerData {
  LayerData({
    required this.id,
    this.name = 'Layer',
    this.isVisible = true,
    this.isLocked = false,
    this.isGuide = false,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    List<PaintContent>? history,
    int currentIndex = 0,
    int? sessionStartIndex,
  })  : history = history ?? <PaintContent>[],
        currentIndex = (currentIndex < 0)
            ? 0
            : (currentIndex > (history?.length ?? 0)
                ? (history?.length ?? 0)
                : currentIndex),
        sessionStartIndex = (sessionStartIndex ?? 0).clamp(0, (history?.length ?? 0));

  final String id;
  String name;
  bool isVisible;
  bool isLocked;
  bool isGuide;
  double opacity;
  BlendMode blendMode;
  
  List<PaintContent> history;
  int currentIndex;
  int sessionStartIndex;

  /// Draws the layer history onto the canvas.
  /// If a SmudgeContent or BlurContent is present, it is rendered first as the base raster state,
  /// followed by interior fills (pass 1), non-fill strokes (pass 2), and re-coloring fills (pass 3).
  void drawHistory(Canvas canvas, Size size, bool deeper, [Canvas? tempCanvas]) {
    final int count = currentIndex.clamp(0, history.length);
    if (count == 0) return;

    int rasterIndex = -1;
    for (int j = count - 1; j >= 0; j--) {
      if (history[j] is SmudgeContent || history[j] is BlurContent) {
        rasterIndex = j;
        break;
      }
    }

    final int startIdx = rasterIndex >= 0 ? rasterIndex + 1 : 0;

    if (rasterIndex >= 0) {
      // Draw the base raster state first (Smudge or Blur)
      history[rasterIndex].draw(canvas, size, deeper);
      if (tempCanvas != null) {
        history[rasterIndex].draw(tempCanvas, size, deeper);
      }
    }

    // Pass 1: Draw interior FillContent items (underneath strokes)
    for (int j = startIdx; j < count; j++) {
      final item = history[j];
      if (item is FillContent && item.isUnderneath) {
        item.draw(canvas, size, deeper);
        if (tempCanvas != null) {
          item.draw(tempCanvas, size, deeper);
        }
      }
    }

    // Pass 2: Draw non-fill items (strokes, shapes, lines, etc.)
    for (int j = startIdx; j < count; j++) {
      final item = history[j];
      if (item is! FillContent) {
        item.draw(canvas, size, deeper);
        if (tempCanvas != null) {
          item.draw(tempCanvas, size, deeper);
        }
      }
    }

    // Pass 3: Draw re-coloring / overlay FillContent items (on top of strokes)
    for (int j = startIdx; j < count; j++) {
      final item = history[j];
      if (item is FillContent && !item.isUnderneath) {
        item.draw(canvas, size, deeper);
        if (tempCanvas != null) {
          item.draw(tempCanvas, size, deeper);
        }
      }
    }
  }

  LayerData copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    bool? isGuide,
    double? opacity,
    BlendMode? blendMode,
    List<PaintContent>? history,
    int? currentIndex,
    int? sessionStartIndex,
  }) {
    final List<PaintContent> newHistory = history ?? List.from(this.history);
    final int newIndex = currentIndex ?? this.currentIndex;
    final int newSessionStartIndex = sessionStartIndex ?? this.sessionStartIndex;
    return LayerData(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      isGuide: isGuide ?? this.isGuide,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      history: newHistory,
      currentIndex: newIndex.clamp(0, newHistory.length),
      sessionStartIndex: newSessionStartIndex.clamp(0, newHistory.length),
    );
  }
}
