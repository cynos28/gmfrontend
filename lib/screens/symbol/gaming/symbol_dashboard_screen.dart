import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/services/api/symbol_service.dart';
import 'package:ganithamithura/screens/symbol/gaming/config/level_config.dart';
import 'package:ganithamithura/screens/symbol/gaming/game_welcome_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

class SymbolDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool playCongratsSound;

  const SymbolDashboardScreen({
    super.key, 
    this.initialTabIndex = 0,
    this.playCongratsSound = false,
  });

  @override
  State<SymbolDashboardScreen> createState() => _SymbolDashboardScreenState();
}

class _SymbolDashboardScreenState extends State<SymbolDashboardScreen> {
  User? _currentUser;
  bool _isLoadingUser = true;
  String? _characterName;
  int _totalScore = 0;
  int _selectedTabIndex = 0;
  List<dynamic> _leaderboard = [];
  bool _soundEffectsEnabled = true;
  double _audioVolume = 0.7;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _loadAudioSettings();
    _loadData();
    if (widget.initialTabIndex == 2 && widget.playCongratsSound) {
       _confettiController.play();
    }
  }

  Future<void> _loadAudioSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEffectsEnabled = prefs.getBool('audio_enabled') ?? true;
        _audioVolume = prefs.getDouble('audio_volume') ?? 0.7;
      });
      if (widget.playCongratsSound && _soundEffectsEnabled) {
        _audioPlayer.setVolume(_audioVolume);
        _audioPlayer.play(AssetSource('symbols/sounds/congratulations.mp3.mpeg'));
      }
    }
  }

  Future<void> _saveAudioEnabled(bool val) async {
    setState(() => _soundEffectsEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', val);
  }

  Future<void> _saveAudioVolume(double val) async {
    setState(() => _audioVolume = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_volume', val);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      
      if (mounted && user != null) {
        int score = 0;
        List<dynamic> fetchedLeaderboard = [];
        try {
          fetchedLeaderboard = await SymbolService.instance.getLeaderboard();
          for (var p in fetchedLeaderboard) {
            if (p['user_id'] == user.id) {
              score = p['score'] ?? 0;
              break;
            }
          }
        } catch(e) {
          // Ignore
        }

        if (mounted) {
          setState(() {
            _currentUser = user;
            _totalScore = score;
            _leaderboard = fetchedLeaderboard;
          });
        }

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

  String _getAvatarPath(String? charName) {
    if (charName == null || charName.isEmpty) return 'assets/symbols/game/character1.png';
    return 'assets/symbols/game/$charName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC0DAC6),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/symbols/gaminBack.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
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
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8), // White matching welcome screen
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 2.0), // Optical centering
                          child: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 24),
                        ),
                      ),
                    ),
                    
                    // Conditionally show score pill in the middle if NOT My League Tab
                    if (_selectedTabIndex != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/symbols/game/pointsIcon.png', width: 24, height: 24),
                            const SizedBox(width: 8),
                            Text(
                              '$_totalScore',
                              style: GoogleFonts.alfaSlabOne(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    else 
                      const SizedBox(width: 45), // Balance the flex space when score not showing
                    
                    // Home Button
                    GestureDetector(
                      onTap: () => Get.offAllNamed('/home'), 
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
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Tabs Row Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9EBA9D), // Light green container
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTabItem("MY LEAGUE", 0)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildTabItem("CHAMP LEVELS", 1)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildTabItem("CHAMPIONS", 2)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Build the correct tab body
                      Expanded(
                        child: _isLoadingUser 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : _buildCurrentTabContent(),
                      ),
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

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMyLeagueTab();
      case 1:
        return _buildChampLevelsTab();
      case 2:
        return _buildChampionsTab();
      default:
        return _buildMyLeagueTab();
    }
  }

  // ============== TAB 0: MY LEAGUE ==============
  Widget _buildMyLeagueTab() {
    final userName = _currentUser?.name ?? 'Player';
    final firstName = userName.split(' ').first;
    final String avatarPath = _getAvatarPath(_characterName);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60), // Top padding for floating avatar!
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                    // Inner Grey Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB1B1B1), 
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
                        padding: const EdgeInsets.only(top: 60, bottom: 15),
                        child: Column(
                          children: [
                            // Name Pill Label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E977A), 
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Hi  $firstName',
                                style: GoogleFonts.alfaSlabOne(
                                  fontSize: 26,
                                  color: const Color(0xFF0F3124),
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            // Score & Level Stat Indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Level Column
                                Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3C5E3D), 
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset('assets/symbols/game/settingsIcon.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Level',
                                      style: GoogleFonts.alfaSlabOne(
                                        fontSize: 18,
                                        color: const Color(0xFF0F3124),
                                      ),
                                    ),
                                    Text(
                                      '${LevelConfig.getUnlockedLevel(_totalScore)}',
                                      style: GoogleFonts.alfaSlabOne(
                                        fontSize: 16,
                                        color: const Color(0xFF0F3124),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Points Column
                                Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3C5E3D), 
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset('assets/symbols/game/pointsIcon.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Points',
                                      style: GoogleFonts.alfaSlabOne(
                                        fontSize: 18,
                                        color: const Color(0xFF0F3124),
                                      ),
                                    ),
                                    Text(
                                      '$_totalScore',
                                      style: GoogleFonts.alfaSlabOne(
                                        fontSize: 16,
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
                  top: -55,
                  child: Container(
                    width: 110,
                    height: 110,
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
                
                const SizedBox(height: 15),
                
                // Audio Settings Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F746E), // Dark grayish olive match
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Audio Settings',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sound Effects',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Switch(
                            value: _soundEffectsEnabled,
                            onChanged: _saveAudioEnabled,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFFB1B1B1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF1E3321),
                          inactiveTrackColor: const Color(0xFF1E3321),
                          trackHeight: 12.0,
                          thumbColor: const Color(0xFFFFD700), // Gold thumb
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                          overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                        ),
                        child: Slider(
                          value: _audioVolume,
                          onChanged: _saveAudioVolume,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Play Button Area
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFFFBDD69), Color(0xFFB48332)], 
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
    );
  }

  // ============== TAB 1: CHAMP LEVELS ==============
  Widget _buildChampLevelsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Wrap(
          spacing: 15,
          runSpacing: 35, // More space for the top floating icon
          alignment: WrapAlignment.center,
          children: [
            _buildLevelCard("1", "Symbol Start", "100"),
            _buildLevelCard("2", "Sign Seeker", "100"),
            _buildLevelCard("3", "Logic Link", "100"),
            _buildLevelCard("4", "Operation Quest", "100"),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(String number, String title, String points) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 75) / 2, // 2 columns roughly
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Dark Green Card
          Container(
            padding: const EdgeInsets.only(top: 35, bottom: 15, left: 10, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3321), // Dark Green
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "$number\n$title",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alfaSlabOne(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Grey details box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA5B2A1), // subtle grey/green
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Star Bonus Rewards",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E8669),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              points,
                              style: GoogleFonts.alfaSlabOne(fontSize: 10, color: Colors.white),
                            ),
                            const SizedBox(width: 5),
                            Image.asset('assets/symbols/game/pointsIcon.png', width: 12, height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Required Rewards",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E8669),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              points,
                              style: GoogleFonts.alfaSlabOne(fontSize: 10, color: Colors.white),
                            ),
                            const SizedBox(width: 5),
                            Image.asset('assets/symbols/game/pointsIcon.png', width: 12, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Hover gear/settings icon at the top
          Positioned(
            top: -20,
            child: Image.asset(
              'assets/symbols/game/settingsIcon.png',
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  // ============== TAB 2: CHAMPIONS ==============
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
          style: GoogleFonts.alfaSlabOne(
            fontSize: rank == 1 ? 32 : 24,
            color: const Color(0xFF003322),
          ),
        ),
      ],
    );
  }

  Widget _buildChampionsTab() {
    if (_leaderboard.isEmpty) {
       return Center(
         child: Text(
           'No scores yet!',
           style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
         ),
       );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Top 3 Players Podium
            SizedBox(
              height: 160,
              child: Stack(
            alignment: Alignment.center,
            children: [
              // #2
              Positioned(
                left: 10,
                bottom: 0,
                child: _leaderboard.length > 1 
                  ? _buildTopPlayer(_leaderboard[1], 2, 75)
                  : const SizedBox(width: 75),
              ),
              // #3
              Positioned(
                right: 10,
                bottom: 0,
                child: _leaderboard.length > 2 
                  ? _buildTopPlayer(_leaderboard[2], 3, 75)
                  : const SizedBox(width: 75),
              ),
              // #1
              Positioned(
                top: 0,
                child: _leaderboard.isNotEmpty
                  ? _buildTopPlayer(_leaderboard[0], 1, 95)
                  : const SizedBox(height: 95),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // List of players
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF90B48A), // Thinner green background for list
              borderRadius: BorderRadius.circular(30),
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB1CDB0), // Lighter green pill
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(_getAvatarPath(charName)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.alfaSlabOne(
                            fontSize: 14,
                            color: const Color(0xFF0D251A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$score',
                        style: GoogleFonts.alfaSlabOne(
                          fontSize: 16,
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
        
        // Bottom Play Again Button
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFFFBDD69), Color(0xFFB48332)], 
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
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Play Again',
                style: GoogleFonts.alfaSlabOne(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    
    // Confetti layer
    Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        createParticlePath: drawStar,
      ),
    ),
  ],
);
}

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * math.cos(step),
          halfWidth + externalRadius * math.sin(step));
      path.lineTo(halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
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
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF7A9876), 
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
          maxLines: 1,
          textAlign: TextAlign.center,
          style: GoogleFonts.alfaSlabOne(
            fontSize: 10,
            color: Colors.black, // Uniform black font for all tabs
          ),
        ),
      ),
    );
  }
}
