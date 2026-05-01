import 'package:flutter/material.dart';
import 'dart:math';

/// Shared Custom Painter for Background Shapes used across the Shapes module
class AnimatedShapeBackground extends StatelessWidget {
  final Animation<double> animation;
  final List<Color>? colors;

  const AnimatedShapeBackground({
    super.key,
    required this.animation,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ShapeBackgroundPainter(
            progress: animation.value,
            customColors: colors,
          ),
        );
      },
    );
  }
}

class ShapeBackgroundPainter extends CustomPainter {
  final double progress;
  final List<Color>? customColors;

  ShapeBackgroundPainter({
    required this.progress,
    this.customColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Default colors if none provided
    final colors = customColors ?? [
      const Color(0xFFFFCDD2),
      const Color(0xFFBBDEFB),
      const Color(0xFFC8E6C9),
      const Color(0xFFFFF9C4),
      const Color(0xFFE1BEE7),
      const Color(0xFFFFE0B2),
    ];

    _drawShape(canvas, size, colors[0], 0.1, 0.2, 40, progress, isCircle: true);
    _drawShape(canvas, size, colors[1], 0.8, 0.15, 60, progress * 1.2, isCircle: false);
    _drawShape(canvas, size, colors[2], 0.2, 0.8, 50, progress * 0.8, isCircle: true);
    _drawShape(canvas, size, colors[3], 0.85, 0.75, 45, progress * 1.5, isCircle: false);
    _drawShape(canvas, size, colors[4], 0.5, 0.1, 35, progress * 0.9, isCircle: true);
    _drawShape(canvas, size, colors[5], 0.1, 0.6, 30, progress * 1.1, isCircle: false);
  }

  void _drawShape(Canvas canvas, Size size, Color color, double xFactor, double yFactor, double baseSize, double animValue, {required bool isCircle}) {
    final paint = Paint()..color = color.withOpacity(0.3);
    final offset = Offset(
      size.width * xFactor + sin(animValue * 2 * pi) * 20,
      size.height * yFactor + cos(animValue * 2 * pi) * 20,
    );
    
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(animValue * 0.2);
    
    if (isCircle) {
      canvas.drawCircle(Offset.zero, baseSize + sin(animValue * pi) * 10, paint);
    } else {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: baseSize + cos(animValue * pi) * 10,
        height: baseSize + cos(animValue * pi) * 10,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ShapeBackgroundPainter oldDelegate) => oldDelegate.progress != progress;
}
