/// Fish Tank Filler Game (V-V2)
/// Fill the tank to make fish happy!

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

// ─── Bucket Data ──────────────────────────────────────────────────────────────

class _Bucket {
  final String name;
  final String emoji;
  final int fillPercent;
  final Color color;

  const _Bucket({
    required this.name,
    required this.emoji,
    required this.fillPercent,
    required this.color,
  });
}

// ─── Fish Emotion ─────────────────────────────────────────────────────────────

enum FishEmotion { dry, sad, neutral, happy, panicked }

// ─── Level Data ───────────────────────────────────────────────────────────────

class _LevelConfig {
  final int levelNumber;
  final int targetPercent;
  final int tolerancePercent;
  final List<_Bucket> buckets;
  final int fishCount;
  final bool showLabels;

  const _LevelConfig({
    required this.levelNumber,
    required this.targetPercent,
    required this.tolerancePercent,
    required this.buckets,
    required this.fishCount,
    required this.showLabels,
  });
}

// All level configurations
final List<_LevelConfig> _levels = [
  // Level 1 - Easy (Fill to Half)
  _LevelConfig(
    levelNumber: 1,
    targetPercent: 50,
    tolerancePercent: 5,
    buckets: [
      _Bucket(name: 'Small', emoji: '🪣', fillPercent: 10, color: Color(0xFF4FC3F7)),
      _Bucket(name: 'Medium', emoji: '🧊', fillPercent: 25, color: Color(0xFF29B6F6)),
      _Bucket(name: 'Large', emoji: '🏺', fillPercent: 50, color: Color(0xFF0288D1)),
    ],
    fishCount: 1,
    showLabels: false,
  ),
  // Level 2 - Medium (Fill to ¾)
  _LevelConfig(
    levelNumber: 2,
    targetPercent: 75,
    tolerancePercent: 5,
    buckets: [
      _Bucket(name: 'Tiny', emoji: '🥤', fillPercent: 5, color: Color(0xFF81D4FA)),
      _Bucket(name: 'Small', emoji: '🪣', fillPercent: 20, color: Color(0xFF4FC3F7)),
      _Bucket(name: 'Medium', emoji: '🧊', fillPercent: 30, color: Color(0xFF29B6F6)),
    ],
    fishCount: 2,
    showLabels: false,
  ),
  // Level 3 - Hard (Exact Amount)
  _LevelConfig(
    levelNumber: 3,
    targetPercent: 60,
    tolerancePercent: 3,
    buckets: [
      _Bucket(name: 'Tiny', emoji: '🥤', fillPercent: 5, color: Color(0xFF81D4FA)),
      _Bucket(name: 'Small', emoji: '🪣', fillPercent: 15, color: Color(0xFF4FC3F7)),
      _Bucket(name: 'Medium', emoji: '🧊', fillPercent: 25, color: Color(0xFF29B6F6)),
      _Bucket(name: 'Large', emoji: '🏺', fillPercent: 40, color: Color(0xFF0288D1)),
    ],
    fishCount: 3,
    showLabels: true,
  ),
  // Level 4 - Challenge (Variable targets)
  _LevelConfig(
    levelNumber: 4,
    targetPercent: 80,
    tolerancePercent: 3,
    buckets: [
      _Bucket(name: 'Tiny', emoji: '🥤', fillPercent: 5, color: Color(0xFF81D4FA)),
      _Bucket(name: 'Small', emoji: '🪣', fillPercent: 10, color: Color(0xFF4FC3F7)),
      _Bucket(name: 'Medium', emoji: '🧊', fillPercent: 20, color: Color(0xFF29B6F6)),
      _Bucket(name: 'Large', emoji: '🏺', fillPercent: 35, color: Color(0xFF0288D1)),
      _Bucket(name: 'Watering Can', emoji: '🚿', fillPercent: 15, color: Color(0xFF00ACC1)),
    ],
    fishCount: 3,
    showLabels: true,
  ),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────

class FishTankGameScreen extends StatefulWidget {
  const FishTankGameScreen({super.key});

  @override
  State<FishTankGameScreen> createState() => _FishTankGameScreenState();
}

class _FishTankGameScreenState extends State<FishTankGameScreen>
    with TickerProviderStateMixin {
  // Game state
  int _currentLevel = 0;
  int _currentPercent = 0;
  int _pourCount = 0;
  bool _levelComplete = false;
  bool _isOverflow = false;
  bool _isPouring = false;
  int _totalStars = 0;

  // Animation controllers
  late AnimationController _waterController;
  late AnimationController _fishController;
  late AnimationController _pourAnimController;
  late Animation<double> _waterAnimation;
  late Animation<double> _fishAnimation;

  @override
  void initState() {
    super.initState();
    _waterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waterAnimation = CurvedAnimation(
      parent: _waterController,
      curve: Curves.easeOutCubic,
    );

    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fishAnimation = CurvedAnimation(
      parent: _fishController,
      curve: Curves.easeInOut,
    );

    _pourAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _waterController.dispose();
    _fishController.dispose();
    _pourAnimController.dispose();
    super.dispose();
  }

  _LevelConfig get _level => _levels[_currentLevel];

  FishEmotion get _fishEmotion {
    if (_isOverflow) return FishEmotion.panicked;
    if (_currentPercent == 0) return FishEmotion.dry;
    if (_currentPercent < _level.targetPercent - 20) return FishEmotion.sad;
    if ((_currentPercent - _level.targetPercent).abs() <= _level.tolerancePercent) {
      return FishEmotion.happy;
    }
    return FishEmotion.neutral;
  }

  String get _fishMessage {
    switch (_fishEmotion) {
      case FishEmotion.dry:
        return "We need water! 💧";
      case FishEmotion.sad:
        return "Need MORE! 😢";
      case FishEmotion.neutral:
        return "Keep going... 🤔";
      case FishEmotion.happy:
        return "Just Right! 🎉";
      case FishEmotion.panicked:
        return "Too Much! 😱";
    }
  }

  int _calculateStars() {
    if (_isOverflow) return 0;
    if (!_levelComplete) return 0;
    if (_pourCount == 1) return 3;
    if (_pourCount <= 3) return 2;
    return 1;
  }

  void _pourBucket(_Bucket bucket) {
    if (_levelComplete || _isPouring) return;

    setState(() {
      _isPouring = true;
      _pourCount++;
      final newPercent = _currentPercent + bucket.fillPercent;

      if (newPercent > 100) {
        _currentPercent = 100;
        _isOverflow = true;
      } else {
        _currentPercent = newPercent;
        // Check if target reached
        if ((_currentPercent - _level.targetPercent).abs() <= _level.tolerancePercent) {
          _levelComplete = true;
          _totalStars += _calculateStars();
        }
      }
    });

    _waterController.forward(from: 0);
    _pourAnimController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isPouring = false);
      }
    });
  }

  void _resetLevel() {
    setState(() {
      _currentPercent = 0;
      _pourCount = 0;
      _levelComplete = false;
      _isOverflow = false;
      _isPouring = false;
    });
    _waterController.reset();
  }

  void _nextLevel() {
    if (_currentLevel < _levels.length - 1) {
      setState(() {
        _currentLevel++;
        _currentPercent = 0;
        _pourCount = 0;
        _levelComplete = false;
        _isOverflow = false;
        _isPouring = false;
      });
      _waterController.reset();
    } else {
      // Game complete - show finish screen
      _showFinishScreen();
    }
  }

  void _showFinishScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildFinishDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildFishTank(),
                    const SizedBox(height: 16),
                    _buildFishMessage(),
                    const SizedBox(height: 20),
                    if (!_levelComplete && !_isOverflow) _buildBuckets(),
                    if (_levelComplete || _isOverflow) _buildResultCard(),
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
            const Color(0xFF2196F3).withOpacity(0.1),
            const Color(0xFFE3F2FD),
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
                      '🐟',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level ${_level.levelNumber}',
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
                  'Target: ${_level.targetPercent}% | Stars: $_totalStars',
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
                const Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: Color(0xFF2196F3),
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

  Widget _buildFishTank() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: KidsShadows.medium,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_waterAnimation, _fishAnimation]),
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _FishTankPainter(
              currentPercent: _currentPercent,
              targetPercent: _level.targetPercent,
              tolerancePercent: _level.tolerancePercent,
              fishCount: _level.fishCount,
              showLabels: _level.showLabels,
              fishEmotion: _fishEmotion,
              fishAnimation: _fishAnimation.value,
              waterAnimation: _waterAnimation.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFishMessage() {
    Color bgColor;
    switch (_fishEmotion) {
      case FishEmotion.happy:
        bgColor = const Color(0xFF4CAF50);
        break;
      case FishEmotion.panicked:
        bgColor = const Color(0xFFF44336);
        break;
      case FishEmotion.sad:
      case FishEmotion.dry:
        bgColor = const Color(0xFFFF9800);
        break;
      default:
        bgColor = const Color(0xFF2196F3);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _fishMessage,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBuckets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a bucket to pour:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KidsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _level.buckets.map((bucket) {
            return _buildBucketButton(bucket);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBucketButton(_Bucket bucket) {
    return GestureDetector(
      onTap: () => _pourBucket(bucket),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPouring
                ? [bucket.color.withOpacity(0.5), bucket.color.withOpacity(0.3)]
                : [bucket.color, bucket.color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bucket.color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              bucket.emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 6),
            Text(
              bucket.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _levelComplete && !_isOverflow;
    final stars = _calculateStars();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSuccess
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : [const Color(0xFFF44336), const Color(0xFFEF5350)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                .withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isSuccess ? '🐟 🎉 🐟' : '💧 😱 💧',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            isSuccess ? 'Fish are Happy!' : 'Tank Overflowed!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSuccess
                ? 'You filled to $_currentPercent% in $_pourCount pours!'
                : 'The water spilled! Try pouring less next time.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (isSuccess) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: i < stars ? const Color(0xFFFFB800) : Colors.white60,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetLevel,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isSuccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (isSuccess) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _nextLevel,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _currentLevel < _levels.length - 1 ? 'Next Level' : 'Finish',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏆',
              style: TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Levels Complete!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You earned $_totalStars stars!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                12,
                (i) => Icon(
                  i < _totalStars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: i < _totalStars ? const Color(0xFFFFB800) : Colors.white38,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _currentLevel = 0;
                        _totalStars = 0;
                        _resetLevel();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Play Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.back();
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
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

// ─── Fish Tank Painter ────────────────────────────────────────────────────────

class _FishTankPainter extends CustomPainter {
  final int currentPercent;
  final int targetPercent;
  final int tolerancePercent;
  final int fishCount;
  final bool showLabels;
  final FishEmotion fishEmotion;
  final double fishAnimation;
  final double waterAnimation;

  _FishTankPainter({
    required this.currentPercent,
    required this.targetPercent,
    required this.tolerancePercent,
    required this.fishCount,
    required this.showLabels,
    required this.fishEmotion,
    required this.fishAnimation,
    required this.waterAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tankWidth = size.width * 0.75;
    final tankHeight = size.height * 0.85;
    final tankLeft = (size.width - tankWidth) / 2;
    final tankTop = size.height * 0.05;
    final tankBottom = tankTop + tankHeight;

    // Tank glass outline
    final tankPaint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final tankRect = RRect.fromLTRBR(
      tankLeft,
      tankTop,
      tankLeft + tankWidth,
      tankBottom,
      const Radius.circular(12),
    );
    canvas.drawRRect(tankRect, tankPaint);

    // Tank fill (glass effect)
    final glassPaint = Paint()
      ..color = const Color(0xFFE3F2FD).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tankRect, glassPaint);

    // Water fill
    if (currentPercent > 0) {
      final waterHeight = (currentPercent / 100) * tankHeight;
      final waterTop = tankBottom - waterHeight;

      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fishEmotion == FishEmotion.panicked
                ? const Color(0xFFEF5350).withOpacity(0.7)
                : const Color(0xFF4FC3F7).withOpacity(0.7),
            fishEmotion == FishEmotion.panicked
                ? const Color(0xFFF44336)
                : const Color(0xFF0288D1),
          ],
        ).createShader(Rect.fromLTRB(tankLeft, waterTop, tankLeft + tankWidth, tankBottom));

      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          tankLeft + 2,
          waterTop,
          tankLeft + tankWidth - 2,
          tankBottom - 2,
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
        waterPaint,
      );

      // Water surface wave
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(tankLeft + 2, waterTop, tankLeft + tankWidth - 2, waterTop + 4),
        wavePaint,
      );
    }

    // Target line (dotted red)
    final targetY = tankBottom - (targetPercent / 100) * tankHeight;
    final targetPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    double startX = tankLeft - 15;
    while (startX < tankLeft + tankWidth + 15) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(startX + dashWidth, targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Target label
    final targetTextPainter = TextPainter(
      text: TextSpan(
        text: '${targetPercent}%',
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    targetTextPainter.layout();
    targetTextPainter.paint(
      canvas,
      Offset(tankLeft + tankWidth + 20, targetY - targetTextPainter.height / 2),
    );

    // Scale labels (if enabled)
    if (showLabels) {
      final labelStyle = TextStyle(
        color: Colors.grey.shade600,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
      for (final percent in [25, 50, 75, 100]) {
        final y = tankBottom - (percent / 100) * tankHeight;
        final painter = TextPainter(
          text: TextSpan(text: '$percent%', style: labelStyle),
          textDirection: TextDirection.ltr,
        );
        painter.layout();
        painter.paint(canvas, Offset(tankLeft - painter.width - 12, y - painter.height / 2));

        // Tick mark
        canvas.drawLine(
          Offset(tankLeft - 6, y),
          Offset(tankLeft, y),
          Paint()
            ..color = Colors.grey.shade400
            ..strokeWidth = 2,
        );
      }
    }

    // Draw fish
    _drawFish(canvas, size, tankLeft, tankWidth, tankTop, tankHeight, tankBottom);
  }

  void _drawFish(Canvas canvas, Size size, double tankLeft, double tankWidth,
      double tankTop, double tankHeight, double tankBottom) {
    final waterTop = tankBottom - (currentPercent / 100) * tankHeight;
    final fishZoneHeight = currentPercent > 5 ? (currentPercent / 100) * tankHeight - 20 : 0.0;

    for (int i = 0; i < fishCount; i++) {
      // Fish position based on water level
      double fishX = tankLeft + tankWidth * ((i + 1) / (fishCount + 1));
      double fishY;

      if (currentPercent == 0) {
        // Dry - fish at bottom
        fishY = tankBottom - 30;
      } else {
        // Swimming in water
        final baseY = tankBottom - 30 - (i * 40) - (fishZoneHeight * 0.3);
        fishY = baseY + (math.sin(fishAnimation * math.pi * 2 + i) * 8);
      }

      // Fish bounce horizontally
      fishX += math.cos(fishAnimation * math.pi * 2 + i * 0.5) * 15;

      _drawSingleFish(canvas, fishX, fishY, i);
    }
  }

  void _drawSingleFish(Canvas canvas, double x, double y, int index) {
    // Fish color based on index
    final colors = [
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    final fishColor = colors[index % colors.length];

    // Fish body
    final bodyPath = Path();
    bodyPath.moveTo(x - 20, y);
    bodyPath.quadraticBezierTo(x, y - 12, x + 20, y);
    bodyPath.quadraticBezierTo(x, y + 12, x - 20, y);
    bodyPath.close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = fishColor
        ..style = PaintingStyle.fill,
    );

    // Fish tail
    final tailPath = Path();
    tailPath.moveTo(x - 20, y);
    tailPath.lineTo(x - 32, y - 10);
    tailPath.lineTo(x - 32, y + 10);
    tailPath.close();
    canvas.drawPath(tailPath, Paint()..color = fishColor);

    // Fish eye
    canvas.drawCircle(
      Offset(x + 10, y - 3),
      4,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x + 11, y - 3),
      2,
      Paint()..color = Colors.black,
    );

    // Expression based on emotion
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (fishEmotion) {
      case FishEmotion.happy:
        // Smile
        final smilePath = Path();
        smilePath.addArc(
          Rect.fromCenter(center: Offset(x + 6, y + 4), width: 8, height: 6),
          0,
          math.pi,
        );
        canvas.drawPath(smilePath, mouthPaint);
        break;
      case FishEmotion.sad:
      case FishEmotion.dry:
        // Frown
        final frownPath = Path();
        frownPath.addArc(
          Rect.fromCenter(center: Offset(x + 6, y + 8), width: 8, height: 6),
          math.pi,
          math.pi,
        );
        canvas.drawPath(frownPath, mouthPaint);
        break;
      case FishEmotion.panicked:
        // Open mouth (surprised)
        canvas.drawCircle(
          Offset(x + 6, y + 4),
          4,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
      default:
        // Neutral line
        canvas.drawLine(
          Offset(x + 2, y + 4),
          Offset(x + 10, y + 4),
          mouthPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _FishTankPainter oldDelegate) {
    return oldDelegate.currentPercent != currentPercent ||
        oldDelegate.fishEmotion != fishEmotion ||
        oldDelegate.fishAnimation != fishAnimation;
  }
}
