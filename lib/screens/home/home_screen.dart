import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
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
                left: KidsSpacing.screenPadding,
                right: KidsSpacing.screenPadding,
                top: KidsSpacing.xxxl,
                bottom: 90, // Space for bottom nav
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section
                  _buildGreeting(),
                  const SizedBox(height: KidsSpacing.xl),

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
                  const SizedBox(height: KidsSpacing.xxxl),

                  // Learning Tips Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KidsColors.starBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '💡',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Today\'s Tip',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: KidsColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KidsSpacing.cardMarginLarge),

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
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KidsColors.primaryAccent.withOpacity(0.1),
            KidsColors.secondaryAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👋 Hi, Shehan!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: KidsColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: KidsColors.highlightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KidsColors.highlightAccent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: KidsColors.highlightAccent,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '5 days!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KidsColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                backgroundColor: const Color(AppColors.symbolColor),
                borderColor: const Color(AppColors.symbolBorder),
                iconColor: const Color(AppColors.symbolIcon),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Symbols will be available soon',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                    borderRadius: KidsSpacing.radiusMedium,
                  );
                },
                isEnabled: false,
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
                subtitle: '2D & 3D',
                icon: Icons.category_rounded,
                backgroundColor: const Color(AppColors.shapeColor),
                borderColor: const Color(AppColors.shapeBorder),
                iconColor: const Color(AppColors.shapeIcon),
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Shapes will be available soon',
                    backgroundColor: const Color(AppColors.infoColor),
                    colorText: Colors.white,
                    borderRadius: KidsSpacing.radiusMedium,
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
