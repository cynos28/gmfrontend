import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'measurement_progress_screen.dart';
import 'numbers_progress_screen.dart';
import 'symbols_progress_screen.dart';
import 'shapes_progress_screen.dart';

/// Main Progress screen with large kid-friendly category cards
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1 column on phone, 2 on tablet
    final int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 2 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────
            _buildHeader(context),
            const SizedBox(height: 16),

            // ─── Grid Cards ────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  // Tweak aspect ratio based on columns so they are always large
                  childAspectRatio: crossAxisCount == 1 ? 1.8 : 1.2,
                  children: [
                    _CategoryCard(
                      title: 'Numbers',
                      icon: Icons.looks_one_rounded,
                      color: const Color(0xFFFF9800), // Orange
                      bgColor: const Color(0xFFFFE0B2),
                      image: 'assets/vectors/stitch1.png',
                      onTap: () => Get.to(() => const NumbersProgressScreen(), transition: Transition.rightToLeft),
                    ),
                    _CategoryCard(
                      title: 'Symbols',
                      icon: Icons.compare_arrows_rounded,
                      color: const Color(0xFF9C27B0), // Purple
                      bgColor: const Color(0xFFE1BEE7),
                      image: 'assets/vectors/stitch2.png',
                      onTap: () => Get.to(() => const SymbolsProgressScreen(), transition: Transition.rightToLeft),
                    ),
                    _CategoryCard(
                      title: 'Measurements',
                      icon: Icons.straighten_rounded,
                      color: const Color(0xFF4CAF50), // Green
                      bgColor: const Color(0xFFC8E6C9),
                      image: 'assets/vectors/stitch3.png',
                      onTap: () => Get.to(() => const MeasurementProgressScreen(), transition: Transition.rightToLeft),
                    ),
                    _CategoryCard(
                      title: 'Shapes',
                      icon: Icons.category_rounded,
                      color: const Color(0xFF2196F3), // Blue
                      bgColor: const Color(0xFFBBDEFB),
                      image: 'assets/vectors/stitch4.png',
                      onTap: () => Get.to(() => const ShapesProgressScreen(), transition: Transition.rightToLeft),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Progress 📊',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'See how far you\'ve come!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Trophy icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFB300),
              size: 36,
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
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String image;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
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
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Text side
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 28),
                          ),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Image side
                    Expanded(
                      flex: 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
