/// Volume Game Hub
/// Fill to Target game for kids

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'volume_game_play_screen.dart';
import 'volume_compare_game_screen.dart';

// ─── variant metadata ──────────────────────────────────────────────────────

class _VariantInfo {
  final String code; // e.g. "V-V1"
  final String title;
  final String subtitle;
  final String emoji;
  final String description;
  final int stars; // 1-4
  final Color color;
  final Color lightColor;

  const _VariantInfo({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.description,
    required this.stars,
    required this.color,
    required this.lightColor,
  });
}

const List<_VariantInfo> _variants = [
  _VariantInfo(
    code: 'V-V1',
    title: 'Fill to Target',
    subtitle: 'Measure and pour',
    emoji: '🥤',
    description: 'Pour liquid to reach the target amount. Use the measuring scale to help you!',
    stars: 1,
    color: Color(0xFF00BCD4),
    lightColor: Color(0xFFE0F7FA),
  ),
  _VariantInfo(
    code: 'V-V2',
    title: 'Volume Compare',
    subtitle: 'Which holds more?',
    emoji: '🥛',
    description: 'Compare containers and find which holds the most, least, or same amount!',
    stars: 2,
    color: Color(0xFF2196F3),
    lightColor: Color(0xFFE3F2FD),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class VolumeGameHubScreen extends StatefulWidget {
  const VolumeGameHubScreen({super.key});

  @override
  State<VolumeGameHubScreen> createState() => _VolumeGameHubScreenState();
}

class _VolumeGameHubScreenState extends State<VolumeGameHubScreen>
    with SingleTickerProviderStateMixin {
  String _currentVariant = 'V-V1';
  bool _isLoading = true;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  // IRT state per variant
  Map<String, int> _irtLevels = {'V-V1': 1, 'V-V2': 1};
  Map<String, double> _irtThetas = {'V-V1': 0.0, 'V-V2': 0.0};
  String _studentId = 'default_student';

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _loadParams();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadParams() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('student_id') ?? 'default_student';
    
    // Fetch IRT state for both variants
    final vv1State = await GamesApiService.getIRTState(
      studentId: _studentId,
      domain: 'volume',
      variant: 'V-V1',
    );
    final vv2State = await GamesApiService.getIRTState(
      studentId: _studentId,
      domain: 'volume',
      variant: 'V-V2',
    );
    
    if (mounted) {
      setState(() {
        _irtLevels['V-V1'] = (vv1State['difficulty_level'] as int?) ?? 1;
        _irtThetas['V-V1'] = (vv1State['theta'] as num?)?.toDouble() ?? 0.0;
        _irtLevels['V-V2'] = (vv2State['difficulty_level'] as int?) ?? 1;
        _irtThetas['V-V2'] = (vv2State['theta'] as num?)?.toDouble() ?? 0.0;
        _currentVariant = 'V-V1';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
                        const Text(
                          'Volume Games',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: KidsColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_drink_rounded,
                              size: 16,
                              color: KidsColors.volumeColor,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Pour and measure!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: KidsColors.textSecondary,
                                height: 1.2,
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

            // Game variants
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _variants.length,
                      itemBuilder: (context, index) {
                        final variant = _variants[index];
                        return _buildVariantCard(variant);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(_VariantInfo variant) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              variant.lightColor,
              variant.lightColor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: variant.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: variant.color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              if (variant.code == 'V-V2') {
                Get.to(
                  () => const VolumeCompareGameScreen(),
                  transition: Transition.rightToLeft,
                );
              } else {
                Get.to(
                  () => VolumeGamePlayScreen(variant: variant.code),
                  transition: Transition.rightToLeft,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          variant.color,
                          variant.color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: variant.color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        variant.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                variant.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: KidsColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildIRTLevelBadge(variant.code),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          variant.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KidsColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          variant.description,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: KidsColors.textSecondary.withOpacity(0.8),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Stars
                        Row(
                          children: List.generate(
                            4,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                i < variant.stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 18,
                                color: i < variant.stars
                                    ? const Color(0xFFFFB800)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Play button with bounce animation
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            variant.color,
                            variant.color.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: variant.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIRTLevelBadge(String variantCode) {
    final level = _irtLevels[variantCode] ?? 1;
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0)
    ];
    final idx = (level - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors[idx].withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, color: colors[idx], size: 14),
          const SizedBox(width: 4),
          Text(
            labels[idx],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors[idx],
            ),
          ),
        ],
      ),
    );
  }
}
