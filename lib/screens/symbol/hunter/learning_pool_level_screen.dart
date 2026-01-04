import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ganithamithura/screens/symbol/hunter/symbol_video_list_screen.dart';

class LearningPoolLevelScreen extends StatefulWidget {
  const LearningPoolLevelScreen({super.key});

  @override
  State<LearningPoolLevelScreen> createState() => _LearningPoolLevelScreenState();
}

class _LearningPoolLevelScreenState extends State<LearningPoolLevelScreen> {
  
  @override
  void initState() {
    super.initState();
    // Warmup optimization removed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Background Card
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE0B2), // Light Orange/Peach
                  Color(0xFFF5F5F5), // Fading to White/Grey
                ],
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
                // Custom App Bar
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
                              'Let\'s Learn Symbols Together !',
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

                const SizedBox(height: 20),

                // Orange "Choose Grade" Header Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D), // Light Orange
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Choose the Grade',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                       Text(
                        'want to study',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Grade Cards List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildGradeCard(
                        grade: "01",
                        description: "Learn through the video sets we created for you.",
                        buttonText: "Watch",
                        badgeText: "4/12",
                        color: const Color(0xFF9CCC9C), // Muted Green/Teal
                        imageAsset: 'assets/symbols/leaningCurveGrade.png',
                        onTap: () {
                          // Navigate to video list
                          Get.to(() => const SymbolVideoListScreen(grade: "01"));
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGradeCard(
                        grade: "02",
                        description: "Learn through the video sets we created for you.",
                        buttonText: "Watch",
                        badgeText: "0/12",
                        color: const Color(0xFF9CCC9C), // Muted Green/Teal
                        imageAsset: 'assets/symbols/leaningCurveGrade.png',
                        onTap: () {
                          _showSnackbar("Grade 02", "Coming Soon!");
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGradeCard(
                        grade: "03",
                        description: "Learn through the video sets we created for you.",
                        buttonText: "Watch",
                        badgeText: "0/12",
                        color: const Color(0xFF9CCC9C), // Muted Green/Teal
                        imageAsset: 'assets/symbols/leaningCurveGrade.png',
                        onTap: () {
                           _showSnackbar("Grade 03", "Coming Soon!");
                        },
                      ),
                      const SizedBox(height: 90), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Nav Bar
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

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.black87,
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

  Widget _buildGradeCard({
    required String grade,
    required String description,
    required String buttonText,
    required String badgeText,
    required Color color,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left Content
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 0, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Grade $grade',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
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
                            backgroundColor: const Color(0xFF546E7A), // Blue Grey
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            buttonText,
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
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                       imageAsset,
                       fit: BoxFit.contain,
                       errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image, size: 40, color: Colors.white54)),
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
                color: Color(0xFF1A1F3D), // Dark Navy
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeText,
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
