import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/screens/number/number_home_screen.dart';
import 'package:ganithamithura/screens/measurements/measurement_home_screen.dart';
import 'package:ganithamithura/screens/measurements/learn/learn_screen.dart';
import 'package:ganithamithura/screens/profile/profile_screen.dart';

/// HomeScreen - Main entry point with personalized dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  Key _tipCardKey = UniqueKey();

  void _onNavTap(int index) {
    if (index == 0) {
      // Already on home, refresh tip card
      setState(() {
        _tipCardKey = UniqueKey();
      });
      return;
    }
    
    setState(() {
      _currentNavIndex = index;
    });
    
    if (index == 1) {
      // Navigate to Learn screen
      Get.to(() => const LearnScreen())?.then((_) {
        // Reset nav index when coming back
        setState(() {
          _currentNavIndex = 0;
          _tipCardKey = UniqueKey(); // Refresh tip when returning
        });
      });
      return;
    }
    if (index == 3) {
      // Navigate to Profile/Settings
      Get.to(() => const ProfileScreen())?.then((_) {
        setState(() {
          _currentNavIndex = 0;
          _tipCardKey = UniqueKey();
        });
      });
      return;
    }
    
    // TODO: Navigate to other screens when ready
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
    
    // Reset index since navigation didn't happen
    setState(() {
      _currentNavIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with scroll
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 32,
                bottom: 90, // Space for bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section
                  _buildGreeting(),
                  const SizedBox(height: 16),

                  // Today's Activity Card
                  const TodayActivityCard(
                    activityTitle: "Today's Activity",
                    activitySubtitle: 'Trace, read & say',
                    timeToday: '25 min',
                    completedTasks: '8 tasks',
                    progressBadge: 'Great progress!',
                  ),
                  const SizedBox(height: 20),

                  // Resources Section
                  const Text(
                    'Resources',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textBlack),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resource Cards Grid
                  _buildResourceGrid(),
                  const SizedBox(height: 32),

                  // Learning Tips Section
                  const Text(
                    'Learning Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textBlack),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily Tip Card
                  LearningTipCard(key: _tipCardKey),
                ],
              ),
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

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hi, Shehan👋',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 14,
              color: Color(AppColors.subText2),
            ),
            const SizedBox(width: 4),
            const Text(
              '5 day streak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(AppColors.subText2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceGrid() {
    return Column(
      children: [
        // First row: Numbers and Symbols
        Row(
          children: [
            Expanded(
              child: ResourceCard(
                title: 'Numbers',
                subtitle: 'Trace, read & say',
                icon: Icons.pin,
                backgroundColor: const Color(AppColors.numberColor).withOpacity(0.24),
                borderColor: const Color(AppColors.numberBorder),
                iconColor: const Color(AppColors.numberIcon),
                onTap: () => Get.to(() => const NumberHomeScreen()),
                isEnabled: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ResourceCard(
                title: 'Symbols',
                subtitle: '+ − × ÷ stories & quizzes',
                icon: Icons.calculate,
                backgroundColor: const Color(AppColors.symbolColor).withOpacity(0.24),
                borderColor: const Color(AppColors.symbolBorder),
                iconColor: const Color(AppColors.symbolIcon),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Symbols module will be available soon',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
                isEnabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Measurements and Shapes
        Row(
          children: [
            Expanded(
              child: ResourceCard(
                title: 'Measurement',
                subtitle: 'Length, Area, Capacity, Weight',
                icon: Icons.straighten,
                backgroundColor: const Color(AppColors.measurementColor).withOpacity(0.24),
                borderColor: const Color(AppColors.measurementBorder),
                iconColor: const Color(AppColors.measurementIcon),
                onTap: () => Get.to(() => const MeasurementHomeScreen()),
                isEnabled: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ResourceCard(
                title: 'Shapes',
                subtitle: 'Hunt & build 2D/3D',
                icon: Icons.category,
                backgroundColor: const Color(AppColors.shapeColor).withOpacity(0.24),
                borderColor: const Color(AppColors.shapeBorder),
                iconColor: const Color(AppColors.shapeIcon),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Shapes module will be available soon',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                  );
                },
                isEnabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
