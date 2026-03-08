import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

import '../../widgets/shapes/camera_permission_dialog.dart' as camera_permission;
import 'games/shape_games_screen.dart';
import 'shapes_selection_screen.dart';
import 'find_real_shapes_screen.dart';
import 'ar_hunt_intro_screen.dart';
import 'widgets/camera_permission_dialog.dart';
import 'build_and_match_screen.dart';

/// Kid-Friendly ShapeHomeScreen
class ShapeHomeScreen extends StatefulWidget {
  const ShapeHomeScreen({super.key});

  @override
  State<ShapeHomeScreen> createState() => _ShapeHomeScreenState();
}

class _ShapeHomeScreenState extends State<ShapeHomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Get.back();
      } else {
        Get.offAllNamed('/home');
      }
      return;
    }
    if (index == _currentNavIndex) return;

    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1 column on phone, 2 on tablet
    final int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 2 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Standard app background
      body: SafeArea(
        child: Stack(
          children: [
            
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.4,
                      padding: const EdgeInsets.only(bottom: 160), // Space for bottom image & nav
                      children: [
                        _ShapeCategoryCard(
                          title: 'Learn Shapes',
                          subtitle: 'Explore 2D and 3D shapes',
                          localImage: 'assets/images/Shapes/kids1.png',
                          color: const Color(0xFF4CAF50), // Green
                          bgColor: const Color(0xFFC8E6C9),
                          onTap: () => Get.to(() => const ShapesSelectionScreen(), transition: Transition.rightToLeft),
                        ),
                        _ShapeCategoryCard(
                          title: 'AR Hunt',
                          subtitle: 'Hunt shapes in AR',
                          localImage: 'assets/images/Shapes/kids2.png',
                          color: const Color(0xFFFF9800), // Orange
                          bgColor: const Color(0xFFFFE0B2),
                          onTap: () => _showArHuntDialog(),
                        ),
                        _ShapeCategoryCard(
                          title: 'Find Real Shapes',
                          subtitle: 'Detect shapes around you',
                          localImage: 'assets/images/Shapes/kids3.png',
                          color: const Color(0xFFE91E63), // Pink
                          bgColor: const Color(0xFFF8BBD0),
                          onTap: () async {
                            final granted = await camera_permission.showCameraPermissionDialog(context);
                            if (granted) {
                              Get.to(() => const FindRealShapesScreen(), transition: Transition.rightToLeft);
                            }
                          },
                        ),
                        _ShapeCategoryCard(
                          title: 'Games',
                          subtitle: 'Play shape games',
                          localImage: 'assets/images/Shapes/kids4.png',
                          color: const Color(0xFF2196F3), // Blue
                          bgColor: const Color(0xFFBBDEFB),
                          onTap: () => Get.to(() => const GameHomeScreen(), transition: Transition.rightToLeft),
                        ),
                        _ShapeCategoryCard(
                          title: 'Build and Match',
                          subtitle: 'Draw and create shapes',
                          localImage: 'assets/images/Shapes/kids5.png',
                          color: const Color(0xFF9C27B0), // Purple
                          bgColor: const Color(0xFFE1BEE7),
                          onTap: () => Get.to(() => const BuildAndMatchScreen(), transition: Transition.rightToLeft),
                        ),
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

  void _showArHuntDialog() {
    showDialog(
      context: context,
      builder: (context) => CameraPermissionDialog(
        onLetsGo: () {
          Navigator.pop(context); // Close dialog
          Get.to(() => const ArHuntIntroScreen(), transition: Transition.rightToLeft);
        },
        onGoBack: () {
          Navigator.pop(context); // Close dialog
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                Get.offAllNamed('/home');
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shapes',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore the world of shapes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String localImage;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ShapeCategoryCard({
    required this.title,
    required this.subtitle,
    required this.localImage,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Image.asset(
                    localImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
