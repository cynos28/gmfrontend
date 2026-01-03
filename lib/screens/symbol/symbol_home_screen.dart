import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/symbol/quiz/symbol_quiz_intro_screen.dart';
import 'package:ganithamithura/screens/symbol/widgets/floating_symbols_background.dart';

/// SymbolHomeScreen - Child-friendly screen with dynamic background
class SymbolHomeScreen extends StatelessWidget {
  const SymbolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Light greyish background
      body: Stack(
        children: [
          // Subtle background
          const Opacity(
            opacity: 0.6,
            child: FloatingSymbolsBackground(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Back Button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1. Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 2. Level/Progress Card
                  _buildLevelCard(),
                  const SizedBox(height: 24),

                  // 3. Categories
                  _buildCategories(),
                  const SizedBox(height: 24),

                  // 4. Feature Cards
                  _buildFeatureCard(
                    title: 'Lessons',
                    subtitle: 'Fun learning lessons\nthat help kids grow\nsmarter daily.',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFFE3F2FD), // Light Blue
                    iconColor: const Color(0xFF2196F3),
                    imageAsset: 'assets/symbols/teacher1.png', 
                    isLarge: true,
                    onTap: () {
                      Get.to(() => const SymbolQuizIntroScreen());
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    title: 'Games',
                    subtitle: 'Play and learn!',
                    icon: Icons.games_rounded,
                    color: const Color(0xFFF3E5F5), // Light Purple
                    iconColor: const Color(0xFF9C27B0),
                    imageAsset: null, 
                    isLarge: false,
                    onTap: () {
                      Get.snackbar(
                        'Symbol Games',
                        'Coming Soon!',
                        backgroundColor: Colors.purpleAccent,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Marion',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Progress 10%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildLevelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7)], // Periwinkle/Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F7FD5).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level 1',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This is your first step to greatness!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              // Trophy Icon Placeholder
              const Icon(Icons.emoji_events_rounded, size: 48, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 100, // Fixed width for 10% progress visual
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC80), // Orange/Amber
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Lessons', 'icon': Icons.menu_book_rounded, 'color': 0xFF9575CD},
      {'name': 'Games', 'icon': Icons.sports_esports_rounded, 'color': 0xFF64B5F6},
      {'name': 'Stories', 'icon': Icons.auto_stories_rounded, 'color': 0xFFE57373},
      {'name': 'Activities', 'icon': Icons.brush_rounded, 'color': 0xFFFFB74D},
      {'name': 'Discover', 'icon': Icons.public_rounded, 'color': 0xFF4DB6AC},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(cat['color'] as int).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: Color(cat['color'] as int),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    String? imageAsset,
    required bool isLarge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (imageAsset != null)
              Image.asset(
                imageAsset,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(icon, size: 80, color: iconColor.withOpacity(0.5)),
              )
            else
              Icon(Icons.arrow_outward_rounded, size: 32, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}


