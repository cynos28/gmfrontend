import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/gaming_parallax_background.dart' hide AnimatedBuilder; // Hide to avoid conflict
import 'package:ganithamithura/screens/symbol/gaming/widgets/level_island_widget.dart';
import 'package:ganithamithura/screens/symbol/gaming/balloon_game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> 
    with SingleTickerProviderStateMixin {
  // Simulate level data
  final int totalLevels = 7; // Restored to 7 levels
  final int unlockedLevels = 3;
  
  AnimationController? _playTextController;
  Animation<double>? _playTextBounce;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }
  
  void _initializeAnimation() {
    _playTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Bouncing drop animation (0 to -15 pixels, like falling and bouncing)
    _playTextBounce = Tween<double>(begin: -15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _playTextController!,
        curve: Curves.bounceOut,
      ),
    );
    
    _playTextController!.repeat();
  }
  
  @override
  void dispose() {
    _playTextController?.dispose();
    super.dispose();
  } 

  void _onLevelTap(int level) {
    // Navigate to balloon math game
    Get.to(() => BalloonGameScreen(
      grade: 1,
      level: level,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          const GamingParallaxBackground(
            backgroundImage: 'assets/symbols/gaminBack.png',
            driftDuration: Duration(seconds: 20),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (Brown Circle Home Icon)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D4C41), // Brown
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.home_outlined, color: Colors.white, size: 30),
                          onPressed: () => Get.back(), 
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      
                      // Currency/Score Display (White Pill with Gold Coin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 28), // Gold Coin/Star
                            const SizedBox(width: 8),
                            Text(
                              '2755', // Mock score
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // "Unlock your level" Banner - Custom built to match reference
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8D5BA).withOpacity(0.9), // Sage Green background
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                     children: [
                       // Text Content
                       Positioned(
                         left: 0,
                         right: 0,
                         top: 50, // Moved down from 24 to 50
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             Text(
                               'Unlock your level',
                               style: GoogleFonts.luckiestGuy(
                                 fontSize: 22,
                                 color: const Color(0xFF2E5E4E), // Dark Green text
                               ),
                             ),
                             const SizedBox(height: 18), // Increased spacing
                             _playTextBounce != null
                                 ? AnimatedBuilder(
                                     animation: _playTextBounce!,
                                     builder: (context, child) {
                                       return Transform.translate(
                                         offset: Offset(0, _playTextBounce!.value),
                                         child: Text(
                                           'PLAY',
                                           style: GoogleFonts.luckiestGuy(
                                             fontSize: 60,
                                             color: const Color(0xFF2E5E4E), // Dark Green text
                                             height: 1.0,
                                           ),
                                         ),
                                       );
                                     },
                                   )
                                 : Text(
                                     'PLAY',
                                     style: GoogleFonts.luckiestGuy(
                                       fontSize: 60,
                                       color: const Color(0xFF2E5E4E), // Dark Green text
                                       height: 1.0,
                                     ),
                                   ),
                           ],
                         ),
                       ),
                       
                       // Explosion/Starburst Image (gamingLevel.png)
                       Positioned(
                         right: 0,
                         bottom: 10,
                         child: Image.asset(
                           'assets/symbols/game/gamingLevel.png',
                           width: 140, 
                           height: 140,
                           fit: BoxFit.contain,
                         ),
                       ),
                     ],
                  ),
                ),
                
                // Scrollable Level Path
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // User requested NO scrolling
                    child: SizedBox(
                      height: 850, // Reduced height for compact fit without scrolling
                      child: Stack(
                        children: [
                          // 1 (Bottom Left) -> 2 (Up Right) -> 3 (Right) -> 4 (Up Center) -> 
                          // 5 (Right) -> 6 (Up Right) -> 7 (Far Right Edge)
                          
                          // 1 (Bottom Left) -> 2/3 (Right) -> 4/5 (Left) -> 6/7 (Right) S-curve
                          
                          // Compact "No Scroll" Layout (60px vertical gaps, Level 1 fully visible)
                          _buildLevelIsland(context, 7, 340, 60),  // 7: Top Right (Below Banner)
                          _buildLevelIsland(context, 6, 220, 120), // 6: Below 7, Left
                          _buildLevelIsland(context, 5, 80, 180),  // 5: Far Left
                          _buildLevelIsland(context, 4, 160, 240), // 4: Center
                          _buildLevelIsland(context, 3, 200, 320), // 3: Far Right
                          _buildLevelIsland(context, 2, 110, 380), // 2: Center/Right
                          _buildLevelIsland(context, 1, 10, 430),  // 1: Bottom Left (FULLY VISIBLE)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIsland(BuildContext context, int level, double left, double top) {
     final isLocked = level > unlockedLevels;
     return Positioned(
       left: left,
       top: top,
       child: LevelIslandWidget(
         levelNumber: level,
         isLocked: isLocked,
         isCompleted: level < unlockedLevels,
         onTap: () => _onLevelTap(level),
         size: 125, // Increased size as requested
       ),
     );
  }
}
