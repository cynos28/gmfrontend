import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/widgets/floating_symbols_background.dart';

class SymbolActivityScreen extends StatefulWidget {
  const SymbolActivityScreen({super.key});

  @override
  State<SymbolActivityScreen> createState() => _SymbolActivityScreenState();
}

class _SymbolActivityScreenState extends State<SymbolActivityScreen> {
  List<dynamic> _activityHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = await AuthService.instance.getCurrentUser();
    if (user != null) {
      try {
        final history = await SymbolService.instance.getActivityHistory(user.id);
        if (mounted) {
          setState(() {
            _activityHistory = history;
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
          'My Activities',
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB74D)))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_activityHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No activities yet. Start a lesson to see your history!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activityHistory.length,
      itemBuilder: (context, index) {
        final activity = _activityHistory[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final activityType = activity['activity_type'] as String? ?? 'learning';
    final timestampStr = activity['timestamp'];
    
    DateTime? date;
    if (timestampStr != null) {
      try {
        date = DateTime.parse(timestampStr);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    
    final formattedDate = date != null ? DateFormat('MMM d, yyyy • h:mm a').format(date) : 'Unknown Date';
    
    if (activityType == 'gaming') {
      return _buildGamingCard(activity, formattedDate);
    } else {
      return _buildLearningCard(activity, formattedDate);
    }
  }

  Widget _buildLearningCard(dynamic activity, String formattedDate) {
    final score = activity['score'] ?? 0;
    final sublevel = activity['sublevel'] ?? 'Starter';
    final level = activity['level'] ?? 1;

    IconData icon;
    Color color;
    if (score >= 80) {
      icon = Icons.star_rounded;
      color = Colors.amber;
    } else if (score >= 50) {
      icon = Icons.thumb_up_rounded;
      color = Colors.green;
    } else {
      icon = Icons.psychology_rounded;
      color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning: $sublevel (Lvl $level)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(score as num).toInt()}%',
                style: GoogleFonts.alfaSlabOne(
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(
                'Score',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGamingCard(dynamic activity, String formattedDate) {
    final gameName = activity['game_name'] ?? 'Game';
    final score = activity['score'] ?? 0;
    final level = activity['level'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_esports_rounded, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game: $gameName (Lvl $level)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(score as num).toInt()}',
                style: GoogleFonts.alfaSlabOne(
                  fontSize: 20,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Pts',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
