import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An animated wooden sign title card with swinging pendulum effect.
/// 
/// Creates a 3D-like hanging sign that swings gently as if suspended by ropes.
/// Includes shadow effects for depth and customizable title text.
/// 
/// Example usage:
/// ```dart
/// AnimatedTitleCard(
///   titleImage: 'assets/symbols/gamingTitle.png',
///   titleText: 'FUN MATH',
///   swingAmplitude: 0.05,
/// )
/// ```
class AnimatedTitleCard extends StatefulWidget {
  /// Asset path for the wooden sign background
  final String titleImage;
  
  /// Text to display on the sign
  final String titleText;
  
  /// Maximum swing angle in radians (0.05 = ~3 degrees)
  final double swingAmplitude;
  
  /// Duration for one complete swing cycle
  final Duration swingDuration;
  
  /// Text style for the title (optional)
  final TextStyle? textStyle;

  const AnimatedTitleCard({
    super.key,
    required this.titleImage,
    required this.titleText,
    this.swingAmplitude = 0.05,
    this.swingDuration = const Duration(milliseconds: 2500),
    this.textStyle,
  });

  @override
  State<AnimatedTitleCard> createState() => _AnimatedTitleCardState();
}

class _AnimatedTitleCardState extends State<AnimatedTitleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _swingAnimation;
  late final Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.swingDuration,
    );

    // Smooth pendulum-like swing
    _swingAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    // Shadow offset matches swing direction
    _shadowAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
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
        final swingAngle = _swingAnimation.value * widget.swingAmplitude;
        
        // Calculate responsive size based on screen width - increased to 1.1x
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = screenWidth * 1.1; // Make it extra large as requested
        final cardHeight = cardWidth * 0.55; // Slightly taller aspect ratio

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gray lines (ropes) removed as requested
            // _buildRopes(swingAngle), 
            
            // The sign with swing transform
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateZ(swingAngle),
              child: Container(
                decoration: const BoxDecoration(), // Removed box shadow
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wooden sign image - Responsive size
                    Image.asset(
                      widget.titleImage,
                      width: cardWidth,
                      height: cardHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF5D3A1A),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    
                    // Title text overlay - Perfectly Centered
                    Padding(
                      padding: const EdgeInsets.only(top: 20), // Slight top padding for visual center on the wood texture
                      child: Text(
                        widget.titleText,
                        textAlign: TextAlign.center,
                        style: widget.textStyle ?? GoogleFonts.luckiestGuy(
                          fontSize: cardWidth * 0.15, // Adjusted font size
                          height: 1.0, 
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [], 
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRopes(double swingAngle) {
    return Transform.rotate(
      angle: swingAngle * 0.3,
      child: SizedBox(
        width: 200,
        height: 25,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRope(),
            _buildRope(),
          ],
        ),
      ),
    );
  }

  Widget _buildRope() {
    return Container(
      width: 3,
      height: 25,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B7355),
            const Color(0xFFA0826D),
          ],
        ),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
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
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
