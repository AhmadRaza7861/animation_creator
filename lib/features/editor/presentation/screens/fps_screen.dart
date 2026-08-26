import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';

class FpsScreen extends StatefulWidget {
  final int initialFps;

  const FpsScreen({
    super.key,
    required this.initialFps,
  });

  @override
  State<FpsScreen> createState() => _FpsScreenState();
}

class _FpsScreenState extends State<FpsScreen> {
  late int _selectedFps;
  late FixedExtentScrollController _scrollController;
  Timer? _timer;
  int _currentFrame = 0;

  // 12-frame squash-and-stretch bounce cycle data
  static const List<Map<String, double>> _bounceFrames = [
    {'y': 0.0, 'w': 40.0, 'h': 40.0},
    {'y': 15.0, 'w': 38.0, 'h': 42.0},
    {'y': 45.0, 'w': 36.0, 'h': 44.0},
    {'y': 85.0, 'w': 36.0, 'h': 44.0},
    {'y': 125.0, 'w': 38.0, 'h': 42.0},
    {'y': 150.0, 'w': 46.0, 'h': 30.0}, // squashed on ground
    {'y': 125.0, 'w': 36.0, 'h': 44.0}, // stretch rebound
    {'y': 85.0, 'w': 38.0, 'h': 42.0},
    {'y': 45.0, 'w': 40.0, 'h': 40.0},
    {'y': 20.0, 'w': 40.0, 'h': 40.0},
    {'y': 5.0, 'w': 40.0, 'h': 40.0},
    {'y': 0.0, 'w': 40.0, 'h': 40.0},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFps = widget.initialFps;
    _scrollController = FixedExtentScrollController(initialItem: _selectedFps - 1);
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();
    final intervalMs = (1000 / _selectedFps).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _bounceFrames.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final frameData = _bounceFrames[_currentFrame];

    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.darkText),
          onPressed: () {
            Navigator.pop(context, _selectedFps);
          },
        ),
        title: const Text(
          'Frames per second',
          style: TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: ColorConstants.background,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview Section
            Expanded(
              flex: 4,
              child: Container(
                color: ColorConstants.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Canvas Area for bouncing ball
                      SizedBox(
                        height: 240,
                        width: 300,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Ground Line
                            Positioned(
                              bottom: 30,
                              left: 30,
                              right: 30,
                              child: Container(
                                height: 2,
                                color: Colors.black12,
                              ),
                            ),
                            // Shadow of the ball
                            Positioned(
                              bottom: 26,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                width: (60.0 - frameData['y']! * 0.25).clamp(10.0, 70.0),
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(
                                    (0.15 - (frameData['y']! * 0.0008)).clamp(0.01, 0.25),
                                  ),
                                  borderRadius: const BorderRadius.all(Radius.elliptical(50, 8)),
                                ),
                              ),
                            ),
                            // Bouncing Ball
                            Positioned(
                              top: 20 + frameData['y']!,
                              child: Container(
                                width: frameData['w'],
                                height: frameData['h'],
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black54, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Currently you would need to draw $_selectedFps frames to make 1 second',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Picker Section
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[50],
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection Highlight Borders
                    IgnorePointer(
                      child: Container(
                        height: 54,
                        decoration: const BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: ColorConstants.accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _scrollController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedFps = index + 1;
                        });
                        _startAnimation();
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 30,
                        builder: (context, index) {
                          final value = index + 1;
                          final isSelected = value == _selectedFps;

                          return Center(
                            child: Text(
                              '$value',
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? ColorConstants.accent : Colors.black45,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
