import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/number/level_selection/level_selection_screen.dart';
import 'package:ganithamithura/screens/number/test/progress_test_screen.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/screens/number/widgets/floating_numbers_background.dart';

/// NumberHomeScreen - Main screen for Number Service
class NumberHomeScreen extends StatefulWidget {
  const NumberHomeScreen({super.key});

  @override
  State<NumberHomeScreen> createState() => _NumberHomeScreenState();
}

class _NumberHomeScreenState extends State<NumberHomeScreen> {
  final StorageService _storageService = StorageService.instance;
  int _progressPercentage = 0;
  bool _isLoadingProgress = true;
  String _userName = 'Learner';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _calculateProgress();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user.name.split(' ').first;
      });
    }
  }

  Future<void> _calculateProgress() async {
    try {
      int totalNumbers = 0;
      int completedNumbers = 0;

      for (int level = 1; level <= AppConstants.totalLevels; level++) {
        final config = AppConstants.getLevelConfig(level);
        final levelTotalNumbers = config.numberCount;
        totalNumbers += levelTotalNumbers;

        final completed = await _storageService.getCompletedNumbers(level);
        final levelCompletedCount = completed.values.where((isCompleted) => isCompleted).length;
        completedNumbers += levelCompletedCount;
      }

      final numberProgress = totalNumbers > 0 
          ? (completedNumbers / totalNumbers) * 100 
          : 0.0;

      final testTypes = ['placement', 'beginner', 'intermediate', 'advanced'];
      int passedTests = 0;

      for (final testType in testTypes) {
        final bestScore = await _storageService.getBestTestScore(testType);
        if (bestScore != null && bestScore.isPassed) {
          passedTests++;
        }
      }

      final testProgress = (passedTests / testTypes.length) * 100;
      final overallProgress = (numberProgress * 0.7) + (testProgress * 0.3);

      if (mounted) {
        setState(() {
          _progressPercentage = overallProgress.round();
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
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Subtle background
          const Opacity(
            opacity: 0.8,
            child: FloatingNumbersBackground(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Back Button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1. Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 2. Level/Progress Card
                  _buildLevelCard(),
                  const SizedBox(height: 32),

                  // 3. Feature Cards
                  Text(
                    "Let's Do",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    title: 'Learn Numbers',
                    subtitle: 'Master numbers from 1 to 1000\nwith fun interactive lessons.',
                    icon: Icons.school_rounded,
                    color: const Color(0xFFFCE4EC), // Light Pink/Rose
                    iconColor: const Color(0xFFE91E63), // Pink
                    imageAsset: 'assets/images/number/teacher_avatar.png', 
                    onTap: () {
                      Get.to(() => const LevelSelectionScreen());
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFeatureCard(
                    title: 'Activity Hub',
                    subtitle: 'Test your knowledge and\nbecome a number genius!',
                    icon: Icons.extension_rounded,
                    color: const Color(0xFFE8F5E9), // Light Green
                    iconColor: const Color(0xFF4CAF50), // Green
                    imageAsset: 'assets/images/number/kids_learning.png', 
                    onTap: () {
                      Get.to(() => const ProgressTestScreen());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_userName',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.insert_chart_outlined_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to count!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildLevelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple gradient corresponding to numbers
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _isLoadingProgress
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            '$_progressPercentage%',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOutCubic,
                      width: _isLoadingProgress ? 0 : (constraints.maxWidth * (_progressPercentage / 100)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399), // Bright emerald progress
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34D399).withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    String? imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (imageAsset != null)
              Image.asset(
                imageAsset,
                width: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(icon, size: 80, color: iconColor.withOpacity(0.5)),
              )
            else
              Icon(Icons.arrow_forward_ios_rounded, size: 24, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
