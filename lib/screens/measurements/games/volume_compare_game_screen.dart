/// Volume Compare Game Screen - Visual Comparison (V-V2)
/// Compare containers and identify which holds most/least/same

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  
  late _Question _currentQuestion;
  int? _selectedAnswer;
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
    _generateQuestion();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = math.Random();
    final questionTypes = ['most', 'least', 'same'];
    final containerTypes = ['cup1', 'glass1', 'jug1', 'jug2', 'jug3'];
    
    // Select question type based on difficulty
    String questionType;
    if (_consecutiveSuccesses >= 3) {
      questionType = questionTypes[random.nextInt(questionTypes.length)];
    } else if (_consecutiveSuccesses >= 2) {
      questionType = random.nextBool() ? 'most' : 'least';
    } else {
      questionType = 'most'; // Start with easiest
    }
    
    final containerType = containerTypes[random.nextInt(containerTypes.length)];
    
    setState(() {
      _currentQuestion = _Question.generate(questionType, containerType);
      _selectedAnswer = null;
      _showFeedback = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback) return;
    
    setState(() {
      _selectedAnswer = selectedIndex;
      _isCorrect = selectedIndex == _currentQuestion.correctAnswer;
      _showFeedback = true;
      _totalAttempts++;
      
      if (_isCorrect) {
        _totalCorrect++;
        _consecutiveSuccesses++;
        if (_startTime != null) {
          _recentCompletionTimes.add(DateTime.now().difference(_startTime!).inSeconds);
        }
      } else {
        _consecutiveSuccesses = 0;
      }
    });
    
    _feedbackController.forward(from: 0.0);
    
    // Auto advance after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _showFeedback) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_questionNumber >= _maxQuestions) {
      setState(() {
        _showFinishScreen = true;
      });
    } else {
      setState(() {
        _questionNumber++;
        _startTime = DateTime.now();
      });
      _generateQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFinishScreen) {
      return _buildFinishScreen();
    }
    
    return Scaffold(
      backgroundColor: KidsColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KidsColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Volume Compare',
          style: const TextStyle(
            color: KidsColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: 24),
              
              // Question text
              _buildQuestionText(),
              const SizedBox(height: 32),
              
              // Options
              Expanded(
                child: _buildOptions(),
              ),
              
              // Feedback
              if (_showFeedback) _buildFeedback(),
            ],
          ),
        ),
      ),
    );
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
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _currentQuestion.options.length == 3 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _currentQuestion.options.length,
      itemBuilder: (context, index) {
        return _buildOptionCard(index);
      },
    );
  }

  Widget _buildOptionCard(int index) {
    final option = _currentQuestion.options[index];
    final isSelected = _selectedAnswer == index;
    final isCorrectAnswer = index == _currentQuestion.correctAnswer;
    
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
      borderColor = isSelected
          ? KidsColors.volumeColor
          : Colors.grey[300]!;
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
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  _getImagePath(option.type),
                  height: 100 * option.size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (_showFeedback && isCorrectAnswer)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 32,
                ),
              ),
            if (_showFeedback && isSelected && !_isCorrect)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Icon(
                  Icons.cancel_rounded,
                  color: const Color(0xFFFF5252),
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getImagePath(String type) {
    return 'assets/images/volume/$type.png';
  }

  Widget _buildFeedback() {
    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isCorrect
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF5252),
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
              _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Trophy
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
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
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
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
              
              // Stats
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
              
              const Spacer(),
              
              // Buttons
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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
                            width: 2,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KidsColors.textSecondary,
            ),
          ),
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

  _Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory _Question.generate(String questionType, String containerType) {
    final random = math.Random();
    
    if (questionType == 'most') {
      // Which holds the most?
      final sizes = [0.5, 0.7, 1.0]..shuffle();
      final correctIndex = sizes.indexOf(1.0);
      
      return _Question(
        questionText: 'Which ${_pluralName(containerType)} holds the most?',
        options: sizes
            .map((size) => _ContainerOption(type: containerType, size: size))
            .toList(),
        correctAnswer: correctIndex,
      );
    } else if (questionType == 'least') {
      // Which holds the least?
      final sizes = [0.5, 0.7, 1.0]..shuffle();
      final correctIndex = sizes.indexOf(0.5);
      
      return _Question(
        questionText: 'Which ${_pluralName(containerType)} holds the least?',
        options: sizes
            .map((size) => _ContainerOption(type: containerType, size: size))
            .toList(),
        correctAnswer: correctIndex,
      );
    } else {
      // Which two hold the same?
      final sameSize = [0.6, 0.8, 1.0][random.nextInt(3)];
      final options = [
        _ContainerOption(type: containerType, size: sameSize),
        _ContainerOption(type: containerType, size: sameSize),
        _ContainerOption(type: containerType, size: sameSize == 0.6 ? 1.0 : 0.6),
        _ContainerOption(type: containerType, size: sameSize == 0.8 ? 1.0 : 0.8),
      ]..shuffle();
      
      // Find first pair that matches
      int correctIndex = 0;
      for (int i = 0; i < options.length; i++) {
        for (int j = i + 1; j < options.length; j++) {
          if (options[i].size == options[j].size) {
            correctIndex = i; // Return first of the pair
            break;
          }
        }
      }
      
      return _Question(
        questionText: 'Which two ${_pluralName(containerType)} hold the same?',
        options: options,
        correctAnswer: correctIndex,
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

class _ContainerOption {
  final String type;
  final double size;

  _ContainerOption({required this.type, required this.size});
}
