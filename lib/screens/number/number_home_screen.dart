import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/number/level_selection/level_selection_screen.dart';
import 'package:ganithamithura/screens/number/test/progress_test_screen.dart';

/// NumberHomeScreen - Main screen for Number Service
/// Two options: Learn or take the Progress Test
class NumberHomeScreen extends StatelessWidget {
  const NumberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Numbers'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Title section
              Icon(Icons.pin, size: 80, color: Color(AppColors.numberColor)),
              const SizedBox(height: 16),
              const Text(
                'Learn Numbers!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Master counting from 1 to 1000',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),

              const Spacer(flex: 3),

              // Learn Button
              _buildOptionCard(
                context,
                icon: Icons.school,
                title: 'Learn',
                subtitle: 'Watch videos, trace numbers, and practice step by step',
                gradientColors: [const Color(0xFF4CAF50), const Color(0xFF45A049)],
                onTap: () => Get.to(() => const LevelSelectionScreen()),
              ),

              const SizedBox(height: 20),

              // Progress Test Button
              _buildOptionCard(
                context,
                icon: Icons.psychology,
                title: 'Progress Test',
                subtitle: 'Take a quiz to find your level and unlock challenges',
                gradientColors: [const Color(0xFF6B7FFF), const Color(0xFF5567E8)],
                onTap: () => Get.to(() => const ProgressTestScreen()),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
