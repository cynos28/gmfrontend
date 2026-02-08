import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart' hide AnimatedBuilder;
import 'package:ganithamithura/screens/symbol/gaming/character_selection_screen.dart';

class GameWelcomeScreen extends StatefulWidget {
  const GameWelcomeScreen({super.key});

  @override
  State<GameWelcomeScreen> createState() => _GameWelcomeScreenState();
}

class _GameWelcomeScreenState extends State<GameWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() {
    Get.to(
      () => const CharacterSelectionScreen(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Reuse Parallax Background
          const GamingParallaxBackground(
            backgroundImage: 'assets/symbols/gaminBack.png',
            parallaxIntensity: 0.015,
            driftDuration: Duration(seconds: 12),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: IconButton(
                       icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                       onPressed: () => Get.back(),
                       style: IconButton.styleFrom(
                         backgroundColor: Colors.white.withOpacity(0.8),
                         shape: const CircleBorder(),
                       ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // "Let's Play" Card with Icon
                // Using Scale/Fade animation for entrance
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2D8C8).withOpacity(0.9), // Sage/Mint Green from image
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Let's",
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 32,
                                      color: const Color(0xFF2E5E4E), // Dark Green
                                    ),
                                  ),
                                  Text(
                                    "Play",
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 64,
                                      color: const Color(0xFF2E5E4E), // Dark Green
                                      height: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              // Game Icon
                              Image.asset(
                                'assets/symbols/game/gameIcon.png',
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.videogame_asset,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Get Started Button
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child:Padding(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: SizedBox(
                            width: 220,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _onGetStartedPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE6B44C), // Gold/Mustard
                                foregroundColor: Colors.black87,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 24,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
