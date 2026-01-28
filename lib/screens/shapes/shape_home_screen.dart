import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/measurements/measurement_widgets.dart';
import 'package:ganithamithura/widgets/measurements/ar_challenge_card.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

import '../../widgets/shapes/shape_widgets.dart';
import '../../widgets/shapes/camera_permission_dialog.dart';
import 'games/shape_games_screen.dart';
import 'shapes_selection_screen.dart';
import 'find_real_shapes_screen.dart';
import 'learn_shapes.dart';


/// ShapeHomeScreen - Main screen for Shape module
class ShapeHomeScreen extends StatefulWidget {
  const ShapeHomeScreen({super.key});

  @override
  State<ShapeHomeScreen> createState() => _ShapeHomeScreenState();
}

class _ShapeHomeScreenState extends State<ShapeHomeScreen> {
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
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset('assets/images/icegif-5860 1.png'),
            ),
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
                              'Shapes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textBlack),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '',
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
                        // AR Challenges Grid
                        _buildShapeMenuCardGrid(),
                        const SizedBox(height: 24),
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
            Positioned(
              bottom: 75,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset('assets/images/shape_home_img1.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeMenuCardGrid() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // First row: Length and Capacity
        Row(
          children: [
            Expanded(
              child: ShapeMenuCard(
                title: 'Learn Shapes',
                subtitle: 'Explore 2D and 3D shapes',
                icon: 'assets/images/simple-icons_leanpub.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () {
                  Get.to(() => const ShapesSelectionScreen());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShapeMenuCard(
                title: 'AR Hunt',
                subtitle: 'Hunt shapes in AR',
                icon: 'assets/images/lucide_camera.png',
                backgroundColor: const Color(0xFFE76E50),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () {
                  // Navigate to AR measurement screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShapeMenuCard(
                title: 'Find Real Shapes',
                subtitle: 'Detect shapes around you',
                icon: 'assets/images/bx_search.png',
                backgroundColor: const Color(0xFFE9638F),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () async {
                  // Show camera permission dialog
                  final granted = await showCameraPermissionDialog(context);
                  if (granted) {
                    Get.to(() => const FindRealShapesScreen());
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShapeMenuCard(
                title: 'Games',
                subtitle: 'Play shape games',
                icon: 'assets/images/dashicons_games.png',
                backgroundColor: const Color(0xFF4799EB),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () {
                  Get.to(() => const GameHomeScreen());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShapeMenuCard(
                title: 'Build and Match',
                subtitle: 'Draw and create shapes',
                icon: 'assets/images/build_match.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                onTap: () {
                  // Navigate to AR measurement screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Area and Weight
      ],
    );
  }
}
