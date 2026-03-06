/// Weight Game Hub - Kid-Friendly Redesign
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'magic_scale_game_screen.dart';

class _VariantInfo {
  final String code;
  final String title;
  final String emoji;
  final int stars;
  final Color color;
  final Color bgColor;
  final String vectorImage;
  final GameMode gameMode;

  const _VariantInfo({
    required this.code,
    required this.title,
    required this.emoji,
    required this.stars,
    required this.color,
    required this.bgColor,
    required this.vectorImage,
    required this.gameMode,
  });
}

const List<_VariantInfo> _variants = [
  _VariantInfo(
    code: 'W-W1',
    title: 'Match the Target',
    emoji: '⚖️',
    stars: 1,
    color: Color(0xFFFF9800), // Orange from home screen
    bgColor: Color(0xFFFFE0B2), // Stronger Light Orange
    vectorImage: 'assets/vectors/stitch3.png',
    gameMode: GameMode.matchTarget,
  ),
  _VariantInfo(
    code: 'W-W2',
    title: 'Equal Sides',
    emoji: '🎯',
    stars: 2,
    color: Color(0xFFFF9800),
    bgColor: Color(0xFFFFE0B2),
    vectorImage: 'assets/vectors/stitch5.png',
    gameMode: GameMode.equalSides,
  ),
];

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
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Match home screen bg
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚖️', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 16),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                          ),
                        ],
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
        color: Color(0xFFE8E8F0), // Match home screen header color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
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
          const Expanded(
            child: Text(
              'Weight Games',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.1,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: Image.asset('assets/vectors/stitch2.png', height: 70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
      itemCount: _variants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => _buildVariantCard(_variants[i], i),
    );
  }

  Widget _buildVariantCard(_VariantInfo info, int index) {
    final level = (_irtLevels[info.code] ?? 1).clamp(1, 5);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 150),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: info.bgColor, // Using the background color from home screen
          borderRadius: BorderRadius.circular(20),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Text and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.emoji, style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(
                          info.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            info.stars,
                            (_) => Icon(Icons.star_rounded, color: info.color, size: 22),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLevelBadge(level, info.color),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vector Image
                  Image.asset(info.vectorImage, width: 140, height: 120, fit: BoxFit.contain),
                ],
              ),
            ),
            // Play Game Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: () => Get.to(
                  () => MagicScaleGameScreen(mode: info.gameMode),
                  transition: Transition.rightToLeft,
                ),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: info.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Play!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, Color color) {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    final idx = (level - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Level $level • ${labels[idx]}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
