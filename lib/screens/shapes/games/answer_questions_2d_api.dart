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

      setState(() {
        _gameData = game;
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
    if (_selectedAnswer == null) return;
    
    setState(() {
      _userAnswers[_currentQuestion.id] = _selectedAnswer!;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _gameData!.questions.length - 1) {
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
  bool get _isLastQuestion => _currentQuestionIndex == _gameData!.questions.length - 1;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 393.0 : screenWidth - 32;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back Navigation Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: const Color(0xFF2D4059),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fun 2D Shape Quiz! 🌟',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedAnswer != null && !_hasAnswered)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedAnswer = null;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B6B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: cardWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xF2F9F9F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      
                      // Header Section
                      _buildHeader(),
                      
                      const SizedBox(height: 30),
                      
                      // Question and Answer Section
                      _buildQuestionSection(q),
                      
                      const SizedBox(height: 30),
                      
                      // Next Button
                      _buildNextButton(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header with icon, title, and question counter
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F3FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        shadows: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF36D399),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.category_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick the right answer!',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF36D399),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${_currentQuestionIndex + 1}/${_gameData!.questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Question display with shape and answer options
  Widget _buildQuestionSection(ShapeQuestion q) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(28),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F0), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 3,
            color: const Color(0xFF36D399),
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question Text
          Text(
            '❓ ' + q.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Option Buttons in 2x2 grid
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
    
    String emoji = '';
    if (showAsCorrect) emoji = '✅ ';
    if (showAsWrong) emoji = '❌ ';
    
    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: ShapeDecoration(
          gradient: showAsCorrect 
              ? const LinearGradient(
                  colors: [Color(0xFF36D399), Color(0xFF2BC58A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : showAsWrong
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: showAsCorrect || showAsWrong
              ? null
              : (isSelected 
                  ? const Color(0xFF8A38F5)
                  : Colors.white),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 3,
              color: showAsWrong
                  ? const Color(0xFFE53935)
                  : (showAsCorrect
                      ? const Color(0xFF36D399)
                      : (isSelected 
                          ? const Color(0xFF8A38F5) 
                          : const Color(0xFFA349596D))),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            if (isSelected || showAsCorrect)
              BoxShadow(
                color: (showAsCorrect 
                    ? const Color(0xFF36D399) 
                    : const Color(0xFF8A38F5)).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 1,
              maxWidth: MediaQuery.of(context).size.width / 2.5,
            ),
            child: Text(
              emoji + option,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: showAsCorrect || showAsWrong
                    ? Colors.white
                    : (isSelected ? Colors.white : const Color(0xFF2859C5)),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Next button
  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : (_hasAnswered
                ? _nextQuestion
                : (_selectedAnswer != null ? _submitAnswer : null)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: ShapeDecoration(
            gradient: ((_selectedAnswer == null && !_hasAnswered) || _isSubmitting)
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF1AD7F), Color(0xFFFF9A6C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: ((_selectedAnswer == null && !_hasAnswered) || _isSubmitting)
                ? const Color(0xFFCCCCCC)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            shadows: [
              if (_selectedAnswer != null || _hasAnswered)
                BoxShadow(
                  color: const Color(0xFFF1AD7F).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: _isSubmitting
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hasAnswered 
                          ? (_isLastQuestion ? '🎉 Finish Quiz' : '➡️ Next Question') 
                          : '✨ Check Answer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final result = _gameResult!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D4059)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            color: Color(0xFF2D4059),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy/emoji
              Text(
                result.isPassed ? '🏆' : '😊',
                style: const TextStyle(fontSize: 80),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                result.isPassed ? 'Excellent Work!' : 'Keep Practicing!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D4059),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Results card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    // Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${result.score}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D4059),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          '${result.correctAnswers}',
                          'Correct',
                          const Color(0xFF36D399),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          '${result.wrongAnswers}',
                          'Wrong',
                          const Color(0xFFE57A7A),
                        ),
                      ],
                    ),
                    
                    // Show unlock message if passed
                    const SizedBox(height: 20),
                    if (result.isPassed) 
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36D399).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF36D399),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_open,
                              color: Color(0xFF36D399),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Next level unlocked! 🎉',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF36D399),
                              ),
                            ),
                          ],
                        ),
                      )
                    else 
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFA726),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFFFA726),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Get all answers correct to unlock next level!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFFA726),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Icon(
                          index < result.stars
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF36D399),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF36D399),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Games',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF36D399),
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

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
