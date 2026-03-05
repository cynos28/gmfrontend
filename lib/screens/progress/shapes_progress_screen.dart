import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

/// Shapes progress screen — UI only (no backend)
class ShapesProgressScreen extends StatelessWidget {
  const ShapesProgressScreen({super.key});

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

                    // 2D Shapes section
                    Text('2D Shapes',
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
                      title: 'Match Shapes',
                      emoji: '🃏',
                      desc: 'Find the matching pair',
                      played: 28,
                      accuracy: 0.82,
                      color: const Color(0xFFFF9500),
                    ),
                    _ShapeGameCard(
                      title: 'Build & Match',
                      emoji: '🏗️',
                      desc: 'Build the right shape',
                      played: 15,
                      accuracy: 0.7,
                      color: const Color(0xFF4CAF50),
                    ),
                    _ShapeGameCard(
                      title: 'Find Real Shapes',
                      emoji: '📸',
                      desc: 'Spot shapes in photos',
                      played: 22,
                      accuracy: 0.75,
                      color: const Color(0xFF2196F3),
                    ),
                    _ShapeGameCard(
                      title: 'Pattern Match',
                      emoji: '🧩',
                      desc: 'Complete the pattern',
                      played: 12,
                      accuracy: 0.6,
                      color: const Color(0xFF9C27B0),
                    ),
                    _ShapeGameCard(
                      title: 'AR Shape Hunt',
                      emoji: '🔍',
                      desc: 'Find 3D shapes in AR',
                      played: 8,
                      accuracy: 0.55,
                      color: const Color(0xFFE91E63),
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

  static const _shapes2D = [
    _ShapeInfo('Circle', '⭕', 'assets/images/2d_shapes/circle.png', 0.9,
        Color(0xFF4285F4)),
    _ShapeInfo('Square', '🟧', 'assets/images/2d_shapes/square.png', 0.85,
        Color(0xFFFF9500)),
    _ShapeInfo('Triangle', '🔺', 'assets/images/2d_shapes/triangle.png',
        0.75, Color(0xFF34C759)),
    _ShapeInfo('Rectangle', '🟩', 'assets/images/2d_shapes/rectangle.png',
        0.8, Color(0xFF9C27B0)),
  ];

  static const _shapes3D = [
    _ShapeInfo(
        'Cube', '🧊', 'assets/images/3d_shapes/cube.png', 0.6, Color(0xFF00BCD4)),
    _ShapeInfo('Sphere', '🔮', 'assets/images/3d_shapes/sphere.png', 0.5,
        Color(0xFFE91E63)),
    _ShapeInfo('Cone', '🔻', 'assets/images/3d_shapes/cone.png', 0.4,
        Color(0xFFFF5722)),
    _ShapeInfo('Cylinder', '🪣', 'assets/images/3d_shapes/cylinder.png',
        0.45, Color(0xFF795548)),
  ];

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
                    value: 0.62,
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
                  '62% Mastered',
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
                      '8 Shapes Learned',
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
  final int played;
  final double accuracy;
  final Color color;

  const _ShapeGameCard({
    required this.title,
    required this.emoji,
    required this.desc,
    required this.played,
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
