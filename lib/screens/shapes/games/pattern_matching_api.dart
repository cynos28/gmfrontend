import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/shape_models.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// PatternMatchingAPIScreen - API-integrated pattern matching game
class PatternMatchingAPIScreen extends StatefulWidget {
  final String gameId;
  
  const PatternMatchingAPIScreen({
    super.key,
    this.gameId = 'level5',
  });

  @override
  State<PatternMatchingAPIScreen> createState() =>
      _PatternMatchingAPIScreenState();
}

class _PatternMatchingAPIScreenState extends State<PatternMatchingAPIScreen> {
  final ShapesApiService _apiService = ShapesApiService.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  PatternMatchingGame? _gameData;
  GameResult? _gameResult;
  
  int _currentPatternIndex = 0;
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
      
      if (game is! PatternMatchingGame) {
        throw Exception('Invalid game type. Expected pattern matching game.');
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

  /// Helper method to extract correct asset path
  String _getAssetPath(String backendPath) {
    // Check if path already starts with assets/
    if (backendPath.startsWith('assets/')) {
      return backendPath;
    }
    // Otherwise, extract just the filename and use it in assets/images/
    final filename = backendPath.split('/').last;
    return 'assets/images/$filename';
  }

  PatternData get _currentPattern => _gameData!.patterns[_currentPatternIndex];
  bool get _hasAnswered => _userAnswers.containsKey(_currentPattern.id);
  bool get _isLastPattern => _currentPatternIndex == _gameData!.patterns.length - 1;

  void _selectAnswer(String shapeName) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswer = shapeName;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    setState(() {
      _userAnswers[_currentPattern.id] = _selectedAnswer!;
    });
  }

  void _nextPattern() {
    if (_currentPatternIndex < _gameData!.patterns.length - 1) {
      setState(() {
        _currentPatternIndex++;
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
      _currentPatternIndex = 0;
      _selectedAnswer = null;
      _userAnswers.clear();
      _gameResult = null;
    });
  }

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

    return _buildGameScreen();
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
              'Loading pattern game...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
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
                'Failed to load game',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36D399),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

  Widget _buildGameScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 393.0 : screenWidth - 32;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: cardWidth,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xF2F9F9F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildProgressBar(),
                        const SizedBox(height: 20),
                        _buildPatternDisplay(),
                        const SizedBox(height: 30),
                        _buildOptionsSection(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: const ShapeDecoration(
        color: Color(0xFFAAD6FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 31,
              height: 31,
              decoration: ShapeDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _gameData?.title ?? 'Pattern Matching',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentPatternIndex + 1) / _gameData!.patterns.length,
              minHeight: 8,
              color: const Color(0xFF36D399),
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_currentPatternIndex + 1}/${_gameData!.patterns.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternDisplay() {
    final pattern = _currentPattern;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Complete the pattern:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pattern sequence
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: pattern.sequence.asMap().entries.map((entry) {
              final index = entry.key;
              final shape = entry.value;
              
              if (shape == null) {
                // Missing shape slot
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFFF6B6B),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                );
              }
              
              // Filled shape slot
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  _getAssetPath(shape.imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Failed to load pattern image: ${shape.imageUrl}');
                    return const Icon(Icons.image_not_supported, size: 32);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final pattern = _currentPattern;
    final correctAnswer = _hasAnswered ? pattern.correctAnswer.name : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Choose the missing shape:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: pattern.options.map((option) {
              final isSelected = _selectedAnswer == option.name;
              final isCorrect = _hasAnswered && option.name == correctAnswer;
              final isWrong = _hasAnswered && isSelected && !isCorrect;
              
              Color borderColor = Colors.grey.shade300;
              Color bgColor = Colors.white;
              
              if (_hasAnswered) {
                if (isCorrect) {
                  borderColor = const Color(0xFF36D399);
                  bgColor = const Color(0xFFE8FFEF);
                } else if (isWrong) {
                  borderColor = const Color(0xFFE57A7A);
                  bgColor = const Color(0xFFFFE8E8);
                }
              } else if (isSelected) {
                borderColor = const Color(0xFF36D399);
                bgColor = const Color(0xFFF0F8FF);
              }
              
              return GestureDetector(
                onTap: () => _selectAnswer(option.name),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            _getAssetPath(option.imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Failed to load option image: ${option.imageUrl}');
                              return const Icon(Icons.image_not_supported, size: 32);
                            },
                          ),
                        ),
                      ),
                      if (_hasAnswered && isCorrect)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF36D399),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (_hasAnswered && isWrong)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE57A7A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 12,
        children: [
          if (_hasAnswered)
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextPattern,
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
                        _isLastPattern ? 'Finish' : 'Next Pattern',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36D399),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final result = _gameResult!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                result.isPassed ? '🌟' : '💪',
                style: const TextStyle(fontSize: 80),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                result.isPassed ? 'Amazing!' : 'Good Try!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 40),
              
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
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          '${result.correctAnswers}',
                          'Correct',
                          const Color(0xFF36D399),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatColumn(
                          '${result.wrongAnswers}',
                          'Wrong',
                          const Color(0xFFE57A7A),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                        'Play Again',
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

  Widget _buildStatColumn(String value, String label, Color color) {
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
