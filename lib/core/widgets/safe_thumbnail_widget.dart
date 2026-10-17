import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a [ui.Image] directly to canvas without invoking [ui.Image.clone].
///
/// This protects against Flutter's [RawImage] throwing
/// "Bad state: Cannot clone a disposed image" during concurrent frame builds,
/// animations, or rebuild cascades.
class SafeThumbnailWidget extends StatelessWidget {
  final ui.Image? image;
  final BoxFit fit;

  const SafeThumbnailWidget({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _SafeThumbnailPainter(img, fit: fit),
    );
  }
}

class _SafeThumbnailPainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  const _SafeThumbnailPainter(this.image, {this.fit = BoxFit.contain});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: image,
        fit: fit,
      );
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant _SafeThumbnailPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.fit != fit;
  }
}
