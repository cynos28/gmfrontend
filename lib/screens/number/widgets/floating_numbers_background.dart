import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ganithamithura/utils/constants.dart';

class FloatingNumbersBackground extends StatefulWidget {
  const FloatingNumbersBackground({super.key});

  @override
  State<FloatingNumbersBackground> createState() => _FloatingNumbersBackgroundState();
}

class _FloatingNumbersBackgroundState extends State<FloatingNumbersBackground>
    with SingleTickerProviderStateMixin {
  final List<FloatingNumberData> _numbers = [];
  final Random _random = Random();
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    // Generate 15 random numbers
    for (int i = 0; i < 15; i++) {
      _numbers.add(_generateNumberData());
    }
    
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  FloatingNumberData _generateNumberData() {
    final numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    final colors = [
      const Color(AppColors.numberIcon),      // Purple
      const Color(AppColors.shapeIcon),       // Green
      const Color(AppColors.measurementIcon), // Orange
      const Color(0xFFFFB74D),               // Yellow/Amber
      const Color(0xFF64B5F6),               // Light Blue
      const Color(0xFFE57373),               // Red/Rose
    ];
    
    return FloatingNumberData(
      digit: numbers[_random.nextInt(numbers.length)],
      color: colors[_random.nextInt(colors.length)],
      size: 30.0 + _random.nextInt(50), // slightly larger numbers
      initialX: _random.nextDouble(),
      initialY: _random.nextDouble(),
      speed: 0.04 + _random.nextDouble() * 0.08,
      swayAmount: 0.02 + _random.nextDouble() * 0.04,
      swaySpeed: 1.0 + _random.nextDouble() * 1.5,
      opacity: 0.15 + _random.nextDouble() * 0.25, // Soft opacity
      rotationSpeed: (_random.nextBool() ? 1 : -1) * (_random.nextDouble() * 0.1), // Gentle rotation
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ticker.isActive) return const SizedBox.shrink();

    return Stack(
      children: _numbers.map((data) {
        double currentY = (data.initialY - _time * data.speed) % 1.0;
        if (currentY < 0) currentY += 1.0;

        double currentX = (data.initialX + 
            math.sin((_time * pi * data.swaySpeed) + (data.initialY * 10)) * 
            data.swayAmount);
            
        double rotation = _time * pi * data.rotationSpeed;

        return Positioned(
          top: currentY * MediaQuery.of(context).size.height,
          left: currentX * MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: data.opacity,
              child: Text(
                data.digit,
                style: TextStyle(
                  fontSize: data.size,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Staatliches', // Optional: if Staatliches is loaded
                  color: data.color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FloatingNumberData {
  final String digit;
  final Color color;
  final double size;
  final double initialX;
  final double initialY;
  final double speed;
  final double swayAmount;
  final double swaySpeed;
  final double opacity;
  final double rotationSpeed;

  FloatingNumberData({
    required this.digit,
    required this.color,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.swayAmount,
    required this.swaySpeed,
    required this.opacity,
    required this.rotationSpeed,
  });
}
