import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_voice_level_selection_screen.dart';

class SymbolVoiceSuccessScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;

  const SymbolVoiceSuccessScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int percentage = ((correctAnswers / totalQuestions) * 100).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.offAll(() => const SymbolVoiceLevelSelectionScreen()), 
        ),
        title: Text(
          'Symbol Hunter',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Image.asset(
                        'assets/symbols/levelselection.png', // Using known working asset
                        height: 220,
                        errorBuilder: (context, error, stackTrace) {
                           return const Icon(Icons.emoji_events, size: 100, color: Color(0xFFFFD700));
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Congratulations!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3F51B5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildStatsRow(totalQuestions, correctAnswers, percentage),
                      const SizedBox(height: 24),
                      _buildMessageCard(percentage),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                             Get.offAll(() => const SymbolVoiceLevelSelectionScreen());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF5350), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text("Swipe to Next", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
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

  Widget _buildStatsRow(int total, int correct, int percentage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC5CAE9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.quiz, "$total", "Quiz"),
            _buildVerticalDivider(),
            _buildStatItem(Icons.check_circle, "$correct", "Correct"),
            _buildVerticalDivider(),
            _buildStatItem(Icons.track_changes, "$percentage%", "Score"),
          ],
        ),
      );
  }

  Widget _buildVerticalDivider() => Container(height: 30, width: 1, color: Colors.black12);

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(children: [
        Icon(icon, size: 24, color: Colors.black87),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
    ]);
  }

  Widget _buildMessageCard(int percentage) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFC5CAE9),
            borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text("You got $percentage% correct!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(percentage >= 80 ? "Amazing work!" : "Keep practicing!", style: GoogleFonts.poppins(color: Colors.indigo)),
          ],
        ),
      );
  }
}
