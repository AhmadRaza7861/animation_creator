import 'dart:ui';
import 'package:flutter/material.dart';

import 'paint_content.dart';

/// Represents a single drawing layer.
class LayerData {
  LayerData({
    required this.id,
    this.name = 'Layer',
    this.isVisible = true,
    this.isLocked = false,
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
  double opacity;
  BlendMode blendMode;
  
  List<PaintContent> history;
  int currentIndex;

  LayerData copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
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
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      history: newHistory,
      currentIndex: newIndex.clamp(0, newHistory.length),
    );
  }
}
