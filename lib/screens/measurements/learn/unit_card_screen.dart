import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/screens/measurements/learn/units/unit_home_screen.dart';

import 'package:ganithamithura/services/unit_progress_service.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/models/unit_models.dart';

class UnitCardScreen extends StatefulWidget {
  const UnitCardScreen({super.key});

  @override
  State<UnitCardScreen> createState() => _UnitCardScreenState();
}

class _UnitCardScreenState extends State<UnitCardScreen> {
  int _selectedIndex = 1; // Learn tab selected
  final UnitProgressService _progressService = UnitProgressService.instance;
  
  Map<String, dynamic> _lengthProgress = {};
  Map<String, dynamic> _areaProgress = {};
  Map<String, dynamic> _capacityProgress = {};
  Map<String, dynamic> _weightProgress = {};
  bool _isLoadingProgress = true;
  int _currentGrade = 1;

  @override
  void initState() {
    super.initState();
    _loadGradeAndProgress();
  }

  /// Get available topics based on grade level
  /// Grade 1: Length only
  /// Grade 2: Length, Area
  /// Grade 3: Length, Area, Weight, Capacity
  /// Grade 4: All topics
  List<String> _getAvailableTopics(int grade) {
    switch (grade) {
      case 1:
        return ['Length'];
      case 2:
        return ['Length', 'Area'];
      case 3:
        return ['Length', 'Area', 'Weight', 'Capacity'];
      case 4:
        return ['Length', 'Area', 'Weight', 'Capacity'];
      default:
        return ['Length'];
    }
  }

