import 'package:flutter/material.dart';

class ThreeDCharacterCard extends StatefulWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const ThreeDCharacterCard({
    super.key,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.size = 100,
  });

  @override
  State<ThreeDCharacterCard> createState() => _ThreeDCharacterCardState();
}

class _ThreeDCharacterCardState extends State<ThreeDCharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
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
          final scale = _scaleAnimation.value;
          final elevation = widget.isSelected ? 15.0 : (_isPressed ? 2.0 : 5.0);
          final borderWidth = widget.isSelected ? 4.0 : 0.0;

          return Transform.scale(
            scale: widget.isSelected ? 1.1 : scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF4CAF50), // Selection color
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: elevation,
                    offset: Offset(0, elevation / 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
