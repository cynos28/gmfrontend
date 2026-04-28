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

  /// Maps backend image paths to real local asset paths.
  /// The patterns/3d_shapes folder contains stub files — redirect to the
  /// real 3D images in assets/images/3d_shapes/ instead.
  String _getAssetPath(String backendPath) {
    if (backendPath.isEmpty) return '';

    // For level6 (3D pattern matching), always use the real 3D shape images
    if (widget.gameId == 'level6') {
      final filename = backendPath.split('/').last; // e.g. "cube.png"
      return 'assets/images/3d_shapes/$filename';
    }

    // For level5 (2D pattern matching), use the 2D pattern images
    if (backendPath.startsWith('assets/')) return backendPath;
    final filename = backendPath.split('/').last;
    return 'assets/images/patterns/2d_shapes/$filename';
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
                'Failed to load game',
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

  Widget _buildGameScreen() {
    final q = _currentPattern;
    
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
                    _buildPatternSection(q),
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
                  _gameData?.title ?? 'Pattern Matching',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pattern ${_currentPatternIndex + 1} of ${_gameData?.patterns.length ?? 0}',
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
            child: const Icon(Icons.extension_rounded, color: Color(0xFF2196F3), size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Complete the pattern!',
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

  Widget _buildPatternSection(PatternData pattern) {
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: pattern.sequence.asMap().entries.map((entry) {
              final shape = entry.value;
              
              if (shape == null) {
                return Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _hasAnswered 
                        ? (pattern.correctAnswer.name == _userAnswers[pattern.id] 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFE91E63))
                        : const Color(0xFF2196F3),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: _hasAnswered
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            _getAssetPath(pattern.correctAnswer.imageUrl),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Text(
                          '?',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                  ),
                );
              }
              
              return Container(
                width: 65,
                height: 65,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: Image.asset(
                  _getAssetPath(shape.imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        shape.name[0],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildOptionsSection(),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final pattern = _currentPattern;
    
    return Column(
      children: [
        const Text(
          'Choose the next shape:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: pattern.options.map((option) => _buildOptionButton(option, pattern)).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionButton(ShapeData option, PatternData pattern) {
    final isSelected = _selectedAnswer == option.name;
    final isCorrect = _hasAnswered && option.name == pattern.correctAnswer.name;
    final isWrong = _hasAnswered && isSelected && !isCorrect;
    
    Color borderColor;
    Color bgColor;
    
    if (isCorrect) {
      borderColor = const Color(0xFF4CAF50);
      bgColor = const Color(0xFFE8F5E9);
    } else if (isWrong) {
      borderColor = const Color(0xFFE91E63);
      bgColor = const Color(0xFFFCE4EC);
    } else if (isSelected) {
      borderColor = const Color(0xFF2196F3);
      bgColor = const Color(0xFFBBDEFB);
    } else {
      borderColor = Colors.black12;
      bgColor = const Color(0xFFF8F9FA);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(option.name),
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isSelected || isCorrect || isWrong ? [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                _getAssetPath(option.imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    option.name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (isCorrect)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
              ),
            if (isWrong)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.cancel, color: Color(0xFFE91E63), size: 20),
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
          : (_hasAnswered ? _nextPattern : _submitAnswer),
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
                    ? (_isLastPattern ? 'Finish Game 🎉' : 'Next Pattern ➡️') 
                    : 'Check Answer ✨',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _buildResultsScreen() {
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
    final bool isExcellent = result.correctAnswers >= (_gameData?.patterns.length ?? 0) * 0.8;
    
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
            'You finished with a score of ${result.score}!',
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
          if (result.isPassed) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Next level unlocked! 🚀',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
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
