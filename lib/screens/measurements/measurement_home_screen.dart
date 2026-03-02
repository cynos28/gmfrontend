import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'games/length_game_hub_screen.dart';
import 'games/area_game_hub_screen.dart';
import 'games/volume_game_hub_screen.dart';
import 'dart:math' as math;

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
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadGrade();
    
    // Floating animation for decorative elements
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
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
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background decorations
            _buildFloatingDecorations(),
            
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

  Widget _buildFloatingDecorations() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top right decoration
            Positioned(
              top: 100 + (_floatingController.value * 20),
              right: 20,
              child: Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: _floatingController.value * math.pi / 4,
                  child: Icon(
                    Icons.straighten_rounded,
                    size: 80,
                    color: KidsColors.lengthColor,
                  ),
                ),
              ),
            ),
            // Bottom left decoration
            Positioned(
              bottom: 200 + (_floatingController.value * -15),
              left: 30,
              child: Opacity(
                opacity: 0.1,
                child: Transform.rotate(
                  angle: -_floatingController.value * math.pi / 6,
                  child: Icon(
                    Icons.grid_on_rounded,
                    size: 60,
                    color: KidsColors.areaColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KidsColors.primaryAccent.withOpacity(0.08),
            KidsColors.secondaryAccent.withOpacity(0.05),
          ],
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
                    color: KidsColors.primaryAccent.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 28,
                  color: KidsColors.textPrimary,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 32,
                        color: KidsColors.highlightAccent,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Let\'s Measure!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: KidsColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
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
        'emoji': '📏',
        'color': KidsColors.lengthColor,
        'bgColor': KidsColors.lengthBackground,
        'icon': Icons.straighten_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'length'},
        'gameScreen': const LengthGameHubScreen(),
      });
    }

    if (availableTopics.contains('Area')) {
      activities.add({
        'title': 'Area',
        'emoji': '⬜',
        'color': KidsColors.areaColor,
        'bgColor': KidsColors.areaBackground,
        'icon': Icons.grid_on_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'area'},
        'gameScreen': const AreaGameHubScreen(),
      });
    }

    if (availableTopics.contains('Volume')) {
      activities.add({
        'title': 'Volume',
        'emoji': '🥤',
        'color': KidsColors.volumeColor,
        'bgColor': KidsColors.volumeBackground,
        'icon': Icons.local_drink_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'volume'},
        'gameScreen': const VolumeGameHubScreen(),
      });
    }

    if (availableTopics.contains('Weight')) {
      activities.add({
        'title': 'Weight',
        'emoji': '⚖️',
        'color': KidsColors.weightColor,
        'bgColor': KidsColors.weightBackground,
        'icon': Icons.scale_rounded,
        'arRoute': '/ar-measurement',
        'arArgs': {'type': 'weight'},
        'gameScreen': null,
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
                opacity: value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildBigActivityCard(
              title: activity['title'],
              emoji: activity['emoji'],
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
                        () => activity['gameScreen'],
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
    required String emoji,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onARTap,
    required VoidCallback onGameTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title section with emoji
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Animated emoji
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                    ),
                  ),
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
