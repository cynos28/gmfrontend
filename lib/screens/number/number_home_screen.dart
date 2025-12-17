import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/screens/number/level_selection/level_selection_screen.dart';
import 'package:ganithamithura/screens/number/test/test_screen.dart';

/// NumberHomeScreen - Main screen for Number Service
class NumberHomeScreen extends StatelessWidget {
  const NumberHomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Numbers Learning'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and title
              Icon(
                Icons.pin,
                size: 100,
                color: Color(AppColors.numberColor),
              ),
              const SizedBox(height: 24),
              const Text(
                'Learn Numbers!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Master counting from 1 to 10',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              
              // Start Learning Button
              ActionButton(
                text: 'Start Learning',
                icon: Icons.play_arrow,
                color: Color(AppColors.numberColor),
                onPressed: () {
                  Get.to(() => const LevelSelectionScreen());
                },
              ),
              
              const SizedBox(height: 16),
              
              // Progress Test Button
              ActionButton(
                text: 'Progress Test',
                icon: Icons.quiz,
                color: Color(AppColors.successColor),
                onPressed: () {
                  Get.to(() => const TestScreen(testType: 'beginner'));
                },
              ),
              
              const SizedBox(height: 48),
              
              // Info card
              Card(
                elevation: AppConstants.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(AppColors.infoColor),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'What you\'ll learn:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(Icons.video_library, 'Watch video lessons'),
                      _buildInfoItem(Icons.edit, 'Trace numbers'),
                      _buildInfoItem(Icons.menu_book, 'Read and recognize'),
                      _buildInfoItem(Icons.mic, 'Say numbers aloud'),
                      _buildInfoItem(Icons.camera_alt, 'Identify objects'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
