import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/shape_models.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// Questions2DShapesAPIScreen - API-integrated quiz game for shape questions
/// Updated for grade 2-3 students with larger fonts and colorful design
class Questions2DShapesAPIScreen extends StatefulWidget {
  final String gameId;
  
  const Questions2DShapesAPIScreen({
    super.key,
    this.gameId = 'level2',
  });

  @override
  State<Questions2DShapesAPIScreen> createState() => _Questions2DShapesAPIScreenState();
}

class _Questions2DShapesAPIScreenState extends State<Questions2DShapesAPIScreen> {
  static const int _quizSize = 5; // Number of questions per quiz round
  
  final ShapesApiService _apiService = ShapesApiService.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  QuestionRoundGame? _gameData;
  GameResult? _gameResult;
  
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  Map<String, String> _userAnswers = {};
  bool _isSubmitting = false;
  Map<String, List<String>> _shuffledOptions = {}; // Cache shuffled options per question

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final game = await _apiService.startGame(gameId: widget.gameId);
      
      if (game is! QuestionRoundGame) {
        throw Exception('Invalid game type. Expected question round game.');
      }

      // Randomly select questions from the available questions
      final random = Random();
      final allQuestions = game.questions;
      final shuffledQuestions = List<ShapeQuestion>.from(allQuestions)..shuffle(random);
      final selectedQuestions = shuffledQuestions.take(_quizSize).toList();
      
      assert(selectedQuestions.length == _quizSize, 'Quiz must have exactly $_quizSize questions');
      
      // Create a new game with only the selected questions
      final limitedGame = QuestionRoundGame(
        gameId: game.gameId,
        level: game.level,
        title: game.title,
        questions: selectedQuestions,
        answerPool: game.answerPool,
        correctAnswers: game.correctAnswers,
      );

      setState(() {
        _gameData = limitedGame;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(String answer) {
    if (_userAnswers.containsKey(_currentQuestion.id)) return; // Already answered
    
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _userAnswers.containsKey(_currentQuestion.id)) return; // Prevent duplicate submission
    
    setState(() {
      _userAnswers[_currentQuestion.id] = _selectedAnswer!;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizSize - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      _submitAllAnswers();
    }
  }

  Future<void> _submitAllAnswers() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final gameAnswer = GameAnswer(
        gameId: widget.gameId,
        answers: _userAnswers,
      );

      final result = await _apiService.checkAnswers(gameAnswer);
      
      setState(() {
        _gameResult = result;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answers: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _userAnswers.clear();
      _gameResult = null;
      _shuffledOptions.clear();
    });
  }

  ShapeQuestion get _currentQuestion => _gameData!.questions[_currentQuestionIndex];
  bool get _hasAnswered => _userAnswers.containsKey(_currentQuestion.id);
  bool get _isLastQuestion => _currentQuestionIndex == _quizSize - 1;
  bool get _is3DQuiz => widget.gameId == 'level4'; // Level 4 is 3D shapes quiz

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_gameResult != null) {
      return _buildResultsScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36D399)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading quiz...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D4059),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D4059)),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load quiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D4059),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D4059),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36D399),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final q = _currentQuestion;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildQuestionSection(q),
                    const SizedBox(height: 32),
                    _buildNextButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _is3DQuiz ? '3D Shapes Quiz' : '2D Shapes Quiz',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Question ${_currentQuestionIndex + 1} of $_quizSize',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.psychology_rounded, color: Color(0xFF2196F3), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Pick the right answer!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          if (_selectedAnswer != null && !_hasAnswered)
            IconButton(
              onPressed: () => setState(() => _selectedAnswer = null),
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF9800)),
              tooltip: 'Reset selection',
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(ShapeQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            q.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),
          _buildOptionButtons(),
        ],
      ),
    );
  }

  // Option buttons in 2x2 grid
  Widget _buildOptionButtons() {
    final q = _currentQuestion;
    
    // Get or create shuffled options for this question
    if (!_shuffledOptions.containsKey(q.id)) {
      final correctAnswer = _gameData!.correctAnswers[q.id]!;
      final allOptions = List<String>.from(_gameData!.answerPool);
      
      // Remove correct answer from pool to get wrong answers
      allOptions.remove(correctAnswer);
      
      // Shuffle and take 3 wrong answers
      allOptions.shuffle();
      final wrongAnswers = allOptions.take(3).toList();
      
      // Combine correct and wrong answers, then shuffle
      final displayOptions = [correctAnswer, ...wrongAnswers];
      displayOptions.shuffle();
      
      // Cache the shuffled options
      _shuffledOptions[q.id] = displayOptions;
    }
    
    final displayOptions = _shuffledOptions[q.id]!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildOptionButton(displayOptions[0], q)),
            const SizedBox(width: 8),
            if (displayOptions.length > 1)
              Expanded(child: _buildOptionButton(displayOptions[1], q)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (displayOptions.length > 2)
              Expanded(child: _buildOptionButton(displayOptions[2], q)),
            const SizedBox(width: 8),
            if (displayOptions.length > 3)
              Expanded(child: _buildOptionButton(displayOptions[3], q)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(String option, ShapeQuestion q) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = _hasAnswered && _gameData!.correctAnswers[q.id] == option;
    final showAsWrong = _hasAnswered && isSelected && _gameData!.correctAnswers[q.id] != option;
    final showAsCorrect = isCorrectAnswer;
    
    Color borderColor;
    Color bgColor;
    Color textColor;
    
    if (showAsCorrect) {
      borderColor = const Color(0xFF4CAF50);
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else if (showAsWrong) {
      borderColor = const Color(0xFFE91E63);
      bgColor = const Color(0xFFFCE4EC);
      textColor = const Color(0xFFC2185B);
    } else if (isSelected) {
      borderColor = const Color(0xFF2196F3);
      bgColor = const Color(0xFFBBDEFB);
      textColor = const Color(0xFF1976D2);
    } else {
      borderColor = const Color(0xFFE0E0E0);
      bgColor = Colors.white;
      textColor = Colors.black87;
    }
    
    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isSelected || showAsCorrect || showAsWrong ? [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showAsCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
            if (showAsWrong) const Icon(Icons.cancel_rounded, color: Color(0xFFC2185B), size: 20),
            if (showAsCorrect || showAsWrong) const SizedBox(width: 8),
            Flexible(
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final bool canInteract = _selectedAnswer != null || _hasAnswered;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isSubmitting || (!canInteract)) 
          ? null 
          : (_hasAnswered ? _nextQuestion : _submitAnswer),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: canInteract ? 4 : 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Text(
                _hasAnswered 
                    ? (_isLastQuestion ? 'Finish Quiz 🎉' : 'Next Question ➡️') 
                    : 'Check Answer ✨',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final result = _gameResult!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildResultsSummary(),
                    const SizedBox(height: 30),
                    _buildStatsRow(),
                    const SizedBox(height: 40),
                    _buildResultsActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    final result = _gameResult!;
    final bool isExcellent = result.correctAnswers >= 4;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isExcellent ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isExcellent ? '🎉 Amazing! 🎉' : '😊 Good Effort! 😊',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You got ${result.correctAnswers} out of $_quizSize questions correct!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < result.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: index < result.stars ? const Color(0xFFFFC107) : Colors.black26,
                  size: 48,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final result = _gameResult!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${result.correctAnswers}', 'Correct', const Color(0xFF4CAF50)),
          _buildStatItem('${result.wrongAnswers}', 'Wrong', const Color(0xFFE91E63)),
          _buildStatItem('${result.score}', 'Score', const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildResultsActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
            child: const Text('Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Go Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
