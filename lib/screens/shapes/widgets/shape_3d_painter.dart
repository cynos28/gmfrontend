import 'package:flutter/material.dart';
import 'dart:math' as math;

class Shape3DPainter extends CustomPainter {
  final String shapeName;
  final Color shapeColor;
  final double rotationAngle;

  Shape3DPainter({
    required this.shapeName,
    required this.shapeColor,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = shapeColor;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    switch (shapeName) {
      case 'Cube':
        _drawCube(canvas, center, size.width * 0.3, paint, strokePaint);
        break;
      case 'Sphere':
        _drawSphere(canvas, center, size.width * 0.3, paint, strokePaint);
        break;
      case 'Pyramid':
        _drawPyramid(canvas, center, size.width * 0.3, paint, strokePaint);
        break;
      case 'Cone':
        _drawCone(canvas, center, size.width * 0.3, paint, strokePaint);
        break;
      case 'Cylinder':
        _drawCylinder(canvas, center, size.width * 0.3, paint, strokePaint);
        break;
    }
  }

  void _drawCube(Canvas canvas, Offset center, double size, Paint paint, Paint strokePaint) {
    final frontFace = Path()
      ..moveTo(center.dx - size / 2, center.dy - size / 2)
      ..lineTo(center.dx + size / 2, center.dy - size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx - size / 2, center.dy + size / 2)
      ..close();

    // Draw front face
    canvas.drawPath(frontFace, paint..color = shapeColor);
    canvas.drawPath(frontFace, strokePaint);

    // Draw top face (3D effect)
    final topFace = Path()
      ..moveTo(center.dx - size / 2, center.dy - size / 2)
      ..lineTo(center.dx - size / 4, center.dy - size / 1.5)
      ..lineTo(center.dx + size / 1.3, center.dy - size / 1.5)
      ..lineTo(center.dx + size / 2, center.dy - size / 2)
      ..close();

    canvas.drawPath(topFace, paint..color = shapeColor.withOpacity(0.7));
    canvas.drawPath(topFace, strokePaint);

    // Draw right face
    final rightFace = Path()
      ..moveTo(center.dx + size / 2, center.dy - size / 2)
      ..lineTo(center.dx + size / 1.3, center.dy - size / 1.5)
      ..lineTo(center.dx + size / 1.3, center.dy + size / 1.7)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..close();

    canvas.drawPath(rightFace, paint..color = shapeColor.withOpacity(0.5));
    canvas.drawPath(rightFace, strokePaint);
  }

  void _drawSphere(Canvas canvas, Offset center, double size, Paint paint, Paint strokePaint) {
    // Main sphere
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 2, strokePaint);

    // Add shading effect
    final shadePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          shapeColor.withOpacity(1.0),
          shapeColor.withOpacity(0.5),
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size / 2));

    canvas.drawCircle(center, size / 2, shadePaint);

    // Draw horizontal circles for 3D effect
    for (int i = 1; i <= 3; i++) {
      final y = center.dy - size / 2 + (size / 4) * i;
      final radiusAtY = size / 2 * math.sin(math.acos((y - center.dy) / (size / 2)));
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, y),
          width: radiusAtY * 2,
          height: radiusAtY * 0.3,
        ),
        strokePaint,
      );
    }
  }

  void _drawPyramid(Canvas canvas, Offset center, double size, Paint paint, Paint strokePaint) {
    // Base
    final base = Path()
      ..moveTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 1.5, center.dy + size / 3)
      ..lineTo(center.dx - size / 3, center.dy + size / 3)
      ..close();

    canvas.drawPath(base, paint..color = shapeColor.withOpacity(0.6));
    canvas.drawPath(base, strokePaint);

    // Front face
    final frontFace = Path()
      ..moveTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx, center.dy - size / 2)
      ..close();

    canvas.drawPath(frontFace, paint..color = shapeColor);
    canvas.drawPath(frontFace, strokePaint);

    // Right face
    final rightFace = Path()
      ..moveTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 1.5, center.dy + size / 3)
      ..lineTo(center.dx, center.dy - size / 2)
      ..close();

    canvas.drawPath(rightFace, paint..color = shapeColor.withOpacity(0.7));
    canvas.drawPath(rightFace, strokePaint);
  }

  void _drawCone(Canvas canvas, Offset center, double size, Paint paint, Paint strokePaint) {
    // Base ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size / 2),
        width: size,
        height: size * 0.3,
      ),
      paint..color = shapeColor.withOpacity(0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size / 2),
        width: size,
        height: size * 0.3,
      ),
      strokePaint,
    );

    // Left face
    final leftFace = Path()
      ..moveTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx, center.dy - size / 2)
      ..lineTo(center.dx, center.dy + size / 2)
      ..close();

    canvas.drawPath(leftFace, paint..color = shapeColor.withOpacity(0.8));
    canvas.drawPath(leftFace, strokePaint);

    // Right face
    final rightFace = Path()
      ..moveTo(center.dx, center.dy - size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2)
      ..lineTo(center.dx, center.dy + size / 2)
      ..close();

    canvas.drawPath(rightFace, paint..color = shapeColor);
    canvas.drawPath(rightFace, strokePaint);
  }

  void _drawCylinder(Canvas canvas, Offset center, double size, Paint paint, Paint strokePaint) {
    // Top ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size / 2),
        width: size,
        height: size * 0.3,
      ),
      paint..color = shapeColor.withOpacity(0.7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size / 2),
        width: size,
        height: size * 0.3,
      ),
      strokePaint,
    );

    // Cylinder body
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size,
      ),
      paint..color = shapeColor,
    );

    // Side borders
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy - size / 2),
      Offset(center.dx - size / 2, center.dy + size / 2),
      strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx + size / 2, center.dy - size / 2),
      Offset(center.dx + size / 2, center.dy + size / 2),
      strokePaint,
    );

    // Bottom ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size / 2),
        width: size,
        height: size * 0.3,
      ),
      paint..color = shapeColor.withOpacity(0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size / 2),
        width: size,
        height: size * 0.3,
      ),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant Shape3DPainter oldDelegate) {
    return oldDelegate.shapeName != shapeName ||
        oldDelegate.shapeColor != shapeColor ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
