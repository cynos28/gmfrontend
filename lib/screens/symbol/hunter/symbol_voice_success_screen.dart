import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_voice_level_selection_screen.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';

class SymbolVoiceSuccessScreen extends StatefulWidget {
  final int totalQuestions;
  final int correctAnswers;
  final String? userId;
  final int? grade;
  final String? sessionType; // "typing" or "telling"
  final int? level;
  final String? sublevel;

  const SymbolVoiceSuccessScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    this.userId,
    this.grade,
    this.sessionType,
    this.level,
    this.sublevel,
  });

  @override
  State<SymbolVoiceSuccessScreen> createState() => _SymbolVoiceSuccessScreenState();
}

class _SymbolVoiceSuccessScreenState extends State<SymbolVoiceSuccessScreen> {
  Map<String, dynamic>? _prediction;
  bool _isSaving = true;

  @override
  void initState() {
    super.initState();
    _savePerformance();
  }

  Future<void> _savePerformance() async {
    if (widget.userId == null || widget.grade == null || widget.sessionType == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final result = await SymbolService.instance.savePerformance(
        userId: widget.userId!,
        grade: widget.grade!,
        sessionType: widget.sessionType!,
        level: widget.level ?? 1,
        sublevel: widget.sublevel ?? "Starter",
        totalQuestions: widget.totalQuestions,
        correctAnswers: widget.correctAnswers,
      );

      if (mounted) {
        setState(() {
          _prediction = result;
          _isSaving = false;
        });
      }
    } catch (e) {
      print('Error saving performance: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int percentage = ((widget.correctAnswers / widget.totalQuestions) * 100).round();

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
                        'assets/symbols/levelselection.png',
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
                      _buildStatsRow(widget.totalQuestions, widget.correctAnswers, percentage),
                      const SizedBox(height: 24),
                      _buildMessageCard(percentage),
                      const SizedBox(height: 20),

                      // ML Prediction Card
                      if (_isSaving)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 12),
                              Text("Analyzing performance...", style: GoogleFonts.poppins(color: Colors.blue.shade700)),
                            ],
                          ),
                        )
                      else if (_prediction != null)
                        _buildPredictionCard(),

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

  Widget _buildPredictionCard() {
    final predictedLevel = _prediction?['predicted_level'];
    final predictedSublevel = _prediction?['predicted_sublevel'];
    final confidence = _prediction?['confidence'];
    final recommendation = _prediction?['recommendation'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 22),
              const SizedBox(width: 8),
              Text(
                "Performance Insight",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (predictedLevel != null) ...[
            Row(
              children: [
                _buildPredictionChip("Level $predictedLevel", Colors.blue),
                const SizedBox(width: 8),
                if (predictedSublevel != null)
                  _buildPredictionChip(predictedSublevel, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (confidence != null)
            Text(
              "Confidence: ${(confidence * 100).toStringAsFixed(0)}%",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
            ),
          if (recommendation != null) ...[
            const SizedBox(height: 8),
            Text(
              "💡 $recommendation",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.deepPurple.shade600, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: color.shade800,
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
