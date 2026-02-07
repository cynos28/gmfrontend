import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A widget that creates a 3D-like parallax scrolling background effect.
/// 
/// Uses multiple layers moving at different speeds to create depth illusion.
/// The background image moves subtly to give a sense of motion and immersion.
/// 
/// Example usage:
/// ```dart
/// GamingParallaxBackground(
///   backgroundImage: 'assets/symbols/gaminBack.png',
///   parallaxIntensity: 0.02,
///   driftDuration: const Duration(seconds: 8),
/// )
/// ```
class GamingParallaxBackground extends StatefulWidget {
  /// The asset path for the background image
  final String backgroundImage;
  
  /// Intensity of the parallax effect (0.0 to 0.1 recommended)
  final double parallaxIntensity;
  
  /// Duration for one complete drift cycle
  final Duration driftDuration;
  
  /// Optional overlay color with opacity for depth effect
  final Color? overlayColor;

  const GamingParallaxBackground({
    super.key,
    required this.backgroundImage,
    this.parallaxIntensity = 0.02,
    this.driftDuration = const Duration(seconds: 8),
    this.overlayColor,
  });

  @override
  State<GamingParallaxBackground> createState() => _GamingParallaxBackgroundState();
}

class _GamingParallaxBackgroundState extends State<GamingParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _driftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.driftDuration,
    );

    // Creates a smooth back-and-forth drift animation
    _driftAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final driftOffset = _driftAnimation.value * widget.parallaxIntensity;
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background layer - moves slowest
            Transform.translate(
              offset: Offset(
                driftOffset * MediaQuery.of(context).size.width * 0.5,
                math.sin(_controller.value * math.pi * 2) * 5,
              ),
              child: Transform.scale(
                scale: 1.1, // Slightly larger to prevent edge visibility during drift
                child: Image.asset(
                  widget.backgroundImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF87CEEB), // Sky blue fallback
                    child: const Center(
                      child: Icon(Icons.landscape, size: 100, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
            
            // Gradient overlay for depth
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    widget.overlayColor ?? Colors.black.withOpacity(0.1),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            
            // Animated light rays overlay (subtle shimmer effect)
            Opacity(
              opacity: 0.08 + (0.04 * math.sin(_controller.value * math.pi * 4)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      0.3 + (driftOffset * 0.5),
                      -0.5,
                    ),
                    radius: 1.5,
                    colors: const [
                      Colors.white,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom AnimatedBuilder that matches the Flutter pattern
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
