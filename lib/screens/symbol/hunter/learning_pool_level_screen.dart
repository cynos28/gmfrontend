import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_learning_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class LearningPoolLevelScreen extends StatefulWidget {
  const LearningPoolLevelScreen({super.key});

  @override
  State<LearningPoolLevelScreen> createState() => _LearningPoolLevelScreenState();
}

class _LearningPoolLevelScreenState extends State<LearningPoolLevelScreen> {
  
  @override
  void initState() {
    super.initState();
    // Start generating questions for Level 1 immediately (Warmup)
    _warmupTutor(grade: 1, level: 1, sublevel: "Starter");
  }

  Future<void> _warmupTutor({required int grade, required int level, required String sublevel}) async {
    try {
      String host;
      if (Platform.isAndroid) {
        // Try logical address first, then emulator
         host = '127.0.0.1'; // Using ADB reverse
      } else {
        host = '127.0.0.1';
      }
      
      final url = Uri.parse('http://$host:8000/warmup-tutor/$grade/$level/$sublevel');
      print("Warming up tutor at $url");
      
      final response = await http.post(url);
      if (response.statusCode == 200) {
        print("Tutor Warmup Successful: ${response.body}");
      } else {
        print("Tutor Warmup Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Warmup Error (safe to ignore): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: const AssetImage('assets/images/user_avatar.png'),
              onBackgroundImageError: (_, __) {},
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Section with Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE), // Light Blue tint like design
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Start from the Beginning',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Level Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          children: [
                            _buildLevelButton(
                              text: 'Level 01',
                              color: const Color(0xFFFFE0E0), // Light Pink
                              textColor: Colors.black87,
                              onTap: () {
                                // User requested no navigation for now
                                 Get.snackbar(
                                  'Level 01',
                                  'Learning Pool Level 1 Selected',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildLevelButton(
                              text: 'Level 02',
                              color: const Color(0xFF90A4AE), // Grey Blue
                              textColor: Colors.black87,
                              onTap: () {
                                 Get.snackbar(
                                  'Level 02',
                                  'Locked!',
                                  backgroundColor: Colors.grey,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildLevelButton(
                              text: 'Level 03',
                              color: const Color(0xFF90A4AE), // Grey Blue
                              textColor: Colors.black87,
                              onTap: () {
                                 Get.snackbar(
                                  'Level 03',
                                  'Locked!',
                                  backgroundColor: Colors.grey,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom Illustration
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Image.asset(
                          'assets/symbols/learningLevel.png', // Using the Learning Pool specific asset
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
