/// Area Game Hub
/// Area games for kids: Tile Rectangle and Tiny Builders

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'area_game_play_screen.dart';
import 'area_architect_game_screen.dart';

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
    code: 'A-V1',
    title: 'Tile Rectangle',
    subtitle: 'Cover the shape',
    emoji: '🟩',
    description: 'Fill a rectangle with 1 cm² tiles. Count rows × columns!',
    stars: 1,
    color: Color(0xFF34C759),
    lightColor: Color(0xFFE6F9EC),
  ),
  _VariantInfo(
    code: 'A-V2',
    title: 'Area Architect',
    subtitle: 'Design custom carpets',
    emoji: '🧶',
    description: 'Stretch and cut rugs to fit wacky rooms. Discover area with length × width and smart splits.',
    stars: 2,
    color: Color(0xFFD2691E),
    lightColor: Color(0xFFFFF8DC),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class AreaGameHubScreen extends StatefulWidget {
  const AreaGameHubScreen({super.key});

  @override
  State<AreaGameHubScreen> createState() => _AreaGameHubScreenState();
}

class _AreaGameHubScreenState extends State<AreaGameHubScreen>
    with SingleTickerProviderStateMixin {
  String _currentVariant = 'A-V1';
  bool _isLoading = true;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // IRT state per variant
  final Map<String, int> _irtLevels = {};
  final Map<String, double> _irtThetas = {};

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
    if (!mounted) return;
    final userId = prefs.getString('student_id') ?? 'student_001';

    // Fetch IRT state for each variant
    for (final v in _variants) {
      try {
        final irt = await GamesApiService.getIRTState(
          studentId: userId,
          domain: 'area',
          variant: v.code,
        );
        if (!mounted) return;
        _irtLevels[v.code] = (irt['difficulty_level'] as num?)?.toInt() ?? 1;
        _irtThetas[v.code] = (irt['theta'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        _irtLevels[v.code] = 1;
        _irtThetas[v.code] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _currentVariant = 'A-V1';
        _isLoading = false;
      });
    }
  }

  bool _isUnlocked(_VariantInfo info) => true;

  bool _isCurrent(_VariantInfo info) => info.code == _currentVariant;

  void _play(_VariantInfo info) {
    if (!_isUnlocked(info)) {
      Get.snackbar(
        '🔒 Locked',
        'Complete earlier levels to unlock ${info.title}!',
        backgroundColor: KidsColors.warning,
        colorText: KidsColors.textPrimary,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }
    final Widget screen =
        info.code == 'A-V2' ? const AreaArchitectGameScreen() : AreaGamePlayScreen(variant: info.code);
    Get.to(
      () => screen,
      transition: Transition.rightToLeft,
    )?.then((_) {
      // Refresh unlock state when returning from game
      _loadParams();
    });
  }

  // ─── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: KidsColors.areaColor,
                        strokeWidth: 3,
                      ),
                    )
                  : _buildVariantList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34C759), Color(0xFF1B8A3E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          Row(
            children: [
              _circleBtn(
                Icons.arrow_back_rounded,
                Colors.white,
                Colors.white.withOpacity(0.2),
                () => Get.back(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Area Games',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: const Text('📐', style: TextStyle(fontSize: 36)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Your level: $_currentVariant',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: _variants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _buildVariantCard(_variants[i]),
    );
  }

  Widget _buildVariantCard(_VariantInfo info) {
    final unlocked = _isUnlocked(info);
    final current = _isCurrent(info);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(24),
        border: current
            ? Border.all(color: info.color, width: 3)
            : Border.all(color: Colors.transparent, width: 3),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: info.color.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _play(info),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: unlocked ? info.lightColor : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      unlocked ? info.emoji : '🔒',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: unlocked
                                    ? KidsColors.textPrimary
                                    : KidsColors.textTertiary,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              info.stars,
                              (_) => Text(
                                '⭐',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: unlocked
                                      ? null
                                      : Colors.grey.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              unlocked ? info.color : KidsColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: unlocked
                              ? KidsColors.textSecondary
                              : KidsColors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                      if (unlocked && _irtLevels.containsKey(info.code)) ...[                        const SizedBox(height: 8),
                        _buildIRTLevelBadge(info.code),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (unlocked)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: current ? info.color : info.lightColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      current
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      color: current ? Colors.white : info.color,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIRTLevelBadge(String variantCode) {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0)
    ];
    final level = (_irtLevels[variantCode] ?? 1).clamp(1, 5);
    final idx = level - 1;
    final theta = _irtThetas[variantCode] ?? 0.0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors[idx].withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors[idx].withOpacity(0.4), width: 1),
          ),
          child: Text(
            'Level $level \u2022 ${labels[idx]}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors[idx],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\u03b8 ${theta.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: KidsColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
