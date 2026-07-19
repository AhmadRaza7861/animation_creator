import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../repositories/project_repository.dart';
import 'projects_screen.dart';

class SplashScreen extends StatefulWidget {
  final ProjectRepository repository;
  const SplashScreen({super.key, required this.repository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProjectsScreen(repository: widget.repository),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              CustomPaint(
                size: const Size(120, 120),
                painter: ClipaxLogoPainter(),
              ),
              const SizedBox(height: 24),
              // Brand Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'clip',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3C3043),
                      letterSpacing: -1.5,
                      fontFamily: 'Outfit', // Uses fallback if font family not present
                    ),
                  ),
                  Text(
                    'ax',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF9114),
                      letterSpacing: -1.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Subtitle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9114),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ANIMATE ANYTHING',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8E8895),
                      letterSpacing: 3.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9114),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClipaxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Orange Film Strip Arc on the left
    final orangePaint = Paint()
      ..color = const Color(0xFFFF9114)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.2
      ..strokeCap = StrokeCap.round;

    final outerRect = Rect.fromCircle(
      center: center,
      radius: radius - orangePaint.strokeWidth / 2,
    );

    // Arc covering left, top, bottom, leaving right side open (approx from 100 deg to 260 deg, i.e. 160 deg sweep)
    // In radians: start from 0.55 * pi, sweep 1.5 * pi
    canvas.drawArc(
      outerRect,
      0.6 * math.pi,
      1.55 * math.pi,
      false,
      orangePaint,
    );

    // 2. Draw sprocket holes in the film strip
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw 4 rounded sprocket holes along the arc
    // We place them at specific angles along the left side: 0.8*pi, 1.1*pi, 1.4*pi, 1.7*pi
    final holeRadius = radius - orangePaint.strokeWidth / 2;
    final holeWidth = orangePaint.strokeWidth * 0.5;
    final holeHeight = orangePaint.strokeWidth * 0.25;
    final holeAngles = [0.8 * math.pi, 1.1 * math.pi, 1.4 * math.pi, 1.7 * math.pi];

    for (final angle in holeAngles) {
      final holeCenter = center + Offset(
        holeRadius * math.cos(angle),
        holeRadius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(holeCenter.dx, holeCenter.dy);
      // Rotate the hole to align with the tangent of the circle
      canvas.rotate(angle + math.pi / 2);
      
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: holeWidth,
        height: holeHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.02)),
        holePaint,
      );
      canvas.restore();
    }

    // 3. Draw Dark Purple Play Button on the right
    final darkPurplePaint = Paint()
      ..color = const Color(0xFF3C3043)
      ..style = PaintingStyle.fill;

    // Vertices of the triangle play icon
    final path = Path();
    
    // Shift slightly to the right of the center
    final triangleCenter = center + Offset(size.width * 0.08, 0);
    final triSize = size.width * 0.35;

    // Draw equilateral triangle pointing right
    path.moveTo(triangleCenter.dx - triSize * 0.35, triangleCenter.dy - triSize * 0.6);
    path.lineTo(triangleCenter.dx - triSize * 0.35, triangleCenter.dy + triSize * 0.6);
    path.lineTo(triangleCenter.dx + triSize * 0.65, triangleCenter.dy);
    path.close();

    // Use a nice rounded join path to make it look smooth and premium
    final trianglePaint = Paint()
      ..color = const Color(0xFF3C3043)
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    // We can draw it as a filled path
    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
