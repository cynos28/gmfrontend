import 'package:flutter/material.dart';
import 'package:ganithamithura/screens/shapes/games/match_shapes_3d.dart';
import 'package:ganithamithura/screens/shapes/games/match_shapes_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/answer_questions_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/pattern_matching_api.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

/// GameHomeScreen - Game levels screen for Shapes module
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
        _GameLevelCard(
          title: 'Match 2D Shapes',
          subtitle: 'Level 1',
          localImage: 'assets/images/Shapes/kids1.png',
          color: const Color(0xFF4CAF50), // Green
          bgColor: const Color(0xFFC8E6C9),
          isLocked: _isLevelLocked(1),
          onTap: () => _handleLevelTap(1, () async {
            return Get.to(() => Match2DShapesAPIScreen(gameId: 'level1'));
          }),
        ),
        const SizedBox(height: 16),
        // Level 2
        _GameLevelCard(
          title: 'Answer 2D Questions',
          subtitle: 'Level 2',
          localImage: 'assets/images/Shapes/kids2.png',
          color: const Color(0xFFFF9800), // Orange
          bgColor: const Color(0xFFFFE0B2),
          isLocked: _isLevelLocked(2),
          onTap: () => _handleLevelTap(2, () async {
            return Get.to(() => Questions2DShapesAPIScreen(gameId: 'level2'));
          }),
        ),
        const SizedBox(height: 16),
        // Level 3
        _GameLevelCard(
          title: 'Match 3D Shapes',
          subtitle: 'Level 3',
          localImage: 'assets/images/Shapes/kids3.png',
          color: const Color(0xFFE91E63), // Pink
          bgColor: const Color(0xFFF8BBD0),
          isLocked: _isLevelLocked(3),
          onTap: () => _handleLevelTap(3, () async {
            return Get.to(() => const Match3DShapesScreen());
          }),
        ),
        const SizedBox(height: 16),
        // Level 4
        _GameLevelCard(
          title: 'Answer 3D Questions',
          subtitle: 'Level 4',
          localImage: 'assets/images/Shapes/kids4.png',
          color: const Color(0xFF2196F3), // Blue
          bgColor: const Color(0xFFBBDEFB),
          isLocked: _isLevelLocked(4),
          onTap: () => _handleLevelTap(4, () async {
            return Get.to(() => Questions2DShapesAPIScreen(gameId: 'level4'));
          }),
        ),
        const SizedBox(height: 16),
        // Level 5
        _GameLevelCard(
          title: 'Pattern Matching 1',
          subtitle: 'Level 5',
          localImage: 'assets/images/Shapes/kids5.png',
          color: const Color(0xFF9C27B0), // Purple
          bgColor: const Color(0xFFE1BEE7),
          isLocked: _isLevelLocked(5),
          onTap: () => _handleLevelTap(5, () async {
            return Get.to(() => PatternMatchingAPIScreen(gameId: 'level5'));
          }),
        ),
        const SizedBox(height: 16),
        // Level 6
        _GameLevelCard(
          title: 'Pattern Matching 2',
          subtitle: 'Level 6',
          localImage: 'assets/images/Shapes/kids6.png',
          color: const Color(0xFF00BCD4), // Cyan
          bgColor: const Color(0xFFB2EBF2),
          isLocked: _isLevelLocked(6),
          onTap: () => _handleLevelTap(6, () async {
            return Get.to(() => PatternMatchingAPIScreen(gameId: 'level6'));
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Game Level Card Widget - Styled like ShapeHomeScreen cards
class _GameLevelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String localImage;
  final Color color;
  final Color bgColor;
  final bool isLocked;
  final VoidCallback onTap;

  const _GameLevelCard({
    required this.title,
    required this.subtitle,
    required this.localImage,
    required this.color,
    required this.bgColor,
    this.isLocked = false,
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
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade300 : bgColor,
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
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isLocked 
                                  ? Colors.black45
                                  : Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isLocked) ...[
                              Icon(
                                Icons.lock,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isLocked ? Colors.grey.shade600 : color,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          localImage,
                          fit: BoxFit.contain,
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
