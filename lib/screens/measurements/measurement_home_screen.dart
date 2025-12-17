import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/measurements/measurement_widgets.dart';
import 'package:ganithamithura/widgets/measurements/ar_challenge_card.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';


/// MeasurementHomeScreen - Main screen for Measurement module
class MeasurementHomeScreen extends StatefulWidget {
  const MeasurementHomeScreen({super.key});

  @override
  State<MeasurementHomeScreen> createState() => _MeasurementHomeScreenState();
}

class _MeasurementHomeScreenState extends State<MeasurementHomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate to home
      Get.back();
      return;
    }
    
    if (index == _currentNavIndex) {
      // Already on current tab
      return;
    }
    
    // TODO: Navigate to other screens when ready
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Color(AppColors.textBlack),
                        ),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Measurements',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textBlack),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learn to measure the world! 📏',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2D4059).withOpacity(0.64),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 24,
                      bottom: 90, // Space for bottom nav
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AR Challenges Section (NEW!)
                        const SectionHeader(
                          title: 'AR Challenges',
                          badgeText: '🎯 Scan & Learn',
                        ),
                        const SizedBox(height: 16),
                        
                        // AR Challenges Grid
                        _buildARChallengesGrid(),
                        const SizedBox(height: 24),
                        
                        // Learning Games Section
                        const SectionHeader(
                          title: 'Learning Games',
                          badgeText: 'Fun Practice',
                        ),
                        const SizedBox(height: 16),
                        
                        // Games Grid
                        _buildGamesGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARChallengesGrid() {
    return Column(
      children: [
        // First row: Length and Capacity
        Row(
          children: [
            Expanded(
              child: ARChallengeCard(
                title: 'Length',
                subtitle: 'Measure objects',
                units: 'mm · cm · m',
                icon: '📏',
                backgroundColor: const Color(AppColors.numberColor).withOpacity(0.24),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () {
                  // Navigate to AR measurement screen
                  Get.toNamed('/ar-measurement', arguments: {
                    'type': 'length',
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ARChallengeCard(
                title: 'Capacity',
                subtitle: 'Measure liquids',
                units: 'ml · L',
                icon: '🥤',
                backgroundColor: const Color(AppColors.symbolColor).withOpacity(0.24),
                borderColor: const Color(AppColors.symbolBorder),
                onTap: () {
                  Get.toNamed('/ar-measurement', arguments: {
                    'type': 'capacity',
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Area and Weight
        Row(
          children: [
            Expanded(
              child: ARChallengeCard(
                title: 'Weight',
                subtitle: 'Measure mass',
                units: 'g · kg',
                icon: '⚖️',
                backgroundColor: const Color(AppColors.shapeColor).withOpacity(0.24),
                borderColor: const Color(AppColors.shapeBorder),
                onTap: () {
                  Get.toNamed('/ar-measurement', arguments: {
                    'type': 'weight',
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ARChallengeCard(
                title: 'Area',
                subtitle: 'Measure surfaces',
                units: 'cm² · m²',
                icon: '📐',
                backgroundColor: const Color(AppColors.measurementColor).withOpacity(0.24),
                borderColor: const Color(AppColors.measurementBorder),
                onTap: () {
                  Get.toNamed('/ar-measurement', arguments: {
                    'type': 'area',
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGamesGrid() {
    return Column(
      children: [
        // First row: Length and Capacity games
        Row(
          children: [
            Expanded(
              child: MeasurementGameCard(
                title: 'Length',
                subtitle: 'Find & measure objects',
                icon: Icons.straighten,
                backgroundColor: const Color(AppColors.numberColor).withOpacity(0.24),
                borderColor: const Color(AppColors.numberBorder),
                buttonColor: const Color(AppColors.numberBorder),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Length game is under development',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MeasurementGameCard(
                title: 'Capacity',
                subtitle: 'Change between units',
                icon: Icons.local_drink,
                backgroundColor: const Color(AppColors.symbolColor).withOpacity(0.24),
                borderColor: const Color(AppColors.symbolBorder),
                buttonColor: const Color(AppColors.symbolBorder),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Capacity game is under development',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Area and Weight games
        Row(
          children: [
            Expanded(
              child: MeasurementGameCard(
                title: 'Area',
                subtitle: 'Estimate measurements',
                icon: Icons.grid_on,
                backgroundColor: const Color(AppColors.measurementColor).withOpacity(0.24),
                borderColor: const Color(AppColors.measurementBorder),
                buttonColor: const Color(AppColors.measurementBorder),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Area game is under development',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MeasurementGameCard(
                title: 'Weight',
                subtitle: 'Beat the scaler',
                icon: Icons.scale,
                backgroundColor: const Color(AppColors.shapeColor).withOpacity(0.24),
                borderColor: const Color(AppColors.shapeBorder),
                buttonColor: const Color(AppColors.shapeBorder),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Weight game is under development',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
