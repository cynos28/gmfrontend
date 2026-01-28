import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:ganithamithura/models/shape_models.dart';

class PatternMatchingL5Screen extends StatefulWidget {
  const PatternMatchingL5Screen({Key? key}) : super(key: key);

  @override
  State<PatternMatchingL5Screen> createState() =>
      _PatternMatchingL5ScreenState();
}

class _PatternMatchingL5ScreenState extends State<PatternMatchingL5Screen> {
  // API Service
  final _apiService = ShapesApiService.instance;
  
  // Simple pattern: 6 slots with one missing
  final List<_Tile?> _patternSlots = [
    const _Tile(shape: _Shape.circle, color: Color(0xFFFF6B6B)),
    const _Tile(shape: _Shape.square, color: Color(0xFF4ECDC4)),
    const _Tile(shape: _Shape.triangle, color: Color(0xFFFFE66D)),
    const _Tile(shape: _Shape.circle, color: Color(0xFFFF6B6B)),
    null, 
    const _Tile(shape: _Shape.triangle, color: Color(0xFFFFE66D)),
  ];

  final _Tile _correct = const _Tile(shape: _Shape.square, color: Color(0xFF4ECDC4));
  late List<_Tile> _options;
  _Tile? _selected;
  bool _revealed = false;
  bool _isCorrect = false;
  int _score = 0;
  int _currentQuestion = 1;
  final int _totalQuestions = 5;
  bool _isGameComplete = false;
  int _correctAnswers = 0;
  
