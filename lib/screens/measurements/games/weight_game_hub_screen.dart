/// Weight Game Hub
/// Magic Scale balance game for kids

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'magic_scale_game_screen.dart';

// ─── variant metadata ──────────────────────────────────────────────────────

class _VariantInfo {
  final String code;
  final String title;
  final String subtitle;
  final String emoji;
  final String description;
  final int stars;
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
    code: 'W-W1',
    title: 'Match the Target',
    subtitle: 'Balance to win',
    emoji: '⚖️',
    description: 'Drag weights to match the target number. Make the scale balance perfectly!',
    stars: 1,
    color: Color(0xFFE53935),
    lightColor: Color(0xFFFFEBEE),
  ),
  _VariantInfo(
    code: 'W-W2',
    title: 'Equal Sides',
    subtitle: 'Find balance',
    emoji: '🎯',
    description: 'Match the locked weights on the other side. Can you make them equal?',
    stars: 2,
    color: Color(0xFF8E24AA),
    lightColor: Color(0xFFF3E5F5),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class WeightGameHubScreen extends StatefulWidget {
  const WeightGameHubScreen({super.key});

  @override
  State<WeightGameHubScreen> createState() => _WeightGameHubScreenState();
}

class _WeightGameHubScreenState extends State<WeightGameHubScreen>
    with SingleTickerProviderStateMixin {
  String _currentVariant = 'W-W1';
  bool _isLoading = true;
  Map<String, int> _irtLevels = {'W-W1': 1, 'W-W2': 1};
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

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
    final studentId = prefs.getString('student_id') ?? 'default_student';

    final results = await Future.wait([
      GamesApiService.getIRTState(studentId: studentId, domain: 'weight', variant: 'W-W1'),
      GamesApiService.getIRTState(studentId: studentId, domain: 'weight', variant: 'W-W2'),
    ]);

    if (mounted) {
      setState(() {
        _irtLevels = {
          'W-W1': (results[0]['difficulty_level'] as int?) ?? 1,
          'W-W2': (results[1]['difficulty_level'] as int?) ?? 1,
        };
        _currentVariant = 'W-W1';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8E1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KidsColors.weightColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KidsColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Magic Scale',
          style: TextStyle(
            color: KidsColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: child,
                );
              },
              child: const Text('⚖️', style: TextStyle(fontSize: 32)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Balance the Scale! 🎯',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: KidsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag weights to make the scale perfectly balanced',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Game modes
              Expanded(
                child: ListView.builder(
                  itemCount: _variants.length,
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    return _buildVariantCard(variant, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(_VariantInfo variant, int index) {
    final isSelected = variant.code == _currentVariant;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 120)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? variant.color
                  : variant.color.withOpacity(0.2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: variant.color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                if (variant.code == 'W-W1') {
                  Get.to(
                    () => const MagicScaleGameScreen(mode: GameMode.matchTarget),
                    transition: Transition.rightToLeft,
                  );
                } else if (variant.code == 'W-W2') {
                  Get.to(
                    () => const MagicScaleGameScreen(mode: GameMode.equalSides),
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
                            variant.color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: variant.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                    
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variant.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: KidsColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            variant.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: variant.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildIRTLevelBadge(_irtLevels[variant.code] ?? 1),
                        ],
                      ),
                    ),
                    
                    // Difficulty stars
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            variant.stars,
                            (i) => const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: KidsColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIRTLevelBadge(int level) {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFFE91E63), Color(0xFF9C27B0),
    ];
    final idx = (level - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[idx].withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, size: 12, color: colors[idx]),
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
