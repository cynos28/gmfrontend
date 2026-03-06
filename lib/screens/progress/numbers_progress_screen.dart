import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

/// Numbers progress screen — UI only (no backend)
class NumbersProgressScreen extends StatelessWidget {
  const NumbersProgressScreen({super.key});

  static const _activities = [
    _ActivityItem(
      title: 'Trace Numbers',
      emoji: '✍️',
      desc: 'Practice writing 0-9',
      color: Color(0xFF4285F4),
      progress: 0.7,
      stars: 12,
    ),
    _ActivityItem(
      title: 'Say Numbers',
      emoji: '🗣️',
      desc: 'Speak numbers aloud',
      color: Color(0xFF34C759),
      progress: 0.5,
      stars: 8,
    ),
    _ActivityItem(
      title: 'Read Numbers',
      emoji: '📖',
      desc: 'Identify written numbers',
      color: Color(0xFFFF9500),
      progress: 0.85,
      stars: 15,
    ),
    _ActivityItem(
      title: 'Object Count',
      emoji: '🔍',
      desc: 'Count real objects',
      color: Color(0xFF9C27B0),
      progress: 0.3,
      stars: 5,
    ),
    _ActivityItem(
      title: 'Video Lessons',
      emoji: '🎬',
      desc: 'Watch & learn',
      color: Color(0xFF00BCD4),
      progress: 0.6,
      stars: 10,
    ),
    _ActivityItem(
      title: 'Number Test',
      emoji: '📝',
      desc: 'Test your knowledge',
      color: Color(0xFFFF4081),
      progress: 0.4,
      stars: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalStars = _activities.fold<int>(0, (s, a) => s + a.stars);
    final avgProgress =
        _activities.fold<double>(0, (s, a) => s + a.progress) /
            _activities.length;

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
                    // Overall stats banner
                    _OverallBanner(
                      emoji: '🔢',
                      title: 'Numbers',
                      color: KidsColors.primaryAccent,
                      bg: KidsColors.primaryBackground,
                      totalStars: totalStars,
                      avgProgress: avgProgress,
                    ),
                    const SizedBox(height: KidsSpacing.xl),

                    // Activities header
                    Text('Activities',
                        style: KidsTypography.subtitle
                            .copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),

                    // Activity cards
                    ..._activities.map((a) => _ActivityCard(item: a)),

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
    return _ProgressHeader(
      title: 'Numbers 🔢',
      subtitle: 'Count, trace & learn',
      onBack: () => Get.back(),
    );
  }
}

/// Symbols progress screen — UI only (no backend)
class _ActivityItem {
  final String title;
  final String emoji;
  final String desc;
  final Color color;
  final double progress;
  final int stars;

  const _ActivityItem({
    required this.title,
    required this.emoji,
    required this.desc,
    required this.color,
    required this.progress,
    required this.stars,
  });
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _ProgressHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
            onTap: onBack,
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
                Text(title,
                    style: KidsTypography.title.copyWith(fontSize: 24)),
                const SizedBox(height: 2),
                Text(subtitle, style: KidsTypography.helper),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallBanner extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Color bg;
  final int totalStars;
  final double avgProgress;

  const _OverallBanner({
    required this.emoji,
    required this.title,
    required this.color,
    required this.bg,
    required this.totalStars,
    required this.avgProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: KidsShadows.soft,
      ),
      child: Row(
        children: [
          // Emoji + progress ring
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
                    value: avgProgress,
                    strokeWidth: 6,
                    backgroundColor: color.withOpacity(0.15),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 30)),
              ],
            ),
          ),
          const SizedBox(width: KidsSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KidsTypography.subtitle.copyWith(
                      color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(avgProgress * 100).toInt()}% Complete',
                  style: KidsTypography.label
                      .copyWith(color: KidsColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: KidsColors.starGold, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$totalStars Stars Earned',
                      style: KidsTypography.body.copyWith(
                        color: KidsColors.starGold,
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
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KidsSpacing.md),
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
        boxShadow: KidsShadows.soft,
        border: Border.all(
            color: item.color.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          // Emoji circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child:
                  Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: KidsSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: KidsTypography.label.copyWith(
                    color: item.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.desc,
                    style: KidsTypography.small.copyWith(
                        color: KidsColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 8),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 8,
                          backgroundColor:
                              item.color.withOpacity(0.1),
                          color: item.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(item.progress * 100).toInt()}%',
                      style: KidsTypography.small.copyWith(
                        color: item.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stars
          Column(
            children: [
              const Icon(Icons.star_rounded,
                  color: KidsColors.starGold, size: 22),
              const SizedBox(height: 2),
              Text(
                '${item.stars}',
                style: KidsTypography.small.copyWith(
                  color: KidsColors.starGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
