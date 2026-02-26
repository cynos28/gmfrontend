/// Onboarding screen data model
class OnboardingData {
  final String title;
  final String imagePath;
  final int backgroundColor;
  final int currentPage;
  final int totalPages;

  OnboardingData({
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
    required this.currentPage,
    required this.totalPages,
  });
}

/// Onboarding screens content
class OnboardingContent {
  static final List<OnboardingData> screens = [
    OnboardingData(
      title: 'Trace it. Say it.\nKnow it!',
      imagePath: 'assets/images/onboard_1.png',
      backgroundColor: 0xFFA6ADED, // Purple/lavender
      currentPage: 0,
      totalPages: 4,
    ),
    OnboardingData(
      title: 'Pick the sign.\nGet it right.',
      imagePath: 'assets/images/onboard_2.png',
      backgroundColor: 0xFF9DD0D0, // Cyan/teal
      currentPage: 1,
      totalPages: 4,
    ),
    OnboardingData(
      title: 'Measure. Mix. Make\nMagic!',
      imagePath: 'assets/images/onboard_3.png',
      backgroundColor: 0xFFFFB3B3, // Pink/coral
      currentPage: 2,
      totalPages: 4,
    ),
    OnboardingData(
      title: 'Spot it. Match it.\nMake it.',
      imagePath: 'assets/images/onboard_4.png',
      backgroundColor: 0xFFFFB3B3, // Pink/coral
      currentPage: 3,
      totalPages: 4,
    ),
  ];
}
