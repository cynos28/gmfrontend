import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:ganithamithura/models/shape_models.dart';
/// Match3DShapesScreen - Drag and drop 3D shape matching game
class Match3DShapesScreen extends StatefulWidget {
  const Match3DShapesScreen({super.key});

  @override
  State<Match3DShapesScreen> createState() => _Match3DShapesScreenState();
}

class _Match3DShapesScreenState extends State<Match3DShapesScreen> {
  // Shape slots with their correct answers
  final List<Map<String, dynamic>> _shapeSlots = [
    {
      'color': const Color(0xFFC8E6C9), // Green
      'borderColor': const Color(0xFF4CAF50),
      'image': 'assets/images/3d_shapes/sphere.png',
      'correctAnswer': 'Sphere',
      'answer': null,
    },
    {
      'color': const Color(0xFFBBDEFB), // Blue
      'borderColor': const Color(0xFF2196F3),
      'image': 'assets/images/3d_shapes/cube.png',
      'correctAnswer': 'Cube',
      'answer': null,
    },
    {
      'color': const Color(0xFFFFE0B2), // Orange
      'borderColor': const Color(0xFFFF9800),
      'image': 'assets/images/3d_shapes/cone.png',
      'correctAnswer': 'Cone',
      'answer': null,
    },
    {
      'color': const Color(0xFFF8BBD0), // Pink
      'borderColor': const Color(0xFFE91E63),
      'image': 'assets/images/3d_shapes/cylinder.png',
      'correctAnswer': 'Cylinder',
      'answer': null,
    },
  ];

  final List<String> _wordPool = ['Sphere', 'Cube', 'Cone', 'Cylinder'];
  final List<String> _usedWords = [];
  bool _isGameComplete = false;

  void _onWordDropped(String word, int slotIndex) {
    setState(() {
      for (var slot in _shapeSlots) {
        if (slot['answer'] == word) {
          slot['answer'] = null;
          _usedWords.remove(word);
          break;
        }
      }
      
      _shapeSlots[slotIndex]['answer'] = word;
      if (!_usedWords.contains(word)) {
        _usedWords.add(word);
      }
    });
  }

  void _submitAnswers() {
    if (_usedWords.length < _shapeSlots.length) {
      Get.snackbar(
        'Incomplete',
        'Please match all shapes before submitting!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isGameComplete = true;
    });

    _submitToBackend();
  }

  Future<void> _submitToBackend() async {
    try {
      // Backend level3 correct_answers = {shape_id: shape_name}
      // shape_ids match the order: Sphere=2, Cube=1, Cone=3, Cylinder=4
      const shapeIdMap = {
        'Sphere': '2',
        'Cube': '1',
        'Cone': '3',
        'Cylinder': '4',
      };

      final answersMap = <String, String>{};
      for (final slot in _shapeSlots) {
        final shapeName = slot['correctAnswer'] as String;
        final id = shapeIdMap[shapeName] ?? shapeName;
        answersMap[id] = slot['answer'] as String? ?? '';
      }

      await ShapesApiService.instance.checkAnswers(
        GameAnswer(gameId: 'level3', answers: answersMap),
      );
    } catch (e) {
      print('Level 3 score submission error: $e');
    }

    _signalGameCompleted();
  }

  void _signalGameCompleted() {
    final result = {
      'correct': _getCorrectCount(),
      'total': _shapeSlots.length,
      'screen': 'match_shapes_3d',
      'completed': true,
    };
    
    final args = Get.arguments;
    if (args != null && args is Map && args.containsKey('resultCompleter')) {
      (args['resultCompleter'] as Completer).complete(result);
    }
  }

  int _getCorrectCount() {
    int correct = 0;
    for (var slot in _shapeSlots) {
      if (slot['answer'] == slot['correctAnswer']) {
        correct++;
      }
    }
    return correct;
  }

  void _resetGame() {
    setState(() {
      for (var slot in _shapeSlots) {
        slot['answer'] = null;
      }
      _usedWords.clear();
      _isGameComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameComplete) {
      return _buildResultsScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    _buildShapeGrid(),
                    const SizedBox(height: 30),
                    _buildWordPool(),
                  ],
                ),
              ),
            ),
          ],
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
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level 3',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1),
                ),
                SizedBox(height: 4),
                Text(
                  'Match the 3D shapes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildShapeSlot(0)),
              const SizedBox(width: 16),
              Expanded(child: _buildShapeSlot(1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildShapeSlot(2)),
              const SizedBox(width: 16),
              Expanded(child: _buildShapeSlot(3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeSlot(int index) {
    final slot = _shapeSlots[index];
    final hasAnswer = slot['answer'] != null;
    final isCorrect = hasAnswer && slot['answer'] == slot['correctAnswer'];
    
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
              height: 200,
              decoration: BoxDecoration(
                color: slot['color'] as Color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(
                  width: isDraggingOver ? 3.0 : 2.0,
                  color: (slot['borderColor'] as Color).withOpacity(isDraggingOver ? 1.0 : 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        slot['image'] as String,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_rounded,
                            size: 80,
                            color: (slot['borderColor'] as Color).withOpacity(0.5),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: hasAnswer ? () {
                      setState(() {
                        _usedWords.remove(slot['answer']);
                        slot['answer'] = null;
                      });
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasAnswer 
                            ? (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63))
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
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
                ],
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Names of 3D Shapes',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800),
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
                  child: const Text('Submit Answers', style: TextStyle(fontWeight: FontWeight.w800)),
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
          ),
          child: Text(word, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
        child: Text(word, style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isUsed ? Colors.grey.shade100 : const Color(0xFFE1BEE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUsed ? Colors.grey.shade300 : const Color(0xFF9C27B0).withOpacity(0.3), width: 2),
        ),
        child: Text(word, style: TextStyle(color: isUsed ? Colors.grey.shade400 : const Color(0xFF9C27B0), fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final correctCount = _getCorrectCount();
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
                    _buildResultsSummary(correctCount, totalCount: _shapeSlots.length),
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

  Widget _buildResultsSummary(int correctCount, {required int totalCount}) {
    final bool isPerfect = correctCount == totalCount;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPerfect ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(isPerfect ? '🎉 Amazing! 🎉' : '😊 Good Effort! 😊', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('You got $correctCount out of $totalCount shapes correct!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildResultCard(0)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard(1)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildResultCard(2)),
            const SizedBox(width: 16),
            Expanded(child: _buildResultCard(3)),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(int index) {
    final slot = _shapeSlots[index];
    final isCorrect = slot['answer'] == slot['correctAnswer'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slot['color'] as Color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63), width: 3),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Image.asset(
              slot['image'] as String,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_rounded,
                size: 40,
                color: (slot['borderColor'] as Color).withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(slot['answer'] ?? 'None', style: TextStyle(color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63), fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63), size: 24),
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
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF2196F3), width: 2)),
            ),
            child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Go Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
