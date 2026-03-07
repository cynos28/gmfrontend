import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// Shapes progress screen — Dynamically loads progress from API
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
      // Fetch both regular level progress and build challenge progress
      final progressData = await _apiService.getUserProgress();
      final buildMatchData = await _apiService.getBuildMatchProgress();
      
      final levels = progressData['levels'] as List<dynamic>? ?? [];
      
      // Extract highest_build_challenge from build match API
      final highestBuildChallenge = buildMatchData['highest_build_challenge'] as int? ?? 0;
      
      // Calculate 2D shapes (Circle) mastery based on level 1 and 2
      bool level1Passed = false;
      bool level2Passed = false;
      
      // Calculate 3D shapes (Cube) mastery based on level 3 and 4
      bool level3Passed = false;
      bool level4Passed = false;
      
      // Calculate Pattern Match progress based on level 5 and 6
      bool level5Passed = false;
      bool level6Passed = false;
      
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
      
      // Calculate mastery percentages
      double circle2D = 0.0;
      if (level1Passed && level2Passed) {
        circle2D = 1.0; // 100%
      } else if (level1Passed) {
        circle2D = 0.5; // 50%
      }
      
      double cube3D = 0.0;
      if (level3Passed && level4Passed) {
        cube3D = 1.0; // 100%
      } else if (level3Passed) {
        cube3D = 0.5; // 50%
      }
      
      double patternMatch = 0.0;
      if (level5Passed && level6Passed) {
        patternMatch = 1.0; // 100%
      } else if (level5Passed) {
        patternMatch = 0.5; // 50%
      }
      
      // Calculate Build & Match progress as percentage
      // There are 7 total build challenges (levels 7-13)
      const totalBuildChallenges = 7;
      double buildMatch = highestBuildChallenge / totalBuildChallenges;
      // Clamp to 1.0 maximum
      buildMatch = buildMatch > 1.0 ? 1.0 : buildMatch;
      
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
      print('Error loading user progress: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep default values on error
        });
      }
    }
  }

  // Create dynamic shape info lists

  // Create dynamic shape info lists
  List<_ShapeInfo> get _shapes2D => [
    _ShapeInfo('Circle', '⭕', 'assets/images/2d_shapes/circle.png', _circle2DMastery,
        const Color(0xFF4285F4)),
  ];

  List<_ShapeInfo> get _shapes3D => [
    _ShapeInfo(
        'Cube', '🧊', 'assets/images/3d_shapes/cube.png', _cube3DMastery, const Color(0xFF00BCD4)),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: KidsColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: KidsSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: KidsSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall banner
                    _buildBanner(),
                    const SizedBox(height: KidsSpacing.xl),

                    // 2D Shapes section
                    Text('2D Shapes ',
                        style:
                            KidsTypography.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),
                    _buildShapesGrid(context, _shapes2D),
                    const SizedBox(height: KidsSpacing.xl),

                    // 3D Shapes section
                    Text('3D Shapes',
                        style:
                            KidsTypography.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),
                    _buildShapesGrid(context, _shapes3D),
                    const SizedBox(height: KidsSpacing.xl),

                    // Game activities
                    Text('Shape Games',
                        style:
                            KidsTypography.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),

                    _ShapeGameCard(
                      title: 'Build & Match',
                      emoji: '🏗️',
                      desc: 'Build the right shape',
                      accuracy: _buildMatchProgress,
                      color: const Color(0xFF4CAF50),
                    ),
                    _ShapeGameCard(
                      title: 'Pattern Match',
                      emoji: '🧩',
                      desc: 'Complete the pattern',
                      accuracy: _patternMatchProgress,
                      color: const Color(0xFF9C27B0),
                    ),

                    const SizedBox(height: KidsSpacing.xxl),
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
      padding: const EdgeInsets.fromLTRB(
        KidsSpacing.screenPadding,
        KidsSpacing.lg,
        KidsSpacing.screenPadding,
        KidsSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(KidsSpacing.radiusMedium),
                boxShadow: KidsShadows.soft,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: KidsColors.textPrimary, size: 24),
            ),
          ),
          const SizedBox(width: KidsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shapes 🔷',
                    style: KidsTypography.title.copyWith(fontSize: 24)),
                const SizedBox(height: 2),
                Text('2D & 3D shape mastery',
                    style: KidsTypography.helper),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    const color = KidsColors.highlightAccent;
    // Calculate overall mastery as average of both shapes
    final overallMastery = (_circle2DMastery + _cube3DMastery) / 2;
    final masteryPercent = (overallMastery * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            KidsColors.highlightBackground
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
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
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: overallMastery,
                    strokeWidth: 6,
                    backgroundColor: color.withOpacity(0.15),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Text('🔷', style: TextStyle(fontSize: 30)),
              ],
            ),
          ),
          const SizedBox(width: KidsSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shapes',
                  style: KidsTypography.subtitle
                      .copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$masteryPercent% Mastered',
                  style: KidsTypography.label
                      .copyWith(color: KidsColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.category_rounded,
                        color: color, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '2 Shapes Learning',
                      style: KidsTypography.body.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildShapesGrid(BuildContext context, List<_ShapeInfo> shapes) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: KidsSpacing.md,
      crossAxisSpacing: KidsSpacing.md,
      childAspectRatio: 1.4,
      children: shapes.map((s) => _ShapeTile(shape: s)).toList(),
    );
  }
}

// ─── Data class ─────────────────────────────────────────────────────────────

class _ShapeInfo {
  final String name;
  final String emoji;
  final String asset;
  final double mastery;
  final Color color;

  const _ShapeInfo(this.name, this.emoji, this.asset, this.mastery, this.color);
}

// ─── Shape Tile ─────────────────────────────────────────────────────────────

class _ShapeTile extends StatelessWidget {
  final _ShapeInfo shape;

  const _ShapeTile({required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
        boxShadow: KidsShadows.soft,
        border:
            Border.all(color: shape.color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shape image or emoji
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: shape.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset(
                    shape.asset,
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => Text(
                      shape.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shape.name,
                  style: KidsTypography.label.copyWith(
                    color: shape.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Mastery bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shape.mastery,
                    minHeight: 6,
                    backgroundColor: shape.color.withOpacity(0.1),
                    color: shape.color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(shape.mastery * 100).toInt()}%',
                style: KidsTypography.small.copyWith(
                  color: shape.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shape Game Card ────────────────────────────────────────────────────────

class _ShapeGameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String desc;
  final int? played;
  final double accuracy;
  final Color color;

  const _ShapeGameCard({
    required this.title,
    required this.emoji,
    required this.desc,
    this.played,
    required this.accuracy,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KidsSpacing.md),
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child:
                    Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: KidsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KidsTypography.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc,
                    style: KidsTypography.small.copyWith(
                        color: KidsColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          // Stats column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (played != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_esports_rounded,
                        color: color.withOpacity(0.6), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$played',
                      style: KidsTypography.small.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(accuracy * 100).toInt()}%',
                  style: KidsTypography.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
