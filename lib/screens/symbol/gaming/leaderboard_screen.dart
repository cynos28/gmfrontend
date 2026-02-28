import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/gaming/symbol_dashboard_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final data = await SymbolService.instance.getLeaderboard();
      if (mounted) {
        setState(() {
          _leaderboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAvatarPath(String? charName) {
    if (charName == null || charName.isEmpty) return 'assets/symbols/game/character1.png';
    // Provide fallback
    return 'assets/symbols/game/$charName.png';
  }

  Widget _buildTopPlayer(dynamic player, int rank, double size) {
    if (player == null) return SizedBox(width: size, height: size);
    
    final charName = player['character_name']?.toString() ?? 'character1';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
            image: DecorationImage(
              image: AssetImage(_getAvatarPath(charName)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$rank',
          style: GoogleFonts.luckiestGuy(
            fontSize: rank == 1 ? 32 : 24,
            color: const Color(0xFF003322),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const GamingParallaxBackground(
            backgroundImage: 'assets/symbols/gaminBack.png',
            parallaxIntensity: 0.015,
            driftDuration: Duration(seconds: 15),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top header bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6447),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                          onPressed: () => Get.offAll(() => const SymbolDashboardScreen()),
                        ),
                      ),
                      
                      // Title Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8BB5A9), Color(0xFF6A9B8D)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Leaderboard',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 28,
                            color: const Color(0xFF001100),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 60), // Balance the row
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_leaderboard.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No scores yet!',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else ...[
                  // Top 3 Players
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // #2
                        Positioned(
                          left: 40,
                          bottom: 20,
                          child: _leaderboard.length > 1 
                            ? _buildTopPlayer(_leaderboard[1], 2, 85)
                            : const SizedBox(width: 85),
                        ),
                        // #3
                        Positioned(
                          right: 40,
                          bottom: 20,
                          child: _leaderboard.length > 2 
                            ? _buildTopPlayer(_leaderboard[2], 3, 85)
                            : const SizedBox(width: 85),
                        ),
                        // #1
                        Positioned(
                          top: 0,
                          child: _leaderboard.isNotEmpty
                            ? _buildTopPlayer(_leaderboard[0], 1, 110)
                            : const SizedBox(height: 110),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // List of players
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF90B48A), // Greenish background
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _leaderboard.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final player = _leaderboard[index];
                          final name = player['name'] ?? 'Player';
                          final score = player['score'] ?? 0;
                          final charName = player['character_name'] ?? 'character1';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB1CDB0), // Lighter green pill
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  backgroundImage: AssetImage(_getAvatarPath(charName)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D251A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$score',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 22,
                                    color: const Color(0xFF0D251A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
