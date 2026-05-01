import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart' hide AnimatedBuilder;
import 'package:ganithamithura/screens/symbol/gaming/character_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/gaming/level_selection_screen.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playWelcomeSound();
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

  Future<void> _playWelcomeSound() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('audio_enabled') ?? true;
    final volume = prefs.getDouble('audio_volume') ?? 0.7;
    if (isEnabled && mounted) {
      _audioPlayer.setVolume(volume);
      _audioPlayer.play(AssetSource('symbols/sounds/game-bonus-144751.mp3.mpeg'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() async {
    // Play game start sound
    _audioPlayer.play(AssetSource('symbols/sounds/game_start.mp3'));
    
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user != null) {
        final character = await SymbolService.instance.getCharacter(user.id);
        if (character != null) {
          Get.back(); // close loading
          Get.off(
            () => const LevelSelectionScreen(),
            transition: Transition.rightToLeftWithFade,
            duration: const Duration(milliseconds: 500),
          );
          return;
        }
      }
    } catch (e) {
       print("Error fetching character: $e");
    }
    
    Get.back(); // close loading
    Get.off(
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

          // Boy Image
          Positioned(
            left: -20,
            bottom: -10,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-100 * (1 - _fadeAnimation.value), 0),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Image.asset(
                      'assets/symbols/game/gamingboy.png',
                      height: MediaQuery.of(context).size.height * 0.45,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }
            ),
          ),

          // Symbols Image
          Positioned(
            right: 10,
            bottom: 20,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(100 * (1 - _fadeAnimation.value), 50 * (1 - _fadeAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Image.asset(
                      'assets/symbols/game/symboles.png',
                      height: MediaQuery.of(context).size.height * 0.35,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }
            ),
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

                const SizedBox(height: 10),

                // "Let's Play" Card with Icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4DCC8).withOpacity(0.85), // Light Mint Green
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Let's",
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 32,
                                      color: const Color(0xFF33583E), // Dark Green
                                    ),
                                  ),
                                  Text(
                                    "Play",
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 64,
                                      color: const Color(0xFF33583E), // Dark Green
                                      height: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              // Game Icon
                              Image.asset(
                                'assets/symbols/game/gameIcon.png',
                                width: 70,
                                height: 70,
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

                const SizedBox(height: 40),

                // Middle Text
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Text(
                          "The free , fun and\neffective game to your\nkids early growth",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.alfaSlabOne(
                            fontSize: 22,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                ),

                const SizedBox(height: 30),

                // Get Started Button
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFACC54), Color(0xFFC49A24)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _onGetStartedPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 24,
                                color: Colors.black,
                                letterSpacing: 1.2,
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
