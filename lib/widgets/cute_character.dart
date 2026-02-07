import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Cute blob character widget for kid-friendly UI
class CuteCharacter extends StatefulWidget {
  final Color color;
  final double size;
  final String? emoji;
  final bool animate;

  const CuteCharacter({
    Key? key,
    required this.color,
    this.size = 80,
    this.emoji,
    this.animate = true,
  }) : super(key: key);

  @override
  State<CuteCharacter> createState() => _CuteCharacterState();
}

class _CuteCharacterState extends State<CuteCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);

      _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget character = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _BlobPainter(color: widget.color),
      child: widget.emoji != null
          ? Center(
              child: Text(
                widget.emoji!,
                style: TextStyle(fontSize: widget.size * 0.4),
              ),
            )
          : null,
    );

    if (widget.animate) {
      return AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: child,
          );
        },
        child: character,
      );
    }

    return character;
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;

  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2.5;

    // Create organic blob shape
    path.moveTo(centerX + radius, centerY);

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final nextAngle = ((i + 1) * math.pi / 4);

      final r1 = radius + (i % 2 == 0 ? 5 : -5);
      final r2 = radius + ((i + 1) % 2 == 0 ? 5 : -5);

      final x1 = centerX + r1 * math.cos(angle);
      final y1 = centerY + r1 * math.sin(angle);

      final x2 = centerX + r2 * math.cos(nextAngle);
      final y2 = centerY + r2 * math.sin(nextAngle);

      final cpx = centerX + (r1 + r2) / 2 * math.cos(angle + math.pi / 8);
      final cpy = centerY + (r1 + r2) / 2 * math.sin(angle + math.pi / 8);

      path.quadraticBezierTo(cpx, cpy, x2, y2);
    }

    path.close();
    canvas.drawPath(path, paint);

    // Add shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 4, false);

    // Draw cute face
    final facePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Eyes
    final eyeY = centerY - radius * 0.2;
    final eyeSpacing = radius * 0.4;
    canvas.drawCircle(
      Offset(centerX - eyeSpacing, eyeY),
      radius * 0.12,
      facePaint,
    );
    canvas.drawCircle(
      Offset(centerX + eyeSpacing, eyeY),
      radius * 0.12,
      facePaint,
    );

    // Smile
    final smilePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(centerX - radius * 0.3, centerY + radius * 0.2);
    smilePath.quadraticBezierTo(
      centerX,
      centerY + radius * 0.4,
      centerX + radius * 0.3,
      centerY + radius * 0.2,
    );

    canvas.drawPath(smilePath, smilePaint);

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = Colors.pink.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX - radius * 0.6, centerY + radius * 0.1),
      radius * 0.15,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(centerX + radius * 0.6, centerY + radius * 0.1),
      radius * 0.15,
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pill-shaped button matching the kid-friendly design
class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final bool isSelected;
  final IconData? icon;
  final double? width;

  const PillButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color = const Color(0xFF6C5CE7),
    this.textColor,
    this.isSelected = false,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: isSelected ? color : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSelected
                        ? (textColor ?? Colors.white)
                        : color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected
                          ? (textColor ?? Colors.white)
                          : color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cute card with character
class CuteCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;

  const CuteCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
