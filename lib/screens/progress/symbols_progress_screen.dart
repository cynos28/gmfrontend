import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

/// Symbols progress screen — UI only (no backend)
class SymbolsProgressScreen extends StatelessWidget {
  const SymbolsProgressScreen({super.key});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: KidsSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall banner
                    _buildBanner(),
                    const SizedBox(height: KidsSpacing.xl),

                    // Symbol categories
                    Text('Symbol Skills',
                        style:
                            KidsTypography.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),

                    _SkillCard(
                      symbol: '>',
                      title: 'Greater Than',
                      desc: 'Compare bigger numbers',
                      color: const Color(0xFF9C27B0),
                      mastery: 0.8,
                      gamesPlayed: 24,
                    ),
                    _SkillCard(
                      symbol: '<',
                      title: 'Less Than',
                      desc: 'Compare smaller numbers',
                      color: const Color(0xFFE91E63),
                      mastery: 0.65,
                      gamesPlayed: 18,
                    ),
                    _SkillCard(
                      symbol: '=',
                      title: 'Equal To',
                      desc: 'Find matching values',
                      color: const Color(0xFF4CAF50),
                      mastery: 0.9,
                      gamesPlayed: 30,
                    ),
                    _SkillCard(
                      symbol: '≠',
                      title: 'Not Equal',
                      desc: 'Spot the difference',
                      color: const Color(0xFFFF5722),
                      mastery: 0.45,
                      gamesPlayed: 10,
                    ),
                    _SkillCard(
                      symbol: '+',
                      title: 'Addition',
                      desc: 'Add numbers together',
                      color: const Color(0xFF2196F3),
                      mastery: 0.7,
                      gamesPlayed: 22,
                    ),
                    _SkillCard(
                      symbol: '−',
                      title: 'Subtraction',
                      desc: 'Take away numbers',
                      color: const Color(0xFFFF9800),
                      mastery: 0.55,
                      gamesPlayed: 14,
                    ),

                    const SizedBox(height: KidsSpacing.xl),

                    // Games section
                    Text('Games Played',
                        style:
                            KidsTypography.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: KidsSpacing.md),

                    _GameStatRow(
                      title: 'Symbol Hunter',
                      emoji: '🎯',
                      played: 45,
                      bestScore: 850,
                      color: const Color(0xFF9C27B0),
                    ),
                    _GameStatRow(
                      title: 'Balloon Pop',
                      emoji: '🎈',
                      played: 32,
                      bestScore: 620,
                      color: const Color(0xFFE91E63),
                    ),
                    _GameStatRow(
                      title: 'Symbol Quiz',
                      emoji: '❓',
                      played: 20,
                      bestScore: 400,
                      color: const Color(0xFF4CAF50),
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
                Text('Symbols 🔣',
                    style: KidsTypography.title.copyWith(fontSize: 24)),
                const SizedBox(height: 2),
                Text('Compare & match symbols',
                    style: KidsTypography.helper),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    const color = KidsColors.purple;
    return Container(
      padding: const EdgeInsets.all(KidsSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            KidsColors.capacityBackground
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
          // Progress ring
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
                    value: 0.68,
                    strokeWidth: 6,
                    backgroundColor: color.withOpacity(0.15),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Text('🔣', style: TextStyle(fontSize: 30)),
              ],
            ),
          ),
          const SizedBox(width: KidsSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symbols',
                  style: KidsTypography.subtitle
                      .copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '68% Mastered',
                  style: KidsTypography.label
                      .copyWith(color: KidsColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.gamepad_rounded,
                        color: color, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '97 Games Played',
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
}

// ─── Skill Card ─────────────────────────────────────────────────────────────

class _SkillCard extends StatelessWidget {
  final String symbol;
  final String title;
  final String desc;
  final Color color;
  final double mastery;
  final int gamesPlayed;

  const _SkillCard({
    required this.symbol,
    required this.title,
    required this.desc,
    required this.color,
    required this.mastery,
    required this.gamesPlayed,
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
        border: Border.all(
            color: color.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          // Symbol circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: KidsSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KidsTypography.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc,
                    style: KidsTypography.small.copyWith(
                        color: KidsColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: mastery,
                          minHeight: 8,
                          backgroundColor: color.withOpacity(0.1),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(mastery * 100).toInt()}%',
                      style: KidsTypography.small.copyWith(
                        color: color,
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
          // Games count
          Column(
            children: [
              Text(
                '$gamesPlayed',
                style: KidsTypography.subtitle.copyWith(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'games',
                style: KidsTypography.small
                    .copyWith(color: KidsColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Game Stat Row ──────────────────────────────────────────────────────────

class _GameStatRow extends StatelessWidget {
  final String title;
  final String emoji;
  final int played;
  final int bestScore;
  final Color color;

  const _GameStatRow({
    required this.title,
    required this.emoji,
    required this.played,
    required this.bestScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KidsSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
        boxShadow: KidsShadows.soft,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: KidsTypography.label.copyWith(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('$played games played',
                    style: KidsTypography.small.copyWith(
                        color: KidsColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: KidsColors.starGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$bestScore',
                  style: KidsTypography.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
