import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/widgets/floating_symbols_background.dart';

class SymbolPerformanceScreen extends StatefulWidget {
  const SymbolPerformanceScreen({super.key});

  @override
  State<SymbolPerformanceScreen> createState() => _SymbolPerformanceScreenState();
}

class _SymbolPerformanceScreenState extends State<SymbolPerformanceScreen> {
  Map<String, dynamic>? _performanceData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    final user = await AuthService.instance.getCurrentUser();
    if (user != null) {
      try {
        final data = await SymbolService.instance.getPerformanceSummary(user.id);
        if (mounted) {
          setState(() {
            _performanceData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'My Performance',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingSymbolsBackground(),
          ),
          SafeArea(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _performanceData?['summary'];
    if (summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No performance data found. Complete some lessons!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final avgScore = summary['avg_score'] ?? 0;
    final totalAns = summary['total_questions_answered'] ?? 0;
    final correctAns = summary['total_correct'] ?? 0;
    final bestScore = summary['best_score'] ?? 0;
    final totalSessions = summary['total_sessions'] ?? 0;
    final latestPrediction = _performanceData?['latest_prediction'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Keep it up!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF19324B),
            ),
          ),
          const SizedBox(height: 24),

          if (latestPrediction != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7F7FD5).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded, size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated ML Level',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          '${latestPrediction['predicted_sublevel']} (Lvl ${latestPrediction['predicted_level']})',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _buildStatCard('Average Score', '$avgScore%', Icons.stars_rounded, Colors.orange),
          const SizedBox(height: 16),
          _buildStatCard('Best Score', '$bestScore%', Icons.emoji_events_rounded, Colors.amber),
          const SizedBox(height: 16),
          _buildStatCard('Total Questions', '$totalAns', Icons.help_outline_rounded, Colors.purple),
          const SizedBox(height: 16),
          _buildStatCard('Correct Answers', '$correctAns', Icons.check_circle_outline, Colors.green),
          const SizedBox(height: 16),
          _buildStatCard('Total Sessions', '$totalSessions', Icons.videogame_asset_rounded, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
