import 'dart:ui';
import 'package:flutter/material.dart';

import 'blur.dart';
import 'eraser.dart';
import 'eraser_hole.dart';
import 'fill.dart';
import 'paint_content.dart';
import 'smudge.dart';
import 'stroke_recolor.dart';

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
  /// If a SmudgeContent or BlurContent is present, it is rendered first as the base raster state.
  /// Then, drawing is rendered chronologically in segments partitioned by destructive/erasing operations
  /// (Eraser / EraserHole). Within each segment:
  /// - Pass 1: Interior fills (FillContent with isUnderneath == true)
  /// - Pass 2: Non-fill strokes and content
  /// - Pass 3: Re-coloring / overlay fills (FillContent with isUnderneath == false)
  /// Erasers are rendered chronologically between segments, ensuring earlier erasers do not erase later fills.
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

    // Process history items in segments separated by Eraser operations
    int segStart = startIdx;
    while (segStart < count) {
      // Find the next Eraser/EraserHole or the end of count
      int segEnd = segStart;
      while (segEnd < count && history[segEnd] is! Eraser && history[segEnd] is! EraserHole) {
        segEnd++;
      }

      // Draw segment [segStart, segEnd):
      // Pass 1: Draw interior FillContent items (underneath strokes of this segment)
      for (int j = segStart; j < segEnd; j++) {
        final item = history[j];
        if (item is FillContent && item.isUnderneath) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }

      // Pass 2: Draw non-fill items (strokes, shapes, lines, etc.) in this segment
      for (int j = segStart; j < segEnd; j++) {
        final item = history[j];
        if (item is! FillContent && item is! StrokeRecolorContent) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }

      // Pass 3: Draw re-coloring / overlay FillContent items (on top of strokes) in this segment
      for (int j = segStart; j < segEnd; j++) {
        final item = history[j];
        if (item is FillContent && !item.isUnderneath) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }

      // If segEnd is an Eraser or EraserHole, draw it now (it erases everything drawn up to this point)
      if (segEnd < count && (history[segEnd] is Eraser || history[segEnd] is EraserHole)) {
        history[segEnd].draw(canvas, size, deeper);
        if (tempCanvas != null) {
          history[segEnd].draw(tempCanvas, size, deeper);
        }
        segStart = segEnd + 1;
      } else {
        segStart = segEnd;
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
