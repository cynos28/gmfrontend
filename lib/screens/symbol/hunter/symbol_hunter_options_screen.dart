import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_level_selection_screen.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image
              Expanded(
                flex: 4,
                child: Image.asset(
                  'assets/symbols/learnSymbols.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Practice Questions Button
              _buildOptionCard(
                title: 'Practice Questions',
                subtitle: 'Test your knowledge with questions',
                icon: Icons.quiz_outlined, // Using outline to match style
                color: const Color(0xFFFFA768), // Orange
                textColor: Colors.white,
                onTap: () {
                   Get.to(() => const SymbolLevelSelectionScreen());
                },
              ),
              const SizedBox(height: 16),

              // Learning Pool Button
              _buildOptionCard(
                title: 'Learning Pool',
                subtitle: 'AI tutor teach symbols',
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF5C7CFA), // Royal Blue
                textColor: Colors.white,
                onTap: () {
                  Get.snackbar(
                    'Learning Pool',
                    'Coming soon!',
                    backgroundColor: const Color(0xFF5C7CFA),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }
}
