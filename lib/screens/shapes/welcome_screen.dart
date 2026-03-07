import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/shapes/shape_home_screen.dart';
import 'package:ganithamithura/widgets/shapes/animated_shape_background.dart';
import 'dart:math';

/// WelcomeScreen - Fully Redesigned for a Premium Kid-Friendly Experience
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _floatingController;
  late AnimationController _titleController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Get.back();
      return;
    }
    if (index == _currentNavIndex) return;
    
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA), // Light Cyan
                  Color(0xFFF3E5F5), // Light Purple
                  Color(0xFFFFF9C4), // Light Yellow
                ],
              ),
            ),
          ),

          // 2. Animated Background Shapes
          Positioned.fill(
            child: AnimatedShapeBackground(animation: _floatingController),
          ),

          SafeArea(
            child: Column(
                children: [
                  const SizedBox(height: 80),
                  
                  // 3. Simplified & Clean Kid-Friendly Title
                  _staggeredEntry(
                    index: 0,
                    child: Center(
                      child: Text(
                        'Shapes \n & Patterns',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEC76A0),
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(3, 3),
                              blurRadius: 0,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 4. Hero Character (Centered)
                  _buildHeroCharacter(),

                  const Spacer(),

                  // 5. Deluxe Bouncy Button (Centered)
                  Center(child: _buildDeluxeButton()),
                  
                  const SizedBox(height: 100), // Space for bottom nav
                ],
            ),
          ),

          // 6. Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staggeredEntry({required int index, required Widget child}) {
    final start = index * 0.2;
    final end = start + 0.5;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _titleController, curve: Interval(start, end, curve: Curves.easeIn)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _titleController, curve: Interval(start, end, curve: Curves.elasticOut)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeroCharacter() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final floatOffset = sin(_floatingController.value * 2 * pi) * 15;
        final rotateAngle = sin(_floatingController.value * 2 * pi) * 0.05;
        final scale = 1.0 + sin(_floatingController.value * 2 * pi) * 0.03;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.rotate(
            angle: rotateAngle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Image.asset(
          'assets/images/Shapes/kids8.png',
          height: 320,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildDeluxeButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB199), Color(0xFFFF0844)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0844).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => Get.off(() => const ShapeHomeScreen(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          child: Text(
            'START PLAYING!',
            style: GoogleFonts.bioRhyme(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

