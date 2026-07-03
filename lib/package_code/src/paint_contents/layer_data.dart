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
    this.currentIndex = 0,
  }) : history = history ?? <PaintContent>[];

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
    return LayerData(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      history: history ?? List.from(this.history),
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
