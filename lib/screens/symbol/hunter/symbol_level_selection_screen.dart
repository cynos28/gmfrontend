import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_learning_screen.dart';
import 'dart:io';

class SymbolLevelSelectionScreen extends StatefulWidget {
  const SymbolLevelSelectionScreen({super.key});

  @override
  State<SymbolLevelSelectionScreen> createState() => _SymbolLevelSelectionScreenState();
}

class _SymbolLevelSelectionScreenState extends State<SymbolLevelSelectionScreen> {
  
  @override
  void initState() {
    super.initState();
    // Warmup optimization removed to prevent excessive API usage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Custom Header Background
          Container(
            height: 280, // Extended height for the big blue header
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Light Blue Gradient
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar content inside the blue area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Symbol Hunter',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Let\'s Learn Symbols Together!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: const AssetImage('assets/images/user_avatar.png'),
                        onBackgroundImageError: (_, __) {},
                        child: const Icon(Icons.person, color: Colors.grey, size: 24),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // "Start from the Beginning" Title
                Text(
                  'Start from the Beginning',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                // List of Cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildLevelCard(
                        level: 1,
                        title: "Level 01",
                        description: "Test your knowledge with questions",
                        isLocked: false,
                        color: const Color(0xFFFFCCBC), // Peach/Pink tone like image
                        imageAsset: 'assets/symbols/levelselection.png', 
                        progress: "1/3",
                        onTap: () {
                          Get.to(() => const SymbolLearningScreen(
                            grade: 1, 
                            level: 1, 
                            sublevel: "Starter"
                          ));
                        },
                      ),
                      const SizedBox(height: 20),
                       _buildLevelCard(
                        level: 2,
                        title: "Level 02",
                        description: "Test your knowledge with questions",
                        isLocked: true,
                        color: const Color(0xFFFFCCBC).withOpacity(0.5), 
                        imageAsset: 'assets/symbols/levelselection.png', // Updated from teacher1.png
                        progress: "2/3",
                        onTap: () {
                          _showLockedSnackbar("Level 02");
                        },
                      ),
                      const SizedBox(height: 20),
                       _buildLevelCard(
                        level: 3,
                        title: "Level 03",
                        description: "Test your knowledge with questions",
                        isLocked: true,
                        color: const Color(0xFFFFCCBC).withOpacity(0.5),
                        imageAsset: 'assets/symbols/levelselection.png', // Updated from teacher1.png
                        progress: "3/3",
                        onTap: () {
                           _showLockedSnackbar("Level 03");
                        },
                      ),
                      const SizedBox(height: 90), // Bottom padding for nav bar space
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Bottom Nav Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildNavItem(Icons.home_outlined, "Home", isActive: false),
                   _buildNavItem(Icons.school, "Learn", isActive: true),
                   _buildNavItem(Icons.show_chart, "Progress", isActive: false),
                   _buildNavItem(Icons.person_outline, "Profile", isActive: false),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  
  void _showLockedSnackbar(String level) {
    Get.snackbar(
      level,
      'Locked!',
      backgroundColor: Colors.grey,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {required bool isActive}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF6200EA) : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(
          color: isActive ? const Color(0xFF6200EA) : Colors.grey, 
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal
        ))
      ],
    );
  }

  Widget _buildLevelCard({
    required int level,
    required String title,
    required String description,
    required bool isLocked,
    required Color color,
    required String imageAsset,
    required String progress,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left Content
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.2
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLocked ? Colors.grey[400] : const Color(0xFF81C784), // Green for start
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            isLocked ? 'Unlock' : 'Start',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right Image Area
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(0), // Removed padding to let image fill
                  child: ClipRRect(
                     borderRadius: const BorderRadius.only(
                       topRight: Radius.circular(30),
                       bottomRight: Radius.circular(30),
                     ),
                     child: Image.asset(
                       imageAsset,
                       fit: BoxFit.cover, 
                       height: double.infinity,
                       errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image, size: 50, color: Colors.white54)),
                     ),
                  ),
                ),
              ),
            ],
          ),

          // Badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E), // Navy Blue
                shape: BoxShape.circle,
              ),
              child: Text(
                progress,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
