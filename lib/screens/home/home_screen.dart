import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/screens/number/number_home_screen.dart';
import 'package:ganithamithura/screens/measurements/measurement_home_screen.dart';
import 'package:ganithamithura/screens/measurements/learn/learn_screen.dart';
import 'package:ganithamithura/screens/profile/profile_screen.dart';
import '../shapes/welcome_screen.dart';
import 'package:ganithamithura/screens/symbol/symbol_home_screen.dart';
import 'package:ganithamithura/screens/progress/progress_screen.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/services/api/auth_service.dart';

/// HomeScreen - Main entry point with personalized dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onNavTap(int index) {
    if (index == 0) {
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
        });
      });
      return;
    }
    if (index == 3) {
      // Navigate to Profile/Settings
      Get.to(() => const ProfileScreen())?.then((_) {
        setState(() {
          _currentNavIndex = 0;
        });
      });
      return;
    }

    if (index == 2) {
      // Navigate to Progress screen
      Get.to(() => const ProgressScreen())?.then((_) {
        setState(() {
          _currentNavIndex = 0;
        });
      });
      return;
    }

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
                left: KidsSpacing.screenPadding,
                right: KidsSpacing.screenPadding,
                top: KidsSpacing.xxxl,
                bottom: 90, // Space for bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Today's Activity Card
                  const TodayActivityCard(
                    activityTitle: "Today's Activity",
                    activitySubtitle: 'Trace, read & say',
                    timeToday: '25 min',
                    completedTasks: '8 tasks',
                    progressBadge: 'Great progress!',
                  ),
                  const SizedBox(height: KidsSpacing.xxl),

                  // Resources Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KidsColors.primaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '📚',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Let\'s Learn!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: KidsColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KidsSpacing.cardMarginLarge),

                  // Resource Cards Grid
                  _buildResourceGrid(),
                ],
              ),
            ),

            // Bottom Navigation
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
                icon: Icons.looks_one_rounded,
                imagePath: 'assets/vectors/kid1.png',
                backgroundColor: const Color(AppColors.numberColor),
                borderColor: const Color(AppColors.numberBorder),
                iconColor: const Color(AppColors.numberIcon),
                onTap: () => Get.to(() => const NumberHomeScreen()),
                isEnabled: true,
              ),
            ),
            const SizedBox(width: KidsSpacing.cardMarginLarge),
            Expanded(
              child: ResourceCard(
                title: 'Symbols',
                subtitle: '+ − × ÷',
                icon: Icons.calculate_rounded,
                imagePath: 'assets/vectors/kid2.png',
                backgroundColor: const Color(AppColors.symbolColor),
                borderColor: const Color(AppColors.symbolBorder),
                iconColor: const Color(AppColors.symbolIcon),
                onTap: () => Get.to(() => const SymbolHomeScreen()),
                isEnabled: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: KidsSpacing.cardMarginLarge),
        // Second row: Measurements and Shapes
        Row(
          children: [
            Expanded(
              child: ResourceCard(
                title: 'Measurement',
                subtitle: 'Length, area & more',
                icon: Icons.straighten_rounded,
                imagePath: 'assets/vectors/kid3.png',
                backgroundColor: const Color(AppColors.measurementColor),
                borderColor: const Color(AppColors.measurementBorder),
                iconColor: const Color(AppColors.measurementIcon),
                onTap: () => Get.to(() => const MeasurementHomeScreen()),
                isEnabled: true,
              ),
            ),
            const SizedBox(width: KidsSpacing.cardMarginLarge),
            Expanded(
              child: ResourceCard(
                title: 'Shapes',
                subtitle: 'Hunt & build 2D/3D',
                icon: Icons.category_rounded,
                imagePath: 'assets/vectors/kid4.png',
                backgroundColor: const Color(AppColors.shapeColor),
                borderColor: const Color(AppColors.shapeBorder),
                iconColor: const Color(AppColors.shapeIcon),
                onTap: () => Get.to(() => const WelcomeScreen()),
                isEnabled: true
              ),
            ),
          ],
        ),
      ],
    );
  }
}