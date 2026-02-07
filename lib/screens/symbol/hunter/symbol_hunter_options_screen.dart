import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_level_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_input_mode_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/hunter/learning_pool_level_screen.dart';

class SymbolHunterOptionsScreen extends StatelessWidget {
  const SymbolHunterOptionsScreen({super.key});

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
                'assets/symbols/hunterOptionMain.png',
                height: 250, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              // Practice Questions Card
              _buildImageCard(
                title: 'Practice Questions',
                subtitle: 'Test your knowledge with\nquestions',
                buttonText: 'Start',
                imageAsset: 'assets/symbols/hunterOptionQuection.png',
                color: const Color(0xFFFFCCAA), // Peach/Orange
                textColor: Colors.white,
                onTap: () {
                   Get.to(() => const SymbolInputModeSelectionScreen());
                },
              ),
              const SizedBox(height: 20),

              // Learning Pool Card
              _buildImageCard(
                title: 'Learning Pool',
                subtitle: 'You can learn symbols with\nour AI Tutor',
                buttonText: "Let's Learn",
                imageAsset: 'assets/symbols/hunterGame.png',
                color: const Color(0xFFA8B5FF), // Periwinkle/Blue
                textColor: Colors.white,
                onTap: () {
                  Get.to(() => const LearningPoolLevelScreen());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard({
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
        height: 160, // Fixed height for consistency
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
              top: 24,
              bottom: 24,
              right: 140, // Space for image
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18, // Slightly larger
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                  // "Button" Look
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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
              bottom: 10,
              top: 10,
              width: 140,
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
