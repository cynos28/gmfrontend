import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';
import 'package:ganithamithura/screens/measurements/units/unit_home_screen.dart';

class UnitsListScreen extends StatefulWidget {
  final int grade;
  final String topic; // Length, Area, Capacity, Weight

  const UnitsListScreen({
    super.key,
    required this.grade,
    required this.topic,
  });

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  final UnitApiService _apiService = UnitApiService();
  List<Unit> _units = [];
  Map<String, StudentUnitProgress> _progressMap = {};
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 1; // Learn tab

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch units for the grade
      final units = await _apiService.getUnits(widget.grade);
      
      // Filter by topic if needed
      final filteredUnits = units
          .where((unit) => unit.topic.toLowerCase() == widget.topic.toLowerCase())
          .toList();

      // Fetch progress for each unit
      final progressMap = <String, StudentUnitProgress>{};
      for (final unit in filteredUnits) {
        final progress = await _apiService.getUnitProgress(unit.id);
        if (progress != null) {
          progressMap[unit.id] = progress;
        }
      }

      setState(() {
        _units = filteredUnits;
        _progressMap = progressMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load units. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Go back to previous screen
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
    switch (widget.topic.toLowerCase()) {
      case 'length':
        return const Color(AppColors.measurementColor);
      case 'area':
        return const Color(AppColors.measurementColor);
      case 'capacity':
        return const Color(AppColors.measurementColor);
      case 'weight':
        return const Color(AppColors.measurementColor);
      default:
        return const Color(AppColors.measurementColor);
    }
  }

  Color _getTopicIconColor() {
    return const Color(AppColors.measurementIcon);
  }

  IconData _getTopicIcon() {
    switch (widget.topic.toLowerCase()) {
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
        child: Column(
          children: [
            // Header
            Container(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
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
                          'Grade ${widget.grade}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _getTopicIconColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _getTopicColor().withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getTopicIcon(),
                          color: _getTopicIconColor(),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.topic} Units',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(AppColors.textBlack),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose a unit to start learning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(AppColors.subText1).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(AppColors.subText1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTopicIconColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No units available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.subText1),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        final progress = _progressMap[unit.id];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildUnitCard(unit, progress),
        );
      },
    );
  }

  Widget _buildUnitCard(Unit unit, StudentUnitProgress? progress) {
    final hasProgress = progress != null && progress.questionsAnswered > 0;
    final accuracy = hasProgress ? progress.accuracy : 0.0;
    final stars = hasProgress ? progress.stars : 0;

    return GestureDetector(
      onTap: () {
        Get.to(() => UnitHomeScreen(unit: unit));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _getTopicColor().withOpacity(0.12),
          border: Border.all(
            color: _getTopicColor().withOpacity(0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
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
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _getTopicColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTopicIcon(),
                    color: _getTopicIconColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textBlack),
                        ),
                      ),
                      if (unit.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          unit.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(AppColors.subText1),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stars
                if (stars > 0)
                  Row(
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Progress section
            if (hasProgress) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Questions: ${progress.questionsAnswered}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(AppColors.subText2),
                              ),
                            ),
                            Text(
                              '${accuracy.toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getTopicIconColor(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: accuracy / 100,
                            backgroundColor: _getTopicColor().withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTopicIconColor(),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getTopicIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 18,
                      color: _getTopicIconColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getTopicIconColor(),
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
}
