import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';
import 'package:ganithamithura/screens/measurements/units/question_practice_screen.dart';
import 'package:ganithamithura/screens/measurements/units/unit_chat_screen.dart';

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
  final UnitApiService _apiService = UnitApiService();
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
    final progress = await _apiService.getUnitProgress(widget.unit.id);
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back
      Get.back();
      return;
    }
    
    if (index == _selectedIndex) {
      // Already on current tab
      return;
    }
    
    // TODO: Handle other navigation items
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  Color _getTopicColor() {
    return const Color(AppColors.measurementColor);
  }

  Color _getTopicIconColor() {
    return const Color(AppColors.measurementIcon);
  }

  IconData _getTopicIcon() {
    switch (widget.unit.topic.toLowerCase()) {
      case 'length':
        return Icons.straighten;
      case 'area':
        return Icons.crop_square;
      case 'capacity':
        return Icons.local_drink;
      case 'weight':
        return Icons.fitness_center;
      default:
        return Icons.straighten;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getTopicColor().withOpacity(0.15),
                      _getTopicColor().withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and grade tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 28),
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTopicColor().withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Grade ${widget.unit.grade}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _getTopicIconColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Unit icon and name
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _getTopicColor().withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getTopicIcon(),
                            color: _getTopicIconColor(),
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.unit.topic,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _getTopicIconColor(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.unit.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(AppColors.textBlack),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    if (widget.unit.description != null)
                      Text(
                        widget.unit.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(AppColors.subText1),
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress stats
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_progress != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressStats(),
                ),

              const SizedBox(height: 24),

              // Main action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What would you like to do?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textBlack),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      title: 'Practice Questions',
                      subtitle: 'Test your knowledge with questions',
                      icon: Icons.quiz,
                      gradient: LinearGradient(
                        colors: [
                          _getTopicIconColor(),
                          _getTopicIconColor().withOpacity(0.7),
                        ],
                      ),
                      onTap: () {
                        Get.to(() => QuestionPracticeScreen(unit: widget.unit));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      title: 'Ask a Doubt',
                      subtitle: 'Chat with AI tutor about this unit',
                      icon: Icons.chat_bubble_outline,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6B7FFF),
                          Color(0xFF8CA9FF),
                        ],
                      ),
                      onTap: () {
                        Get.to(() => UnitChatScreen(unit: widget.unit));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Space for bottom nav
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

  Widget _buildProgressStats() {
    final progress = _progress!;
    final accuracy = progress.questionsAnswered > 0
        ? progress.accuracy
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _getTopicColor().withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.textBlack),
                ),
              ),
              Row(
                children: List.generate(
                  3,
                  (index) => Icon(
                    index < progress.stars ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  label: 'Questions',
                  value: '${progress.questionsAnswered}',
                  color: _getTopicIconColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Correct',
                  value: '${progress.correctAnswers}',
                  color: const Color(0xFF2EB872),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.percent,
                  label: 'Accuracy',
                  value: '${accuracy.toInt()}%',
                  color: const Color(0xFF6B7FFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.subText2),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
