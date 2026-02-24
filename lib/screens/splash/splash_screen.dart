import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';
import 'package:ganithamithura/screens/onboards/onboarding_screen.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/utils/constants.dart';

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
    // Wait for 3 seconds before navigating
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Check if onboarding has been seen
      bool hasSeenOnboarding = false;
      try {
        hasSeenOnboarding = StorageService.instance.prefs.getBool(
          StorageKeys.hasSeenOnboarding,
        ) ?? false;
      } catch (e) {
        // If storage not initialized yet, assume first time
        debugPrint('Storage not ready, showing onboarding: $e');
      }

      // Navigate to onboarding if not seen, otherwise go to home
      if (hasSeenOnboarding) {
        Get.offAll(() => const HomeScreen());
      } else {
        Get.offAll(() => const OnboardingScreen());
      }
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
