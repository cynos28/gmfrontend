import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A 3D-style play button with pulsating glow and scale animations.
/// 
/// Creates an eye-catching, interactive button with layered shadows,
/// gradients, and continuous pulse animation to draw attention.
/// 
/// Example usage:
/// ```dart
/// PulsatingPlayButton(
///   onPressed: () => Navigator.pushNamed(context, '/games'),
///   size: 80,
///   color: Colors.green,
/// )
/// ```
class PulsatingPlayButton extends StatefulWidget {
  /// Callback when button is pressed
  final VoidCallback onPressed;
  
  /// Diameter of the button
  final double size;
  
  /// Primary button color
  final Color color;
  
  /// Duration for one complete pulse cycle
  final Duration pulseDuration;
  
  /// Optional custom icon
  final IconData icon;

  const PulsatingPlayButton({
    super.key,
    required this.onPressed,
    this.size = 80,
    this.color = const Color(0xFF4CAF50),
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.icon = Icons.play_arrow_rounded,
  });

  @override
  State<PulsatingPlayButton> createState() => _PulsatingPlayButtonState();
}

class _PulsatingPlayButtonState extends State<PulsatingPlayButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _pressController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pressAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initPulseAnimations();
    _initPressAnimations();
    _pulseController.repeat();
  }

  void _initPulseAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initPressAnimations() {
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _pressController]),
      builder: (context, child) {
        final scale = _pulseAnimation.value * _pressAnimation.value;
        final glowOpacity = _glowAnimation.value;

        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size * 1.4,
              height: widget.size * 1.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  _buildGlowRing(glowOpacity),
                  
                  // Main button with 3D effect
                  _buildMainButton(),
                  
                  // Play icon
                  _buildIcon(),
                  
                  // Highlight overlay
                  _buildHighlight(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowRing(double opacity) {
    return Container(
      width: widget.size * 1.35,
      height: widget.size * 1.35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(opacity * 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: widget.color.withOpacity(opacity * 0.3),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final darkerColor = HSLColor.fromColor(widget.color)
        .withLightness((HSLColor.fromColor(widget.color).lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
    final lighterColor = HSLColor.fromColor(widget.color)
        .withLightness((HSLColor.fromColor(widget.color).lightness + 0.1).clamp(0.0, 1.0))
        .toColor();

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lighterColor,
            widget.color,
            darkerColor,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
        boxShadow: [
          // 3D depth shadow
          BoxShadow(
            color: darkerColor.withOpacity(0.8),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // Ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      widget.icon,
      size: widget.size * 0.55,
      color: Colors.white,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(1, 2),
        ),
      ],
    );
  }

  Widget _buildHighlight() {
    return Positioned(
      top: widget.size * 0.12,
      left: widget.size * 0.25,
      child: Container(
        width: widget.size * 0.35,
        height: widget.size * 0.15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom AnimatedBuilder that matches the Flutter pattern
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
