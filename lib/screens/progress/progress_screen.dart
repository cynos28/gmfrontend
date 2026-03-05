import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'measurement_progress_screen.dart';
import 'numbers_progress_screen.dart';
import 'symbols_progress_screen.dart';
import 'shapes_progress_screen.dart';

/// Main Progress screen with 4 large kid-friendly category cards
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────
            _buildHeader(context),
            const SizedBox(height: KidsSpacing.lg),

            // ─── 4 Grid Cards ────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KidsSpacing.screenPadding,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: KidsSpacing.lg,
                  crossAxisSpacing: KidsSpacing.lg,
                  childAspectRatio: 0.85,
                  children: [
                    _CategoryCard(
                      title: 'Numbers',
                      subtitle: 'Count & Trace',
                      icon: Icons.looks_one_rounded,
                      color: KidsColors.primaryAccent,
                      bgColor: KidsColors.primaryBackground,
                      image: 'assets/vectors/kid1.png',
                      onTap: () => Get.to(() => const NumbersProgressScreen()),
                    ),
                    _CategoryCard(
                      title: 'Symbols',
                      subtitle: 'Compare & Match',
                      icon: Icons.compare_arrows_rounded,
                      color: KidsColors.purple,
                      bgColor: KidsColors.capacityBackground,
                      image: 'assets/vectors/kid2.png',
                      onTap: () => Get.to(() => const SymbolsProgressScreen()),
                    ),
                    _CategoryCard(
                      title: 'Measurements',
                      subtitle: 'Length, Area & More',
                      icon: Icons.straighten_rounded,
                      color: KidsColors.secondaryAccent,
                      bgColor: KidsColors.secondaryBackground,
                      image: 'assets/vectors/kid3.png',
                      onTap: () => Get.to(() => const MeasurementProgressScreen()),
                    ),
                    _CategoryCard(
                      title: 'Shapes',
                      subtitle: '2D & 3D Shapes',
                      icon: Icons.category_rounded,
                      color: KidsColors.highlightAccent,
                      bgColor: KidsColors.highlightBackground,
                      image: 'assets/vectors/kid4.png',
                      onTap: () => Get.to(() => const ShapesProgressScreen()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KidsSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        KidsSpacing.screenPadding,
        KidsSpacing.lg,
        KidsSpacing.screenPadding,
        KidsSpacing.sm,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
                boxShadow: KidsShadows.soft,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: KidsColors.textPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: KidsSpacing.md),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Progress 📊',
                  style: KidsTypography.title.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  'See how far you\'ve come!',
                  style: KidsTypography.helper.copyWith(
                    color: KidsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Trophy icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: KidsColors.starBackground,
              borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
              boxShadow: KidsShadows.soft,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: KidsColors.starGold,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large, colorful kid-friendly category card
class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String image;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
          boxShadow: KidsShadows.medium,
          border: Border.all(color: color.withOpacity(0.15), width: 2),
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KidsSpacing.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor.withOpacity(0.5),
                      bgColor.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(KidsSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  // Character image
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      image,
                      height: 50,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        size: 40,
                        color: color.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: KidsTypography.subtitle.copyWith(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // Subtitle
                  Text(
                    subtitle,
                    style: KidsTypography.small.copyWith(
                      color: KidsColors.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow indicator
            Positioned(
              bottom: KidsSpacing.sm,
              right: KidsSpacing.sm,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
