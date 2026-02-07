import 'package:flutter/material.dart';

/// A wrapper widget that gives a 3D pressed effect to an image button.
class ThreeDGameButton extends StatefulWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final double size;

  const ThreeDGameButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    this.size = 100,
  });

  @override
  State<ThreeDGameButton> createState() => _ThreeDGameButtonState();
}

class _ThreeDGameButtonState extends State<ThreeDGameButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Continuous subtle breathing animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _isPressed ? 0.95 : _scaleAnimation.value;
          final elevation = _isPressed ? 2.0 : 10.0;
          final offsetY = _isPressed ? 8.0 : 0.0;

          return Transform.translate(
            // When pressed, move down to simulate button compression
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Shadow removed as requested
                ),
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
