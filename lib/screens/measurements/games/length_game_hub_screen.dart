/// Length Game Hub
/// Lets kids pick a Length game variant suited to their current level.
/// Variant progression: L-V1 → L-V2 → L-V3 → L-V4

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'length_game_play_screen.dart';

// ─── variant metadata ──────────────────────────────────────────────────────

class _VariantInfo {
  final String code; // e.g. "L-V1"
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
    code: 'L-V1',
    title: 'Ruler Explorer',
    subtitle: 'Measure 1 thing',
    emoji: '📏',
    description: 'Use the ruler to measure one object. How long is it?',
    stars: 1,
    color: Color(0xFF4285F4),
    lightColor: Color(0xFFE8F4FF),
  ),
  _VariantInfo(
    code: 'L-V2',
    title: 'Compare & Win',
    subtitle: 'Measure 2 things',
    emoji: '⚖️',
    description: 'Measure two objects and find out which one is longer!',
    stars: 2,
    color: Color(0xFF34C759),
    lightColor: Color(0xFFE6F9EC),
  ),
  _VariantInfo(
    code: 'L-V3',
    title: 'Calculate & Win',
    subtitle: 'Convert units!',
    emoji: '🧮',
    description: 'See a measurement in mm or m. Can you convert it to cm?',
    stars: 3,
    color: Color(0xFFFF9500),
    lightColor: Color(0xFFFFF3E0),
  ),
  _VariantInfo(
    code: 'L-V4',
    title: 'Build a Bridge',
    subtitle: 'Combine lengths',
    emoji: '🌉',
    description: 'Pick strips that add up to the target length. Can you build it?',
    stars: 4,
    color: Color(0xFF9C27B0),
    lightColor: Color(0xFFF3E5F5),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class LengthGameHubScreen extends StatefulWidget {
  const LengthGameHubScreen({super.key});

  @override
  State<LengthGameHubScreen> createState() => _LengthGameHubScreenState();
}

class _LengthGameHubScreenState extends State<LengthGameHubScreen>
    with SingleTickerProviderStateMixin {
  String _currentVariant = 'L-V1';
  bool _isLoading = true;
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
    final prefs  = await SharedPreferences.getInstance();
    final params = await GamesApiService.getParameters('length');

    // Take whichever is the higher unlocked variant between backend and local.
    const order = ['L-V1', 'L-V2', 'L-V3', 'L-V4'];
    final fromBackend = (params['current_variant'] as String?) ?? 'L-V1';
    final fromLocal   = prefs.getString('length_unlocked_variant') ?? 'L-V1';
    final backendIdx  = order.indexOf(fromBackend);
    final localIdx    = order.indexOf(fromLocal);
    final best = order[localIdx > backendIdx ? localIdx : backendIdx];

    if (mounted) {
      setState(() {
        _currentVariant = best;
        _isLoading = false;
      });
    }
  }

  /// Returns the index (0-3) of the current variant, used to determine locks.
  int get _currentIndex =>
      _variants.indexWhere((v) => v.code == _currentVariant).clamp(0, 3);

  bool _isUnlocked(_VariantInfo info) {
    final idx = _variants.indexOf(info);
    return idx <= _currentIndex;
  }

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
    Get.to(
      () => LengthGamePlayScreen(variant: info.code),
      transition: Transition.rightToLeft,
    );
  }

  // ─── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: KidsColors.lengthColor,
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
          colors: [Color(0xFF4285F4), Color(0xFF0D47A1)],
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
                  'Length Games',
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
                  child: const Text('📏', style: TextStyle(fontSize: 36)),
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
                // Icon circle
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
                // Text
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
                          // Stars
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow / play btn
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
