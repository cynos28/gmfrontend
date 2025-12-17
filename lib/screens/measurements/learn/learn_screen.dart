import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8CA9FF).withOpacity(0.15),
                      const Color(0xFFA6ADED).withOpacity(0.10),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Color(AppColors.textBlack),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Master math concepts step by step',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(AppColors.subText1).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        // Achievement badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Color(0xFFFFB800),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '15',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFB800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Overall progress card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B7FFF), Color(0xFF8CA9FF)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(AppColors.subText2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: 0.13,
                                    backgroundColor: const Color(0xFFE8EEFF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6B7FFF),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '13%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(AppColors.textBlack),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Learning Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Continue Learning',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textBlack),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7FFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                            icon: Icons.pin,
                          ),
                          const SizedBox(width: 12),
                          _buildRecentCard(
                            title: 'Measurement',
                            subtitle: 'Learn about Length',
                            progress: 0.15,
                            color: const Color(AppColors.measurementColor),
                            iconColor: const Color(AppColors.measurementIcon),
                            icon: Icons.straighten,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // All Modules Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textBlack),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Module list cards (vertical)
                    _buildModuleListCard(
                      title: 'Numbers',
                      subtitle: 'Trace, read & say numbers',
                      description: '25 lessons • 12 activities',
                      icon: Icons.pin,
                      color: const Color(AppColors.numberColor),
                      borderColor: const Color(AppColors.numberBorder),
                      iconColor: const Color(AppColors.numberIcon),
                      progress: 0.35,
                      isLocked: false,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Numbers learning module will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModuleListCard(
                      title: 'Symbols',
                      subtitle: '+ − × ÷ stories & quizzes',
                      description: '18 lessons • 10 activities',
                      icon: Icons.calculate,
                      color: const Color(AppColors.symbolColor),
                      borderColor: const Color(AppColors.symbolBorder),
                      iconColor: const Color(AppColors.symbolIcon),
                      progress: 0.0,
                      isLocked: true,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Symbols learning module will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModuleListCard(
                      title: 'Measurement',
                      subtitle: 'Length, Area, Capacity, Weight',
                      description: '20 lessons • 15 activities',
                      icon: Icons.straighten,
                      color: const Color(AppColors.measurementColor),
                      borderColor: const Color(AppColors.measurementBorder),
                      iconColor: const Color(AppColors.measurementIcon),
                      progress: 0.15,
                      isLocked: false,
                      onTap: () {
                        Get.to(() => const UnitCardScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModuleListCard(
                      title: 'Shapes',
                      subtitle: 'Hunt & build 2D/3D shapes',
                      description: '22 lessons • 14 activities',
                      icon: Icons.category,
                      color: const Color(AppColors.shapeColor),
                      borderColor: const Color(AppColors.shapeBorder),
                      iconColor: const Color(AppColors.shapeIcon),
                      progress: 0.0,
                      isLocked: true,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Shapes learning module will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textBlack),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(AppColors.subText1),
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 5,
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
          color: isLocked ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.15),
          border: Border.all(
            color: isLocked ? Colors.grey.withOpacity(0.3) : borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.withOpacity(0.2)
                    : borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLocked
                  ? const Icon(Icons.lock, color: Colors.grey, size: 28)
                  : Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: isLocked
                                ? Colors.grey
                                : const Color(AppColors.textBlack),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
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
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: iconColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isLocked
                          ? Colors.grey
                          : const Color(AppColors.subText1),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 13,
                        color: isLocked
                            ? Colors.grey
                            : const Color(AppColors.subText2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isLocked
                              ? Colors.grey
                              : const Color(AppColors.subText2),
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
          ],
        ),
      ),
    );
  }
}
