import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';

import 'package:ganithamithura/screens/symbol/gaming/symbol_dashboard_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CongratulationsScreen extends StatefulWidget {
  final int score;
  final int level;

  const CongratulationsScreen({
    super.key, 
    required this.score, 
    required this.level,
  });

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playCongratsSound();
  }

  Future<void> _playCongratsSound() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('audio_enabled') ?? true;
    final volume = prefs.getDouble('audio_volume') ?? 0.7;
    if (isEnabled && mounted) {
      _audioPlayer.setVolume(volume);
      _audioPlayer.play(AssetSource('symbols/sounds/congratulations.mp3.mpeg'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const GamingParallaxBackground(
            backgroundImage: 'assets/symbols/gaminBack.png',
            parallaxIntensity: 0.015,
            driftDuration: Duration(seconds: 15),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6447),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.home_outlined, color: Colors.black, size: 40),
                          onPressed: () => Get.offAllNamed('/home'),
                        ),
                      ),
                      
                      // Score Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDAA520),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.score}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Wooden Board Image Container
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/symbols/gaminBack.png', // Temporary fallback, actually wooden board if you had one.
                      // Since we don't have a specific board asset, I'll simulate a wooden board with UI.
                      width: 0, height: 0, // hide this placeholder
                    ),
                    Container(
                      width: 300,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC79860), // Wooden color
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF5D4037), width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Congratulations',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 32,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.star, color: Colors.orange, size: 50),
                              Icon(Icons.star, color: Colors.orange, size: 65),
                              Icon(Icons.star, color: Colors.orange, size: 50),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Next Level Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: ElevatedButton(
                    onPressed: () {
                      Get.off(() => const SymbolDashboardScreen(initialTabIndex: 2));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A33C), // Gold Button
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Next Level',
                      style: GoogleFonts.luckiestGuy(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
