import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'games/length_game_hub_screen.dart';
import 'games/area_game_hub_screen.dart';
import 'games/volume_game_hub_screen.dart';
import 'games/weight_game_hub_screen.dart';
import 'dart:math' as math;
import 'package:ganithamithura/screens/progress/progress_screen.dart';

/// MeasurementHomeScreen - Kindergarten-friendly measurement module
class MeasurementHomeScreen extends StatefulWidget {
  const MeasurementHomeScreen({super.key});

  @override
  State<MeasurementHomeScreen> createState() => _MeasurementHomeScreenState();
}

class _MeasurementHomeScreenState extends State<MeasurementHomeScreen> 
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  int _currentGrade = 1;
  bool _isLoadingGrade = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadGrade();
    
    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadGrade() async {
    try {
      final grade = await UserService.getGrade();
      setState(() {
        _currentGrade = grade;
        _isLoadingGrade = false;
      });
    } catch (e) {
      debugPrint('Error loading grade: $e');
      setState(() => _isLoadingGrade = false);
    }
  }

  List<String> _getAvailableTopics(int grade) {
    switch (grade) {
      case 1:
        return ['Length'];
      case 2:
        return ['Length', 'Area'];
      case 3:
        return ['Length', 'Area', 'Weight', 'Volume'];
      case 4:
        return ['Length', 'Area', 'Weight', 'Volume'];
      default:
        return ['Length'];
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Get.back();
      return;
    }
    
    if (index == _currentNavIndex) return;
    
    if (index == 2) {
      // Navigate to Progress screen
      Get.to(() => const ProgressScreen());
      return;
    }

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
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Simplified header
                _buildHeader(),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                      bottom: 100,
                    ),
                    child: Column(
                      children: [
                        // Main activity cards
                        _buildActivityCards(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Back button with bounce animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 28,
                  color: Colors.black,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => Get.back(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title with slide animation
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Measurement',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCards() {
    if (_isLoadingGrade) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            strokeWidth: 5,
          ),
        ),
      );
    }

    final availableTopics = _getAvailableTopics(_currentGrade);
    final activities = <Map<String, dynamic>>[];

    // Build activity list based on available topics
    if (availableTopics.contains('Length')) {
      activities.add({
        'title': 'Length',
        'image': 'assets/vectors/stitch1.png',
        'color': const Color(0xFF2196F3), // Blue
        'bgColor': const Color(0xFFBBDEFB), // Stronger Light Blue
        'icon': Icons.straighten_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'length'},
        'gameScreen': const LengthGameHubScreen(),
      });
    }

    if (availableTopics.contains('Area')) {
      activities.add({
        'title': 'Area',
        'image': 'assets/vectors/stitch2.png',
        'color': const Color(0xFF4CAF50), // Green
        'bgColor': const Color(0xFFC8E6C9), // Stronger Light Green
        'icon': Icons.grid_on_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'area'},
        'gameScreen': const AreaGameHubScreen(),
      });
    }

    if (availableTopics.contains('Volume')) {
      activities.add({
        'title': 'Volume',
        'image': 'assets/vectors/stitch3.png',
        'color': const Color(0xFF00BCD4), // Light Blue / Cyan
        'bgColor': const Color(0xFFB2EBF2), // Stronger Light Cyan
        'icon': Icons.local_drink_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'volume'},
        'gameScreen': const VolumeGameHubScreen(),
      });
    }

    if (availableTopics.contains('Weight')) {
      activities.add({
        'title': 'Weight',
        'image': 'assets/vectors/stitch4.png',
        'color': const Color(0xFFFF9800), // Orange
        'bgColor': const Color(0xFFFFE0B2), // Stronger Light Orange
        'icon': Icons.scale_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'weight'},
        'gameScreen': const WeightGameHubScreen(),
      });
    }

    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 150)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildBigActivityCard(
              title: activity['title'],
              image: activity['image'],
              color: activity['color'],
              bgColor: activity['bgColor'],
              icon: activity['icon'],
              onARTap: () {
                Get.toNamed(
                  activity['arRoute'],
                  arguments: activity['arArgs'],
                );
              },
              onGameTap: activity['gameScreen'] != null
                  ? () {
                      Get.to(
                        activity['gameScreen'] as Widget,
                        transition: Transition.rightToLeft,
                      );
                    }
                  : () {
                      Get.snackbar(
                        'Coming Soon',
                        '${activity['title']} game is under development',
                        backgroundColor: activity['color'],
                        colorText: Colors.white,
                        icon: const Icon(Icons.info_rounded, color: Colors.white),
                      );
                    },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBigActivityCard({
    required String title,
    required String image,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onARTap,
    required VoidCallback onGameTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content (Title and Image)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left side - Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - Vector Illustration
                Image.asset(
                  image,
                  width: 140,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 140,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8BBD0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFC2185B),
                        size: 50,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                // AR Camera button
                Expanded(
                  child: _buildActionButton(
                    label: 'Camera',
                    icon: Icons.camera_alt_rounded,
                    color: color,
                    onTap: onARTap,
                  ),
                ),
                const SizedBox(width: 16),
                // Play Game button
                Expanded(
                  child: _buildActionButton(
                    label: 'Play',
                    icon: Icons.videogame_asset_rounded,
                    color: color,
                    onTap: onGameTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4 + (_pulseController.value * 0.2)),
                  blurRadius: 12 + (_pulseController.value * 4),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
