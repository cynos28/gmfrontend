import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/utils/ui_helpers.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/widgets/test/question_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUnlockState();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  /// Load saved unlock state from local storage
  Future<void> _loadUnlockState() async {
    final completed = await _storageService.getProgressValue('progress_test_completed');
    final difficulty = await _storageService.getProgressValue('progress_test_difficulty');

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
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Progress Test'),
        backgroundColor: const Color(0xFF6B7FFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(Icons.psychology, size: 64, color: Color(0xFF6B7FFF)),
              const SizedBox(height: 12),
              const Text(
                'Test Your Knowledge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _placementDone
                    ? 'Current level: ${_currentLevel.capitalize}'
                    : 'Take the placement quiz to find your starting level',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              // Placement Quiz Card
              _buildTestCard(
                title: _placementDone ? 'Retake Placement Quiz' : 'Placement Quiz',
                subtitle: '5 quick questions to determine your starting level',
                icon: Icons.quiz,
                gradientColors: _placementDone
                    ? [const Color(0xFF4CAF50), const Color(0xFF45A049)]
                    : [const Color(0xFF6B7FFF), const Color(0xFF5567E8)],
                badge: _placementDone ? 'Completed' : 'Start Here',
                badgeColor: _placementDone ? Colors.green : const Color(0xFF6B7FFF),
                onTap: () => _startTest('placement'),
              ),

              const SizedBox(height: 24),

              // Difficulty Tests Section
              const Text(
                'Difficulty Tests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pass each test to unlock the next level',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 14),

              // Beginner
              _buildDifficultyCard(
                title: 'Beginner Test',
                subtitle: '8 easy questions • Numbers 1-10 basics',
                icon: Icons.looks_one,
                color: Colors.green,
                isUnlocked: _beginnerUnlocked,
                passingInfo: 'Pass 5/8 to unlock Intermediate',
                onTap: () => _startTest('beginner'),
              ),
              const SizedBox(height: 12),

              // Intermediate
              _buildDifficultyCard(
                title: 'Intermediate Test',
                subtitle: '10 medium questions • Matching, patterns, counting',
                icon: Icons.looks_two,
                color: Colors.orange,
                isUnlocked: _intermediateUnlocked,
                passingInfo: 'Pass 6/10 to unlock Advanced',
                onTap: () => _startTest('intermediate'),
              ),
              const SizedBox(height: 12),

              // Advanced
              _buildDifficultyCard(
                title: 'Advanced Test',
                subtitle: '10 hard questions • Word problems, estimation',
                icon: Icons.looks_3,
                color: Colors.red,
                isUnlocked: _advancedUnlocked,
                passingInfo: 'Score 7/10 to master all levels',
                onTap: () => _startTest('advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
    required String passingInfo,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnlocked ? color.withOpacity(0.4) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isUnlocked
                ? onTap
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Pass the previous test to unlock this level!'),
                        backgroundColor: Color(AppColors.warningColor),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (isUnlocked ? color : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isUnlocked ? color : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passingInfo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isUnlocked
                                ? color.withOpacity(0.8)
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.arrow_forward_ios : Icons.lock,
                    color: isUnlocked ? color : Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LOADING VIEW ====================

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      body: const Center(
        child: LoadingOverlay(message: 'Preparing your test...'),
      ),
    );
  }

  // ==================== INTRO VIEW ====================

  Widget _buildIntro() {
    final testLabel = _getTestLabel(_activeTestType);
    final testColor = _getTestColor(_activeTestType);

    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(testLabel),
        backgroundColor: testColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _currentView = _ScreenView.hub),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getTestIcon(_activeTestType),
                size: 90,
                color: testColor,
              ),
              const SizedBox(height: 20),
              Text(
                testLabel,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _getTestDescription(_activeTestType),
                style: const TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.numbers,
                        '${_testData!.totalQuestions} Questions',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.timer_off, 'No time limit'),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          Icons.category, 'Different question types'),
                      if (_testData!.passingScore != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.check_circle_outline,
                          'Pass: ${_testData!.passingScore}/${_testData!.totalQuestions} correct',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ActionButton(
                text: 'Start Test',
                icon: Icons.play_arrow,
                color: testColor,
                onPressed: () {
                  setState(() => _currentView = _ScreenView.testing);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7FFF)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  // ==================== QUESTION VIEW ====================

  Widget _buildQuestion() {
    // Check if all questions answered
    if (_currentQuestionIndex >= _testData!.questions.length) {
      // Trigger evaluation
      if (_currentView != _ScreenView.evaluating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _evaluateTest();
        });
      }
      return _buildEvaluating();
    }

    final question = _testData!.questions[_currentQuestionIndex];
    final progress = _currentQuestionIndex / _testData!.questions.length;
    final testColor = _getTestColor(_activeTestType);

    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text(
          'Question ${_currentQuestionIndex + 1}/${_testData!.questions.length}',
        ),
        backgroundColor: testColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_results.values.where((v) => v).length} correct',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: testColor,
                  minHeight: 6,
                );
              },
            ),
            const SizedBox(height: 8),

            // Question type badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(question.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(question.type),
                          size: 16,
                          color: _getTypeColor(question.type),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTypeLabel(question.type),
                          style: TextStyle(
                            color: _getTypeColor(question.type),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${question.points} pts',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Question widget
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    _buildQuestionWidget(question),
                    
                    // Feedback overlay with countdown
                    if (_showingFeedback)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Card(
                            margin: const EdgeInsets.all(32),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _results[question.id] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _results[question.id] == true
                                        ? Colors.green
                                        : Colors.red,
                                    size: 80,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _results[question.id] == true
                                        ? 'Correct!'
                                        : 'Incorrect',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _results[question.id] == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Next question in $_feedbackCountdown...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _moveToNextQuestion,
                                      icon: const Icon(Icons.skip_next),
                                      label: const Text('Next Question'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: testColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
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
      backgroundColor: Color(AppColors.backgroundColor),
      body: const Center(
        child: LoadingOverlay(message: 'Evaluating your answers...'),
      ),
    );
  }

  // ==================== RESULTS VIEW ====================

  Widget _buildResults() {
    final eval = _evaluation!;
    final isExcellent = eval.percentage >= 80;
    final isGood = eval.percentage >= 50;
    final testColor = _getTestColor(_activeTestType);

    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: Text('${_getTestLabel(_activeTestType)} Results'),
        backgroundColor: testColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Score
              ScoreCard(
                score: eval.score,
                total: eval.total,
                title: 'Your Score',
              ),
              const SizedBox(height: 20),

              // Result icon
              Icon(
                isExcellent
                    ? Icons.star
                    : isGood
                        ? Icons.thumb_up
                        : Icons.school,
                size: 72,
                color: isExcellent
                    ? Colors.amber
                    : isGood
                        ? Color(AppColors.successColor)
                        : Color(AppColors.infoColor),
              ),
              const SizedBox(height: 12),
              Text(
                isExcellent
                    ? 'Outstanding!'
                    : isGood
                        ? 'Great Job!'
                        : 'Good Start!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                eval.message,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Unlocked levels card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'Unlocked Levels',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLevelUnlockRow(
                        'Beginner',
                        Icons.looks_one,
                        true,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildLevelUnlockRow(
                        'Intermediate',
                        Icons.looks_two,
                        _intermediateUnlocked,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildLevelUnlockRow(
                        'Advanced',
                        Icons.looks_3,
                        _advancedUnlocked,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Actions
              ActionButton(
                text: 'Retake This Test',
                icon: Icons.refresh,
                color: Colors.grey[600]!,
                onPressed: () => _startTest(_activeTestType),
              ),
              const SizedBox(height: 10),
              ActionButton(
                text: 'Back to Tests',
                icon: Icons.list,
                color: testColor,
                onPressed: () {
                  setState(() => _currentView = _ScreenView.hub);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelUnlockRow(
    String label,
    IconData icon,
    bool isUnlocked,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          isUnlocked ? Icons.lock_open : Icons.lock,
          color: isUnlocked ? color : Colors.grey[400],
          size: 26,
        ),
        const SizedBox(width: 10),
        Icon(icon, color: isUnlocked ? color : Colors.grey[400], size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.black87 : Colors.grey[400],
            ),
          ),
        ),
        if (isUnlocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Unlocked',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'matching':
        return Colors.purple;
      case 'drag_drop_order':
      case 'drag_drop_count':
        return Colors.orange;
      case 'image_counting':
        return Colors.teal;
      case 'pattern_fill':
        return Colors.indigo;
      case 'trace':
        return Colors.blue;
      case 'say':
        return Colors.green;
      case 'show':
      case 'object_detection':
        return Colors.cyan;
      case 'select':
      default:
        return Colors.deepPurple;
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

