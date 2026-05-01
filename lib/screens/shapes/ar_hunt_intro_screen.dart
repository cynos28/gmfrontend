import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ar_hunt_game_screen.dart';

class ArHuntIntroScreen extends StatelessWidget {
  const ArHuntIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'AR Hunt',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AR Hero Image/Icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(seconds: 1),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) => Transform.scale(scale: value, child: child),
                        child: Container(
                          width: 280,
                          height: 380,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF1AD7F), Color(0xFFFFD5B4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF1AD7F).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/Shapes/kids6.png',
                              fit: BoxFit.contain,
                              height: 300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Title
                      const Text(
                        'Shape Magic',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      const Text(
                        'Put your hand in front of the camera and see magic shapes! 🪄',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Let's Play button
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const ArHuntGameScreen(), transition: Transition.fadeIn);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1AD7F),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF1AD7F).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              SizedBox(width: 8),
                              Text(
                                'Let\'s Play',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
