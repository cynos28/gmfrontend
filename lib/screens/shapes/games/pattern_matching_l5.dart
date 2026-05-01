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
  
  // Simple pattern: 6 slots with one missing — uses 3D shapes
  final List<_Tile?> _patternSlots = [
    const _Tile(shape: _Shape.cube, color: Color(0xFF2196F3)),
    const _Tile(shape: _Shape.sphere, color: Color(0xFFE91E63)),
    const _Tile(shape: _Shape.cone, color: Color(0xFFFF9800)),
    const _Tile(shape: _Shape.cube, color: Color(0xFF2196F3)),
    null,
    const _Tile(shape: _Shape.cone, color: Color(0xFFFF9800)),
  ];

  final _Tile _correct = const _Tile(shape: _Shape.sphere, color: Color(0xFFE91E63));
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
      const _Tile(shape: _Shape.cube, color: Color(0xFF2196F3)),
      const _Tile(shape: _Shape.cylinder, color: Color(0xFF00BCD4)),
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
  }  @override
  Widget build(BuildContext context) {
    if (_isGameComplete) {
      return _buildCompletionScreen();
    }
    
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
                    _buildPatternGrid(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
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
                const Text(
                  'Pattern Matching',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level 5 • Question $_currentQuestion of $_totalQuestions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$_score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF36D399),
              ),
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
          if (_selected != null && !_revealed)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF9800)),
              tooltip: 'Reset selection',
            ),
        ],
      ),
    );
  }

  Widget _buildPatternGrid() {
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
            children: List.generate(_patternSlots.length, (index) {
              final tile = _patternSlots[index];
              final isMissing = tile == null;
              
              return Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isMissing 
                        ? (_revealed 
                            ? (_isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63))
                            : const Color(0xFF2196F3))
                        : Colors.black12,
                    width: isMissing ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: isMissing
                      ? (_selected != null || _revealed
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildTileWidget(_revealed && !_isCorrect ? _correct : (_selected ?? _correct), size: 45),
                            )
                          : const Text('?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF2196F3))))
                      : Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _buildTileWidget(tile!, size: 45),
                        ),
                ),
              );
            }),
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
          children: _options.map((option) => _buildOptionButton(option)).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionButton(_Tile option) {
    final isSelected = _selected == option;
    final isCorrect = _revealed && option == _correct;
    final isWrong = _revealed && isSelected && !isCorrect;
    
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
      onTap: () => _select(option),
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
              child: _buildTileWidget(option, size: 50),
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

  Widget _buildActionButtons() {
    final bool canInteract = _selected != null || _revealed;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !canInteract 
                ? null 
                : (_revealed && _isCorrect 
                   ? (_currentQuestion >= _totalQuestions ? null : _nextQuestion)
                   : (_revealed ? _reset : _submit)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: canInteract ? 4 : 0,
            ),
            child: Text(
              _revealed 
                  ? (_isCorrect ? (_currentQuestion >= _totalQuestions ? 'Level Complete 🎉' : 'Next Question ➡️') : 'Try Again 🔄') 
                  : 'Check Answer ✨',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (_isSavingProgress) ...[
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
          ),
        ],
      ],
    );
  }

  Widget _buildTileWidget(_Tile tile, {double size = 40}) {
    String assetPath;
    switch (tile.shape) {
      case _Shape.cube:
        assetPath = 'assets/images/3d_shapes/cube.png';
        break;
      case _Shape.sphere:
        assetPath = 'assets/images/3d_shapes/sphere.png';
        break;
      case _Shape.cone:
        assetPath = 'assets/images/3d_shapes/cone.png';
        break;
      case _Shape.cylinder:
        assetPath = 'assets/images/3d_shapes/cylinder.png';
        break;
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _buildFallbackTile(tile, size),
    );
  }

  Widget _buildFallbackTile(_Tile tile, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tile.color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

enum _Shape { cube, sphere, cone, cylinder }

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

  // Completion Screen (Unified)
  Widget _buildCompletionScreen() {
    final stars = _calculateStars();
    final bool isExcellent = _correctAnswers >= _totalQuestions * 0.8;
    
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
                    Container(
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
                            'You finished with a score of $_score!',
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
                                  index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: index < stars ? const Color(0xFFFFC107) : Colors.black26,
                                  size: 48,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Level Complete! 🚀',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('$_correctAnswers', 'Correct', const Color(0xFF4CAF50)),
                          _buildStatItem('${_totalQuestions - _correctAnswers}', 'Wrong', const Color(0xFFE91E63)),
                          _buildStatItem('$_score', 'Score', const Color(0xFF2196F3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _playAgain,
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
