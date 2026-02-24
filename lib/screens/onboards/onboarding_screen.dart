import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/onboarding_data.dart';
import 'package:ganithamithura/widgets/onboard_page.dart';
import 'package:ganithamithura/screens/onboards/permissions_screen.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/utils/constants.dart';

/// Main onboarding flow screen with PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalOnboardingPages = OnboardingContent.screens.length;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalOnboardingPages - 1) {
      _pageController.nextPage(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPermissions();
    }
  }

  void _skipToEnd() {
    _navigateToPermissions();
  }

  void _navigateToPermissions() {
    Get.to(
      () => PermissionsScreen(
        onComplete: _completeOnboarding,
      ),
      transition: Transition.rightToLeft,
      duration: AppConstants.shortAnimationDuration,
    );
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as seen
    try {
      await StorageService.instance.prefs.setBool(
        StorageKeys.hasSeenOnboarding,
        true,
      );
    } catch (e) {
      // If storage fails, still navigate but log error
      debugPrint('Error saving onboarding status: $e');
    }

    // Navigate to home
    if (mounted) {
      Get.offAll(
        () => const HomeScreen(),
        transition: Transition.fadeIn,
        duration: AppConstants.mediumAnimationDuration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _totalOnboardingPages,
        itemBuilder: (context, index) {
          return OnboardPage(
            data: OnboardingContent.screens[index],
            onSkip: _skipToEnd,
            onNext: _nextPage,
          );
        },
      ),
    );
  }
}
