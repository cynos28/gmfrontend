import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';

/// Measurement analytics screen with charts for length, area, volume, weight
class MeasurementProgressScreen extends StatefulWidget {
  const MeasurementProgressScreen({super.key});

  @override
  State<MeasurementProgressScreen> createState() =>
      _MeasurementProgressScreenState();
}

class _MeasurementProgressScreenState extends State<MeasurementProgressScreen> {
  bool _loading = true;
  Map<String, dynamic> _progressData = {};
  String? _selectedDomain; // null = overview, else "length"/"area"/...

  // Domain metadata
  static const _domainMeta = {
    'length': {
      'label': 'Length',
      'icon': Icons.straighten_rounded,
      'emoji': '📏',
      'color': KidsColors.lengthColor,
      'bg': KidsColors.lengthBackground,
    },
    'area': {
      'label': 'Area',
      'icon': Icons.grid_on_rounded,
      'emoji': '📐',
      'color': KidsColors.areaColor,
      'bg': KidsColors.areaBackground,
    },
    'volume': {
      'label': 'Volume',
      'icon': Icons.local_drink_rounded,
      'emoji': '🧪',
      'color': KidsColors.volumeColor,
      'bg': KidsColors.volumeBackground,
    },
    'weight': {
      'label': 'Weight',
      'icon': Icons.fitness_center_rounded,
      'emoji': '⚖️',
      'color': KidsColors.weightColor,
      'bg': KidsColors.weightBackground,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('student_id') ?? 'student_001';
      final data =
          await GamesApiService.getMeasurementProgress(studentId: studentId);
      setState(() {
        _progressData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: KidsSpacing.sm),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: KidsColors.secondaryAccent,
                        strokeWidth: 3,
                      ),
                    )
                  : _selectedDomain == null
                      ? _buildOverview()
                      : _buildDomainDetail(_selectedDomain!),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

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
            onTap: () {
              if (_selectedDomain != null) {
                setState(() => _selectedDomain = null);
              } else {
                Get.back();
              }
            },
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
                Text(
                  _selectedDomain == null
                      ? 'Measurements 📐'
                      : '${(_domainMeta[_selectedDomain]!['emoji'])} ${_domainMeta[_selectedDomain]!['label']}',
                  style: KidsTypography.title.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedDomain == null
                      ? 'Your learning journey'
                      : 'Detailed analytics',
                  style: KidsTypography.helper,
                ),
              ],
            ),
          ),
          // Refresh
          GestureDetector(
            onTap: _loadProgress,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: KidsColors.secondaryBackground,
                borderRadius:
                    BorderRadius.circular(KidsSpacing.radiusMedium),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: KidsColors.secondaryAccent, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overview (4 domain cards + overall stats) ────────────────────────────

  Widget _buildOverview() {
    final domains =
        (_progressData['domains'] as List<dynamic>?) ?? [];
    final overallRounds = _progressData['overall_rounds'] ?? 0;
    final overallAccuracy =
        ((_progressData['overall_accuracy'] ?? 0.0) as num).toDouble();
    final overallStars = _progressData['overall_stars'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: KidsSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats row
          _buildOverallStatsRow(overallRounds, overallAccuracy, overallStars),
          const SizedBox(height: KidsSpacing.xl),

          // Accuracy pie chart
          if (domains.isNotEmpty) ...[
            Text('Performance by Topic',
                style: KidsTypography.subtitle.copyWith(fontSize: 20)),
            const SizedBox(height: KidsSpacing.md),
            _buildAccuracyBarChart(domains),
            const SizedBox(height: KidsSpacing.xl),
          ],
          
          // Cognitive Skills Profile
          if (_progressData['cognitive_skills'] != null &&
              (_progressData['cognitive_skills'] as List).isNotEmpty) ...[
            Text('Cognitive Skills Profile 🧠',
                style: KidsTypography.subtitle.copyWith(fontSize: 20)),
            const SizedBox(height: KidsSpacing.md),
            _buildCognitiveSkillsProfile(_progressData['cognitive_skills'] as List<dynamic>),
            const SizedBox(height: KidsSpacing.xl),
          ],

          // Domain cards
          Text('Tap a topic for details',
              style: KidsTypography.subtitle.copyWith(fontSize: 20)),
          const SizedBox(height: KidsSpacing.md),
          ...domains.map((d) => _buildDomainCard(d)),
          const SizedBox(height: KidsSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildOverallStatsRow(
      int rounds, double accuracy, int stars) {
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
        border: Border.all(
            color: KidsColors.secondaryAccent.withOpacity(0.15), width: 2),
      ),
      child: Row(
        children: [
          _StatBubble(
            icon: Icons.sports_esports_rounded,
            label: 'Rounds',
            value: '$rounds',
            color: KidsColors.primaryAccent,
          ),
          const SizedBox(width: KidsSpacing.md),
          _StatBubble(
            icon: Icons.check_circle_rounded,
            label: 'Accuracy',
            value: '${(accuracy * 100).toInt()}%',
            color: KidsColors.secondaryAccent,
          ),
          const SizedBox(width: KidsSpacing.md),
          _StatBubble(
            icon: Icons.star_rounded,
            label: 'Stars',
            value: '$stars',
            color: KidsColors.starGold,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyBarChart(List<dynamic> domains) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                final d = domains[group.x];
                final label = (_domainMeta[d['domain']]?['label'] ?? d['domain']) as String;
                return BarTooltipItem(
                  '$label\n${rod.toY.toInt()}%',
                  KidsTypography.small.copyWith(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: KidsTypography.small.copyWith(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= domains.length) return const SizedBox();
                  final meta = _domainMeta[domains[idx]['domain']];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      (meta?['emoji'] as String?) ?? '',
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (v) => FlLine(
              color: KidsColors.borderLight.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(domains.length, (i) {
            final d = domains[i];
            final acc =
                ((d['accuracy'] ?? 0.0) as num).toDouble() * 100;
            final color =
                (_domainMeta[d['domain']]?['color'] ?? KidsColors.primaryAccent)
                    as Color;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: acc,
                  color: color,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: color.withOpacity(0.08),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCognitiveSkillsProfile(List<dynamic> cognitiveSkills) {
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        children: cognitiveSkills.map((skill) {
          final title = skill['name'] as String;
          final desc = skill['description'] as String;
          final emoji = skill['emoji'] as String;
          final score = ((skill['score'] ?? 0.0) as num).toDouble();
          
          // Parse color
          final hex = (skill['color_hex'] as String).replaceAll('#', '');
          final color = Color(int.parse(hex, radix: 16) + 0xFF000000);

          return GestureDetector(
            onTap: () => _showCognitiveSkillDetails(context, skill, color),
            child: Padding(
              padding: const EdgeInsets.only(bottom: KidsSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                ),
                child: Row(
              children: [
                // Emoji Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular( KidsSpacing.radiusMedium),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: KidsSpacing.md),
                // Text and Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: KidsTypography.label.copyWith(
                                color: KidsColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(score * 100).toInt()}%',
                            style: KidsTypography.label.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(desc, style: KidsTypography.small.copyWith(fontSize: 12, color: KidsColors.textSecondary)),
                      const SizedBox(height: 8),
                      // Progress wrapper
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: score.clamp(0.0, 1.0),
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
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
        ),
      );
    }).toList(),
  ),
);
}

  void _showCognitiveSkillDetails(BuildContext context, Map<String, dynamic> skill, Color color) {
    final title = skill['name'] as String;
    final emoji = skill['emoji'] as String;
    final desc = skill['description'] as String;
    
    String tips = '';
    String relatedGames = '';
    
    if (title.contains('Spatial')) {
      relatedGames = 'Area Architect, Length Explorer';
      tips = 'Practice playing with building blocks, doing jigsaw puzzles, and drawing shapes to improve spatial reasoning.';
    } else if (title.contains('Logic')) {
      relatedGames = 'Magic Scale, Volume Compare';
      tips = 'Play sorting games, balance a seesaw, or help with cooking to better understand concepts like heavier, lighter, and more/less.';
    } else if (title.contains('Estimation')) {
      relatedGames = 'Volume Fill, Area Architect';
      tips = 'Try guessing how many steps it takes to reach the door, or how many small cups of water fill a big jug before actually trying it!';
    } else if (title.contains('Conservation')) {
      relatedGames = 'Magic Scale, Weight Match';
      tips = 'Pour water between different sized glasses to see that the amount of water stays the same even if it looks taller or shorter!';
    } else {
      relatedGames = 'Area Tiles, Length Ruler';
      tips = 'Practice lining up identical objects (like paper clips or blocks) end-to-end without any gaps to measure things accurately.';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(KidsSpacing.screenPadding),
        decoration: const BoxDecoration(
          color: KidsColors.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: KidsSpacing.xl),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: KidsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KidsTypography.title.copyWith(fontSize: 24, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: KidsTypography.subtitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KidsSpacing.xl),
            Container(
              padding: const EdgeInsets.all(KidsSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.videogame_asset_rounded, color: color),
                      const SizedBox(width: 8),
                      Text('Related Games', style: KidsTypography.label.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(relatedGames, style: KidsTypography.small),
                ],
              ),
            ),
            const SizedBox(height: KidsSpacing.md),
            Container(
              padding: const EdgeInsets.all(KidsSpacing.md),
              decoration: BoxDecoration(
                color: KidsColors.starGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                border: Border.all(color: KidsColors.starGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: KidsColors.starGold),
                      const SizedBox(width: 8),
                      Text('How to Improve', style: KidsTypography.label.copyWith(color: KidsColors.starGold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tips, style: KidsTypography.small.copyWith(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: KidsSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it!',
                  style: KidsTypography.label.copyWith(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: KidsSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard(Map<String, dynamic> d) {
    final domain = d['domain'] as String;
    final meta = _domainMeta[domain]!;
    final color = meta['color'] as Color;
    final bg = meta['bg'] as Color;
    final label = meta['label'] as String;
    final emoji = meta['emoji'] as String;
    final rounds = d['total_rounds'] ?? 0;
    final accuracy =
        ((d['accuracy'] ?? 0.0) as num).toDouble();
    final stars = d['total_stars'] ?? 0;
    final level = (d['avg_difficulty'] ?? 0.0) as num;

    return GestureDetector(
      onTap: () => setState(() => _selectedDomain = domain),
      child: Container(
        margin: const EdgeInsets.only(bottom: KidsSpacing.md),
        padding: const EdgeInsets.all(KidsSpacing.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(KidsSpacing.radiusLarge),
          boxShadow: KidsShadows.soft,
          border: Border.all(color: color.withOpacity(0.15), width: 2),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    BorderRadius.circular(KidsSpacing.radiusMedium),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: KidsSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: KidsTypography.label.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniStat(
                          icon: Icons.sports_esports_rounded,
                          text: '$rounds rounds',
                          color: color),
                      const SizedBox(width: 12),
                      _MiniStat(
                          icon: Icons.star_rounded,
                          text: '$stars ⭐',
                          color: KidsColors.starGold),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Accuracy bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: accuracy,
                            minHeight: 8,
                            backgroundColor: color.withOpacity(0.12),
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(accuracy * 100).toInt()}%',
                        style: KidsTypography.small.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Level badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv ${level.toStringAsFixed(0)}',
                    style: KidsTypography.small.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.5), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Domain Detail View (with charts) ─────────────────────────────────────

  Widget _buildDomainDetail(String domain) {
    final domains =
        (_progressData['domains'] as List<dynamic>?) ?? [];
    final domainData = domains.firstWhere(
      (d) => d['domain'] == domain,
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;

    final meta = _domainMeta[domain]!;
    final color = meta['color'] as Color;
    final bg = meta['bg'] as Color;
    final label = meta['label'] as String;
    final emoji = meta['emoji'] as String;

    final rounds = domainData['total_rounds'] ?? 0;
    final correct = domainData['total_correct'] ?? 0;
    final attempts = domainData['total_attempts'] ?? 0;
    final stars = domainData['total_stars'] ?? 0;
    final accuracy =
        ((domainData['accuracy'] ?? 0.0) as num).toDouble();
    final avgTheta =
        ((domainData['avg_theta'] ?? 0.0) as num).toDouble();
    final avgDiff =
        ((domainData['avg_difficulty'] ?? 0.0) as num).toDouble();
    final thetaTrend =
        (domainData['theta_trend'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [];
    final diffTrend =
        (domainData['difficulty_trend'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [];
    final variants =
        (domainData['variants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: KidsSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards row
          _buildDetailStatsRow(
            rounds: rounds,
            correct: correct,
            attempts: attempts,
            stars: stars,
            accuracy: accuracy,
            color: color,
            bg: bg,
          ),
          const SizedBox(height: KidsSpacing.xl),

          // Skill Level gauge
          _buildSkillLevelCard(avgTheta, avgDiff, color, bg, label),
          const SizedBox(height: KidsSpacing.xl),

          // Theta trend chart
          if (thetaTrend.isNotEmpty) ...[
            Text('Skill Progress 📈',
                style: KidsTypography.subtitle.copyWith(fontSize: 20)),
            const SizedBox(height: KidsSpacing.sm),
            _buildThetaTrendChart(thetaTrend, color),
            const SizedBox(height: KidsSpacing.xl),
          ],

          // Difficulty trend chart
          if (diffTrend.isNotEmpty) ...[
            Text('Difficulty Level 🎯',
                style: KidsTypography.subtitle.copyWith(fontSize: 20)),
            const SizedBox(height: KidsSpacing.sm),
            _buildDifficultyChart(diffTrend, color),
            const SizedBox(height: KidsSpacing.xl),
          ],

          // Variants played
          if (variants.isNotEmpty) ...[
            Text('Games Played 🎮',
                style: KidsTypography.subtitle.copyWith(fontSize: 20)),
            const SizedBox(height: KidsSpacing.sm),
            _buildVariantsChips(variants, color, bg),
            const SizedBox(height: KidsSpacing.xl),
          ],

          // No data state
          if (rounds == 0)
            _buildNoDataCard(emoji, label, color, bg),

          const SizedBox(height: KidsSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildDetailStatsRow({
    required int rounds,
    required int correct,
    required int attempts,
    required int stars,
    required double accuracy,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
        border: Border.all(color: color.withOpacity(0.15), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatBubble(
                icon: Icons.sports_esports_rounded,
                label: 'Rounds',
                value: '$rounds',
                color: color,
              ),
              const SizedBox(width: KidsSpacing.sm),
              _StatBubble(
                icon: Icons.check_circle_rounded,
                label: 'Correct',
                value: '$correct',
                color: KidsColors.success,
              ),
              const SizedBox(width: KidsSpacing.sm),
              _StatBubble(
                icon: Icons.star_rounded,
                label: 'Stars',
                value: '$stars',
                color: KidsColors.starGold,
              ),
            ],
          ),
          const SizedBox(height: KidsSpacing.md),
          // Accuracy bar
          Row(
            children: [
              Text('Accuracy', style: KidsTypography.label.copyWith(fontSize: 16)),
              const Spacer(),
              Text(
                '${(accuracy * 100).toInt()}%',
                style: KidsTypography.subtitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: accuracy,
              minHeight: 12,
              backgroundColor: color.withOpacity(0.1),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillLevelCard(
      double theta, double diff, Color color, Color bg, String label) {
    // Map theta (-3 to 3) to a 0-100 skill meter
    final skillPercent = ((theta + 3) / 6.0).clamp(0.0, 1.0);
    final levelLabel = _getLevelLabel(diff);

    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Skill Level',
                  style: KidsTypography.subtitle.copyWith(fontSize: 18)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  levelLabel,
                  style: KidsTypography.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KidsSpacing.md),
          // Skill bar
          Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade300,
                      Colors.orange.shade300,
                      Colors.yellow.shade400,
                      Colors.lightGreen.shade400,
                      Colors.green.shade500,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (MediaQuery.of(context).size.width -
                        KidsSpacing.screenPadding * 2 -
                        KidsSpacing.cardPadding * 2) *
                    skillPercent -
                    12,
                top: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    boxShadow: KidsShadows.soft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Beginner',
                  style: KidsTypography.small.copyWith(fontSize: 11)),
              Text('Expert',
                  style: KidsTypography.small.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThetaTrendChart(List<double> theta, Color color) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
      ),
      child: LineChart(
        LineChartData(
          minY: -3,
          maxY: 3,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        'θ = ${s.y.toStringAsFixed(2)}',
                        KidsTypography.small.copyWith(color: Colors.white),
                      ))
                  .toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: KidsColors.borderLight.withOpacity(0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: KidsTypography.small.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(theta.length,
                  (i) => FlSpot(i.toDouble(), theta[i])),
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChart(List<int> diff, Color color) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, _) {
                  if (v < 1 || v > 5) return const SizedBox();
                  return Text('${v.toInt()}',
                      style: KidsTypography.small.copyWith(fontSize: 10));
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: KidsColors.borderLight.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(diff.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: diff[i].toDouble(),
                  width: diff.length > 10 ? 8 : 16,
                  color: color.withOpacity(0.3 + (diff[i] / 5.0) * 0.7),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVariantsChips(
      List<String> variants, Color color, Color bg) {
    final variantLabels = {
      'L-V4': 'Bridge Builder',
      'A-V1': 'Tile Rectangle',
      'A-V2': 'Carpet Designer',
      'V-V1': 'Volume Fill',
      'V-V2': 'Volume Compare',
      'W-W1': 'Weight Match',
      'W-W2': 'Weight Balance',
    };

    return Wrap(
      spacing: KidsSpacing.sm,
      runSpacing: KidsSpacing.sm,
      children: variants.toSet().map((v) {
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gamepad_rounded,
                  size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                variantLabels[v] ?? v,
                style: KidsTypography.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDataCard(
      String emoji, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        border: Border.all(
            color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: KidsSpacing.md),
          Text(
            'No $label games yet!',
            style: KidsTypography.subtitle.copyWith(
                color: color, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Play some games to see you progress here 🎮',
            style: KidsTypography.body.copyWith(
                color: KidsColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(num diff) {
    if (diff < 1.5) return '🌱 Beginner';
    if (diff < 2.5) return '🌿 Learning';
    if (diff < 3.5) return '🌳 Growing';
    if (diff < 4.5) return '🌟 Advanced';
    return '🏆 Expert';
  }
}

// ─── Reusable widgets ───────────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBubble({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: KidsTypography.subtitle.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: KidsTypography.small.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: KidsTypography.small.copyWith(
            color: KidsColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
