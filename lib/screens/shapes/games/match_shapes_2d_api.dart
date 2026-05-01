import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/shape_models.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';

/// Match2DShapesAPIScreen - API-integrated drag and drop shape matching game
class Match2DShapesAPIScreen extends StatefulWidget {
  final String gameId;
  
  const Match2DShapesAPIScreen({
    super.key,
    this.gameId = 'level1',
  });

  @override
  State<Match2DShapesAPIScreen> createState() => _Match2DShapesAPIScreenState();
}

class _Match2DShapesAPIScreenState extends State<Match2DShapesAPIScreen> {
  final ShapesApiService _apiService = ShapesApiService.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  ShapeMatchingGame? _gameData;
  GameResult? _gameResult;
  
  // Shape slots with their correct answers
  List<Map<String, dynamic>> _shapeSlots = [];
  List<String> _wordPool = [];
  final List<String> _usedWords = [];
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
      
      if (game is! ShapeMatchingGame) {
        throw Exception('Invalid game type. Expected shape matching game.');
      }

      if (!mounted) return;
      
      setState(() {
        _gameData = game;
        _wordPool = List.from(game.wordPool);
        _shapeSlots = game.shapes.map((shape) {
          return {
            'id': shape.id,
            'name': shape.name,
            'imageUrl': shape.imageUrl,
            'correctAnswer': shape.name,
            'answer': null,
            'color': _getColorForIndex(int.parse(shape.id) - 1),
            'borderColor': _getBorderColorForIndex(int.parse(shape.id) - 1),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Helper method to extract correct asset path
  /// Converts backend paths like "assets/images/2d_shapes/circle.png" 
  /// to "assets/images/circle.png" which matches Flutter's actual asset location
  String _getAssetPath(String backendPath) {
    // Check if path already starts with assets/
    if (backendPath.startsWith('assets/')) {
      return backendPath;
    }
    // Otherwise, extract just the filename and use it in assets/images/
    final filename = backendPath.split('/').last;
    return 'assets/images/$filename';
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFC8E6C9), // Green
      const Color(0xFFBBDEFB), // Blue
      const Color(0xFFFFE0B2), // Orange
      const Color(0xFFF8BBD0), // Pink
    ];
    return colors[index % colors.length];
  }

  Color _getBorderColorForIndex(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  void _onWordDropped(String word, int slotIndex) {
    setState(() {
      // Remove word from previous slot if it was already placed
      for (var slot in _shapeSlots) {
        if (slot['answer'] == word) {
          slot['answer'] = null;
          _usedWords.remove(word);
          break;
        }
      }
      
      // Place word in new slot
      _shapeSlots[slotIndex]['answer'] = word;
      if (!_usedWords.contains(word)) {
        _usedWords.add(word);
      }
    });
  }

  Future<void> _submitAnswers() async {
    // Check if all slots are filled
    bool allFilled = true;
    for (var slot in _shapeSlots) {
      if (slot['answer'] == null) {
        allFilled = false;
        break;
      }
    }
    
    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all shapes before submitting!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare answers map
      final answers = <String, String>{};
      for (var slot in _shapeSlots) {
        answers[slot['id']] = slot['answer'];
      }

      final gameAnswer = GameAnswer(
        gameId: widget.gameId,
        answers: answers,
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
      for (var slot in _shapeSlots) {
        slot['answer'] = null;
      }
      _usedWords.clear();
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
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8CA9FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading game...',
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
      backgroundColor: Colors.white,
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
                  backgroundColor: const Color(0xFF8CA9FF),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 20),
                    _buildShapeGrid(),
                    const SizedBox(height: 30),
                    _buildWordPool(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
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
                  _gameData?.title ?? 'Match Shapes',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Match the 2D shapes',
                  style: TextStyle(
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

  Widget _buildShapeGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        spacing: 16,
        children: [
          // Dynamic rows based on number of shapes
          for (int i = 0; i < _shapeSlots.length; i += 2)
            Row(
              spacing: 16,
              children: [
                Expanded(child: _buildShapeSlot(i)),
                if (i + 1 < _shapeSlots.length)
                  Expanded(child: _buildShapeSlot(i + 1)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShapeSlot(int index) {
    final slot = _shapeSlots[index];
    final hasAnswer = slot['answer'] != null;
    
    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (data) => _onWordDropped(data, index),
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: isDraggingOver ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: slot['color'] as Color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  width: isDraggingOver ? 3.0 : 2.0,
                  color: (slot['borderColor'] as Color).withOpacity(isDraggingOver ? 1.0 : 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shape image from backend
                    Expanded(
                      child: Image.asset(
                        _getAssetPath(slot['imageUrl'] as String),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: (slot['borderColor'] as Color).withOpacity(0.5),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Answer box
                    GestureDetector(
                      onTap: hasAnswer ? () {
                        setState(() {
                          _usedWords.remove(slot['answer']);
                          slot['answer'] = null;
                        });
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasAnswer 
                              ? const Color(0xFF2196F3) 
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: hasAnswer ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] : [],
                        ),
                        child: Text(
                          hasAnswer ? slot['answer'] : 'Drop here',
                          style: TextStyle(
                            color: hasAnswer ? Colors.white : Colors.black45,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasAnswer ? 'Tap to remove' : 'Drag name here',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordPool() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          const Text(
            'Names of Shapes',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _wordPool.map((word) => _buildWordButton(word)).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_usedWords.isNotEmpty) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE91E63),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE91E63), width: 2),
                      ),
                    ),
                    child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _usedWords.length == _shapeSlots.length ? _submitAnswers : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Answers', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordButton(String word) {
    final isUsed = _usedWords.contains(word);
    
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isUsed ? Colors.grey.shade100 : const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUsed 
                ? Colors.grey.shade300 
                : const Color(0xFF9C27B0).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: isUsed ? Colors.grey.shade400 : const Color(0xFF9C27B0),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 54,
            offset: Offset(6, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.school, 'Learn', false),
          _buildNavItem(Icons.trending_up, 'Progress', false),
          _buildNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return SizedBox(
      width: 83.50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive 
                ? const Color(0xFF8CA9FF) 
                : const Color(0xA349596D),
          ),
          Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? const Color(0xFF8CA9FF) 
                  : const Color(0xA349596D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    if (_gameResult == null) return const SizedBox();
    
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
                    _buildResultsGrid(),
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
    final isPassed = result.isPassed;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPassed ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
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
            isPassed ? '🎉 Amazing! 🎉' : '😊 Good Effort! 😊',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPassed ? 'You matched all shapes correctly!' : 'Keep practicing to match them all.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('${result.correctAnswers}', 'Correct', const Color(0xFF4CAF50)),
              const SizedBox(width: 40),
              _buildStatItem('${result.wrongAnswers}', 'Wrong', const Color(0xFFE91E63)),
              const SizedBox(width: 40),
              _buildStatItem('${result.score}', 'Score', const Color(0xFF2196F3)),
            ],
          ),
        ],
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

  Widget _buildResultsActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 30,
        alignment: WrapAlignment.center,
        children: List.generate(
          _shapeSlots.length,
          (index) => _buildResultCard(index),
        ),
      ),
    );
  }

  Widget _buildResultCard(int index) {
    final slot = _shapeSlots[index];
    final answer = slot['answer'] as String?;
    final correctAnswer = slot['correctAnswer'] as String;
    final isCorrect = _gameResult?.answerResults[slot['id']] ?? false;
    
    return Container(
      width: 160,
      height: 167,
      decoration: ShapeDecoration(
        color: isCorrect ? Colors.white : const Color(0xFFF5E5E7),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2,
            strokeAlign: BorderSide.strokeAlignCenter,
            color: isCorrect 
                ? const Color(0xFF36D399) 
                : const Color(0xFFD33636),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 12,
            child: SizedBox(
              height: 80,
              child: Image.asset(
                _getAssetPath(slot['imageUrl'] as String),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 60);
                },
              ),
            ),
          ),
          
          Positioned(
            left: 28,
            top: 101,
            child: Container(
              width: 121,
              height: 26,
              decoration: ShapeDecoration(
                color: isCorrect ? const Color(0xFF36D399) : const Color(0xFFD33636),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  answer ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.57,
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            left: 81,
            top: 131,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFF36D399) : const Color(0xFFD33636),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check : Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    final result = _gameResult!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                result.isPassed ? '🎉' : '😊',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 8),
              Text(
                result.isPassed ? 'Great Job!' : 'Keep Trying!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.10,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${result.correctAnswers}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF36D399),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Correct',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xA349596D),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 50),
              
              Column(
                children: [
                  Text(
                    '${result.wrongAnswers}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD33636),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xA349596D),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Score: ${result.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Show unlock message if passed
          if (result.isPassed) ...[
            const SizedBox(height: 16),
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
                children: [
                  const Icon(
                    Icons.lock_open,
                    color: Color(0xFF36D399),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next level unlocked! 🎉',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF36D399),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
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
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFFA726),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get all answers correct to unlock next level!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFFA726),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _resetGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2,
                          color: Color(0xFFF1AD7F),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        Icon(Icons.refresh, color: Color(0xFFF1AD7F), size: 18),
                        Text(
                          'Try Again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF1AD7F),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.57,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF1AD7F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back To Games',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.57,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
