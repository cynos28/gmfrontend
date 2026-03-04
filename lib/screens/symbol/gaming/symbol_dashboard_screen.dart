import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/gaming/config/level_config.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart';
import 'package:ganithamithura/screens/symbol/gaming/character_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/gaming/game_welcome_screen.dart';

class SymbolDashboardScreen extends StatefulWidget {
  const SymbolDashboardScreen({super.key});

  @override
  State<SymbolDashboardScreen> createState() => _SymbolDashboardScreenState();
}

class _SymbolDashboardScreenState extends State<SymbolDashboardScreen> {
  User? _currentUser;
  bool _isLoadingUser = true;
  String? _characterName;
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      
      if (mounted && user != null) {
        // Fetch leaderboard to get total score
        int score = 0;
        try {
          final leaderboard = await SymbolService.instance.getLeaderboard();
          for (var p in leaderboard) {
            if (p['user_id'] == user.id) {
              score = p['score'] ?? 0;
              break;
            }
          }
        } catch(e) {
          print("Error fetching score: $e");
        }

        setState(() {
          _currentUser = user;
          _totalScore = score;
        });

        // Calculate dynamic level based on score
        final userLevel = LevelConfig.getUnlockedLevel(_totalScore);

        // Fetch character
        final characterName = await SymbolService.instance.getCharacter(user.id);
        if (mounted) {
          setState(() {
            _characterName = characterName;
            _isLoadingUser = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.name ?? 'Player';
    final firstName = userName.split(' ').first;
    final level = _currentUser?.grade ?? 1;
    
    final String avatarPath = (_characterName != null && _characterName!.isNotEmpty)
        ? 'assets/symbols/game/$_characterName.png'
        : 'assets/symbols/game/character1.png';

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
                // Top Header with Back outline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Dashboard Card
                if (_isLoadingUser)
                   const Center(child: CircularProgressIndicator())
                else
                   Container(
                     margin: const EdgeInsets.symmetric(horizontal: 24),
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.9),
                       borderRadius: BorderRadius.circular(30),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 10,
                           offset: const Offset(0, 5),
                         )
                       ],
                       border: Border.all(color: const Color(0xFFC79860), width: 4),
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         // Avatar
                         Container(
                           width: 120,
                           height: 120,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.white,
                             border: Border.all(color: const Color(0xFFC79860), width: 4),
                             image: DecorationImage(
                               image: AssetImage(avatarPath),
                               fit: BoxFit.cover,
                             ),
                           ),
                         ),
                         const SizedBox(height: 20),
                         Text(
                           'Hi, $firstName!',
                           style: GoogleFonts.luckiestGuy(
                             fontSize: 36,
                             color: const Color(0xFF0D251A),
                           ),
                         ),
                         const SizedBox(height: 20),
                         // Stats Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: [
                             // Level
                             Column(
                               children: [
                                 Text(
                                   'Level',
                                   style: GoogleFonts.poppins(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.grey[700],
                                   ),
                                 ),
                                 Text(
                                   '${LevelConfig.getUnlockedLevel(_totalScore)}',
                                   style: GoogleFonts.luckiestGuy(
                                     fontSize: 28,
                                     color: const Color(0xFF4CAF50),
                                   ),
                                 ),
                               ],
                             ),
                             // Points
                             Column(
                               children: [
                                 Text(
                                   'Points',
                                   style: GoogleFonts.poppins(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.grey[700],
                                   ),
                                 ),
                                 Row(
                                   children: [
                                     const Icon(Icons.star, color: Colors.orange, size: 28),
                                     const SizedBox(width: 4),
                                     Text(
                                       '$_totalScore',
                                       style: GoogleFonts.luckiestGuy(
                                         fontSize: 28,
                                         color: const Color(0xFFDAA520),
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),

                   const Spacer(),

                   // Play Button
                   Padding(
                     padding: const EdgeInsets.only(bottom: 60),
                     child: ElevatedButton(
                       onPressed: () {
                         Get.to(() => const GameWelcomeScreen());
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF4CAF50),
                         padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(30),
                         ),
                         elevation: 5,
                       ),
                       child: Text(
                         'PLAY GAME',
                         style: GoogleFonts.luckiestGuy(
                           fontSize: 28,
                           color: Colors.white,
                         ),
                       ),
                     ),
                   ),
              ],
            ),
          ),

          // Left side icons (migrated from Gaming Screen)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 100,
            child: Column(
              children: [
                _buildSideIcon(Icons.volume_up),
                const SizedBox(height: 18),
                _buildSideIcon(Icons.pause),
                const SizedBox(height: 18),
                _buildSideIcon(Icons.settings),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSideIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}
