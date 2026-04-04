import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/ui_helpers.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/widgets/test/question_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ganithamithura/screens/number/widgets/floating_numbers_background.dart';

/// ProgressTestScreen - Hub for placement quiz and difficulty-level tests
/// Flow: Hub → (optional placement quiz) → Beginner/Intermediate/Advanced tests
/// Passing each test progressively unlocks the next difficulty level.
class ProgressTestScreen extends StatefulWidget {
  const ProgressTestScreen({super.key});

  @override
  State<ProgressTestScreen> createState() => _ProgressTestScreenState();
}

enum _ScreenView { hub, loading, intro, testing, evaluating, results }

class _ProgressTestScreenState extends State<ProgressTestScreen>
    with TickerProviderStateMixin {
  final _apiService = NumApiService.instance;
  final _storageService = StorageService.instance;

  // Current view state
  _ScreenView _currentView = _ScreenView.hub;

  // Unlock state
  bool _placementDone = false;
  bool _beginnerUnlocked = true;
  bool _intermediateUnlocked = false;
  bool _advancedUnlocked = false;
  String _currentLevel = 'beginner';

  // Test session state
  String _activeTestType = ''; // placement, beginner, intermediate, advanced
  ProgressTestResponse? _testData;
  int _currentQuestionIndex = 0;
  final Map<String, bool> _results = {};
  final List<Map<String, dynamic>> _answers = [];
  ProgressTestEvaluation? _evaluation;

  // Answer feedback state
  bool _showingFeedback = false;
  int _feedbackCountdown = 3;
  Timer? _feedbackTimer;

  late AnimationController _progressAnimController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _loadUnlockState();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  /// Load saved unlock state from local storage
  Future<void> _loadUnlockState() async {
    final completed =
        await _storageService.getProgressValue('progress_test_completed');
    final difficulty =
        await _storageService.getProgressValue('progress_test_difficulty');

    if (mounted) {
      setState(() {
        _placementDone = completed == true;
        if (difficulty != null) {
          _currentLevel = difficulty as String;
          _beginnerUnlocked = true;
          _intermediateUnlocked =
              _currentLevel == 'intermediate' || _currentLevel == 'advanced';
          _advancedUnlocked = _currentLevel == 'advanced';
        }
      });
    }
  }

  /// Start a test of the given type
  Future<void> _startTest(String testType) async {
    setState(() {
      _activeTestType = testType;
      _currentView = _ScreenView.loading;
      _testData = null;
      _currentQuestionIndex = 0;
      _results.clear();
      _answers.clear();
      _evaluation = null;
    });

    try {
      // For placement use 'progress' endpoint, otherwise use the testType directly
      final endpoint = testType == 'placement' ? 'progress' : testType;
      final data = await _apiService.getTestQuestions(endpoint).timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection.');
        },
      );

      if (!mounted) return;

      setState(() {
        _testData = data;
        _currentView = _ScreenView.intro;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMessage = UIHelpers.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(AppColors.errorColor),
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _currentView = _ScreenView.hub;
      });
    }
  }

  void _onQuestionAnswered(String questionId, bool isCorrect, dynamic answer) {
    setState(() {
      _results[questionId] = isCorrect;
      _answers.add({
        'question_id': questionId,
        'is_correct': isCorrect,
        'answer': answer?.toString(),
      });
      _showingFeedback = true;
      _feedbackCountdown = 3;
    });

    // Start countdown timer
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _feedbackCountdown--;
      });

      if (_feedbackCountdown <= 0) {
        timer.cancel();
        _moveToNextQuestion();
      }
    });
  }

  void _moveToNextQuestion() {
    _feedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _currentQuestionIndex++;
      _showingFeedback = false;
      _feedbackCountdown = 3;
    });
    _progressAnimController.forward(from: 0);
  }

  Future<void> _evaluateTest() async {
    setState(() => _currentView = _ScreenView.evaluating);

    final correctCount = _results.values.where((v) => v).length;
    final evalTestType =
        _activeTestType == 'placement' ? 'placement' : _activeTestType;

    try {
      final evaluation = await _apiService.evaluateTest(
        testType: evalTestType,
        score: correctCount,
        totalQuestions: _testData!.totalQuestions,
        answers: _answers,
      );

      // Save to local storage
      final testResult = TestResult(
        testType: _activeTestType,
        totalQuestions: _testData!.totalQuestions,
        correctAnswers: correctCount,
        completedAt: DateTime.now(),
        activityIds: _testData!.questions.map((q) => q.id).toList(),
        activityResults: _results,
        difficultyLevel: evaluation.difficultyLevel,
        unlockedLevels: evaluation.unlockedLevels,
      );

      await _storageService.saveTestResult(testResult);

      for (final level in evaluation.unlockedLevels) {
        await _storageService.unlockLevel(level);
      }

      await _storageService.saveProgressData(
        'progress_test_difficulty',
        evaluation.difficultyLevel,
      );
      await _storageService.saveProgressData('progress_test_completed', true);

      if (!mounted) return;

      setState(() {
        _evaluation = evaluation;
        _currentView = _ScreenView.results;
        // Update unlock state
        _placementDone = true;
        _currentLevel = evaluation.difficultyLevel;
        _beginnerUnlocked = true;
        _intermediateUnlocked = evaluation.unlockedLevels.length >= 2;
        _advancedUnlocked = evaluation.unlockedLevels.length >= 3;
      });
    } catch (e) {
      if (!mounted) return;

      // Fallback: local evaluation
      _fallbackEvaluate(correctCount);
    }
  }

  void _fallbackEvaluate(int correctCount) {
    final total = _testData!.totalQuestions;
    String difficultyLevel;
    List<int> unlockedLevels;
    String message;

    if (_activeTestType == 'placement') {
      if (correctCount >= 5) {
        difficultyLevel = 'advanced';
        unlockedLevels = [1, 2, 3];
        message = 'Excellent! All difficulty levels are unlocked!';
      } else if (correctCount >= 3) {
        difficultyLevel = 'intermediate';
        unlockedLevels = [1, 2];
        message = 'Good job! Beginner and Intermediate are unlocked!';
      } else {
        difficultyLevel = 'beginner';
        unlockedLevels = [1];
        message = "Let's start from the basics! Beginner level is ready.";
      }
    } else if (_activeTestType == 'beginner') {
      if (correctCount >= 5) {
        difficultyLevel = 'intermediate';
        unlockedLevels = [1, 2];
        message = "Great work! You've unlocked Intermediate level!";
      } else {
        difficultyLevel = 'beginner';
        unlockedLevels = [1];
        message = 'Keep practicing! Try again to unlock Intermediate.';
      }
    } else if (_activeTestType == 'intermediate') {
      if (correctCount >= 6) {
        difficultyLevel = 'advanced';
        unlockedLevels = [1, 2, 3];
        message = "Amazing! You've unlocked Advanced level!";
      } else {
        difficultyLevel = 'intermediate';
        unlockedLevels = [1, 2];
        message = 'Good effort! Practice more to unlock Advanced.';
      }
    } else {
      difficultyLevel = 'advanced';
      unlockedLevels = [1, 2, 3];
      message = correctCount >= 7
          ? "Outstanding! You've mastered all levels!"
          : 'Great attempt! Keep practicing the advanced topics.';
    }

    _storageService.saveProgressData(
      'progress_test_difficulty',
      difficultyLevel,
    );
    _storageService.saveProgressData('progress_test_completed', true);

    final testResult = TestResult(
      testType: _activeTestType,
      totalQuestions: total,
      correctAnswers: correctCount,
      completedAt: DateTime.now(),
      activityIds: _testData!.questions.map((q) => q.id).toList(),
      activityResults: _results,
      difficultyLevel: difficultyLevel,
      unlockedLevels: unlockedLevels,
    );
    _storageService.saveTestResult(testResult);

    for (final level in unlockedLevels) {
      _storageService.unlockLevel(level);
    }

    setState(() {
      _evaluation = ProgressTestEvaluation(
        score: correctCount,
        total: total,
        percentage: (correctCount / total) * 100,
        difficultyLevel: difficultyLevel,
        unlockedLevels: unlockedLevels,
        message: message,
        testType: _activeTestType,
      );
      _currentView = _ScreenView.results;
      _placementDone = true;
      _currentLevel = difficultyLevel;
      _beginnerUnlocked = true;
      _intermediateUnlocked = unlockedLevels.length >= 2;
      _advancedUnlocked = unlockedLevels.length >= 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case _ScreenView.hub:
        return _buildHub();
      case _ScreenView.loading:
        return _buildLoading();
      case _ScreenView.intro:
        return _buildIntro();
      case _ScreenView.testing:
        return _buildQuestion();
      case _ScreenView.evaluating:
        return _buildEvaluating();
      case _ScreenView.results:
        return _buildResults();
    }
  }

  // ==================== HUB VIEW ====================

  Widget _buildHub() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 20, color: Colors.black54),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Activity Hub',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Let's Test Your Knowledge Together!",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/number/teacher_avatar.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Color(0xFF7C6FDD),
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quiz Card with pulse animation
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                  child: _buildQuizCard(),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Difficulty Level Cards with staggered animation
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _AnimatedTestCard(
                                    delay: 100,
                                    child: _buildDifficultyLevelCard(
                                      title: 'Beginner',
                                      subtitle: 'Number basics',
                                      backgroundColor: const Color(0xFFB9E6D3),
                                      isUnlocked: _beginnerUnlocked,
                                      progress: '1/3',
                                      onTap: () => _startTest('beginner'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _AnimatedTestCard(
                                    delay: 200,
                                    child: _buildDifficultyLevelCard(
                                      title: 'Intermediate',
                                      subtitle: 'Matching, patterns, counting',
                                      backgroundColor: const Color(0xFFFFCC80),
                                      isUnlocked: _intermediateUnlocked,
                                      progress: '2/3',
                                      onTap: () => _startTest('intermediate'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _AnimatedTestCard(
                                    delay: 300,
                                    child: _buildDifficultyLevelCard(
                                      title: 'Advanced',
                                      subtitle: 'Word problems, estimation',
                                      backgroundColor: const Color(0xFFEF9A9A),
                                      isUnlocked: _advancedUnlocked,
                                      progress: '3/3',
                                      onTap: () => _startTest('advanced'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
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

  Widget _buildQuizCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6FDD), Color(0xFF5F52C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6FDD).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startTest('placement'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _placementDone
                            ? 'Retake Placement Quiz'
                            : 'Placement Quiz',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '5 Quick questions to determine\nyour starting level',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyLevelCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required bool isUnlocked,
    required String progress,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isUnlocked ? onTap : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUnlocked
                              ? const Color(0xFFFFFFFF)
                              : Colors.white.withOpacity(0.5),
                          foregroundColor:
                              isUnlocked ? backgroundColor : Colors.black54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: isUnlocked ? 4 : 0,
                          shadowColor: isUnlocked
                              ? backgroundColor.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                        child: Text(
                          isUnlocked ? 'Start' : 'Unlock',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/number/difficulty_illustration.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.white.withOpacity(0.8),
                        size: 50,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                progress,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LOADING VIEW ====================

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          const Center(
            child: LoadingOverlay(message: 'Preparing your test...'),
          ),
        ],
      ),
    );
  }

  // ==================== INTRO VIEW ====================

  Widget _buildIntro() {
    final testLabel = _getTestLabel(_activeTestType);
    final testColor = _getTestColor(_activeTestType);
    final testColorDark = _getTestColorDark(_activeTestType);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => _currentView = _ScreenView.hub),
                        icon: const Icon(Icons.close,
                            size: 22, color: Colors.black54),
                      ),
                      Expanded(
                        child: Text(
                          testLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        // Hero banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 36, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [testColor, testColorDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: testColor.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTestIcon(_activeTestType),
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                testLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getTestDescription(_activeTestType),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'What to Expect',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                Icons.numbers_rounded,
                                '${_testData!.totalQuestions} Questions',
                                testColor,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.timer_off_rounded,
                                  'No time limit', testColor),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.category_rounded,
                                  'Different question types', testColor),
                              if (_testData!.passingScore != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.check_circle_outline_rounded,
                                  'Pass: ${_testData!.passingScore}/${_testData!.totalQuestions} correct',
                                  testColor,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Start button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(
                                  () => _currentView = _ScreenView.testing);
                            },
                            icon:
                                const Icon(Icons.play_arrow_rounded, size: 24),
                            label: Text(
                              'Start Test',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: testColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              shadowColor: testColor.withOpacity(0.4),
                            ),
                          ),
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

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // ==================== QUESTION VIEW ====================

  Widget _buildQuestion() {
    // Check if all questions answered
    if (_currentQuestionIndex >= _testData!.questions.length) {
      if (_currentView != _ScreenView.evaluating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _evaluateTest();
        });
      }
      return _buildEvaluating();
    }

    final question = _testData!.questions[_currentQuestionIndex];
    final totalQ = _testData!.questions.length;
    final progress = _currentQuestionIndex / totalQ;
    final testColor = _getTestColor(_activeTestType);
    final testColorDark = _getTestColorDark(_activeTestType);
    final correctCount = _results.values.where((v) => v).length;
    final isCorrectAnswer = _results[question.id] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Custom gradient header ──
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [testColor, testColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: testColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Question counter pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Q ${_currentQuestionIndex + 1} / $totalQ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(question.type),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _getTypeLabel(question.type),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Score pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '$correctCount correct',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedBuilder(
                          animation: _progressAnimController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Question content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        _buildQuestionWidget(question),

                        // ── Polished feedback overlay ──
                        if (_showingFeedback)
                          Container(
                            decoration: BoxDecoration(
                              color: (isCorrectAnswer
                                      ? const Color(0xFF388E3C)
                                      : const Color(0xFFD32F2F))
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.all(28),
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isCorrectAnswer
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(0.25),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: (isCorrectAnswer
                                              ? Colors.green
                                              : Colors.red)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: (isCorrectAnswer
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCorrectAnswer
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: isCorrectAnswer
                                              ? Colors.green
                                              : Colors.red,
                                          size: 64,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isCorrectAnswer
                                            ? '🎉 Correct!'
                                            : 'Not quite!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: isCorrectAnswer
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isCorrectAnswer
                                            ? 'Keep up the great work!'
                                            : 'Better luck next time!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Countdown indicator
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.timer_rounded,
                                            size: 18,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Next in $_feedbackCountdown...',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _moveToNextQuestion,
                                          icon: const Icon(
                                              Icons.arrow_forward_rounded),
                                          label: Text(
                                            'Next Question',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: testColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                            shadowColor:
                                                testColor.withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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

  Widget _buildQuestionWidget(ProgressTestQuestion question) {
    switch (question.type) {
      case 'matching':
        return MatchingQuestionWidget(
          key: ValueKey('matching_${question.id}'),
          question: question,
          onAnswered: (isCorrect) =>
              _onQuestionAnswered(question.id, isCorrect, null),
        );
      case 'drag_drop_order':
        return DragDropOrderWidget(
          key: ValueKey('drag_order_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'drag_drop_count':
        return DragDropCountWidget(
          key: ValueKey('drag_count_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'image_counting':
        return ImageCountingWidget(
          key: ValueKey('image_count_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'pattern_fill':
        return PatternFillWidget(
          key: ValueKey('pattern_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'trace':
        return TraceQuestionWidget(
          key: ValueKey('trace_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'say':
        return SayQuestionWidget(
          key: ValueKey('say_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'show':
      case 'object_detection':
        return ObjectDetectionQuestionWidget(
          key: ValueKey('obj_detect_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
      case 'select':
      default:
        return SelectQuestionWidget(
          key: ValueKey('select_${question.id}'),
          question: question,
          onAnswered: (isCorrect, answer) =>
              _onQuestionAnswered(question.id, isCorrect, answer),
        );
    }
  }

  // ==================== EVALUATING VIEW ====================

  Widget _buildEvaluating() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          const Center(
            child: LoadingOverlay(message: 'Evaluating your answers...'),
          ),
        ],
      ),
    );
  }

  // ==================== RESULTS VIEW ====================

  Widget _buildResults() {
    final eval = _evaluation!;
    final isExcellent = eval.percentage >= 80;
    final isGood = eval.percentage >= 50;
    final testColor = _getTestColor(_activeTestType);
    final testColorDark = _getTestColorDark(_activeTestType);

    final resultEmoji = isExcellent
        ? '🏆'
        : isGood
            ? '👍'
            : '📚';
    final resultTitle = isExcellent
        ? 'Outstanding!'
        : isGood
            ? 'Great Job!'
            : 'Good Start!';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          const Opacity(
            opacity: 0.6,
            child: FloatingNumbersBackground(),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          '${_getTestLabel(_activeTestType)} Results',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        // ── Score hero card ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [testColor, testColorDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: testColor.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                resultEmoji,
                                style: const TextStyle(fontSize: 56),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                resultTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${eval.score} / ${eval.total} correct',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Percentage bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: eval.percentage / 100,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Colors.white),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${eval.percentage.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Message card ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            eval.message,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Skill summary card ──
                        if (_testData != null) _buildSkillSummaryCard(),

                        const SizedBox(height: 16),

                        // ── Unlocked levels card ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Level Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLevelUnlockRow(
                                'Beginner',
                                Icons.looks_one_rounded,
                                true,
                                const Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 12),
                              _buildLevelUnlockRow(
                                'Intermediate',
                                Icons.looks_two_rounded,
                                _intermediateUnlocked,
                                const Color(0xFFE65100),
                              ),
                              const SizedBox(height: 12),
                              _buildLevelUnlockRow(
                                'Advanced',
                                Icons.looks_3_rounded,
                                _advancedUnlocked,
                                const Color(0xFFC62828),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Action buttons ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _startTest(_activeTestType),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              'Retake This Test',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _currentView = _ScreenView.hub);
                            },
                            icon: const Icon(Icons.grid_view_rounded),
                            label: Text(
                              'Back to Tests',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: testColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              shadowColor: testColor.withOpacity(0.4),
                            ),
                          ),
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

  Widget _buildSkillSummaryCard() {
    // Group questions by type and compute accuracy per type
    final Map<String, List<bool>> typeResults = {};
    for (final q in _testData!.questions) {
      final isCorrect = _results[q.id] ?? false;
      typeResults.putIfAbsent(q.type, () => []).add(isCorrect);
    }

    // Build sorted lists: strengths (≥70%) and needs practice (<70%)
    final strengths = <MapEntry<String, double>>[];
    final practice = <MapEntry<String, double>>[];

    typeResults.forEach((type, results) {
      final acc = results.where((r) => r).length / results.length;
      if (acc >= 0.7) {
        strengths.add(MapEntry(type, acc));
      } else {
        practice.add(MapEntry(type, acc));
      }
    });

    strengths.sort((a, b) => b.value.compareTo(a.value));
    practice.sort((a, b) => a.value.compareTo(b.value));

    if (typeResults.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6FDD).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF7C6FDD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Skill Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFF2E7D32), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Strong skills',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...strengths.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSkillRow(
                    type: e.key,
                    accuracy: e.value,
                    isStrength: true,
                    total: typeResults[e.key]!.length,
                    correct: typeResults[e.key]!.where((r) => r).length,
                  ),
                )),
          ],
          if (practice.isNotEmpty) ...[
            SizedBox(height: strengths.isNotEmpty ? 16 : 16),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: Color(0xFFE65100), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Needs more practice',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...practice.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSkillRow(
                    type: e.key,
                    accuracy: e.value,
                    isStrength: false,
                    total: typeResults[e.key]!.length,
                    correct: typeResults[e.key]!.where((r) => r).length,
                  ),
                )),
          ],
          if (practice.isEmpty && strengths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🎉 Perfect! You nailed every skill in this test!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillRow({
    required String type,
    required double accuracy,
    required bool isStrength,
    required int total,
    required int correct,
  }) {
    final label = _getTypeLabel(type);
    final icon = _getTypeIcon(type);
    final accent =
        isStrength ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final bg = isStrength
        ? const Color(0xFF2E7D32).withOpacity(0.07)
        : const Color(0xFFE65100).withOpacity(0.07);
    final tip = _getSkillTip(type, isStrength);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '$correct / $total',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: accuracy,
              backgroundColor: accent.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getSkillTip(String type, bool isStrength) {
    // [0] = strong tip, [1] = practice tip
    const tips = <String, List<String>>{
      'select': [
        'Great at recognising and choosing the right number!',
        'Try the Read activity to practise choosing the right number.',
      ],
      'matching': [
        'Excellent at matching numbers to their names!',
        'Practise matching numbers and words in the Read activity.',
      ],
      'image_counting': [
        'You can count objects perfectly!',
        'Practise counting objects by going through the video lessons.',
      ],
      'drag_drop_order': [
        'You know the order of numbers well!',
        'Work on ordering numbers \u2014 try the Beginner activities.',
      ],
      'drag_drop_count': [
        'Great at counting and dragging items!',
        'Keep practising counting by dragging the right number.',
      ],
      'pattern_fill': [
        'You can spot and fill number patterns easily!',
        'Practise number patterns to improve this skill.',
      ],
      'trace': [
        'You write numbers beautifully!',
        'Use the Trace activity to practise writing numbers.',
      ],
      'say': [
        'Great at saying numbers aloud!',
        'Use the Say activity to practise pronouncing numbers correctly.',
      ],
      'show': [
        'You can show the right number of objects!',
        'Practise showing the right number of objects to the camera.',
      ],
      'object_detection': [
        'You can show the right number of objects!',
        'Practise showing the right number of objects to the camera.',
      ],
    };
    final t = tips[type];
    if (t == null) {
      return isStrength
          ? 'You did well on this skill!'
          : 'Keep practising to improve this skill.';
    }
    return isStrength ? t[0] : t[1];
  }

  Widget _buildLevelUnlockRow(
    String label,
    IconData icon,
    bool isUnlocked,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withOpacity(0.08)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: isUnlocked ? color : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: isUnlocked ? color : Colors.grey[400], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isUnlocked ? 'Unlocked ✓' : 'Locked',
              style: GoogleFonts.poppins(
                color: isUnlocked ? color : Colors.grey[500],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  String _getTestLabel(String testType) {
    switch (testType) {
      case 'placement':
        return 'Placement Quiz';
      case 'beginner':
        return 'Beginner Test';
      case 'intermediate':
        return 'Intermediate Test';
      case 'advanced':
        return 'Advanced Test';
      default:
        return 'Test';
    }
  }

  Color _getTestColor(String testType) {
    switch (testType) {
      case 'placement':
        return const Color(0xFF6B7FFF);
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return const Color(0xFF6B7FFF);
    }
  }

  Color _getTestColorDark(String testType) {
    switch (testType) {
      case 'placement':
        return const Color(0xFF3D52D5);
      case 'beginner':
        return const Color(0xFF1B5E20);
      case 'intermediate':
        return const Color(0xFFE65100);
      case 'advanced':
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFF3D52D5);
    }
  }

  IconData _getTestIcon(String testType) {
    switch (testType) {
      case 'placement':
        return Icons.psychology;
      case 'beginner':
        return Icons.looks_one;
      case 'intermediate':
        return Icons.looks_two;
      case 'advanced':
        return Icons.looks_3;
      default:
        return Icons.quiz;
    }
  }

  String _getTestDescription(String testType) {
    switch (testType) {
      case 'placement':
        return "Let's see how much you already know!\nAnswer these questions to unlock the right level.";
      case 'beginner':
        return 'Show your knowledge of numbers 1-10.\nPass to unlock the Intermediate level!';
      case 'intermediate':
        return 'Matching, patterns, and counting challenges.\nPass to unlock the Advanced level!';
      case 'advanced':
        return 'Word problems, estimation, and complex patterns.\nProve you have mastered all levels!';
      default:
        return 'Answer the questions to test your knowledge.';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'matching':
        return Icons.compare_arrows;
      case 'drag_drop_order':
        return Icons.swap_vert;
      case 'drag_drop_count':
        return Icons.drag_indicator;
      case 'image_counting':
        return Icons.image;
      case 'pattern_fill':
        return Icons.pattern;
      case 'trace':
        return Icons.edit;
      case 'say':
        return Icons.mic;
      case 'show':
      case 'object_detection':
        return Icons.camera_alt;
      case 'select':
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'matching':
        return 'Matching';
      case 'drag_drop_order':
        return 'Drag & Drop';
      case 'drag_drop_count':
        return 'Drag & Count';
      case 'image_counting':
        return 'Counting';
      case 'pattern_fill':
        return 'Pattern';
      case 'trace':
        return 'Drawing';
      case 'say':
        return 'Speaking';
      case 'show':
      case 'object_detection':
        return 'Show Objects';
      case 'select':
      default:
        return 'Select';
    }
  }
}

/// Animated wrapper for test cards with scale and tap effects
class _AnimatedTestCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedTestCard({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedTestCard> createState() => _AnimatedTestCardState();
}

class _AnimatedTestCardState extends State<_AnimatedTestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
