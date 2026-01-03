import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';

/// SymbolHomeScreen - Child-friendly screen with dynamic background
class SymbolHomeScreen extends StatelessWidget {
  const SymbolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Very light pink background
      body: Stack(
        children: [
          // 1. Dynamic Background with Random Symbols
          const FloatingSymbolsBackground(),
          
          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(AppColors.symbolIcon)),
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      const Text(
                        'Symbol World',
                        style: TextStyle(
                          fontFamily: 'Fredoka', // Assuming a playful font is available, or falls back
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(AppColors.symbolIcon),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Image / Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(AppColors.symbolColor).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 80,
                              color: Color(AppColors.symbolIcon),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        const Text(
                          'Let\'s Play with Symbols!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(AppColors.textBlack),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Discover the magic of math ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Big Action Cards
                        _buildActionCard(
                          title: 'Symbol Stories',
                          subtitle: 'Read fun stories about +, −, ×, ÷',
                          icon: Icons.menu_book,
                          color: const Color(0xFFFFB7B2), // Soft Red
                          accentColor: const Color(0xFFFF6B6B),
                          onTap: () => _showComingSoon('Stories'),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildActionCard(
                          title: 'Symbol Quiz',
                          subtitle: 'Test your superpowers!',
                          icon: Icons.psychology,
                          color: const Color(0xFFA0E7E5), // Soft Teal/Green
                          accentColor: const Color(0xFF2EB872),
                          onTap: () => _showComingSoon('Quiz'),
                        ),
                      ],
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

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300]),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon 🚀',
      '$feature are being built right now!',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

class FloatingSymbolsBackground extends StatefulWidget {
  const FloatingSymbolsBackground({super.key});

  @override
  State<FloatingSymbolsBackground> createState() => _FloatingSymbolsBackgroundState();
}

class _FloatingSymbolsBackgroundState extends State<FloatingSymbolsBackground>
    with SingleTickerProviderStateMixin {
  final List<FloatingSymbolData> _symbols = [];
  final Random _random = Random();
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    // Generate 15 random symbols (Reduced count for performance)
    for (int i = 0; i < 15; i++) {
      _symbols.add(_generateSymbolData());
    }
    
    // Use Ticker for continuous monotonic time (no loop reset jumps)
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0; // Time in seconds
      });
    });
    _ticker.start();
  }

  FloatingSymbolData _generateSymbolData() {
    final symbols = ['+', '−', '×', '÷', '=', '?', '%'];
    final colors = [
      const Color(AppColors.measurementIcon), // Orange
      const Color(AppColors.numberIcon),      // Purple
      const Color(AppColors.shapeIcon),       // Green
      const Color(AppColors.symbolIcon),      // Rose
      const Color(0xFF2196F3),               // Blue (Info)
      const Color(0xFFFFC107),               // Amber (Warning)
    ];
    
    return FloatingSymbolData(
      symbol: symbols[_random.nextInt(symbols.length)],
      color: colors[_random.nextInt(colors.length)], // Random color
      size: 20.0 + _random.nextInt(40),
      initialX: _random.nextDouble(),
      initialY: _random.nextDouble(),
      speed: 0.05 + _random.nextDouble() * 0.10,
      swayAmount: 0.02 + _random.nextDouble() * 0.05,
      swaySpeed: 1.0 + _random.nextDouble() * 2.0,
      opacity: 0.3 + _random.nextDouble() * 0.3, // Increased opacity for better visibility of colors
      rotationSpeed: (_random.nextBool() ? 1 : -1) * (0.1 + _random.nextDouble() * 0.2),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ticker.isActive) return const SizedBox.shrink();

    return Stack(
      children: _symbols.map((data) {
        // Continuous upward movement
        // Position = initial - (speed * time)
        // Modulo 1.0 wraps it around the screen continuously
        double currentY = (data.initialY - _time * data.speed) % 1.0;
        if (currentY < 0) currentY += 1.0;

        // Horizontal sway
        double currentX = (data.initialX + 
            math.sin((_time * pi * data.swaySpeed) + (data.initialY * 10)) * 
            data.swayAmount);
            
        // Rotation
        double rotation = _time * pi * data.rotationSpeed;

        return Positioned(
          top: currentY * MediaQuery.of(context).size.height,
          left: currentX * MediaQuery.of(context).size.width,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: data.opacity,
              child: Text(
                data.symbol,
                style: TextStyle(
                  fontSize: data.size,
                  fontWeight: FontWeight.w900,
                  color: data.color, // Use the random color
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FloatingSymbolData {
  final String symbol;
  final Color color; // New property
  final double size;
  final double initialX;
  final double initialY;
  final double speed;
  final double swayAmount;
  final double swaySpeed;
  final double opacity;
  final double rotationSpeed;

  FloatingSymbolData({
    required this.symbol,
    required this.color, // New required parameter
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.swayAmount,
    required this.swaySpeed,
    required this.opacity,
    required this.rotationSpeed,
  });
}
