import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/screens/measurements/learn/unit_card_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedIndex = 1; // Learn tab selected

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to home
      Get.back();
      return;
    }
    
    if (index == 1) {
      // Already on Learn screen
      return;
    }
    
    // TODO: Navigate to other tabs when ready
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
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with gradient background
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KidsColors.primaryAccent.withOpacity(0.1),
                        KidsColors.secondaryAccent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KidsColors.primaryAccent.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    KidsSpacing.screenPadding,
                    KidsSpacing.xxl,
                    KidsSpacing.screenPadding,
                    KidsSpacing.xxxl,
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
                            const Text(
                              'Learn & Explore',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: KidsColors.textPrimary,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 18,
                                  color: KidsColors.primaryAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Learn step by step',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: KidsColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Achievement badge with pulse animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.9, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  KidsColors.starGold,
                                  KidsColors.starOrange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: KidsColors.starGold.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '15',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
              const SizedBox(height: KidsSpacing.xl),
              
              // All Modules Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: KidsSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                KidsColors.highlightAccent,
                                KidsColors.highlightAccent.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: KidsColors.highlightAccent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'All Modules',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: KidsColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KidsSpacing.cardMarginLarge),
                    // Module list cards (vertical)
                    _buildModuleListCard(
                      title: 'Numbers',
                      imagePath: 'assets/vectors/stitch1.png',
                      color: const Color(AppColors.numberColor),
                      borderColor: const Color(AppColors.numberBorder),
                      iconColor: const Color(AppColors.numberIcon),
                      progress: 0.35,
                      isLocked: false,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Numbers will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                          borderRadius: KidsSpacing.radiusMedium,
                        );
                      },
                    ),
                    const SizedBox(height: KidsSpacing.cardMargin),
                    _buildModuleListCard(
                      title: 'Symbols',
                      imagePath: 'assets/vectors/stitch2.png',
                      color: const Color(AppColors.symbolColor),
                      borderColor: const Color(AppColors.symbolBorder),
                      iconColor: const Color(AppColors.symbolIcon),
                      progress: 0.0,
                      isLocked: true,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Symbols will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                          borderRadius: KidsSpacing.radiusMedium,
                        );
                      },
                    ),
                    const SizedBox(height: KidsSpacing.cardMargin),
                    _buildModuleListCard(
                      title: 'Measurement',
                      imagePath: 'assets/vectors/stitch3.png',
                      color: const Color(AppColors.measurementColor),
                      borderColor: const Color(AppColors.measurementBorder),
                      iconColor: const Color(AppColors.measurementIcon),
                      progress: 0.15,
                      isLocked: false,
                      onTap: () {
                        Get.to(() => const UnitCardScreen());
                      },
                    ),
                    const SizedBox(height: KidsSpacing.cardMargin),
                    _buildModuleListCard(
                      title: 'Shapes',
                      imagePath: 'assets/vectors/stitch4.png',
                      color: const Color(AppColors.shapeColor),
                      borderColor: const Color(AppColors.shapeBorder),
                      iconColor: const Color(AppColors.shapeIcon),
                      progress: 0.0,
                      isLocked: true,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Shapes will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                          borderRadius: KidsSpacing.radiusMedium,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }


  Widget _buildModuleListCard({
    required String title,
    required String imagePath,
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required double progress,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.withOpacity(0.08) : color,
          border: Border.all(
            color: isLocked ? Colors.grey.withOpacity(0.3) : borderColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
          boxShadow: isLocked ? null : KidsShadows.coloredBlue, // Brighter shadow
        ),
        child: Row(
          children: [
            // Animated Character Image
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.15)
                          : borderColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      imagePath,
                      color: isLocked ? Colors.grey : null,
                      colorBlendMode: isLocked ? BlendMode.saturation : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24, // Larger text
                      fontWeight: FontWeight.w800,
                      color: isLocked
                          ? Colors.grey
                          : KidsColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: borderColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        minHeight: 8, // Thicker bar
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: KidsSpacing.md),
            // Arrow or locked badge
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KidsSpacing.sm,
                  vertical: KidsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(KidsSpacing.sm),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: iconColor.withOpacity(0.2),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
