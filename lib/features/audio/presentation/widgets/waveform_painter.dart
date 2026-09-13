import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color waveColor;
  final Color playedColor;
  final double progress; // 0.0 to 1.0
  final double barWidth;
  final double barGap;

  const WaveformPainter({
    required this.samples,
    this.waveColor = const Color(0xFFFF4B72),
    this.playedColor = const Color(0xFFC2185B),
    this.progress = 0.0,
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
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.progress != progress ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.playedColor != playedColor;
  }
}
