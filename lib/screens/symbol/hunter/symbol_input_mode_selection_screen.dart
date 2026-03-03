import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_learning_screen.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_level_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_voice_level_selection_screen.dart'; // Add this

class SymbolInputModeSelectionScreen extends StatelessWidget {
  const SymbolInputModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symbol Hunter',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Let\'s Learn Symbols Together!',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: const AssetImage('assets/images/user_avatar.png'),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image (Main Illustration)
              Image.asset(
                'assets/symbols/quectionTypeMain.png',
                height: 200, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Select the way you are going\nto answer the questions',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800, // Extra Bold like screenshot
                  color: const Color(0xFF330000), // Dark Brown/Black
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Typing Card
              _buildInputModeCard(
                title: 'Typing the Answer',
                subtitle: 'You can give your answer by\ntyping it with open the keyboard.',
                buttonText: 'Choose',
                imageAsset: 'assets/symbols/quectionTypeTyping.png',
                color: const Color(0xFFF9B872), // Sandy Orange
                textColor: Colors.white,
                onTap: () {
                   Get.to(() => const SymbolLevelSelectionScreen());
                },
              ),
              const SizedBox(height: 20),

              // Telling Card
              _buildInputModeCard(
                title: 'Telling the Answer',
                subtitle: 'Using microphone you can\ntell your answer.',
                buttonText: 'Choose',
                imageAsset: 'assets/symbols/quectionTypeTellling.png', // Note: double 'l' in filename
                color: const Color(0xFFF9B872), // Sandy Orange
                textColor: Colors.white,
                onTap: () {
                   // Navigate to Voice Level Selection
                   Get.to(() => const SymbolVoiceLevelSelectionScreen());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputModeCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required String imageAsset,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140, 
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content (Left)
            Positioned(
              left: 24,
              top: 20,
              bottom: 20,
              right: 120, // Space for image
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: textColor.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ),
                  // Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4), // Darker pill bg
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Image (Right)
            Positioned(
              right: 10,
              bottom: 0, 
              top: 10,
              width: 120,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
