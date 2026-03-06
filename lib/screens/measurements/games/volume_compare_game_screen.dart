/// Volume Compare Game Screen - Visual Comparison (V-V2)
/// Compare containers and identify which holds most/least/same

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/services/api/games_api_service.dart';
import 'package:ganithamithura/utils/kids_theme.dart';

class VolumeCompareGameScreen extends StatefulWidget {
  const VolumeCompareGameScreen({super.key});

  @override
  State<VolumeCompareGameScreen> createState() => _VolumeCompareGameScreenState();
}

class _VolumeCompareGameScreenState extends State<VolumeCompareGameScreen>
    with TickerProviderStateMixin {
  // ─── Game State ──────────────────────────────────────────────────────────────
  static const int _maxQuestions = 5;
  int _questionNumber = 1;
  int _totalCorrect = 0;
  int _totalAttempts = 0;
  int _consecutiveSuccesses = 0;
  List<int> _recentCompletionTimes = [];
  bool _showFinishScreen = false;

  // ─── IRT State ──────────────────────────────────────────────────────────────
  String _studentId = 'default_student';
  double _theta = 0.0;
  int _irtDifficultyLevel = 1;
  int _irtRoundsPlayed = 0;
  Map<String, dynamic> _irtParams = {};
  bool _irtLoading = true;
  int _hintsUsed = 0;

  late _Question _currentQuestion;
  int? _selectedAnswer;
  List<int> _selectedAnswers = [];
  bool _showFeedback = false;
  bool _isCorrect = false;
  DateTime? _startTime;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
    _fetchIRTState();
  }

  Future<void> _fetchIRTState() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('student_id') ?? 'default_student';

    final state = await GamesApiService.getIRTState(
      studentId: _studentId,
      domain: 'volume',
      variant: 'V-V2',
    );

    if (mounted) {
      setState(() {
        _theta = (state['theta'] as num?)?.toDouble() ?? 0.0;
        _irtDifficultyLevel = (state['difficulty_level'] as int?) ?? 1;
        _irtRoundsPlayed = (state['rounds_played'] as int?) ?? 0;
        _irtParams = (state['next_params'] as Map<String, dynamic>?) ?? {};
        _irtLoading = false;
      });
      _generateQuestion();
      _startTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();

    final questionTypes = (_irtParams['question_types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        _getDefaultQuestionTypes(_irtDifficultyLevel);
    final containerTypes = (_irtParams['container_types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        ['cup1', 'glass1', 'jug1'];
    final sizeDifferences =
        (_irtParams['size_differences'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            _getDefaultSizes(_irtDifficultyLevel);

    final questionType = questionTypes[random.nextInt(questionTypes.length)];
    final containerType = containerTypes[random.nextInt(containerTypes.length)];

    setState(() {
      _currentQuestion =
          _Question.generate(questionType, containerType, sizeDifferences);
      _selectedAnswer = null;
      _selectedAnswers = [];
      _showFeedback = false;
      _isCorrect = false;
      _hintsUsed = 0;
    });
  }

  List<double> _getDefaultSizes(int level) {
    // Use more extreme size differences for clear visual distinction
    // These multiply against base height 140px → 42px, 84px, 140px
    // This creates unmistakable size differences that children can easily see
    return [0.3, 0.6, 1.0];
  }

  List<String> _getDefaultQuestionTypes(int level) {
    switch (level) {
      case 1:
        return ['most'];
      case 2:
        return ['most', 'least'];
      case 3:
        return ['most', 'least', 'same'];
      case 4:
        return ['most', 'least', 'same'];
      case 5:
        return ['least', 'same'];
      default:
        return ['most', 'least', 'same'];
    }
  }

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback) return;

    final isSameQuestion = _currentQuestion.questionType == 'same';

    if (isSameQuestion) {
      setState(() {
        if (_selectedAnswers.contains(selectedIndex)) {
          _selectedAnswers.remove(selectedIndex);
        } else {
          _selectedAnswers.add(selectedIndex);
        }
      });

      if (_selectedAnswers.length == 2) {
        final selected1 = _currentQuestion.options[_selectedAnswers[0]];
        final selected2 = _currentQuestion.options[_selectedAnswers[1]];
        final bothCorrect = selected1.logicalSize == selected2.logicalSize;

        setState(() {
          _isCorrect = bothCorrect;
          _showFeedback = true;
          _totalAttempts++;
          if (_isCorrect) {
            _totalCorrect++;
            _consecutiveSuccesses++;
            if (_startTime != null) {
              _recentCompletionTimes
                  .add(DateTime.now().difference(_startTime!).inSeconds);
            }
          } else {
            _consecutiveSuccesses = 0;
          }
        });

        _feedbackController.forward(from: 0.0);
        Future.delayed(const Duration(milliseconds: 2000), () async {
          if (mounted && _showFeedback) {
            await _submitRoundToIRT();
            _nextQuestion();
          }
        });
      }
      return;
    }

    // Single-select for 'most' / 'least'
    setState(() {
      _selectedAnswer = selectedIndex;
      _isCorrect = selectedIndex == _currentQuestion.correctAnswer;
      _showFeedback = true;
      _totalAttempts++;
      if (_isCorrect) {
        _totalCorrect++;
        _consecutiveSuccesses++;
        if (_startTime != null) {
          _recentCompletionTimes
              .add(DateTime.now().difference(_startTime!).inSeconds);
        }
      } else {
        _consecutiveSuccesses = 0;
      }
    });

    _feedbackController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted && _showFeedback) {
        await _submitRoundToIRT();
        _nextQuestion();
      }
    });
  }

  Future<void> _submitRoundToIRT() async {
    final timeSeconds =
        DateTime.now().difference(_startTime!).inSeconds.toDouble();
    final result = await GamesApiService.submitRoundResult(
      studentId: _studentId,
      domain: 'volume',
      variant: 'V-V2',
      correct: _isCorrect,
      attempts: 1,
      hintsUsed: _hintsUsed,
      timeSeconds: timeSeconds,
      starsEarned: _isCorrect ? 1 : 0,
    );

    if (mounted) {
      setState(() {
        _theta = (result['theta'] as num?)?.toDouble() ?? _theta;
        _irtDifficultyLevel =
            (result['difficulty_level'] as int?) ?? _irtDifficultyLevel;
        _irtRoundsPlayed =
            (result['rounds_played'] as int?) ?? _irtRoundsPlayed;
        _irtParams =
            (result['next_params'] as Map<String, dynamic>?) ?? _irtParams;
      });
    }
  }

  void _nextQuestion() {
    if (_questionNumber >= _maxQuestions) {
      setState(() => _showFinishScreen = true);
    } else {
      setState(() {
        _questionNumber++;
        _startTime = DateTime.now();
      });
      _generateQuestion();
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showFinishScreen) return _buildFinishScreen();

    if (_irtLoading) {
      return Scaffold(
        backgroundColor: KidsColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: KidsColors.volumeColor),
              const SizedBox(height: 16),
              Text('Loading...',
                  style: TextStyle(color: KidsColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: KidsColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Compare',
                style: const TextStyle(
                  color: KidsColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildIRTBadge(),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: KidsColors.volumeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Q $_questionNumber/$_maxQuestions',
              style: TextStyle(
                color: KidsColors.volumeColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: 24),
              _buildQuestionText(),
              if (_currentQuestion.questionType == 'same' && !_showFeedback)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select 2 containers with the same volume',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KidsColors.volumeColor,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildOptions(),
              if (_showFeedback) _buildFeedback(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIRTBadge() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
    ];
    final idx = (_irtDifficultyLevel - 1).clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[idx].withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[idx].withOpacity(0.5), width: 1),
      ),
      child: Text(
        labels[idx],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors[idx],
        ),
      ),
    );
  }

  Color _getIRTColor() {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
    ];
    return colors[(_irtDifficultyLevel - 1).clamp(0, 4)];
  }

  String _getIRTLabel() {
    const labels = ['Easy', 'Medium', 'Hard', 'Expert', 'Master'];
    return labels[(_irtDifficultyLevel - 1).clamp(0, 4)];
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: _questionNumber / _maxQuestions,
        minHeight: 12,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(KidsColors.volumeColor),
      ),
    );
  }

  Widget _buildQuestionText() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KidsColors.volumeColor.withOpacity(0.1),
            KidsColors.volumeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: KidsColors.volumeColor.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Text(
        _currentQuestion.questionText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: KidsColors.textPrimary,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final count = _currentQuestion.options.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count == 4 ? 2 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Increased aspect ratio to accommodate larger container sizes (up to 150px)
        childAspectRatio: 0.7,
      ),
      itemCount: count,
      itemBuilder: (context, index) => _buildOptionCard(index),
    );
  }

  Widget _buildOptionCard(int index) {
    final option = _currentQuestion.options[index];
    final isSameQuestion = _currentQuestion.questionType == 'same';

    final isSelected = isSameQuestion
        ? _selectedAnswers.contains(index)
        : _selectedAnswer == index;

    final isCorrectAnswer = isSameQuestion
        ? _currentQuestion.correctIndices.contains(index)
        : index == _currentQuestion.correctAnswer;

    Color borderColor;
    Color bgColor;

    if (_showFeedback) {
      if (isCorrectAnswer) {
        borderColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
      } else if (isSelected && !_isCorrect) {
        borderColor = const Color(0xFFFF5252);
        bgColor = const Color(0xFFFF5252).withOpacity(0.1);
      } else {
        borderColor = Colors.grey[300]!;
        bgColor = Colors.white;
      }
    } else {
      borderColor =
          isSelected ? KidsColors.volumeColor : Colors.grey[300]!;
      bgColor = isSelected
          ? KidsColors.volumeColor.withOpacity(0.1)
          : Colors.white;
    }

    return GestureDetector(
      onTap: () => _checkAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : KidsShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                // Align to bottom so containers "sit" on the same baseline,
                // making size differences immediately obvious to children.
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(
                    'assets/images/volume/${option.type}.png',
                    // displaySize creates EXTREME visual differences:
                    //   small  → 45 px  (30% of 150)
                    //   medium → 90 px  (60% of 150)
                    //   large  → 150 px (100% of 150)
                    // The large is MORE THAN 3X the small for unmistakable differences!
                    height: option.displaySize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_showFeedback && isCorrectAnswer)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 32,
                ),
              )
            else if (_showFeedback && isSelected && !_isCorrect)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFFF5252),
                  size: 32,
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isCorrect
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252))
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _isCorrect
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isCorrect ? '🎉 Correct!' : 'Try again next time!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishScreen() {
    final successRate = (_totalCorrect / _totalAttempts * 100).toInt();

    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KidsColors.volumeColor,
                        KidsColors.volumeColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KidsColors.volumeColor.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      size: 80, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '🎉 Great Job! 🎉',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: KidsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You completed all $_maxQuestions questions!',
                style: const TextStyle(
                  fontSize: 18,
                  color: KidsColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _getIRTColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _getIRTColor().withOpacity(0.3), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded,
                        color: _getIRTColor(), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Skill Level: ${_getIRTLabel()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _getIRTColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Correct',
                      value: '$_totalCorrect/$_maxQuestions',
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.percent_rounded,
                      label: 'Success Rate',
                      value: '$successRate%',
                      color: KidsColors.volumeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _questionNumber = 1;
                          _totalCorrect = 0;
                          _totalAttempts = 0;
                          _consecutiveSuccesses = 0;
                          _recentCompletionTimes.clear();
                          _showFinishScreen = false;
                          _startTime = DateTime.now();
                          _generateQuestion();
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 24),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsColors.volumeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.home_rounded, size: 24),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: KidsColors.volumeColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                              color: KidsColors.volumeColor.withOpacity(0.3),
                              width: 2),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KidsColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Question Model ──────────────────────────────────────────────────────────

