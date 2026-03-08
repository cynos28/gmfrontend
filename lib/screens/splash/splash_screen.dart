import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';
import 'package:ganithamithura/screens/onboards/onboarding_screen.dart';
import 'package:ganithamithura/screens/authentication/sign_in_screen.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
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
      // TEMPORARY: Bypass authentication - go directly to HomeScreen
      Get.offAll(() => const HomeScreen());
      
      /* AUTHENTICATION TEMPORARILY DISABLED
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

      // Navigate based on onboarding and login status
      if (!hasSeenOnboarding) {
        // First time user - show onboarding
        Get.offAll(() => const OnboardingScreen());
      } else {
        // Check if user is logged in
        bool isLoggedIn = await AuthService.instance.isLoggedIn();
        if (isLoggedIn) {
          // User is logged in - go to home
          Get.offAll(() => const HomeScreen());
        } else {
          // User not logged in - go to sign in
          Get.offAll(() => const SignInScreen());
        }
      }
      */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
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
