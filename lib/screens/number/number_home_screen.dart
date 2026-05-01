import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/number/level_selection/level_selection_screen.dart';
import 'package:ganithamithura/screens/number/test/progress_test_screen.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';

/// NumberHomeScreen - Main screen for Number Service
/// Displays progress, main learning card, and activity options
class NumberHomeScreen extends StatefulWidget {
  const NumberHomeScreen({super.key});

  @override
  State<NumberHomeScreen> createState() => _NumberHomeScreenState();
}

class _NumberHomeScreenState extends State<NumberHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressFadeAnimation;
  late Animation<double> _floatAnimation;
  
  final StorageService _storageService = StorageService.instance;
  int _progressPercentage = 0;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _progressFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
    _calculateProgress();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  /// Calculate overall progress across all levels and tests
  Future<void> _calculateProgress() async {
    try {
      // Calculate number completion progress
      int totalNumbers = 0;
      int completedNumbers = 0;

      // Loop through all 5 levels
      for (int level = 1; level <= AppConstants.totalLevels; level++) {
        final config = AppConstants.getLevelConfig(level);
        final levelTotalNumbers = config.numberCount;
        totalNumbers += levelTotalNumbers;

        // Get completed numbers for this level
        final completed = await _storageService.getCompletedNumbers(level);
        final levelCompletedCount = completed.values.where((isCompleted) => isCompleted).length;
        completedNumbers += levelCompletedCount;
      }

      final numberProgress = totalNumbers > 0 
          ? (completedNumbers / totalNumbers) * 100 
          : 0.0;

      // Calculate test completion progress
      final testTypes = ['placement', 'beginner', 'intermediate', 'advanced'];
      int passedTests = 0;

      for (final testType in testTypes) {
        final bestScore = await _storageService.getBestTestScore(testType);
        if (bestScore != null && bestScore.isPassed) {
          passedTests++;
        }
      }

      final testProgress = (passedTests / testTypes.length) * 100;

      // Combine progress: 70% weight to numbers, 30% weight to tests
      final overallProgress = (numberProgress * 0.7) + (testProgress * 0.3);
      final percentage = overallProgress.round();

      if (mounted) {
        setState(() {
          _progressPercentage = percentage;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      if (mounted) {
        setState(() {
          _progressPercentage = 0;
          _isLoadingProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Numbers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.standardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Progress Card with fade animation
              FadeTransition(
                opacity: _progressFadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildProgressCard(),
                ),
              ),

              const SizedBox(height: 20),

              // Main Learning Card with gentle floating animation
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMainLearningCard(context),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // "Let's Do" Section Title with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Let's Do",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Learn Numbers Card with staggered animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _AnimatedCard(
                    delay: 200,
                    child: _buildLearnNumbersCard(context),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Activity Hub Card with staggered animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _AnimatedCard(
                    delay: 400,
                    child: _buildActivityHubCard(context),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress indicator card
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          _isLoadingProgress
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                  ),
                )
              : Text(
                  '$_progressPercentage%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
        ],
      ),
    );
  }

  /// Main "Let's Learn Numbers" card with purple gradient
  Widget _buildMainLearningCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6FDD), Color(0xFF5F52C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6FDD).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => const LevelSelectionScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Let's Learn Numbers",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Master counting from 1 to 1000',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
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
    );
  }

  /// Learn Numbers card - pink background with avatar
  Widget _buildLearnNumbersCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => const LevelSelectionScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Image.asset(
                  'assets/images/number/learn_icon.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8BBD0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Color(0xFFC2185B),
                        size: 30,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Learn Numbers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Watch video lessons,\ntrace numbers and\npractice number name',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar image
                Image.asset(
                  'assets/images/number/teacher_avatar.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8BBD0),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFC2185B),
                        size: 40,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Activity Hub card - green background with kids illustration
  Widget _buildActivityHubCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB9E6D3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => const ProgressTestScreen()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Image.asset(
                  'assets/images/number/activity_icon.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.extension,
                        color: Colors.white,
                        size: 30,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Hub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Let's test your\nknowledge",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kids illustration
                Image.asset(
                  'assets/images/number/kids_learning.png',
                  width: 120,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated wrapper for cards with scale and tap effects
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
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
