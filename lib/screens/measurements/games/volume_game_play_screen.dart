/// Volume Game Play Screen - Fill to Target (V-V1)
/// Pour liquid carefully to reach the target amount

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

class VolumeGamePlayScreen extends StatefulWidget {
  final String variant;
  const VolumeGamePlayScreen({super.key, required this.variant});

  @override
  State<VolumeGamePlayScreen> createState() => _VolumeGamePlayScreenState();
}

class _VolumeGamePlayScreenState extends State<VolumeGamePlayScreen>
    with TickerProviderStateMixin {
  // ─── Game State ──────────────────────────────────────────────────────────────
  late int _capacityMl;
  late int _targetMl;
  late int _toleranceMl;
  late int _currentMl;
  late int _normalPourStepMl;
  late int _fastPourStepMl;
  late int _fineTuneStepMl;
  late int _fineTuneThresholdMl;
  
  int _pourCount = 0;
  int _overshootCount = 0;
  bool _gameEnded = false;
  bool _isSuccess = false;
  bool _isOverflow = false;
  bool _isPouring = false;
  
  // ─── Adaptive System ─────────────────────────────────────────────────────────
  static const int _maxQuestions = 5;
  int _questionNumber = 1;
  int _totalCorrect = 0;
  int _totalAttempts = 0;
  int _consecutiveSuccesses = 0;
  int _consecutiveFailures = 0;
  List<int> _recentCompletionTimes = [];
  bool _showFinishScreen = false;
  
  DateTime? _startTime;
  late AnimationController _liquidController;
  late AnimationController _successController;
  late Animation<double> _liquidAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _liquidAnimation = CurvedAnimation(
      parent: _liquidController,
      curve: Curves.easeOut,
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _startTime = DateTime.now();
  }

  void _initializeGame() {
    _generateAdaptiveQuestion();
  }
  
  void _generateAdaptiveQuestion() {
    // Base difficulty on performance
    final successRate = _totalAttempts > 0 ? _totalCorrect / _totalAttempts : 0.0;
    
    // Start easy, increase difficulty based on consecutive successes
    if (_consecutiveSuccesses >= 3) {
      // Advanced level - harder targets, smaller tolerance, varied amounts
      _capacityMl = 1000;
      _targetMl = [150, 350, 450, 650, 850].elementAt(_questionNumber % 5);
      _toleranceMl = 5;
      _normalPourStepMl = 100;
      _fastPourStepMl = 25;
      _fineTuneStepMl = 5;
    } else if (_consecutiveSuccesses >= 2 || successRate > 0.7) {
      // Intermediate level - medium difficulty
      // Targets must be reachable with 100+50+10 combinations
      _capacityMl = 500;
      _targetMl = [160, 220, 280, 340, 410, 460].elementAt(_questionNumber % 6);
      _toleranceMl = 10;
      _normalPourStepMl = 100;
      _fastPourStepMl = 50;
      _fineTuneStepMl = 10;
    } else {
      // Beginner level - easy targets with larger tolerance
      _capacityMl = 500;
      _targetMl = [100, 200, 250, 300, 400].elementAt(_questionNumber % 5);
      _toleranceMl = 15;
      _normalPourStepMl = 100;
      _fastPourStepMl = 50;
      _fineTuneStepMl = 10;
    }
    
    _currentMl = 0;
    _fineTuneThresholdMl = 20;
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ─── Game Logic ──────────────────────────────────────────────────────────────

  void _pour(int amount) {
    if (_gameEnded) return;

    setState(() {
      _isPouring = true;
      final newAmount = _currentMl + amount;
      
      // Check overflow
      if (newAmount > _capacityMl) {
        _currentMl = _capacityMl;
        _isOverflow = true;
        _gameEnded = true;
        _pourCount++;
      } else {
        _currentMl = newAmount;
        _pourCount++;

        // Check success
        if ((_currentMl - _targetMl).abs() <= _toleranceMl) {
          _isSuccess = true;
          _gameEnded = true;
          _successController.forward();
        }
        // Check overshoot
        else if (_currentMl > _targetMl + _toleranceMl) {
          _overshootCount++;
        }
      }
    });

    _liquidController.forward(from: 0);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPouring = false;
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _currentMl = 0;
      _pourCount = 0;
      _overshootCount = 0;
      _gameEnded = false;
      _isSuccess = false;
      _isOverflow = false;
      _isPouring = false;
      _startTime = DateTime.now();
    });
    _successController.reset();
  }
  
  void _nextQuestion() {
    _totalAttempts++;
    
    if (_isSuccess) {
      _totalCorrect++;
      _consecutiveSuccesses++;
      _consecutiveFailures = 0;
      
      final completionTime = DateTime.now().difference(_startTime!).inSeconds;
      _recentCompletionTimes.add(completionTime);
      if (_recentCompletionTimes.length > 5) {
        _recentCompletionTimes.removeAt(0);
      }
    } else {
      _consecutiveSuccesses = 0;
      _consecutiveFailures++;
    }
    
    // Check if finished all questions
    if (_questionNumber >= _maxQuestions) {
      setState(() {
        _showFinishScreen = true;
      });
      return;
    }
    
    setState(() {
      _questionNumber++;
      _currentMl = 0;
      _pourCount = 0;
      _overshootCount = 0;
      _gameEnded = false;
      _isSuccess = false;
      _isOverflow = false;
      _isPouring = false;
      _startTime = DateTime.now();
      _generateAdaptiveQuestion();
    });
    _successController.reset();
  }

  int _calculateStars() {
    if (!_isSuccess) return 0;
    
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    int stars = 1;
    
    // Bonus star for no overshoots
    if (_overshootCount == 0) stars++;
    
    // Bonus star for fewer pours (efficient)
    final minPours = (_targetMl / _fastPourStepMl).ceil();
    if (_pourCount <= minPours + 3) stars++;
    
    // Bonus star for quick completion (< 30 seconds)
    if (duration < 30) stars++;
    
    return math.min(stars, 4);
  }

  @override
  Widget build(BuildContext context) {
    if (_showFinishScreen) {
      return _buildFinishScreen();
    }
    
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMeasuringCup(),
                    const SizedBox(height: 24),
                    _buildStats(),
                    const SizedBox(height: 24),
                    if (!_gameEnded) _buildControls(),
                    if (_gameEnded) _buildResultCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KidsColors.volumeColor.withOpacity(0.1),
            KidsColors.volumeBackground,
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
                Row(
                  children: [
                    const Text(
                      '🥤',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Question $_questionNumber',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: KidsColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: $_targetMl mL | Score: $_totalCorrect/$_totalAttempts',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KidsColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (!_gameEnded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: KidsShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_drink_rounded,
                    size: 18,
                    color: KidsColors.volumeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_pourCount pours',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KidsColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasuringCup() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: KidsShadows.medium,
      ),
      child: Column(
        children: [
          // Measuring cup visualization
          SizedBox(
            height: 400,
            child: AnimatedBuilder(
              animation: _liquidAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _MeasuringCupPainter(
                    capacity: _capacityMl,
                    current: _currentMl,
                    target: _targetMl,
                    tolerance: _toleranceMl,
                    isSuccess: _isSuccess,
                    isOverflow: _isOverflow,
                    liquidAnimation: _liquidAnimation.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Current amount display
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSuccess
                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                    : _isOverflow
                        ? [const Color(0xFFF44336), const Color(0xFFEF5350)]
                        : [KidsColors.volumeColor, KidsColors.volumeColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isSuccess
                          ? const Color(0xFF4CAF50)
                          : _isOverflow
                              ? const Color(0xFFF44336)
                              : KidsColors.volumeColor)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_currentMl mL',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.straighten_rounded,
            label: 'Target',
            value: '$_targetMl mL',
            color: KidsColors.volumeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            label: 'Overshoots',
            value: '$_overshootCount',
            color: _overshootCount > 0 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KidsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Three contextual pour buttons
        Row(
          children: [
            Expanded(
              child: _buildPourButton(
                amount: _normalPourStepMl,
                label: _formatVolume(_normalPourStepMl),
                color: const Color(0xFF4CAF50),
                icon: Icons.water_drop_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPourButton(
                amount: _fastPourStepMl,
                label: _formatVolume(_fastPourStepMl),
                color: KidsColors.volumeColor,
                icon: Icons.water_drop_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPourButton(
                amount: _fineTuneStepMl,
                label: _formatVolume(_fineTuneStepMl),
                color: const Color(0xFFFF9800),
                icon: Icons.water_drop_outlined,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Reset button
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text(
            'Start Over',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: KidsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPourButton({
    required int amount,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => _pour(amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPouring
                ? [color.withOpacity(0.7), color.withOpacity(0.5)]
                : [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVolume(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000;
      if (liters == liters.toInt()) {
        return '${liters.toInt()} L';
      }
      return '${liters.toStringAsFixed(1)} L';
    }
    return '$ml mL';
  }

  Widget _buildFinishScreen() {
    final successRate = (_totalCorrect / _totalAttempts * 100).toInt();
    final avgTime = _recentCompletionTimes.isNotEmpty
        ? (_recentCompletionTimes.reduce((a, b) => a + b) / _recentCompletionTimes.length).toInt()
        : 0;
    
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Celebration animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KidsColors.volumeColor,
                        KidsColors.volumeColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KidsColors.volumeColor.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                '🎉 Amazing Work! 🎉',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: KidsColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You completed all questions!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Stats cards
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: KidsShadows.medium,
                ),
                child: Column(
                  children: [
                    // Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 32,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_totalCorrect / $_maxQuestions',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: KidsColors.textPrimary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Questions Correct',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KidsColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    
                    // Performance metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.percent_rounded,
                            label: 'Success Rate',
                            value: '$successRate%',
                            color: successRate >= 80
                                ? const Color(0xFF4CAF50)
                                : successRate >= 60
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFFF44336),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.timer_rounded,
                            label: 'Avg Time',
                            value: '${avgTime}s',
                            color: KidsColors.volumeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.trending_up_rounded,
                            label: 'Best Streak',
                            value: '$_consecutiveSuccesses',
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFinishStatCard(
                            icon: Icons.replay_rounded,
                            label: 'Total Tries',
                            value: '$_totalAttempts',
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _questionNumber = 1;
                          _totalCorrect = 0;
                          _totalAttempts = 0;
                          _consecutiveSuccesses = 0;
                          _consecutiveFailures = 0;
                          _recentCompletionTimes.clear();
                          _showFinishScreen = false;
                          _currentMl = 0;
                          _pourCount = 0;
                          _overshootCount = 0;
                          _gameEnded = false;
                          _isSuccess = false;
                          _isOverflow = false;
                          _startTime = DateTime.now();
                          _generateAdaptiveQuestion();
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 24),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsColors.volumeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.home_rounded, size: 24),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: KidsColors.volumeColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: KidsColors.volumeColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSuccess ? (0.8 + 0.2 * _successAnimation.value) : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isSuccess
                ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                : [const Color(0xFFF44336), const Color(0xFFEF5350)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (_isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                  .withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _isSuccess ? '🎉' : '💧',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              _isSuccess
                  ? 'Perfect Pour!'
                  : _isOverflow
                      ? 'Overflow!'
                      : 'Overshot!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSuccess
                  ? 'You reached $_targetMl mL in $_pourCount pours!'
                  : _isOverflow
                      ? 'The cup overflowed! Try pouring more carefully.'
                      : 'You went past the target. Try again!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            if (_isSuccess) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _calculateStars()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: i < _calculateStars() ? const Color(0xFFFFB800) : Colors.white60,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isSuccess)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (!_isSuccess)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFF44336),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Measuring Cup Painter ────────────────────────────────────────────────────

class _MeasuringCupPainter extends CustomPainter {
  final int capacity;
  final int current;
  final int target;
  final int tolerance;
  final bool isSuccess;
  final bool isOverflow;
  final double liquidAnimation;

  _MeasuringCupPainter({
    required this.capacity,
    required this.current,
    required this.target,
    required this.tolerance,
    required this.isSuccess,
    required this.isOverflow,
    required this.liquidAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cupWidth = size.width * 0.5;
    final cupHeight = size.height * 0.85;
    final cupLeft = (size.width - cupWidth) / 2;
    final cupTop = size.height * 0.05;
    final cupBottom = cupTop + cupHeight;

    // Cup outline
    final cupPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cupPath = Path()
      ..moveTo(cupLeft, cupTop)
      ..lineTo(cupLeft, cupBottom)
      ..lineTo(cupLeft + cupWidth, cupBottom)
      ..lineTo(cupLeft + cupWidth, cupTop);

    canvas.drawPath(cupPath, cupPaint);

    // Tick marks and labels - SHOW ALL VALUES
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    final labelStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    final tickInterval = capacity >= 1000 ? 100 : 50;
    for (int ml = 0; ml <= capacity; ml += tickInterval) {
      final y = cupBottom - (ml / capacity) * cupHeight;
      final isLongTick = ml % (tickInterval * 2) == 0;
      final tickLength = isLongTick ? 15.0 : 10.0;

      canvas.drawLine(
        Offset(cupLeft, y),
        Offset(cupLeft - tickLength, y),
        tickPaint,
      );

      // Show ALL labels, not just long ticks
      final textPainter = TextPainter(
        text: TextSpan(text: '$ml', style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cupLeft - tickLength - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Liquid fill (no target line shown)
    if (current > 0) {
      final animatedCurrent = current * liquidAnimation;
      final fillHeight = (animatedCurrent / capacity) * cupHeight;
      final fillY = cupBottom - fillHeight;

      final liquidColor = isSuccess
          ? const Color(0xFF4CAF50)
          : isOverflow
              ? const Color(0xFFF44336)
              : (current - target).abs() <= tolerance
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF00BCD4);

      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            liquidColor.withOpacity(0.6),
            liquidColor,
          ],
        ).createShader(Rect.fromLTRB(cupLeft, fillY, cupLeft + cupWidth, cupBottom));

      canvas.drawRect(
        Rect.fromLTRB(cupLeft + 2, fillY, cupLeft + cupWidth - 2, cupBottom - 2),
        liquidPaint,
      );

      // Surface shimmer
      final shimmerPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(cupLeft + 2, fillY, cupLeft + cupWidth - 2, fillY + 4),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeasuringCupPainter oldDelegate) {
    return oldDelegate.current != current ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.isOverflow != isOverflow ||
        oldDelegate.liquidAnimation != liquidAnimation;
  }
}
