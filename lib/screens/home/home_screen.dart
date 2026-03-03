import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/screens/number/number_home_screen.dart';
import 'package:ganithamithura/screens/measurements/measurement_home_screen.dart';
import 'package:ganithamithura/screens/measurements/learn/learn_screen.dart';
import 'package:ganithamithura/screens/profile/profile_screen.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/models/user.dart';
import 'dart:math' as math;

/// HomeScreen - Kindergarten-friendly main dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _scaleController;
  User? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    
    // Scale animation for cards
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() => _isLoadingUser = false);
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      return;
    }
    
    setState(() {
      _currentNavIndex = index;
    });
    
    if (index == 1) {
      Get.to(() => const LearnScreen())?.then((_) {
        setState(() {
          _currentNavIndex = 0;
        });
      });
      return;
    }
    if (index == 3) {
      Get.to(() => const ProfileScreen())?.then((_) {
        setState(() {
          _currentNavIndex = 0;
        });
      });
      return;
    }
    
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
    
    setState(() {
      _currentNavIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive padding and spacing
    final horizontalPadding = screenWidth * 0.05;
    final cardSpacing = screenWidth * 0.04;
    
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Greeting section with Jerry
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: _buildGreetingSection(),
                ),
                
                const SizedBox(height: 8),
                
                // Simple header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildHeader(),
                ),
                
                const SizedBox(height: 16),
                
                // Expanded grid area
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _buildLearningGrid(cardSpacing),
                  ),
                ),
                
                // Space for bottom nav
                const SizedBox(height: 80),
              ],
            ),

            // Bottom Navigation - Fixed at bottom
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

  Widget _buildGreetingSection() {
    final userName = _currentUser?.name ?? 'Friend';
    final firstName = userName.split(' ').first;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF5F5F5),
              const Color(0xFFE8E8E8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoadingUser
                      ? const Text(
                          'Hello!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        )
                      : Text(
                          'Hello, $firstName!',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nice to see you again!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Jerry character with bounce animation
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * _scaleController.value),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/vectors/jerry.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: const Text(
        'What do you want to learn?',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: KidsColors.textPrimary,
          height: 1.2,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildLearningGrid(double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card size based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Card width: half of available width minus spacing
        final cardWidth = (availableWidth - spacing) / 2;
        
        // Card height: make it responsive but maintain good proportions
        final cardHeight = math.min(
          (availableHeight - spacing) / 2,
          cardWidth * 1.2, // Maintain aspect ratio
        );
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First row: Numbers and Symbols
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _buildModuleCard(
                      title: 'Numbers',
                      imagePath: 'assets/vectors/stitch1.png',
                      color: const Color(0xFFE8B86D),
                      enabled: true,
                      onTap: () => Get.to(() => const NumberHomeScreen()),
                      delay: 0,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _buildModuleCard(
                      title: 'Symbols',
                      imagePath: 'assets/vectors/stitch2.png',
                      color: const Color(0xFFE07B5F),
                      enabled: false,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Symbols will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                        );
                      },
                      delay: 150,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Second row: Measurement and Shapes
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _buildModuleCard(
                      title: 'Measurement',
                      imagePath: 'assets/vectors/stitch3.png',
                      color: const Color(0xFF7FA99B),
                      enabled: true,
                      onTap: () => Get.to(() => const MeasurementHomeScreen()),
                      delay: 300,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _buildModuleCard(
                      title: 'Shapes',
                      imagePath: 'assets/vectors/stitch4.png',
                      color: const Color(0xFFB88B9D),
                      enabled: false,
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Shapes will be available soon',
                          backgroundColor: const Color(AppColors.infoColor),
                          colorText: Colors.white,
                        );
                      },
                      delay: 450,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String imagePath,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive font sizes based on card width
            final cardWidth = constraints.maxWidth;
            final baseFontSize = (cardWidth * 0.12).clamp(20.0, 32.0);
            // Reduce font size by 2px for Measurement
            final titleFontSize = title == 'Measurement' ? baseFontSize - 2 : baseFontSize;
            final imageHeight = constraints.maxHeight * 0.65;
            
            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Title at top
                  Positioned(
                    top: 16,
                    left: 8,
                    right: 8,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Character image at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _scaleController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -5 * _scaleController.value),
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        child: Image.asset(
                          imagePath,
                          height: imageHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: imageHeight,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported,
                                size: cardWidth * 0.2,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
