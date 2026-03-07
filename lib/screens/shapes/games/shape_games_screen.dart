import 'package:flutter/material.dart';
import 'package:ganithamithura/screens/shapes/games/match_shapes_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/answer_questions_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/pattern_matching_api.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/measurements/measurement_widgets.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

import '../../../widgets/shapes/shape_widgets.dart';

/// GameHomeScreen - Main screen for Measurement module
class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  final _apiService = ShapesApiService.instance;
  int _currentNavIndex = 0;
  Map<String, dynamic>? _levelAccessData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchLevelAccess();
  }
  
  Future<void> _fetchLevelAccess() async {
    try {
      final accessData = await _apiService.getLevelAccessStatus();
      if (!mounted) return;
      setState(() {
        _levelAccessData = accessData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching level access: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  bool _isLevelLocked(int level) {
    if (_levelAccessData == null) return level > 1; // Default: only level 1 unlocked
    
    final levels = _levelAccessData!['level_details'] as List<dynamic>;
    final levelInfo = levels.firstWhere(
      (l) => l['level'] == level,
      orElse: () => {'is_locked': true},
    );
    
    return levelInfo['is_locked'] ?? true;
  }
  
  Future<void> _handleLevelTap(int level, Future<dynamic> Function() onNavigate) async {
    if (_isLevelLocked(level)) {
      final highestPassed = _levelAccessData?['highest_passed_level'] ?? 0;
      final nextLevelNeeded = level - 1;
      
      Get.snackbar(
        '🔒 Level Locked',
        'Complete Level $nextLevelNeeded with full marks to unlock this level!',
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.lock, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } else {
      // Navigate and wait for return
      await onNavigate();
      // Refresh level access when user returns
      _fetchLevelAccess();
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate to home
      Get.back();
      return;
    }

    if (index == _currentNavIndex) {
      // Already on current tab
      return;
    }

    // TODO: Navigate to other screens when ready
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
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Color(AppColors.textBlack),
                        ),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Games',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.textBlack),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 24,
                            bottom: 90, // Space for bottom nav
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AR Challenges Grid
                              _buildShapeMenuCardGrid(),
                              const SizedBox(height: 24),
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

  Widget _buildShapeMenuCardGrid() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Level 1
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Match 2D Shapes',
                level: 'Level 1',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(1),
                onTap: () => _handleLevelTap(1, () async {
                  return Get.to(() => Match2DShapesAPIScreen(gameId: 'level1'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level 2
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Answer 2D Questions',
                level: 'Level 2',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(2),
                onTap: () => _handleLevelTap(2, () async {
                  return Get.to(() => Questions2DShapesAPIScreen(gameId: 'level2'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level 3
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Match 3D Shapes',
                level: 'Level 3',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(3),
                onTap: () => _handleLevelTap(3, () async {
                  return Get.to(() => Match2DShapesAPIScreen(gameId: 'level3'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level 4
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Answer 3D Questions',
                level: 'Level 4',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(4),
                onTap: () => _handleLevelTap(4, () async {
                  return Get.to(() => Questions2DShapesAPIScreen(gameId: 'level4'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level 5
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Pattern Matching 1',
                level: 'Level 5',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(5),
                onTap: () => _handleLevelTap(5, () async {
                  return Get.to(() => PatternMatchingAPIScreen(gameId: 'level5'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level 6
        Row(
          children: [
            Expanded(
              child: ShapeGameCard(
                title: 'Pattern Matching 2',
                level: 'Level 6',
                icon: 'assets/images/Vector.png',
                backgroundColor: const Color(0xFF36D399),
                borderColor: const Color(AppColors.numberBorder),
                starCount: 3,
                isLocked: _isLevelLocked(6),
                onTap: () => _handleLevelTap(6, () async {
                  return Get.to(() => PatternMatchingAPIScreen(gameId: 'level6'));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
