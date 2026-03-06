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
  Map<String, dynamic> _volumeProgress = {};
  Map<String, dynamic> _weightProgress = {};
  bool _isLoadingProgress = true;
  int _currentGrade = 1;

  @override
  void initState() {
    super.initState();
    _loadGradeAndProgress();
  }

  List<String> _getAvailableTopics(int grade) {
    if (grade == 1) return ['Length'];
    if (grade == 2) return ['Length', 'Area'];
    return ['Length', 'Area', 'Weight', 'Volume'];
  }

  Future<void> _loadGradeAndProgress() async {
    if (!mounted) return;
    setState(() => _isLoadingProgress = true);
    
    try {
      final grade = await UserService.getGrade();
      if (!mounted) return;
      setState(() => _currentGrade = grade);
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
      await _progressService.loadFromBackend();
      final lengthProgress = await _progressService.getTopicProgress('Length');
      final areaProgress = await _progressService.getTopicProgress('Area');
      final volumeProgress = await _progressService.getTopicProgress('Volume');
      final weightProgress = await _progressService.getTopicProgress('Weight');
      
      setState(() {
        _lengthProgress = lengthProgress;
        _areaProgress = areaProgress;
        _volumeProgress = volumeProgress;
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
      Get.back();
      return;
    }
    if (index == 1) return;
    
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine cross axis count for responsive grid
    final int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 2 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildProgressSummary(),
                    if (!_isLoadingProgress && _hasProgress()) const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Practice by Topic',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingProgress
                          ? const Center(child: CircularProgressIndicator())
                          : _buildUnitsGrid(crossAxisCount),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  bool _hasProgress() {
    final tQ = (_lengthProgress['questionsAnswered'] ?? 0) +
        (_areaProgress['questionsAnswered'] ?? 0) +
        (_volumeProgress['questionsAnswered'] ?? 0) +
        (_weightProgress['questionsAnswered'] ?? 0);
    return tQ > 0;
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
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
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn Units',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Grade $_currentGrade',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.asset('assets/vectors/kid3.png', height: 75),
        ],
      ),
    );
  }

  Widget _buildUnitsGrid(int columns) {
    final availableTopics = _getAvailableTopics(_currentGrade);
    final List<Widget> cards = [];
    
    if (availableTopics.contains('Length')) {
      cards.add(_buildUnitCard(
        title: 'Length',
        subtitle: 'cm, m, km',
        icon: Icons.straighten_rounded,
        color: const Color(0xFF2196F3),
        bgColor: const Color(0xFFBBDEFB),
        image: 'assets/vectors/stitch1.png',
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
          ), transition: Transition.rightToLeft)?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Area')) {
      cards.add(_buildUnitCard(
        title: 'Area',
        subtitle: 'cm², m², km²',
        icon: Icons.crop_square_rounded,
        color: const Color(0xFF4CAF50),
        bgColor: const Color(0xFFC8E6C9),
        image: 'assets/vectors/stitch2.png',
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
          ), transition: Transition.rightToLeft)?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Volume')) {
      cards.add(_buildUnitCard(
        title: 'Volume',
        subtitle: 'ml, l',
        icon: Icons.local_drink_rounded,
        color: const Color(0xFF00BCD4),
        bgColor: const Color(0xFFB2EBF2),
        image: 'assets/vectors/stitch3.png',
        progress: _volumeProgress,
        onTap: () {
          Get.to(() => UnitHomeScreen(
            unit: Unit(
              id: 'unit_volume_$_currentGrade',
              name: 'Volume – ml and l',
              topic: 'Volume',
              grade: _currentGrade,
              description: 'Learn about volume and liquid measurements',
              iconName: 'local_drink',
            ),
          ), transition: Transition.rightToLeft)?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    if (availableTopics.contains('Weight')) {
      cards.add(_buildUnitCard(
        title: 'Weight',
        subtitle: 'g, kg',
        icon: Icons.scale_rounded,
        color: const Color(0xFFFF9800),
        bgColor: const Color(0xFFFFE0B2),
        image: 'assets/vectors/stitch4.png',
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
          ), transition: Transition.rightToLeft)?.then((_) => _loadGradeAndProgress());
        },
      ));
    }
    
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: columns == 1 ? 1.8 : 1.2,
      padding: const EdgeInsets.only(bottom: 24),
      children: cards,
    );
  }

  Widget _buildProgressSummary() {
    if (_isLoadingProgress) return const SizedBox.shrink();

    final totalQuestions = (_lengthProgress['questionsAnswered'] ?? 0) +
        (_areaProgress['questionsAnswered'] ?? 0) +
        (_volumeProgress['questionsAnswered'] ?? 0) +
        (_weightProgress['questionsAnswered'] ?? 0);

    final totalCorrect = (_lengthProgress['correctAnswers'] ?? 0) +
        (_areaProgress['correctAnswers'] ?? 0) +
        (_volumeProgress['correctAnswers'] ?? 0) +
        (_weightProgress['correctAnswers'] ?? 0);

    if (totalQuestions == 0) return const SizedBox.shrink();

    final overallAccuracy = (totalCorrect / totalQuestions * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Great Job!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip(icon: Icons.quiz_rounded, label: '$totalQuestions Q', color: const Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    _buildStatChip(icon: Icons.check_circle_rounded, label: '$totalCorrect OK', color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    _buildStatChip(icon: Icons.percent_rounded, label: '${overallAccuracy.toStringAsFixed(0)}%', color: const Color(0xFF9C27B0)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String image,
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
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Text details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: Colors.white, size: 28),
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          if (hasProgress) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$questionsAnswered Qs',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${accuracy.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Image element
                    Expanded(
                      flex: 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Image.asset(image, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
