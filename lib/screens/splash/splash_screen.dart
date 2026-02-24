import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';
import 'package:ganithamithura/screens/onboarding/onboarding_screen.dart';
import 'package:ganithamithura/services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateForward();
  }

  Future<void> _navigateForward() async {
    // Wait for 3 seconds before navigating
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final onboardingDone = await UserService.isOnboardingCompleted();
    if (!mounted) return;

    if (onboardingDone) {
      Get.offAll(() => const HomeScreen());
    } else {
      Get.offAll(() => const OnboardingScreen());
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
