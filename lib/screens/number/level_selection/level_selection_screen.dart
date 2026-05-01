import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/ui_helpers.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';

/// LevelSelectionScreen - Display 5 levels with only Level 1 enabled
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with TickerProviderStateMixin {
  late List<LearningLevel> _levels;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _initializeLevels();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeLevels() async {
    final storageService = StorageService.instance;
    
    // Load unlock status from storage (set by progress test)
    final level1Unlocked = await storageService.isLevelUnlocked(1);
    final level2Unlocked = await storageService.isLevelUnlocked(2);
    final level3Unlocked = await storageService.isLevelUnlocked(3);
    final level4Unlocked = await storageService.isLevelUnlocked(4);
    final level5Unlocked = await storageService.isLevelUnlocked(5);
    
    setState(() {
      _levels = [
        LearningLevel(
          levelNumber: 1,
          title: 'Level 1',
          description: 'Numbers 1-10',
          minNumber: 1,
          maxNumber: 10,
          isUnlocked: level1Unlocked,
          totalActivities: 50, // 10 numbers × 5 activities
          completedActivities: 0,
        ),
        LearningLevel(
          levelNumber: 2,
          title: 'Level 2',
          description: 'Numbers 11-20',
          minNumber: 11,
          maxNumber: 20,
          isUnlocked: level2Unlocked,
        ),
        LearningLevel(
          levelNumber: 3,
          title: 'Level 3',
          description: 'Numbers 21-50',
          minNumber: 21,
          maxNumber: 50,
          isUnlocked: level3Unlocked,
        ),
        LearningLevel(
          levelNumber: 4,
          title: 'Level 4',
          description: 'Numbers 51-100',
          minNumber: 51,
          maxNumber: 100,
          isUnlocked: level4Unlocked,
        ),
        LearningLevel(
          levelNumber: 5,
          title: 'Level 5',
          description: 'Advanced Numbers',
          minNumber: 100,
          maxNumber: 1000,
          isUnlocked: level5Unlocked,
        ),
      ];
      _isLoading = false;
    });
    
    // Start fade-in animation after data is loaded
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8E8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learn Numbers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              "Let's Learn Numbers Together !",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Image.asset(
                'assets/images/number/teacher_avatar.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Color(0xFF7C6FDD),
                    size: 28,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Start from the Beginning" Section
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8E8F0),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: const Text(
                      'Start from the Beginning',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  // Level Cards with staggered animation
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: _levels.asMap().entries.map((entry) {
                        final index = entry.key;
                        final level = entry.value;
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _AnimatedLevelCard(
                                key: ValueKey(level.levelNumber),
                                delay: index * 100,
                                child: _buildLevelCard(level),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelCard(LearningLevel level) {
    // Calculate progress (for display only - in real app, fetch from backend)
    final totalLevels = _levels.length;
    final progress = '${level.levelNumber}/$totalLevels';
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left side - Text and button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${level.levelNumber.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Start/Unlock Button
                      ElevatedButton(
                        onPressed: level.isUnlocked 
                            ? () => _startLevel(level)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: level.isUnlocked
                              ? const Color(0xFF81C784)
                              : const Color(0xFFBDBDBD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          level.isUnlocked ? 'Start' : 'Unlock',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Illustration
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/number/level_illustration.png',
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
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFFC2185B),
                        size: 50,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Progress badge (top right)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                progress,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startLevel(LearningLevel level) async {
    try {
      // Show loading with a small delay to ensure overlay is ready
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      debugPrint('Starting Level ${level.levelNumber} - Fetching activities...');

      Get.dialog(
        Material(
          color: Colors.transparent,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Additional delay to ensure dialog is fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) {
        Get.back();
        return;
      }

      // Fetch activities for this level with timeout
      final activities = await NumApiService.instance
          .getActivitiesForLevel(level.levelNumber)
          .timeout(
            Duration(seconds: AppConstants.apiTimeout),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      if (!mounted) {
        Get.back();
        return;
      }

      if (activities.isEmpty) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        await UIHelpers.showSafeSnackbar(
          title: 'No Activities',
          message:
              'No activities found for this level. Please try again later.',
          backgroundColor: Color(AppColors.warningColor),
        );
        return;
      }

      Get.back(); // Close loading

      // Use LearningFlowManager to start/resume learning
      final learningFlowManager = LearningFlowManager.instance;
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if there's a saved session for this level
      final savedSession = learningFlowManager.getSavedSession();

      if (savedSession != null && savedSession.level == level.levelNumber) {
        // Resume from saved position (skips completed activities like video)
        debugPrint(
          '📥 Resuming from saved session: Number ${savedSession.number}',
        );
        await learningFlowManager.resumeLearning(levelData: level);
      } else {
        // Start fresh from the first number
        debugPrint('🆕 Starting fresh from number ${level.minNumber}');
        await learningFlowManager.startLearningFromNumber(
          level: level.levelNumber,
          startNumber: level.minNumber,
          levelData: level,
        );
      }
    } catch (e) {
      debugPrint('Error in _startLevel: $e');

      // Safely close dialog if it's open
      try {
        if (mounted && Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (_) {
        // Dialog might not be open, ignore
      }

      // Wait before showing snackbar
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      final errorMessage = UIHelpers.getErrorMessage(e);

      // Use ScaffoldMessenger as fallback for more reliability
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(errorMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Color(AppColors.errorColor),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (snackbarError) {
        debugPrint('Could not show snackbar: $snackbarError');
      }
    }
  }
}

/// Animated wrapper for level cards with scale and tap effects
class _AnimatedLevelCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedLevelCard({
    super.key,
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedLevelCard> createState() => _AnimatedLevelCardState();
}

class _AnimatedLevelCardState extends State<_AnimatedLevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