class _Question {
  final String questionText;
  final List<_ContainerOption> options;
  final int correctAnswer;
  final List<int> correctIndices;
  final String questionType;

  _Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.correctIndices = const [],
    required this.questionType,
  });

  factory _Question.generate(
    String questionType,
    String containerType,
    List<double> availableSizes,
  ) {
    final random = math.Random();

    // Pick 3 distinct sizes with EXTREME differences for maximum visual clarity
    final sorted = List<double>.from(availableSizes)..sort();
    final baseSizes = sorted.length >= 3
        ? [sorted.first, sorted[sorted.length ~/ 2], sorted.last]
        : [0.3, 0.6, 1.0];  // 30%, 60%, 100% - very clear differences!
    final smallSize = baseSizes.first;
    final largeSize = baseSizes.last;
    final midSize = baseSizes.length > 1 ? baseSizes[1] : (smallSize + largeSize) / 2;

    // Base height for container images - larger for better visibility
    // Creates VERY distinct sizes: 45px (small), 90px (medium), 150px (large)
    const double baseHeight = 150.0;

    if (questionType == 'most') {
      // Three options, shuffled; one large, one medium, one small.
      final sizes = [smallSize, midSize, largeSize]..shuffle(random);
      final correctIdx = sizes.indexOf(largeSize);

      return _Question(
        questionText: 'Which ${_pluralName(containerType)} holds the most?',
        options: sizes
            .map((s) => _ContainerOption(
                  type: containerType,
                  logicalSize: s,
                  displaySize: s * baseHeight,
                ))
            .toList(),
        correctAnswer: correctIdx,
        questionType: 'most',
      );
    } else if (questionType == 'least') {
      // Three options, shuffled; correct answer is the smallest.
      final sizes = [smallSize, midSize, largeSize]..shuffle(random);
      final correctIdx = sizes.indexOf(smallSize);

      return _Question(
        questionText: 'Which ${_pluralName(containerType)} holds the least?',
        options: sizes
            .map((s) => _ContainerOption(
                  type: containerType,
                  logicalSize: s,
                  displaySize: s * baseHeight,
                ))
            .toList(),
        correctAnswer: correctIdx,
        questionType: 'least',
      );
    } else {
      // "Same" question: TWO identical + TWO different distractors
      final tierChoices = [smallSize, midSize, largeSize];
      final sameSize = tierChoices[random.nextInt(tierChoices.length)];
      final distractors = tierChoices.where((s) => s != sameSize).toList();

      final sizes = [
        sameSize,
        sameSize,
        distractors[0],
        distractors.length > 1 ? distractors[1] : (sameSize > 0.6 ? smallSize : largeSize),
      ]..shuffle(random);

      final List<int> correctIndices = [
        for (int i = 0; i < sizes.length; i++)
          if (sizes[i] == sameSize) i,
      ];

      return _Question(
        questionText:
            'Which two ${_pluralName(containerType)} hold the same?',
        options: sizes
            .map((s) => _ContainerOption(
                  type: containerType,
                  logicalSize: s,
                  displaySize: s * baseHeight,
                ))
            .toList(),
        correctAnswer:
            correctIndices.isNotEmpty ? correctIndices[0] : 0,
        correctIndices: correctIndices,
        questionType: 'same',
      );
    }
  }

  static String _pluralName(String type) {
    switch (type) {
      case 'cup1':
        return 'cups';
      case 'glass1':
        return 'glasses';
      case 'jug1':
      case 'jug2':
      case 'jug3':
        return 'jugs';
      default:
        return 'containers';
    }
  }
}

// ─── Container Option ────────────────────────────────────────────────────────

class _ContainerOption {
  /// Logical size — used only for equality comparison (correctness check).
  final double logicalSize;

  /// Display size in pixels — always one of 56 / 96 / 140 px so containers
  /// are unmistakably different in size for children.
  final double displaySize;

  final String type;

  _ContainerOption({
    required this.type,
    required this.logicalSize,
    required this.displaySize,
  });
}