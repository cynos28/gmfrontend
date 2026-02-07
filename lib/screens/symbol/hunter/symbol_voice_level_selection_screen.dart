import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_voice_tutor_screen.dart';

class SymbolVoiceLevelSelectionScreen extends StatefulWidget {
  const SymbolVoiceLevelSelectionScreen({super.key});

  @override
  State<SymbolVoiceLevelSelectionScreen> createState() => _SymbolVoiceLevelSelectionScreenState();
}

class _SymbolVoiceLevelSelectionScreenState extends State<SymbolVoiceLevelSelectionScreen> {
  int _selectedGrade = 1;

  void _showGradeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Grade", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3].map((g) => ListTile(
            title: Text("Grade $g", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            selected: _selectedGrade == g,
            selectedColor: const Color(0xFF6200EA),
            onTap: () {
              setState(() {
                _selectedGrade = g;
              });
              Get.back();
            },
          )).toList(),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Custom Header Background
          Container(
            height: 280, 
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], 
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
                // Custom App Bar content
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
                              'Voice Tutor',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Speak & Learn!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showGradeSelector,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage('assets/images/user_avatar.png'),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, color: Colors.grey, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Title with Grade Selector Indicator
                Column(
                  children: [
                    Text(
                      'Start from the Beginning',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Grade $_selectedGrade Selected',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
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
                        description: "Speak your answers to solve math!",
                        isLocked: false,
                        color: const Color(0xFFFFCCBC), 
                        imageAsset: 'assets/symbols/beging1.png', 
                        progress: "1/3",
                        onTap: () {
                          Get.to(() => SymbolVoiceTutorScreen(
                            grade: _selectedGrade, 
                            level: 1, 
                            sublevel: "Starter"
                          ));
                        },
                      ),
                      const SizedBox(height: 20),
                       _buildLevelCard(
                        level: 2,
                        title: "Level 02",
                        description: "Speak your answers to solve math!",
                        isLocked: false, // Unlocked
                        color: const Color(0xFFFFCCBC).withOpacity(0.5), 
                        imageAsset: 'assets/symbols/beging1.png', 
                        progress: "2/3",
                        onTap: () {
                          Get.to(() => SymbolVoiceTutorScreen(
                            grade: _selectedGrade, 
                            level: 2, 
                            sublevel: "Starter"
                          ));
                        },
                      ),
                      const SizedBox(height: 20),
                       _buildLevelCard(
                        level: 3,
                        title: "Level 03",
                        description: "Speak your answers to solve math!",
                        isLocked: false, // Unlocked
                        color: const Color(0xFFFFCCBC).withOpacity(0.5),
                        imageAsset: 'assets/symbols/beging1.png', 
                        progress: "3/3",
                        onTap: () {
                           Get.to(() => SymbolVoiceTutorScreen(
                            grade: _selectedGrade, 
                            level: 3, 
                            sublevel: "Starter"
                          ));
                        },
                      ),
                      const SizedBox(height: 90), 
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
                  padding: const EdgeInsets.all(0),
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
