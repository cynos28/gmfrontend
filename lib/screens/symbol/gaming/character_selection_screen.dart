import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/three_d_character_card.dart';
import 'package:ganithamithura/screens/symbol/gaming/level_selection_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  int? _selectedCharacterIndex;

  final List<String> _characterImages = [
    'assets/symbols/game/character1.png',
    'assets/symbols/game/character2.png',
    'assets/symbols/game/character3.png',
    'assets/symbols/game/character4.png',
    'assets/symbols/game/character5.png',
    'assets/symbols/game/character6.png',
  ];

  void _onCharacterSelected(int index) {
    setState(() {
      _selectedCharacterIndex = index;
    });
  }

  void _onChoosePressed() {
    if (_selectedCharacterIndex != null) {
      Get.to(
        () => const LevelSelectionScreen(),
        transition: Transition.circularReveal,
        duration: const Duration(milliseconds: 800),
      );
    } else {
       Get.snackbar(
        'Select a Character',
        'Please choose your character to start!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
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
            driftDuration: Duration(seconds: 15),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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

                // Title
                Text(
                  'Choose your\nCharacter',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 42,
                    color: const Color(0xFF1B5E20), // Dark Green
                    shadows: [
                      const Shadow(
                        color: Colors.white,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Character Grid
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4), // Semi-transparent container
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                    ),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.0, 
                      ),
                      // Hardcoded count based on assets found
                      itemCount: _characterImages.length,
                      itemBuilder: (context, index) {
                        return Center(
                          child: ThreeDCharacterCard(
                            imagePath: _characterImages[index],
                            isSelected: _selectedCharacterIndex == index,
                            onTap: () => _onCharacterSelected(index),
                            size: 120,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Choose Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _onChoosePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCA28), // Gold/Yellow
                        foregroundColor: Colors.brown,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        // Add 3D effect to button
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      child: Text(
                        'Choose',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 24,
                          letterSpacing: 1.5,
                        ),
                      ),
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
