import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/services/user_service.dart';

/// MeasurementHomeScreen - Main screen for Measurement module
class MeasurementHomeScreen extends StatefulWidget {
  const MeasurementHomeScreen({super.key});

  @override
  State<MeasurementHomeScreen> createState() => _MeasurementHomeScreenState();
}

class _MeasurementHomeScreenState extends State<MeasurementHomeScreen> {
  int _currentNavIndex = 0;
  int _currentGrade = 1;
  bool _isLoadingGrade = true;

  @override
  void initState() {
    super.initState();
    _loadGrade();
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

  /// Get available topics based on grade level
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
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KidsColors.primaryAccent.withOpacity(0.1),
                        KidsColors.secondaryAccent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: KidsShadows.soft,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: KidsColors.textPrimary,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Measurements',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: KidsColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten_rounded,
                                  size: 16,
                                  color: KidsColors.highlightAccent,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Learn to measure!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KidsColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 24,
                      bottom: 80, // Space for bottom nav
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AR Challenges Section
                        _buildSectionHeader(
                          title: 'AR Challenges',
                          icon: Icons.camera_alt_rounded,
                          subtitle: 'Scan & Learn',
                          color: KidsColors.primaryAccent,
                        ),
                        const SizedBox(height: 16),
                        
                        // AR Challenges Grid
                        _buildARChallengesGrid(),
                        const SizedBox(height: 28),
                        
                        // Learning Games Section
                        _buildSectionHeader(
                          title: 'Learning Games',
                          icon: Icons.games_rounded,
                          subtitle: 'Fun Practice',
                          color: KidsColors.secondaryAccent,
                        ),
                        const SizedBox(height: 16),
                        
                        // Games Grid
                        _buildGamesGrid(),
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: KidsColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildARChallengesGrid() {
    if (_isLoadingGrade) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableTopics = _getAvailableTopics(_currentGrade);
    final List<Widget> firstRow = [];
    final List<Widget> secondRow = [];

    // Build first row
    if (availableTopics.contains('Length')) {
      firstRow.add(Expanded(
        child: _buildARCard(
          title: 'Length',
          subtitle: 'Measure objects',
          units: 'mm · cm · m',
          icon: Icons.straighten_rounded,
          backgroundColor: KidsColors.lengthBackground,
          iconColor: KidsColors.lengthColor,
          onTap: () {
            Get.toNamed('/ar-measurement', arguments: {
              'type': 'length',
            });
          },
        ),
      ));
    }

    if (availableTopics.contains('Capacity')) {
      if (firstRow.isNotEmpty) {
        firstRow.add(const SizedBox(width: 16));
      }
      firstRow.add(Expanded(
        child: _buildARCard(
          title: 'Capacity',
          subtitle: 'Measure liquids',
          units: 'ml · L',
          icon: Icons.local_drink_rounded,
          backgroundColor: KidsColors.capacityBackground,
          iconColor: KidsColors.capacityColor,
          onTap: () {
            Get.toNamed('/ar-measurement', arguments: {
              'type': 'capacity',
            });
          },
        ),
      ));
    }

    // Build second row
    if (availableTopics.contains('Weight')) {
      secondRow.add(Expanded(
        child: _buildARCard(
          title: 'Weight',
          subtitle: 'Measure mass',
          units: 'g · kg',
          icon: Icons.scale_rounded,
          backgroundColor: KidsColors.weightBackground,
          iconColor: KidsColors.weightColor,
          onTap: () {
            Get.toNamed('/ar-measurement', arguments: {
              'type': 'weight',
            });
          },
        ),
      ));
    }

    if (availableTopics.contains('Area')) {
      if (secondRow.isNotEmpty) {
        secondRow.add(const SizedBox(width: 16));
      }
      secondRow.add(Expanded(
        child: _buildARCard(
          title: 'Area',
          subtitle: 'Measure surfaces',
          units: 'cm² · m²',
          icon: Icons.grid_on_rounded,
          backgroundColor: KidsColors.areaBackground,
          iconColor: KidsColors.areaColor,
          onTap: () {
            Get.toNamed('/ar-measurement', arguments: {
              'type': 'area',
            });
          },
        ),
      ));
    }

    // Build column with available rows
    return Column(
      children: [
        if (firstRow.isNotEmpty) Row(children: firstRow),
        if (firstRow.isNotEmpty && secondRow.isNotEmpty) const SizedBox(height: 16),
        if (secondRow.isNotEmpty) Row(children: secondRow),
      ],
    );
  }

  Widget _buildARCard({
    required String title,
    required String subtitle,
    required String units,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor,
                      iconColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: KidsColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  units,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamesGrid() {
    return Column(
      children: [
        // First row: Length and Capacity games
        Row(
          children: [
            Expanded(
              child: _buildGameCard(
                title: 'Length',
                subtitle: 'Find & measure',
                icon: Icons.straighten_rounded,
                backgroundColor: KidsColors.lengthBackground,
                iconColor: KidsColors.lengthColor,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Length game is under development',
                    backgroundColor: KidsColors.primaryAccent,
                    colorText: Colors.white,
                    icon: const Icon(Icons.info_rounded, color: Colors.white),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGameCard(
                title: 'Capacity',
                subtitle: 'Unit conversion',
                icon: Icons.local_drink_rounded,
                backgroundColor: KidsColors.capacityBackground,
                iconColor: KidsColors.capacityColor,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Capacity game is under development',
                    backgroundColor: KidsColors.primaryAccent,
                    colorText: Colors.white,
                    icon: const Icon(Icons.info_rounded, color: Colors.white),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Area and Weight games
        Row(
          children: [
            Expanded(
              child: _buildGameCard(
                title: 'Area',
                subtitle: 'Estimate size',
                icon: Icons.grid_on_rounded,
                backgroundColor: KidsColors.areaBackground,
                iconColor: KidsColors.areaColor,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Area game is under development',
                    backgroundColor: KidsColors.primaryAccent,
                    colorText: Colors.white,
                    icon: const Icon(Icons.info_rounded, color: Colors.white),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGameCard(
                title: 'Weight',
                subtitle: 'Beat the scale',
                icon: Icons.scale_rounded,
                backgroundColor: KidsColors.weightBackground,
                iconColor: KidsColors.weightColor,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Weight game is under development',
                    backgroundColor: KidsColors.primaryAccent,
                    colorText: Colors.white,
                    icon: const Icon(Icons.info_rounded, color: Colors.white),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: KidsShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: KidsColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
