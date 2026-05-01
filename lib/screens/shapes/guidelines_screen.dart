import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ShapeGuidelinesScreen extends StatelessWidget {
  const ShapeGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFF3E5F5),
              Color(0xFFFFF9C4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 20),
                      _buildLevelCard(
                        level: '01',
                        emoji: '🔵',
                        topic: '2D Shapes',
                        topicSinhala: '2D හැඩතල',
                        color: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                        borderColor: const Color(0xFF4CAF50),
                        games: [
                          _GameEntry('🎮', 'Game Level 1', 'Match 2D shapes with names'),
                          _GameEntry('❓', 'Game Level 2', '2D shape quiz questions'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLevelCard(
                        level: '02',
                        emoji: '🟡',
                        topic: '3D Shapes',
                        topicSinhala: '3D හැඩතල',
                        color: const Color(0xFF2196F3),
                        bgColor: const Color(0xFFE3F2FD),
                        borderColor: const Color(0xFF2196F3),
                        games: [
                          _GameEntry('🎮', 'Game Level 3', 'Match 3D shapes with names'),
                          _GameEntry('❓', 'Game Level 4', '3D shape quiz questions'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLevelCard(
                        level: '03',
                        emoji: '🟣',
                        topic: 'Practice & Build',
                        topicSinhala: 'පුහුණු වීම',
                        color: const Color(0xFF9C27B0),
                        bgColor: const Color(0xFFF3E5F5),
                        borderColor: const Color(0xFF9C27B0),
                        games: [
                          _GameEntry('🔢', 'Game Level 5', 'Pattern matching - 2D'),
                          _GameEntry('🔷', 'Game Level 6', 'Pattern matching - 3D'),
                          _GameEntry('🏗️', 'Build & Match', 'Draw and build shapes'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shapes Game',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEC76A0),
                  ),
                ),
                Text(
                  'Guidelines  📖',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFCC80), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Section',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'There are 6 game levels in total.\nComplete them step by step! 🌟',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String level,
    required String emoji,
    required String topic,
    required String topicSinhala,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required List<_GameEntry> games,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Level header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  'Level $level',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Topic label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Icon(Icons.label_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$topic  •  $topicSinhala',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Game entries
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: games.map((g) => _buildGameRow(g, color)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRow(_GameEntry entry, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  entry.subtitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 22),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      ('👀', 'Look carefully at the shape.', 'හැඩතලය හොඳින් බලන්න.'),
      ('👂', 'Read or listen to the shape name.', 'නම කියවන්න හෝ අහන්න.'),
      ('👆', 'Tap the correct answer.', 'නිවැරදි පිළිතුර තෝරන්න.'),
      ('🔄', 'Try again if you make a mistake.', 'වැරදුනොත් නැවත උත්සාහ කරන්න.'),
      ('📶', 'Complete levels step by step.', 'පියවරෙන් පියවර ඉදිරියට යන්න.'),
      ('😄', 'Have fun learning shapes!', 'ප්‍රීතිමත්ව ඉගෙන ගන්න!'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFCC80), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                'Tips for You!',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$2,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          t.$3,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameEntry {
  final String emoji;
  final String title;
  final String subtitle;
  const _GameEntry(this.emoji, this.title, this.subtitle);
}