  Future<void> _loadGradeAndProgress() async {
    if (!mounted) return;
    setState(() => _isLoadingProgress = true);
    
    try {
      // Load current grade
      final grade = await UserService.getGrade();
      
      if (!mounted) return;
      setState(() {
        _currentGrade = grade;
      });
      
      await _loadAllProgress();
    } catch (e) {
      debugPrint('Error loading grade: $e');
      if (!mounted) return;
      setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _loadAllProgress() async {
    if (!mounted) return;
    setState(() => _isLoadingProgress = true);
    
    try {
      // Load from backend (syncs with local cache)
      await _progressService.loadFromBackend();
      
      final lengthProgress = await _progressService.getTopicProgress('Length');
      final areaProgress = await _progressService.getTopicProgress('Area');
      final capacityProgress = await _progressService.getTopicProgress('Capacity');
      final weightProgress = await _progressService.getTopicProgress('Weight');
      
      setState(() {
        _lengthProgress = lengthProgress;
        _areaProgress = areaProgress;
        _capacityProgress = capacityProgress;
        _weightProgress = weightProgress;
        _isLoadingProgress = false;
      });
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() => _isLoadingProgress = false);
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to home
      Get.back();
      return;
    }
    
    if (index == 1) {
      // Already on Learn/Units screen
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
        child: Padding(
          padding: const EdgeInsets.all(KidsSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: KidsSpacing.minTapTarget,
                    height: KidsSpacing.minTapTarget,
                    decoration: BoxDecoration(
                      color: KidsColors.primaryBackground,
                      borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: KidsSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Measurement Units',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: KidsColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: KidsSpacing.xs),
                        Text(
                          'Grade $_currentGrade',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KidsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KidsSpacing.xxl),
              
              // Overall Progress Summary
              _buildProgressSummary(),
              
              const SizedBox(height: KidsSpacing.xl),
              
              
              
              const SizedBox(height: KidsSpacing.xl),
              
              const Text(
                'Practice by Topic',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KidsColors.textPrimary,
                ),
              ),
              const SizedBox(height: KidsSpacing.cardMarginLarge),
              
              // Content - Measurement Units Grid
              Expanded(
                child: _isLoadingProgress
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUnitsGrid(),
              ),
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

  Widget _buildUnitsGrid() {
    final availableTopics = _getAvailableTopics(_currentGrade);
    
    // Build cards only for available topics
    final List<Widget> cards = [];
    
    if (availableTopics.contains('Length')) {
      cards.add(_buildUnitCard(
        title: 'Length',
        subtitle: 'cm, m, km',
        icon: Icons.straighten,
        color: const Color(AppColors.measurementColor),
        borderColor: const Color(AppColors.measurementBorder),
        iconColor: const Color(AppColors.measurementIcon),
        progress: _lengthProgress,
        onTap: () {
          Get.to(() => UnitHomeScreen(
            unit: Unit(
              id: 'unit_length_$_currentGrade',
              name: 'Length – cm and m',
              topic: 'Length',
              grade: _currentGrade,
              description: 'Learn to measure length using centimeters and meters',
              iconName: 'straighten',
            ),
          ))?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Area')) {
      cards.add(_buildUnitCard(
        title: 'Area',
        subtitle: 'cm², m², km²',
        icon: Icons.crop_square,
        color: const Color(AppColors.measurementColor),
        borderColor: const Color(AppColors.measurementBorder),
        iconColor: const Color(AppColors.measurementIcon),
        progress: _areaProgress,
        onTap: () {
          Get.to(() => UnitHomeScreen(
            unit: Unit(
              id: 'unit_area_$_currentGrade',
              name: 'Area – cm² and m²',
              topic: 'Area',
              grade: _currentGrade,
              description: 'Understand how to calculate area of shapes',
              iconName: 'crop_square',
            ),
          ))?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Capacity')) {
      cards.add(_buildUnitCard(
        title: 'Capacity',
        subtitle: 'ml, l',
        icon: Icons.local_drink,
        color: const Color(AppColors.measurementColor),
        borderColor: const Color(AppColors.measurementBorder),
        iconColor: const Color(AppColors.measurementIcon),
        progress: _capacityProgress,
        onTap: () {
          Get.to(() => UnitHomeScreen(
            unit: Unit(
              id: 'unit_capacity_$_currentGrade',
              name: 'Capacity – ml and l',
              topic: 'Capacity',
              grade: _currentGrade,
              description: 'Learn about volume and capacity measurements',
              iconName: 'local_drink',
            ),
          ))?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Weight')) {
      cards.add(_buildUnitCard(
        title: 'Weight',
        subtitle: 'g, kg',
        icon: Icons.fitness_center,
        color: const Color(AppColors.measurementColor),
        borderColor: const Color(AppColors.measurementBorder),
        iconColor: const Color(AppColors.measurementIcon),
        progress: _weightProgress,
        onTap: () {
          Get.to(() => UnitHomeScreen(
            unit: Unit(
              id: 'unit_weight_$_currentGrade',
              name: 'Weight – g and kg',
              topic: 'Weight',
              grade: _currentGrade,
              description: 'Understand weight measurements in grams and kilograms',
              iconName: 'fitness_center',
            ),
          ))?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: KidsSpacing.cardMarginLarge,
      mainAxisSpacing: KidsSpacing.cardMarginLarge,
      childAspectRatio: 0.95,
      children: cards,
    );
  }

  Widget _buildProgressSummary() {
    if (_isLoadingProgress) {
      return const SizedBox.shrink();
    }

    final totalQuestions = (_lengthProgress['questionsAnswered'] ?? 0) +
        (_areaProgress['questionsAnswered'] ?? 0) +
        (_capacityProgress['questionsAnswered'] ?? 0) +
        (_weightProgress['questionsAnswered'] ?? 0);

    final totalCorrect = (_lengthProgress['correctAnswers'] ?? 0) +
        (_areaProgress['correctAnswers'] ?? 0) +
        (_capacityProgress['correctAnswers'] ?? 0) +
        (_weightProgress['correctAnswers'] ?? 0);

    if (totalQuestions == 0) {
      return const SizedBox.shrink();
    }

    final overallAccuracy = (totalCorrect / totalQuestions * 100);

    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KidsColors.successLight,
            KidsColors.secondaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
        border: Border.all(
          color: KidsColors.success,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: KidsColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: KidsColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: KidsSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KidsSpacing.sm),
                Wrap(
                  spacing: KidsSpacing.sm,
                  runSpacing: KidsSpacing.sm,
                  children: [
                    _buildStatChip(
                      icon: Icons.quiz_rounded,
                      label: '$totalQuestions',
                      color: KidsColors.primaryAccent,
                    ),
                    _buildStatChip(
                      icon: Icons.check_circle_rounded,
                      label: '$totalCorrect',
                      color: KidsColors.success,
                    ),
                    _buildStatChip(
                      icon: Icons.percent_rounded,
                      label: '${overallAccuracy.toStringAsFixed(0)}%',
                      color: KidsColors.highlightAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KidsSpacing.sm,
        vertical: KidsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(KidsSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: KidsSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  }

  Widget _buildUnitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required Map<String, dynamic> progress,
    required VoidCallback onTap,
  }) {
    final questionsAnswered = progress['questionsAnswered'] ?? 0;
    final accuracy = progress['accuracy'] ?? 0.0;
    final hasProgress = questionsAnswered > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
          boxShadow: KidsShadows.soft,
        ),
        padding: const EdgeInsets.all(KidsSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(KidsSpacing.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KidsColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: KidsSpacing.xs),
            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KidsColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasProgress) ...[
              const SizedBox(height: KidsSpacing.sm),
              // Progress stats
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KidsSpacing.sm,
                  vertical: KidsSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(KidsSpacing.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: iconColor,
                    ),
                    const SizedBox(width: KidsSpacing.xs),
                    Text(
                      '$questionsAnswered Q',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: KidsSpacing.sm),
                    Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

