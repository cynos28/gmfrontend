import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/shape_models.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// Questions2DShapesAPIScreen - API-integrated quiz game for shape questions
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
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D4059)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _gameData?.title ?? 'Shape Quiz',
          style: const TextStyle(
            color: Color(0xFF2D4059),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _gameData!.questions.length,
                      minHeight: 8,
                      color: const Color(0xFF36D399),
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQuestionIndex + 1}/${_gameData!.questions.length}',
                    style: const TextStyle(
                      color: Color(0xFF2D4059),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Question card
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question text
                        Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D4059),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Answer options
                        Column(
                          children: _gameData!.answerPool.map((option) {
                            final isSelected = _selectedAnswer == option;
                            final isCorrect = _hasAnswered && 
                                _gameData!.correctAnswers[q.id] == option;
                            final isWrong = _hasAnswered && 
                                _selectedAnswer == option && 
                                _gameData!.correctAnswers[q.id] != option;

                            Color bg = Colors.white;
                            Color border = Colors.grey.shade300;

                            if (_hasAnswered) {
                              if (isCorrect) {
                                bg = const Color(0xFFE8FFEF);
                                border = const Color(0xFF36D399);
                              } else if (isWrong) {
                                bg = const Color(0xFFFFE8E8);
                                border = const Color(0xFFE57A7A);
                              }
                            } else if (isSelected) {
                              bg = const Color(0xFFF0F8FF);
                              border = const Color(0xFF36D399);
                            }

                            return GestureDetector(
                              onTap: () => _selectAnswer(option),
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: border, width: 1.4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF2D4059),
                                        ),
                                      ),
                                    ),
                                    if (_hasAnswered && isCorrect)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF36D399),
                                      )
                                    else if (_hasAnswered && isWrong)
                                      const Icon(
                                        Icons.cancel,
                                        color: Color(0xFFE57A7A),
                                      )
                                    else if (!_hasAnswered && isSelected)
                                      const Icon(
                                        Icons.radio_button_checked,
                                        color: Color(0xFF36D399),
                                      )
                                    else if (!_hasAnswered)
                                      const Icon(
                                        Icons.radio_button_off,
                                        color: Colors.grey,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action button
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (_hasAnswered
                        ? _nextQuestion
                        : (_selectedAnswer != null ? _submitAnswer : null)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36D399),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _hasAnswered
                            ? (_isLastQuestion ? 'Finish' : 'Next')
                            : 'Check',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 12),
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
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          '${result.totalQuestions}',
                          'Total',
                          const Color(0xFF2D4059),
                        ),
                      ],
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
