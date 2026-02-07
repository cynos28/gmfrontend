import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/animated_title_card.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/animated_mascot.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/pulsating_play_button.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/three_d_game_button.dart';
import 'package:ganithamithura/screens/symbol/gaming/character_selection_screen.dart';

/// Gaming Intro Screen - A visually engaging splash screen for the gaming section.
/// 
/// Features:
/// - 3D parallax background with subtle drift
/// - Swinging wooden sign title
/// - Animated bouncing cat mascot
/// - Pulsating play button
/// - Flash/shimmer overlay effects
/// 
/// This screen serves as the entry point to the gaming section from the symbols home.
class GamingIntroScreen extends StatefulWidget {
  const GamingIntroScreen({super.key});

  @override
  State<GamingIntroScreen> createState() => _GamingIntroScreenState();
}

class _GamingIntroScreenState extends State<GamingIntroScreen>
    with TickerProviderStateMixin {
  // Entrance animation controllers
  late final AnimationController _entranceController;
  late final AnimationController _flashController;
  
  // Staggered entrance animations
  late final Animation<double> _titleSlideAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _mascotSlideAnimation;
  late final Animation<double> _mascotFadeAnimation;
  late final Animation<double> _buttonScaleAnimation;
  late final Animation<double> _buttonFadeAnimation;
  
  // Flash overlay animation
  late final Animation<double> _flashAnimation;
  
  // Timer for delayed flash start (needed for proper disposal)
  Timer? _delayedFlashTimer;

  @override
  void initState() {
    super.initState();
    _initEntranceAnimations();
    _initFlashAnimation();
    
    // Start entrance animation
    _entranceController.forward();
    
    // Start periodic flash effect
    _delayedFlashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _flashController.repeat();
      }
    });
  }

  void _initEntranceAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Title entrance (0.0 - 0.4)
    _titleSlideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _titleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Mascot entrance (0.2 - 0.6)
    _mascotSlideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );
    _mascotFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Button entrance (0.4 - 0.8)
    _buttonScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.elasticOut),
      ),
    );
    _buttonFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  void _initFlashAnimation() {
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0),
        weight: 75,
      ),
    ]).animate(_flashController);
  }

  @override
  void dispose() {
    _delayedFlashTimer?.cancel();
    _entranceController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _onPlayPressed() {
    // Navigate to character selection screen
    Get.to(
      () => const CharacterSelectionScreen(),
      transition: Transition.zoom, // Fun zoom transition for gaming feel
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Parallax Background
          const GamingParallaxBackground(
            backgroundImage: 'assets/symbols/gaminBack.png',
            parallaxIntensity: 0.015,
            driftDuration: Duration(seconds: 10),
          ),

          // Layer 2: Back Button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildBackButton(),
              ),
            ),
          ),

          // Layer 3: Main Content with Entrance Animations
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              
              return SafeArea(
                child: Column(
                  children: [
                    // Removed top spacing so ropes hang from the very top
                    SizedBox(height: 0),
                    
                    // Title with slide-down animation - positioned at top-center
                    Transform.translate(
                      offset: Offset(0, _titleSlideAnimation.value),
                      child: Opacity(
                        opacity: _titleFadeAnimation.value,
                        child: Align(
                          alignment: Alignment.topCenter, // Centered horizontally
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0.0),
                            child: const AnimatedTitleCard(
                              titleImage: 'assets/symbols/gamingTitle.png',
                              titleText: 'FUN\nMATH',
                              swingAmplitude: 0.04,
                              swingDuration: Duration(milliseconds: 3000),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Spacer to push button to vertical center
                    const Spacer(),
                    

                  ],
                ),
              );
            },
          ),

          // Layer 3.2: Play Button - Absolute Center
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: Opacity(
                    opacity: _buttonFadeAnimation.value,
                    child: ThreeDGameButton(
                      key: const Key('gaming_play_button'),
                      imagePath: 'assets/symbols/gamingButton.png',
                      onPressed: _onPlayPressed,
                      size: 100,
                    ),
                  ),
                ),
              );
            },
          ),

          // Layer 3.5: Mascot (Outside SafeArea for corner positioning)
          AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              final mascotSize = (screenHeight * 0.45).clamp(250.0, 450.0);
              
              return Positioned(
                left: -50, // Push further into the corner
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, _mascotSlideAnimation.value),
                  child: Opacity(
                    opacity: _mascotFadeAnimation.value,
                    child: AnimatedMascot(
                      mascotImage: 'assets/symbols/gamingCat.png',
                      speechText: "Let's\nPlay",
                      bounceHeight: 12,
                      mascotSize: mascotSize,
                      onTap: _onPlayPressed,
                    ),
                  ),
                ),
              );
            },
          ),

          // Layer 4: Flash/Shimmer Overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-1.5, -1.5),
                      end: const Alignment(1.5, 1.5),
                      colors: [
                        Colors.white.withOpacity(_flashAnimation.value),
                        Colors.transparent,
                        Colors.white.withOpacity(_flashAnimation.value * 0.5),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        key: const Key('gaming_back_button'),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: Colors.black87,
        onPressed: () => Get.back(),
        tooltip: 'Go back',
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
