import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/gaming/config/level_config.dart';
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
  int _selectedTabIndex = 0;

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
      backgroundColor: const Color(0xFFC0DAC6), // Light Background Green
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            color: Color(0xFF9E714F), // Brownish
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                        ),
                      ),
                      // Home Button
                      GestureDetector(
                        onTap: () => Get.offAllNamed('/home'), // Or wherever home is
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: const BoxDecoration(
                            color: Color(0xFF9E714F), // Brownish
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.home_outlined, color: Colors.black, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Main Content Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF86A383), // Darker Sage Green Base Card
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        // Tabs Row Container
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9EBA9D), // Light green container
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTabItem("MY LEAGUE", 0),
                                const SizedBox(width: 8),
                                _buildTabItem("CHAMP LEVELS", 1),
                                const SizedBox(width: 8),
                                _buildTabItem("CHAMPIONS", 2),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Character Stats Card Section
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              // Inner Grey Card
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB1B1B1), // Light Grey Card
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, -2),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 80, bottom: 20),
                                  child: Column(
                                    children: [
                                      // Name Pill Label
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7E977A), // Pill Olive Green
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Hi  $firstName',
                                          style: GoogleFonts.alfaSlabOne(
                                            fontSize: 32,
                                            color: const Color(0xFF0F3124),
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 35),
                                      // Score & Level Stat Indicators
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Level Column
                                          Column(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3C5E3D), // Deep green circle
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 3),
                                                    )
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.settings,
                                                  color: Color(0xFFD49C76), // Bronze-ish gear color
                                                  size: 50,
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                'Level',
                                                style: GoogleFonts.alfaSlabOne(
                                                  fontSize: 22,
                                                  color: const Color(0xFF0F3124),
                                                ),
                                              ),
                                              Text(
                                                '${LevelConfig.getUnlockedLevel(_totalScore)}',
                                                style: GoogleFonts.alfaSlabOne(
                                                  fontSize: 20,
                                                  color: const Color(0xFF0F3124),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Points Column
                                          Column(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3C5E3D), // Deep green circle
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 3),
                                                    )
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.monetization_on, // Placeholder for clover coin
                                                  color: Color(0xFFFFD700), // Gold
                                                  size: 50,
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                'Points',
                                                style: GoogleFonts.alfaSlabOne(
                                                  fontSize: 22,
                                                  color: const Color(0xFF0F3124),
                                                ),
                                              ),
                                              Text(
                                                '$_totalScore',
                                                style: GoogleFonts.alfaSlabOne(
                                                  fontSize: 20,
                                                  color: const Color(0xFF0F3124),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Floating Avatar Over the Grey Card
                              Positioned(
                                top: -65,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(avatarPath),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Play Button Area
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBDD69), Color(0xFFB48332)], // Yellow to gold/brown
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Get.to(() => const GameWelcomeScreen());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Play Game',
                                style: GoogleFonts.alfaSlabOne(
                                  fontSize: 24,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF7A9876), // White if selected, darker green otherwise
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.alfaSlabOne(
            fontSize: 12,
            color: Colors.black, // Uniform black font for all tabs
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
