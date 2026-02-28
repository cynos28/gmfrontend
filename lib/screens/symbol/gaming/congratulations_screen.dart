import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';
import 'package:ganithamithura/screens/symbol/gaming/leaderboard_screen.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';

class CongratulationsScreen extends StatelessWidget {
  final int score;
  final int level;

  const CongratulationsScreen({
    super.key, 
    required this.score, 
    required this.level,
  });

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
                          onPressed: () => Get.offAll(() => const HomeScreen()),
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
                              '$score',
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
                      Get.off(() => const LeaderboardScreen());
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
