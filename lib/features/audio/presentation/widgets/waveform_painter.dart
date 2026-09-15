import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color waveColor;
  final Color playedColor;
  final double progress; // 0.0 to 1.0
  final double barWidth;
  final double barGap;

  final double fadeInFraction; // 0.0 to 0.5
  final double fadeOutFraction; // 0.0 to 0.5

  const WaveformPainter({
    required this.samples,
    this.waveColor = const Color(0xFFFF9318),
    this.playedColor = const Color(0xFFE07C0A),
    this.progress = 0.0,
    this.fadeInFraction = 0.0,
    this.fadeOutFraction = 0.0,
    this.barWidth = 2.5,
    this.barGap = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) return;

    final Paint unplayedPaint = Paint()
      ..color = waveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke;

    final Paint playedPaint = Paint()
      ..color = playedColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth
      ..style = PaintingStyle.stroke;

    final double centerY = size.height / 2;
    final double maxBarHeight = size.height * 0.88;
    final double step = barWidth + barGap;
    final int numBars = (size.width / step).floor().clamp(1, 400);

    for (int i = 0; i < numBars; i++) {
      final double x = i * step + barWidth / 2;
      final double normIndex = (i / numBars) * (samples.length - 1);
      final int sampleIdx = normIndex.floor().clamp(0, samples.length - 1);
      final double sample = samples[sampleIdx].clamp(0.08, 1.0);

      final double barHeight = (sample * maxBarHeight).clamp(4.0, maxBarHeight);
      final double topY = centerY - barHeight / 2;
      final double bottomY = centerY + barHeight / 2;

      final bool isPlayed = (x / size.width) <= progress;
      final Paint currentPaint = isPlayed ? playedPaint : unplayedPaint;

      canvas.drawLine(Offset(x, topY), Offset(x, bottomY), currentPaint);
    }

    // Draw Fade In visual envelope triangle/gradient
    if (fadeInFraction > 0.001) {
      final double fadeInWidth = (size.width * fadeInFraction).clamp(2.0, size.width);
      final Path inPath = Path()
        ..moveTo(0, 0)
        ..lineTo(fadeInWidth, 0)
        ..lineTo(0, size.height)
        ..close();

      final Paint inPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFF9318).withValues(alpha: 0.38),
            const Color(0xFFFF9318).withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, fadeInWidth, size.height));

      canvas.drawPath(inPath, inPaint);
    }

    // Draw Fade Out visual envelope triangle/gradient
    if (fadeOutFraction > 0.001) {
      final double fadeOutWidth = (size.width * fadeOutFraction).clamp(2.0, size.width);
      final double startX = size.width - fadeOutWidth;
      final Path outPath = Path()
        ..moveTo(startX, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..close();

      final Paint outPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFFF9318).withValues(alpha: 0.05),
            const Color(0xFFFF9318).withValues(alpha: 0.38),
          ],
        ).createShader(Rect.fromLTWH(startX, 0, fadeOutWidth, size.height));

      canvas.drawPath(outPath, outPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.progress != progress ||
        oldDelegate.fadeInFraction != fadeInFraction ||
        oldDelegate.fadeOutFraction != fadeOutFraction ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.playedColor != playedColor;
  }
}