  // Track answers for backend submission
  final Map<String, String> _userAnswers = {};
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _options = [
      _correct,
      const _Tile(shape: _Shape.square, color: Color(0xFFFF6B6B)),
      const _Tile(shape: _Shape.circle, color: Color(0xFF4ECDC4)),
    ];
    _options.shuffle();
  }

  void _select(_Tile tile) {
    if (_revealed) return;
    setState(() => _selected = tile);
  }

  void _submit() {
    if (_selected == null) return;
    setState(() {
      _revealed = true;
      _isCorrect = _selected == _correct;
      if (_isCorrect) {
        _score += 10;
        _correctAnswers++;
      }
      
      // Save answer for backend submission
      _userAnswers['pattern_$_currentQuestion'] = _selected!.shape.toString().split('.').last;
    });
    
    // Auto advance after delay or show completion
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      if (_currentQuestion >= _totalQuestions) {
        setState(() {
          _isGameComplete = true;
        });
        // Save progress to backend
        _saveProgressToBackend();
      } else if (_isCorrect) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selected = null;
      _revealed = false;
      _isCorrect = false;
      _options.shuffle();
      // In a real app, you'd load a new pattern here
    });
  }

  void _reset() {
    setState(() {
      _selected = null;
      _revealed = false;
      _isCorrect = false;
      _options.shuffle();
    });
  }

  void _playAgain() {
    setState(() {
      _currentQuestion = 1;
      _score = 0;
      _correctAnswers = 0;
      _selected = null;
      _revealed = false;
      _isCorrect = false;
      _isGameComplete = false;
      _userAnswers.clear();
      _options.shuffle();
    });
  }
  
  /// Save progress to backend database
  Future<void> _saveProgressToBackend() async {
    if (_isSavingProgress) return;
    
    setState(() {
      _isSavingProgress = true;
    });
    
    try {
      // Create game answer object
      final gameAnswer = GameAnswer(
        gameId: 'level5',
        answers: _userAnswers,
      );
      
      // Submit to backend
      final result = await _apiService.checkAnswers(gameAnswer);
      
      print('✅ Progress saved successfully!');
      print('   Score: ${result.score}/${result.totalQuestions}');
      print('   Status: ${result.isPassed ? "PASSED" : "FAILED"}');
      print('   Stars: ${result.stars}');
      
      // Show success message
      if (result.isPassed) {
        Get.snackbar(
          'Progress Saved!',
          'Your score: ${result.score}/${result.totalQuestions} (${result.stars} stars)',
          backgroundColor: const Color(0xFF36D399),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Error saving progress: $e');
      Get.snackbar(
        'Save Failed',
        'Could not save progress. Please check your connection.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isSavingProgress = false;
      });
    }
  }

  int _calculateStars() {
    if (_score >= 40) return 3; // 4-5 correct
    if (_score >= 20) return 2; // 2-3 correct
    return 1; // 1 correct
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 393.0 : screenWidth - 32;
    
    // Show completion screen if game is complete
    if (_isGameComplete) {
      return _buildCompletionScreen(context, cardWidth);
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Main game container
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
                        // Header with title, back button, score, and instructions
                        _buildHeader(),
                        
                        const SizedBox(height: 10),
                        
                        // Pattern Display Section
                        _buildPatternSection(),
                        
                        const SizedBox(height: 10),
                        
                        // Feedback Section (shown after submit)
                        if (_revealed) _buildFeedback(),
                        if (_revealed) const SizedBox(height: 10),
                        
                        // Options Section
                        _buildOptionsSection(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Progress Section (between container and buttons)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: (screenWidth - cardWidth) / 2 + 15),
                  child: _buildProgressSection(),
                ),
                const SizedBox(height: 18),

                // Submit / Next / Reset buttons (below the frame)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: (screenWidth - cardWidth) / 2 + 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selected == null
                              ? null
                              : _revealed && _isCorrect
                                  ? (_currentQuestion >= _totalQuestions ? null : _nextQuestion)
                                  : (_revealed ? _reset : _submit),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _revealed && _isCorrect
                                ? const Color(0xFF33AE2F)
                                : const Color(0xFF36D399),
                            disabledBackgroundColor: const Color(0xFFCCCCCC),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _revealed && _isCorrect
                                ? 'Next'
                                : (_revealed ? 'Try Again' : 'Submit'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (!_revealed) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF36D399)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Color(0xFF36D399),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header with back button, title, score, and instructions
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 31,
                  height: 31,
                  decoration: ShapeDecoration(
                    color: const Color(0x7FD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF2D4059),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Level 5: Pattern Matching',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Be Vietnam Pro',
                    fontWeight: FontWeight.w300,
                    height: 1.47,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 21,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF1EF96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontFamily: 'Be Vietnam Pro',
                      fontWeight: FontWeight.w300,
                      height: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag and drop the missing shape to complete the pattern!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontFamily: 'Be Vietnam Pro',
              fontWeight: FontWeight.w300,
              height: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Pattern display with slots - improved layout
  Widget _buildPatternSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Pattern slots in a single row with responsive sizing
          SizedBox(
            height: 43,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_patternSlots.length, (index) {
                final tile = _patternSlots[index];
                final isMissing = tile == null;
                
                return Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 5 : 0),
                  child: Container(
                    width: 45,
                    height: 43,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFAF9F9),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 3,
                          color: isMissing 
                              ? (_revealed && _isCorrect 
                                  ? const Color(0xFF33AE2F) 
                                  : const Color(0xFFB09696))
                              : const Color(0xFFB09696),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: tile != null
                        ? Center(child: _buildTileWidget(tile, size: 30))
                        : Center(
                            child: _revealed && _selected != null
                                ? _buildTileWidget(_selected!, size: 30)
                                : Icon(
                                    Icons.help_outline,
                                    color: const Color(0xFFB09696),
                                    size: 24,
                                  ),
                          ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Feedback section
  Widget _buildFeedback() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: ShapeDecoration(
        color: _isCorrect 
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect 
                ? const Color(0xFF33AE2F)
                : const Color(0xFFE53935),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect 
                  ? 'Great job! That\'s correct!' 
                  : 'Not quite right. Try again!',
              style: TextStyle(
                color: _isCorrect 
                    ? const Color(0xFF33AE2F)
                    : const Color(0xFFE53935),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Options section - with improved styling
  Widget _buildOptionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Click or drag a shape',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF273343),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_options.length, (i) {
              final option = _options[i];
              final isSelected = _selected == option;
              
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: i == 1 ? 22 : 0),
                child: GestureDetector(
                  onTap: _revealed ? null : () => _select(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 52,
                    decoration: ShapeDecoration(
                      color: isSelected 
                          ? const Color(0xFFE8F5E9)
                          : const Color(0x00EAE7E7),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 3,
                          color: isSelected
                              ? const Color(0xFF36D399)
                              : const Color(0xFFB09696),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: _buildTileWidget(option, size: 35),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Progress section - with matching design
  Widget _buildProgressSection() {
    final progress = _currentQuestion / _totalQuestions;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF273343),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_currentQuestion/$_totalQuestions',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 14,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFA68F8F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Widget _buildTileWidget(_Tile tile, {double size = 40}) {
    switch (tile.shape) {
      case _Shape.circle:
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: tile.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      case _Shape.square:
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: tile.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      case _Shape.triangle:
        return Center(
          child: CustomPaint(
            size: Size(size, size),
            painter: _TrianglePainter(color: tile.color),
          ),
        );
      case _Shape.rectangle:
        return Center(
          child: Container(
            width: size,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: tile.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
    }
  }
}

enum _Shape { circle, square, triangle, rectangle }

class _Tile {
  final _Shape shape;
  final Color color;
  const _Tile({required this.shape, required this.color});

  @override
  bool operator ==(Object other) {
    return other is _Tile &&
        other.shape == shape &&
        other.color.value == color.value;
  }

  @override
  int get hashCode => shape.hashCode ^ color.value.hashCode;
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

extension on _PatternMatchingL5ScreenState {
  // Completion Screen
  Widget _buildCompletionScreen(BuildContext context, double cardWidth) {
    final stars = _calculateStars();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: cardWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      // Trophy/Success Image
                      Container(
                        width: 184,
                        height: 187,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 120,
                          color: Color(0xFFF5C53D),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Level Complete!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF604141),
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        _score == _totalQuestions * 10 ? 'Perfect!' : 'Great Job!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF5C53D),
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Star Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Icon(
                            index < stars ? Icons.star : Icons.star_border,
                            color: const Color(0xFFF5C53D),
                            size: 40,
                          );
                        }),
                      ),
                      
                      // Saving Progress Indicator
                      if (_isSavingProgress) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36D399)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Saving progress...',
                              style: TextStyle(
                                color: Color(0xFF36D399),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Score Card
                      Container(
                        width: cardWidth - 54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0x19927777),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your Score',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_score',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 50,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 27),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFECEAEA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$_correctAnswers/$_totalQuestions',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF43D70D),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Patterns',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF48C622),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF1F0F0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$stars/3',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF614A0C),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Stars',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF1D1C19),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Play Again Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 27),
                        child: GestureDetector(
                          onTap: _playAgain,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF1AD7F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.replay,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Play again',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Back to Home Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 27),
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFA6ADED),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.home,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Back to home',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
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
}
