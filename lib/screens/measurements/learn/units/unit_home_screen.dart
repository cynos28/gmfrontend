import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/unit_progress_service.dart';
import 'package:ganithamithura/screens/measurements/learn/units/question_practice_screen.dart';

class UnitHomeScreen extends StatefulWidget {
  final Unit unit;

  const UnitHomeScreen({
    super.key,
    required this.unit,
  });

  @override
  State<UnitHomeScreen> createState() => _UnitHomeScreenState();
}

class _UnitHomeScreenState extends State<UnitHomeScreen> {
  final UnitProgressService _progressService = UnitProgressService.instance;
  StudentUnitProgress? _progress;
  bool _isLoading = true;
  int _selectedIndex = 1; // Learn tab

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await _progressService.getUnitProgress(widget.unit.id);
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Get.back();
      return;
    }
    if (index == _selectedIndex) return;
    
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  Color _getTopicColor() {
    switch (widget.unit.topic.toLowerCase()) {
      case 'length': return const Color(0xFF2196F3);
      case 'area': return const Color(0xFF4CAF50);
      case 'capacity':
      case 'volume': return const Color(0xFF00BCD4);
      case 'weight': return const Color(0xFFFF9800);
      default: return const Color(0xFF2196F3);
    }
  }

  Color _getTopicBackgroundColor() {
    switch (widget.unit.topic.toLowerCase()) {
      case 'length': return const Color(0xFFBBDEFB);
      case 'area': return const Color(0xFFC8E6C9);
      case 'capacity':
      case 'volume': return const Color(0xFFB2EBF2);
      case 'weight': return const Color(0xFFFFE0B2);
      default: return const Color(0xFFBBDEFB);
    }
  }

  IconData _getTopicIcon() {
    switch (widget.unit.topic.toLowerCase()) {
      case 'length': return Icons.straighten_rounded;
      case 'area': return Icons.crop_square_rounded;
      case 'volume':
      case 'capacity': return Icons.local_drink_rounded;
      case 'weight': return Icons.scale_rounded;
      default: return Icons.straighten_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTopicColor();
    final bgColor = _getTopicBackgroundColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header matched to home gradient
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 28),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Grade ${widget.unit.grade}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Icon(_getTopicIcon(), color: Colors.white, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.unit.topic,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: color.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              widget.unit.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.unit.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.unit.description!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_progress != null)
                      _buildProgressCard(color, bgColor),
                      
                    const SizedBox(height: 24),
                    const Text(
                      'Let\'s Play & Learn!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: () => Get.to(() => QuestionPracticeScreen(unit: widget.unit), transition: Transition.rightToLeft),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 40),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Practice Questions',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Test your knowledge!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildProgressCard(Color color, Color bgColor) {
    final progress = _progress!;
    final accuracy = progress.questionsAnswered > 0 ? progress.accuracy : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Progress',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              Row(
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < progress.stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFFFB800),
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(Icons.quiz_rounded, 'Questions', '${progress.questionsAnswered}', color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(Icons.check_circle_rounded, 'Correct', '${progress.correctAnswers}', const Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(Icons.percent_rounded, 'Accuracy', '${accuracy.toInt()}%', const Color(0xFF9C27B0)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
