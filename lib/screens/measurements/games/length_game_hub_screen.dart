/// Length Game Hub - Kid-Friendly Redesign
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'length_game_play_screen.dart';

class _VariantInfo {
  final String code;
  final String title;
  final String emoji;
  final int stars;
  final Color color;
  final Color bgColor;
  final String vectorImage;

  const _VariantInfo({
    required this.code,
    required this.title,
    required this.emoji,
    required this.stars,
    required this.color,
    required this.bgColor,
    required this.vectorImage,
  });
}

const List<_VariantInfo> _variants = [
  _VariantInfo(
    code: 'L-V1',
    title: 'Ruler Explorer',
    emoji: '📏',
    stars: 1,
    color: Color(0xFF2196F3), // Blue from home screen
    bgColor: Color(0xFFBBDEFB), // Stronger Light Blue
    vectorImage: 'assets/vectors/stitch2.png',
  ),
  _VariantInfo(
    code: 'L-V4',
    title: 'Build a Bridge',
    emoji: '🌉',
    stars: 2,
    color: Color(0xFF2196F3),
    bgColor: Color(0xFFBBDEFB),
    vectorImage: 'assets/vectors/stitch4.png',
  ),
];

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
    if (mounted) {
      setState(() {
        _currentVariant = 'L-V4';
        _isLoading = false;
      });
    }
  }

  void _play(_VariantInfo info) {
    Get.to(() => LengthGamePlayScreen(variant: info.code), transition: Transition.rightToLeft);
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2196F3), strokeWidth: 3),
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
              'Length Games',
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
              child: Image.asset('assets/vectors/stitch1.png', height: 70),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(info.vectorImage, width: 140, height: 120, fit: BoxFit.contain),
                ],
              ),
            ),
            // Play Game Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: () => _play(info),
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
}
