import 'dart:ui';
import 'package:flutter/material.dart';

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
  })  : history = history ?? <PaintContent>[],
        currentIndex = (currentIndex < 0)
            ? 0
            : (currentIndex > (history?.length ?? 0)
                ? (history?.length ?? 0)
                : currentIndex);

  final String id;
  String name;
  bool isVisible;
  bool isLocked;
  bool isGuide;
  double opacity;
  BlendMode blendMode;
  
  List<PaintContent> history;
  int currentIndex;

  /// Draws the layer history onto the canvas.
  /// If a SmudgeContent is present, it is rendered first as the base raster state,
  /// followed by subsequent fills (pass 1) and non-fill strokes (pass 2).
  void drawHistory(Canvas canvas, Size size, bool deeper, [Canvas? tempCanvas]) {
    final int count = currentIndex.clamp(0, history.length);
    if (count == 0) return;

    int smudgeIndex = -1;
    for (int j = count - 1; j >= 0; j--) {
      if (history[j] is SmudgeContent) {
        smudgeIndex = j;
        break;
      }
    }

    if (smudgeIndex >= 0) {
      // Draw the base smudge raster state first
      history[smudgeIndex].draw(canvas, size, deeper);
      if (tempCanvas != null) {
        history[smudgeIndex].draw(tempCanvas, size, deeper);
      }

      // Pass 1: Draw subsequent FillContent items
      for (int j = smudgeIndex + 1; j < count; j++) {
        final item = history[j];
        if (item is FillContent) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }

      // Pass 2: Draw subsequent non-fill items (strokes, shapes, lines, etc.)
      for (int j = smudgeIndex + 1; j < count; j++) {
        final item = history[j];
        if (item is! FillContent) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }
    } else {
      // Pass 1: Draw all FillContent items first (underneath strokes)
      for (int j = 0; j < count; j++) {
        final item = history[j];
        if (item is FillContent) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
        }
      }

      // Pass 2: Draw all non-fill items (strokes, shapes, lines, etc.) on top
      for (int j = 0; j < count; j++) {
        final item = history[j];
        if (item is! FillContent) {
          item.draw(canvas, size, deeper);
          if (tempCanvas != null) {
            item.draw(tempCanvas, size, deeper);
          }
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
  }) {
    final List<PaintContent> newHistory = history ?? List.from(this.history);
    final int newIndex = currentIndex ?? this.currentIndex;
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
    );
  }
}
