import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// Shapes progress screen — redesigned with 3 level sections
class ShapesProgressScreen extends StatefulWidget {
  const ShapesProgressScreen({super.key});

  @override
  State<ShapesProgressScreen> createState() => _ShapesProgressScreenState();
}

class _ShapesProgressScreenState extends State<ShapesProgressScreen> {
  final ShapesApiService _apiService = ShapesApiService.instance;
  bool _isLoading = true;
  double _circle2DMastery = 0.0;
  double _cube3DMastery = 0.0;
  double _patternMatchProgress = 0.0;
  double _buildMatchProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    try {
      final progressData = await _apiService.getUserProgress();
      final buildMatchData = await _apiService.getBuildMatchProgress();
      final levels = progressData['levels'] as List<dynamic>? ?? [];
      final highestBuildChallenge =
          buildMatchData['highest_build_challenge'] as int? ?? 0;

      bool level1Passed = false, level2Passed = false;
      bool level3Passed = false, level4Passed = false;
      bool level5Passed = false, level6Passed = false;

      for (var levelData in levels) {
        final levelNum = levelData['level'] as int;
        final isPassed = levelData['is_passed'] as bool? ?? false;
        if (levelNum == 1) level1Passed = isPassed;
        if (levelNum == 2) level2Passed = isPassed;
        if (levelNum == 3) level3Passed = isPassed;
        if (levelNum == 4) level4Passed = isPassed;
        if (levelNum == 5) level5Passed = isPassed;
        if (levelNum == 6) level6Passed = isPassed;
      }

      double circle2D = level1Passed && level2Passed
          ? 1.0
          : level1Passed
              ? 0.5
              : 0.0;
      double cube3D = level3Passed && level4Passed
          ? 1.0
          : level3Passed
              ? 0.5
              : 0.0;
      double patternMatch = level5Passed && level6Passed
          ? 1.0
          : level5Passed
              ? 0.5
              : 0.0;
      const totalBuildChallenges = 7;
      double buildMatch =
          (highestBuildChallenge / totalBuildChallenges).clamp(0.0, 1.0);

      if (mounted) {
        setState(() {
          _circle2DMastery = circle2D;
          _cube3DMastery = cube3D;
          _patternMatchProgress = patternMatch;
          _buildMatchProgress = buildMatch;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _overallMastery =>
      (_circle2DMastery + _cube3DMastery) / 2;

  // ── Level info dialog ─────────────────────────────────────────────────────

  void _showLevelInfoDialog(BuildContext context, int level) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _LevelInfoDialog(
        level: level,
        circle2DMastery: _circle2DMastery,
        cube3DMastery: _cube3DMastery,
        patternMatchProgress: _patternMatchProgress,
        buildMatchProgress: _buildMatchProgress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary banner ──────────────────────────────
                    _buildBanner(),
                    const SizedBox(height: 24),

                    // ── Level 01 ────────────────────────────────────
                    _LevelSection(
                      levelLabel: 'Level 01',
                      levelColor: const Color(0xFF4CAF50),
                      bgColor: const Color(0xFFE8F5E9),
                      icon: Icons.crop_square_rounded,
                      onTap: () => _showLevelInfoDialog(context, 1),
                      child: Column(
                        children: [
                          _ProgressItemCard(
                            title: '2D Shapes',
                            subtitle: 'Match & answer 2D shape games',
                            emoji: '⭕',
                            assetPath: 'assets/images/2d_shapes/circle.png',
                            progress: _circle2DMastery,
                            color: const Color(0xFF4CAF50),
                            bgColor: const Color(0xFFC8E6C9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Level 02 ────────────────────────────────────
                    _LevelSection(
                      levelLabel: 'Level 02',
                      levelColor: const Color(0xFF2196F3),
                      bgColor: const Color(0xFFE3F2FD),
                      icon: Icons.view_in_ar_rounded,
                      onTap: () => _showLevelInfoDialog(context, 2),
                      child: Column(
                        children: [
                          _ProgressItemCard(
                            title: '3D Shapes',
                            subtitle: 'Match & answer 3D shape games',
                            emoji: '🧊',
                            assetPath: 'assets/images/3d_shapes/cube.png',
                            progress: _cube3DMastery,
                            color: const Color(0xFF2196F3),
                            bgColor: const Color(0xFFBBDEFB),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Level 03 ────────────────────────────────────
                    _LevelSection(
                      levelLabel: 'Level 03',
                      levelColor: const Color(0xFF9C27B0),
                      bgColor: const Color(0xFFF3E5F5),
                      icon: Icons.extension_rounded,
                      onTap: () => _showLevelInfoDialog(context, 3),
                      child: Column(
                        children: [
                          _ProgressItemCard(
                            title: 'Build & Match',
                            subtitle: 'Build the right shape',
                            emoji: '🏗️',
                            progress: _buildMatchProgress,
                            color: const Color(0xFF9C27B0),
                            bgColor: const Color(0xFFE1BEE7),
                          ),
                          const SizedBox(height: 12),
                          _ProgressItemCard(
                            title: 'Pattern Match',
                            subtitle: 'Complete the pattern',
                            emoji: '🧩',
                            progress: _patternMatchProgress,
                            color: const Color(0xFFE91E63),
                            bgColor: const Color(0xFFF8BBD0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Game Guidelines ─────────────────────────────
                    _buildGuidelinesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Guidelines section ───────────────────────────────────────────────

  Widget _buildGuidelinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Game Guidelines',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'The game section has 6 game levels.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Level 01 guideline card
        _GuidelineCard(
          levelLabel: 'Level 01',
          topic: '2D Shapes',
          color: const Color(0xFF4CAF50),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.crop_square_rounded,
          games: const ['Game Level 1', 'Game Level 2'],
        ),
        const SizedBox(height: 12),

        // Level 02 guideline card
        _GuidelineCard(
          levelLabel: 'Level 02',
          topic: '3D Shapes',
          color: const Color(0xFF2196F3),
          bgColor: const Color(0xFFE3F2FD),
          icon: Icons.view_in_ar_rounded,
          games: const ['Game Level 3', 'Game Level 4'],
        ),
        const SizedBox(height: 12),

        // Level 03 guideline card
        _GuidelineCard(
          levelLabel: 'Level 03',
          topic: 'Shape Practice & Building',
          color: const Color(0xFF9C27B0),
          bgColor: const Color(0xFFF3E5F5),
          icon: Icons.extension_rounded,
          games: const ['Game Level 5', 'Game Level 6', 'Build & Match'],
        ),
        const SizedBox(height: 20),

        // Tips card
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildTipsCard() {
    const tips = [
      ('👀', 'Look carefully at each shape.'),
      ('✅', 'Choose the correct answer.'),
      ('📶', 'Complete levels step by step.'),
      ('🔄', 'Try again if you make a mistake.'),
      ('😄', 'Have fun learning shapes!'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Tips for You!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.$2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444444),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: KidsShadows.soft,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: KidsColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shapes 🔷',
                  style: KidsTypography.title.copyWith(fontSize: 22)),
              Text('2D & 3D shape mastery',
                  style: KidsTypography.helper),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary banner ────────────────────────────────────────────────────────

  Widget _buildBanner() {
    const color = KidsColors.highlightAccent;
    final masteryPercent = (_overallMastery * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), KidsColors.highlightBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25), width: 2),
        boxShadow: KidsShadows.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _overallMastery,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.15),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                const Text('🔷', style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shapes',
                    style: KidsTypography.subtitle.copyWith(
                        color: color, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$masteryPercent% Mastered',
                    style: KidsTypography.label
                        .copyWith(color: KidsColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.category_rounded,
                        color: color, size: 16),
                    const SizedBox(width: 4),
                    Text('2 Shapes Learning',
                        style: KidsTypography.body.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level Section wrapper ─────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final String levelLabel;
  final Color levelColor;
  final Color bgColor;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  const _LevelSection({
    required this.levelLabel,
    required this.levelColor,
    required this.bgColor,
    required this.icon,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level header row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  levelLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: levelColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: child,
          ),
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}

// ── Progress item card ────────────────────────────────────────────────────

class _ProgressItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? assetPath;
  final double progress;
  final Color color;
  final Color bgColor;

  const _ProgressItemCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.assetPath,
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: assetPath != null
                  ? Image.asset(assetPath!,
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) =>
                          Text(emoji, style: const TextStyle(fontSize: 26)))
                  : Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // Text + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: color.withOpacity(0.12),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color),
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
}

// ── Level Info Dialog — simple & child-friendly ───────────────────────────

class _LevelInfoDialog extends StatelessWidget {
  final int level;
  final double circle2DMastery;
  final double cube3DMastery;
  final double patternMatchProgress;
  final double buildMatchProgress;

  const _LevelInfoDialog({
    required this.level,
    required this.circle2DMastery,
    required this.cube3DMastery,
    required this.patternMatchProgress,
    required this.buildMatchProgress,
  });

  // ── Per-level content ───────────────────────────────────────────────────

  String get _emoji => level == 1 ? '⭕' : level == 2 ? '🧊' : '🎮';

  String get _title =>
      level == 1 ? 'Level 01' : level == 2 ? 'Level 02' : 'Level 03';

  Color get _color => level == 1
      ? const Color(0xFF4CAF50)
      : level == 2
          ? const Color(0xFF2196F3)
          : const Color(0xFF9C27B0);

  Color get _bgColor => level == 1
      ? const Color(0xFFE8F5E9)
      : level == 2
          ? const Color(0xFFE3F2FD)
          : const Color(0xFFF3E5F5);

  String get _mainIdea => level == 1
      ? 'Learn flat shapes! 🟦🔴🔺'
      : level == 2
          ? 'Learn solid shapes! 📦🌐'
          : 'Play shape games! 🎉';

  List<String> get _points => level == 1
      ? ['👀  Look at shapes', '🗣️  Say the shape name', '🔗  Match the shape', '🔢  Count sides and corners']
      : level == 2
          ? ['👀  Look at 3D shapes', '🗣️  Say the shape name', '🔍  Find shapes around you', '📐  Learn faces and corners']
          : ['🏗️  Build shapes', '🔗  Match shapes', '🧩  Find patterns', '⭐  Win stars'];

  String? get _nextText => level == 1
      ? '➡️  Next you will learn 3D shapes!'
      : level == 2
          ? '➡️  Next you will play shape games!'
          : null;

  double get _progress => level == 1
      ? circle2DMastery
      : level == 2
          ? cube3DMastery
          : (buildMatchProgress + patternMatchProgress) / 2;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _color,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: _color, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Main idea ────────────────────────────────────────
            Text(
              _mainIdea,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
            const SizedBox(height: 16),

            // ── Points ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _points
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            p,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Progress bar ─────────────────────────────────────
            Row(
              children: [
                Text('⭐ My Progress',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _color)),
                const Spacer(),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: _color.withOpacity(0.15),
                color: _color,
              ),
            ),

            // ── Level 03 "You learned" summary ───────────────────
            if (level == 3) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆  You learned!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9C27B0))),
                    const SizedBox(height: 10),
                    Text('⭕  2D shapes',
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text('🧊  3D shapes',
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    Text('🎮  Shape games',
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],

            // ── Next level hint ───────────────────────────────────
            if (_nextText != null) ...[
              const SizedBox(height: 14),
              Text(
                _nextText!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange.shade400,
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── OK button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK 👍',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Guideline Card ────────────────────────────────────────────────────────

class _GuidelineCard extends StatelessWidget {
  final String levelLabel;
  final String topic;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final List<String> games;

  const _GuidelineCard({
    required this.levelLabel,
    required this.topic,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  levelLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Game entries
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: games
                  .map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.sports_esports_rounded,
                                color: color, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            g,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
