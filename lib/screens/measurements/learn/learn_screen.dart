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
                    const SizedBox(height: KidsSpacing.xl),
                    // Overall progress card
                    Container(
                      padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                        boxShadow: KidsShadows.soft,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  KidsColors.primaryAccent,
                                  KidsColors.primaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: KidsSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: KidsColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: KidsSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(KidsSpacing.sm),
                                  child: LinearProgressIndicator(
                                    value: 0.13,
                                    backgroundColor: KidsColors.primaryBackground,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      KidsColors.primaryAccent,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: KidsSpacing.md),
                          const Text(
                            '13%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: KidsColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
              
              const SizedBox(height: KidsSpacing.xxl),
              
              // Continue Learning Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: KidsSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    KidsColors.secondaryAccent,
                                    KidsColors.secondaryAccent.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: KidsColors.secondaryAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_circle_filled_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue Learning',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: KidsColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: KidsColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KidsSpacing.md),
                    // Horizontal scrollable recent cards
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildRecentCard(
                            title: 'Numbers',
                            subtitle: 'Continue from Level 3',
                            progress: 0.35,
                            color: const Color(AppColors.numberColor),
                            iconColor: const Color(AppColors.numberIcon),
                            icon: Icons.looks_one_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildRecentCard(
                            title: 'Measurement',
                            subtitle: 'Learn about Length',
                            progress: 0.15,
                            color: const Color(AppColors.measurementColor),
                            iconColor: const Color(AppColors.measurementIcon),
                            icon: Icons.straighten_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: KidsSpacing.xxl),
              
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
                      subtitle: 'Trace, read & say',
                      description: '25 lessons',
                      icon: Icons.looks_one_rounded,
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
                      subtitle: '+ − × ÷',
                      description: '18 lessons',
                      icon: Icons.calculate_rounded,
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
                      subtitle: 'Length, area & more',
                      description: '20 lessons',
                      icon: Icons.straighten_rounded,
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
                      subtitle: '2D & 3D',
                      description: '22 lessons',
                      icon: Icons.category_rounded,
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

  Widget _buildRecentCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KidsColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: KidsColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleListCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.withOpacity(0.08) : color,
          border: Border.all(
            color: isLocked ? Colors.grey.withOpacity(0.3) : borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
          boxShadow: isLocked ? null : KidsShadows.soft,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.withOpacity(0.15)
                    : borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLocked
                  ? const Icon(Icons.lock_rounded, color: Colors.grey, size: 26)
                  : Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLocked
                          ? Colors.grey
                          : KidsColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isLocked
                          ? Colors.grey
                          : KidsColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 12,
                        color: isLocked
                            ? Colors.grey
                            : KidsColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isLocked
                              ? Colors.grey
                              : KidsColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!isLocked) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: borderColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        minHeight: 6,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }
}
