import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 3 seconds before navigating to home
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Get.offAll(() => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF), // Light purple-blue background
      body: Center(
        child: SizedBox(
          width: 319,
          height: 319,
          child: Image.asset(
            'assets/images/gmlogo.gif',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
