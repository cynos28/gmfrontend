import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An animated mascot widget with bouncing animation and speech bubble.
/// 
/// Creates an engaging character that bounces and shows a "Let's Play" message.
/// Designed for gaming intro screens and splash pages.
/// 
/// Example usage:
/// ```dart
/// AnimatedMascot(
///   mascotImage: 'assets/symbols/gamingCat.png',
///   speechText: "Let's Play",
///   bounceHeight: 15,
/// )
/// ```
class AnimatedMascot extends StatefulWidget {
  /// Asset path for the mascot image
  final String mascotImage;
  
  /// Text to display in the speech bubble
  final String speechText;
  
  /// Maximum bounce height in pixels
  final double bounceHeight;
  
  /// Duration for one complete bounce cycle
  final Duration bounceDuration;
  
  /// Size of the mascot image
  final double mascotSize;
  
  /// Callback when mascot is tapped
  final VoidCallback? onTap;

  const AnimatedMascot({
    super.key,
    required this.mascotImage,
    this.speechText = "Let's Play",
    this.bounceHeight = 15,
    this.bounceDuration = const Duration(milliseconds: 1200),
    this.mascotSize = 300,
    this.onTap,
  });

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _bubbleController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _bubbleOpacityAnimation;
  late final Animation<Offset> _bubbleSlideAnimation;

  bool _isPressed = false;
  
  // Timer for delayed bubble appearance (needed for proper disposal)
  Timer? _delayedBubbleTimer;

  @override
  void initState() {
    super.initState();
    _initBounceAnimations();
    _initBubbleAnimations();
    
    _bounceController.repeat(reverse: true);
    
    // Delay bubble appearance for staggered effect
    _delayedBubbleTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _bubbleController.forward();
      }
    });
  }

  void _initBounceAnimations() {
    _bounceController = AnimationController(
      vsync: this,
      duration: widget.bounceDuration,
    );

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: widget.bounceHeight,
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initBubbleAnimations() {
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bubbleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _bubbleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _delayedBubbleTimer?.cancel();
    _bounceController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _bubbleController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.mascotSize,
          height: widget.mascotSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Mascot with gesture and integrated bubble
              _buildMascot(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMascot() {
    final bounceOffset = -_bounceAnimation.value;
    final scale = _scaleAnimation.value * (_isPressed ? 0.95 : 1.0);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Transform.translate(
        offset: Offset(0, bounceOffset), // Bounce applied to both cat and card
        child: Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Mascot Image
              Image.asset(
                widget.mascotImage,
                width: widget.mascotSize,
                height: widget.mascotSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: widget.mascotSize,
                  height: widget.mascotSize,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: widget.mascotSize * 0.5,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              
              // Speech bubble (Note Card) - Moves with the cat
              Positioned(
                left: widget.mascotSize * 0.28,
                bottom: widget.mascotSize * 0.18,
                child: FadeTransition( // Removed SlideTransition, kept Fade
                  opacity: _bubbleOpacityAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Beige/paper color
                      borderRadius: BorderRadius.circular(4), // Small radius for paper look
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.speechText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildAnimatedEmoji() {
    return Transform.rotate(
      angle: math.sin(_bounceController.value * math.pi * 2) * 0.2,
      child: const Text(
        '🎮',
        style: TextStyle(fontSize: 18),
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
