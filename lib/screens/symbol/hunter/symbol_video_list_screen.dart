import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ganithamithura/config.dart';
import 'package:ganithamithura/screens/symbol/hunter/symbol_video_player_screen.dart';

class SymbolVideoListScreen extends StatefulWidget {
  final String grade;

  const SymbolVideoListScreen({super.key, required this.grade});

  @override
  State<SymbolVideoListScreen> createState() => _SymbolVideoListScreenState();
}

class _SymbolVideoListScreenState extends State<SymbolVideoListScreen> {
  List<dynamic> videos = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/videos/${widget.grade}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          videos = data['videos'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching videos: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Background Card
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD), // Light Blue/Lavender like the image
                  Color(0xFFF3E5F5), // Fading to lighter tone
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

                const SizedBox(height: 40),

                // "More to Explore" Title
                Text(
                  'More to Explore',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 60),

                // All Videos Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Videos',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink[50], // Light pink background
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'See All',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.pink[300],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Video List
                        Expanded(
                          child: isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : hasError 
                              ? const Center(child: Text("Failed to load videos"))
                              : videos.isEmpty
                                ? const Center(child: Text("No videos found."))
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: videos.length,
                                    itemBuilder: (context, index) {
                                      final video = videos[index];
                                      final colors = [
                                        const Color(0xFF5C6BC0), // Blue
                                        const Color(0xFFFFAB91), // Salmon/Orange
                                        const Color(0xFFD81B60), // Pink/Red
                                        const Color(0xFF4CAF50), // Green
                                      ];
                                      final icons = [
                                        Icons.looks_one_outlined,
                                        Icons.science_outlined,
                                        Icons.music_note,
                                        Icons.games,
                                      ];
                                      
                                      final color = colors[index % colors.length];
                                      final icon = icons[index % icons.length];
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: _buildVideoCard(
                                          title: video['title'] ?? 'Mathematics Lesson',
                                          subtitle: video['subtitle'] ?? 'Video Lesson',
                                          color: color,
                                          icon: icon,
                                          progress: (video['progress'] ?? 0.0).toDouble(),
                                          videoUrl: '${AppConfig.baseUrl}${video['url']}',
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
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

  Widget _buildVideoCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required double progress,
    required String videoUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Get.to(() => SymbolVideoPlayerScreen(videoUrl: videoUrl, title: title));
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),

            // Text Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Arrow Icon
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
