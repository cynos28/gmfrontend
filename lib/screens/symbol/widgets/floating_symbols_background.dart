import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ganithamithura/utils/constants.dart';

class FloatingSymbolsBackground extends StatefulWidget {
  const FloatingSymbolsBackground({super.key});

  @override
  State<FloatingSymbolsBackground> createState() => _FloatingSymbolsBackgroundState();
}

class _FloatingSymbolsBackgroundState extends State<FloatingSymbolsBackground>
    with SingleTickerProviderStateMixin {
  final List<FloatingSymbolData> _symbols = [];
  final Random _random = Random();
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    // Generate 15 random symbols (Reduced count for performance)
    for (int i = 0; i < 15; i++) {
      _symbols.add(_generateSymbolData());
    }
    
    // Use Ticker for continuous monotonic time (no loop reset jumps)
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0; // Time in seconds
      });
    });
    _ticker.start();
  }

  FloatingSymbolData _generateSymbolData() {
    final symbols = ['+', '−', '×', '÷', '=', '?', '%'];
    final colors = [
      const Color(AppColors.measurementIcon), // Orange
      const Color(AppColors.numberIcon),      // Purple
      const Color(AppColors.shapeIcon),       // Green
      const Color(AppColors.symbolIcon),      // Rose
      const Color(0xFF2196F3),               // Blue (Info)
      const Color(0xFFFFC107),               // Amber (Warning)
    ];
    
    return FloatingSymbolData(
      symbol: symbols[_random.nextInt(symbols.length)],
      color: colors[_random.nextInt(colors.length)], // Random color
      size: 20.0 + _random.nextInt(40),
      initialX: _random.nextDouble(),
      initialY: _random.nextDouble(),
      speed: 0.05 + _random.nextDouble() * 0.10,
      swayAmount: 0.02 + _random.nextDouble() * 0.05,
      swaySpeed: 1.0 + _random.nextDouble() * 2.0,
      opacity: 0.3 + _random.nextDouble() * 0.3, // Increased opacity for better visibility of colors
      rotationSpeed: (_random.nextBool() ? 1 : -1) * (0.1 + _random.nextDouble() * 0.2),
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
      children: _symbols.map((data) {
        // Continuous upward movement
        // Position = initial - (speed * time)
        // Modulo 1.0 wraps it around the screen continuously
        double currentY = (data.initialY - _time * data.speed) % 1.0;
        if (currentY < 0) currentY += 1.0;

        // Horizontal sway
        double currentX = (data.initialX + 
            math.sin((_time * pi * data.swaySpeed) + (data.initialY * 10)) * 
            data.swayAmount);
            
        // Rotation
        double rotation = _time * pi * data.rotationSpeed;

        return Positioned(
          top: currentY * MediaQuery.of(context).size.height,
          left: currentX * MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: data.opacity,
              child: Text(
                data.symbol,
                style: TextStyle(
                  fontSize: data.size,
                  fontWeight: FontWeight.w900,
                  color: data.color, // Use the random color
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FloatingSymbolData {
  final String symbol;
  final Color color; // New property
  final double size;
  final double initialX;
  final double initialY;
  final double speed;
  final double swayAmount;
  final double swaySpeed;
  final double opacity;
  final double rotationSpeed;

  FloatingSymbolData({
    required this.symbol,
    required this.color, // New required parameter
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
