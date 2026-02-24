import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/kids_theme.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';

/// OnboardingScreen - Shown once on first launch to introduce the app and
/// collect the student's grade level.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedGrade = 1;

  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    await UserService.saveGrade(_selectedGrade);
    await UserService.setOnboardingCompleted();
    Get.offAll(() => const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KidsSpacing.screenPadding,
                vertical: KidsSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(AppColors.infoColor)
                              : const Color(AppColors.infoColor)
                                  .withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Skip button (hidden on last page)
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _skipToLast,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(AppColors.infoColor)
                              .withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: [
                  _WelcomePage(),
                  _FeaturesPage(),
                  _GradeSelectionPage(
                    selectedGrade: _selectedGrade,
                    onGradeSelected: (grade) =>
                        setState(() => _selectedGrade = grade),
                  ),
                ],
              ),
            ),

            // Bottom action button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KidsSpacing.screenPadding,
                KidsSpacing.md,
                KidsSpacing.screenPadding,
                KidsSpacing.xxl,
              ),
              child: SizedBox(
                width: double.infinity,
                height: KidsSpacing.minTapTarget + 4,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: KidsComponents.primaryButton(),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Get Started 🚀'
                        : 'Next',
                    style: KidsTypography.button.copyWith(
                      color: Colors.white,
                    ),
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

// ---------------------------------------------------------------------------
// Page 1 – Welcome
// ---------------------------------------------------------------------------
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KidsSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo / hero illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: KidsColors.primaryBackground,
              shape: BoxShape.circle,
              boxShadow: KidsShadows.coloredBlue,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/gmlogo.gif',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: KidsSpacing.xxxl),

          const Text(
            'Welcome to\nGanitha Mithura!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: KidsColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: KidsSpacing.lg),

          Text(
            'Your friendly maths learning companion.\nLearn numbers, shapes & measurements\nthe fun way! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: KidsColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 – Features
// ---------------------------------------------------------------------------
class _FeaturesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(
        emoji: '🔢',
        title: 'Numbers',
        description: 'Trace, read & say numbers 1–10',
        backgroundColor: const Color(AppColors.numberColor),
        borderColor: const Color(AppColors.numberBorder),
      ),
      _FeatureItem(
        emoji: '📐',
        title: 'Measurements',
        description: 'Explore length, area & more with AR',
        backgroundColor: const Color(AppColors.measurementColor),
        borderColor: const Color(AppColors.measurementBorder),
      ),
      _FeatureItem(
        emoji: '🔷',
        title: 'Shapes',
        description: 'Discover 2D & 3D shapes around you',
        backgroundColor: const Color(AppColors.shapeColor),
        borderColor: const Color(AppColors.shapeBorder),
      ),
      _FeatureItem(
        emoji: '➕',
        title: 'Symbols',
        description: 'Learn +, −, × and ÷ with ease',
        backgroundColor: const Color(AppColors.symbolColor),
        borderColor: const Color(AppColors.symbolBorder),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KidsSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What will you\nlearn? 📚',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: KidsColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: KidsSpacing.xl),

          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: KidsSpacing.md),
                child: _buildFeatureRow(f),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KidsSpacing.cardPadding,
        vertical: KidsSpacing.md,
      ),
      decoration: BoxDecoration(
        color: item.backgroundColor,
        borderRadius: BorderRadius.circular(KidsSpacing.radiusMedium),
        border: Border.all(color: item.borderColor, width: 2),
        boxShadow: KidsShadows.soft,
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: KidsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: KidsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KidsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String emoji;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color borderColor;

  const _FeatureItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.borderColor,
  });
}

// ---------------------------------------------------------------------------
// Page 3 – Grade selection
// ---------------------------------------------------------------------------
class _GradeSelectionPage extends StatelessWidget {
  final int selectedGrade;
  final ValueChanged<int> onGradeSelected;

  const _GradeSelectionPage({
    required this.selectedGrade,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KidsSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your\ngrade? 🎓",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: KidsColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: KidsSpacing.md),

          Text(
            'Choose your grade so we can personalise\nyour learning journey.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: KidsColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: KidsSpacing.xxxl),

          // Grade cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: KidsSpacing.cardMarginLarge,
            mainAxisSpacing: KidsSpacing.cardMarginLarge,
            childAspectRatio: 1.6,
            children: List.generate(4, (index) {
              final grade = index + 1;
              final isSelected = selectedGrade == grade;
              return GestureDetector(
                onTap: () => onGradeSelected(grade),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(AppColors.infoColor)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(KidsSpacing.radiusMedium),
                    border: Border.all(
                      color: isSelected
                          ? const Color(AppColors.infoColor)
                          : const Color(AppColors.borderLight),
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? KidsShadows.coloredBlue
                        : KidsShadows.soft,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _gradeEmoji(grade),
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Grade $grade',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : KidsColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _gradeEmoji(int grade) {
    const emojis = ['🌱', '🌿', '🌳', '🌟'];
    return emojis[grade - 1];
  }
}
