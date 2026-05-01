import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Match2DShapesScreen - Drag and drop shape matching game
class Match2DShapesScreen extends StatefulWidget {
  const Match2DShapesScreen({super.key});

  @override
  State<Match2DShapesScreen> createState() => _Match2DShapesScreenState();
}

class _Match2DShapesScreenState extends State<Match2DShapesScreen> {
  // Shape slots with their correct answers
  final List<Map<String, dynamic>> _shapeSlots = [
    {
      'color': const Color(0xFFC8E6C9), // Green BG
      'borderColor': const Color(0xFF4CAF50), // Green border/icon
      'image': 'assets/images/2d_shapes/circle.png',
      'correctAnswer': 'Circle',
      'answer': null,
    },
    {
      'color': const Color(0xFFBBDEFB), // Blue BG
      'borderColor': const Color(0xFF2196F3), // Blue border/icon
      'image': 'assets/images/2d_shapes/square.png',
      'correctAnswer': 'Square',
      'answer': null,
    },
    {
      'color': const Color(0xFFFFE0B2), // Orange BG
      'borderColor': const Color(0xFFFF9800), // Orange border/icon
      'image': 'assets/images/2d_shapes/triangle.png',
      'correctAnswer': 'Triangle',
      'answer': null,
    },
    {
      'color': const Color(0xFFF8BBD0), // Pink BG
      'borderColor': const Color(0xFFE91E63), // Pink border/icon
      'image': 'assets/images/2d_shapes/rectangle.png',
      'correctAnswer': 'Rectangle',
      'answer': null,
    },
  ];

  final List<String> _wordPool = ['Circle', 'Square', 'Triangle', 'Rectangle'];
  final List<String> _usedWords = [];
  bool _isGameComplete = false;

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
      
      // Check if all correct
      _checkAllCorrect();
    });
  }

  void _checkAllCorrect() {
    // Check if all slots are filled
    bool allFilled = true;
    for (var slot in _shapeSlots) {
      if (slot['answer'] == null) {
        allFilled = false;
        break;
      }
    }
    
    // Don't auto-submit, just track if ready
    if (allFilled && !_isGameComplete) {
      // All slots filled, user can now submit
    }
  }

  void _submitAnswers() {
    // Check if all slots are filled
    bool allFilled = true;
    for (var slot in _shapeSlots) {
      if (slot['answer'] == null) {
        allFilled = false;
        break;
      }
    }
    
    if (!allFilled) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all shapes before submitting!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isGameComplete = true;
    });

    _signalGameCompleted();
  }

  // Utility: safely complete any completer or invoke callbacks (supports nested structures).
  bool _completeAny(Object? obj, {dynamic payload}) {
    try {
      if (obj is Completer && !obj.isCompleted) {
        obj.complete(payload ?? true);
        return true;
      }
      if (obj is void Function()) {
        obj();
        return true;
      }
      if (obj is void Function(dynamic)) {
        obj(payload);
        return true;
      }
      if (obj is Map) {
        var did = false;
        for (final v in obj.values) {
          did = _completeAny(v, payload: payload) || did;
        }
        return did;
      }
      if (obj is Iterable) {
        var did = false;
        for (final v in obj) {
          did = _completeAny(v, payload: payload) || did;
        }
        return did;
      }
    } catch (_) {
      // swallow
    }
    return false;
  }

  Map<String, dynamic> _readyPayload() => {
        'screen': 'match_shapes_2d',
        'ready': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

  void _signalGameReady() {
    final args = Get.arguments;
    final payload = _readyPayload();

    print('🚀 Game ready with payload: $payload');
    print('📦 Arguments received: ${args.runtimeType}');

    if (_completeAny(args, payload: payload)) {
      print('✅ Successfully signaled ready via arguments');
      return;
    }

    if (args is Map) {
      print('📋 Checking map keys: ${args.keys.toList()}');
      final keys = [
        'readyCompleter',
        'startCompleter',
        'initCompleter',
        'initializedCompleter',
        'loaderCompleter',
        'gameCompleter',
        'completer',
        'onReady',
        'onStart',
        'onInitialized',
        'onGameReady',
        'loader',
        'start',
        'ready',
        'init',
      ];
      for (final k in keys) {
        if (args.containsKey(k)) {
          print('🔑 Found key: $k');
          if (_completeAny(args[k], payload: payload)) {
            print('✅ Successfully completed via key: $k');
            return;
          }
        }
      }
      
      final loader = args['loader'];
      if (loader != null) {
        print('🔄 Trying nested loader: ${loader.runtimeType}');
        if (_completeAny(loader, payload: payload)) {
          print('✅ Successfully completed via loader');
          return;
        }
        if (loader is Map) {
          for (final v in loader.values) {
            if (_completeAny(v, payload: result)) {
              print('✅ Successfully completed via loader value');
              return;
            }
          }
        }
      }
    }
    
    print('⚠️ No ready handler found - continuing without backend signal');
  }

  void _signalGameCompleted() {
    final result = {
      'correct': _getCorrectCount(),
      'wrong': _getWrongCount(),
      'total': _shapeSlots.length,
      'screen': 'match_shapes_2d',
      'completed': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // First, try to complete via Get.arguments (API wrapper pattern)
    final args = Get.arguments;
    
    // Log for debugging
    print('🎮 Game completed with result: $result');
    print('📦 Arguments received: ${args.runtimeType}');
    
    if (_completeAny(args, payload: result)) {
      print('✅ Successfully signaled completion via arguments');
      return;
    }

    if (args is Map) {
      print('📋 Checking map keys: ${args.keys.toList()}');
      final keys = [
        'resultCompleter',
        'completeCompleter',
        'completionCompleter',
        'gameCompleter',
        'onComplete',
        'onResult',
        'onGameComplete',
        'completer',
        'callback',
        'loader',
      ];
      for (final k in keys) {
        if (args.containsKey(k)) {
          print('🔑 Found key: $k');
          if (_completeAny(args[k], payload: result)) {
            print('✅ Successfully completed via key: $k');
            return;
          }
        }
      }
      
      // Try nested loader map
      final loader = args['loader'];
      if (loader != null) {
        print('🔄 Trying nested loader: ${loader.runtimeType}');
        if (_completeAny(loader, payload: result)) {
          print('✅ Successfully completed via loader');
          return;
        }
        if (loader is Map) {
          for (final v in loader.values) {
            if (_completeAny(v, payload: result)) {
              print('✅ Successfully completed via loader value');
              return;
            }
          }
        }
      }
    }
    
    print('⚠️ No completion handler found - game completed but not signaled');
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

  int _getWrongCount() {
    return _shapeSlots.length - _getCorrectCount();
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _signalGameReady());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 393.0 : screenWidth - 32;

    // Show results screen if game is complete
    if (_isGameComplete) {
      return _buildResultsScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Header with back button and title
                    _buildAppBar(),
                    
                    const SizedBox(height: 20),
                    
                    // 2x2 Grid of shape slots
                    _buildShapeGrid(),
                    
                    const SizedBox(height: 30),
                    
                    // Word Pool section
                    _buildWordPool(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // Bottom Navigation Bar
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

  // App bar with back button and title
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level 1',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
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

  // 2x2 grid of shape drop zones
  Widget _buildShapeGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        spacing: 16,
        children: [
          // First row
          Row(
            spacing: 16,
            children: [
              Expanded(child: _buildShapeSlot(0)),
              Expanded(child: _buildShapeSlot(1)),
            ],
          ),
          // Second row
          Row(
            spacing: 16,
            children: [
              Expanded(child: _buildShapeSlot(2)),
              Expanded(child: _buildShapeSlot(3)),
            ],
          ),
        ],
      ),
    );
  }

  // Individual shape slot with drag target
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
                    // Shape icon
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          slot['image'] as String,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported_rounded,
                            size: 100,
                            color: (slot['borderColor'] as Color).withOpacity(0.5),
                          ),
                        ),
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
                              ? (isCorrect 
                                  ? const Color(0xFF4CAF50) 
                                  : const Color(0xFFE91E63))
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasAnswer ? slot['answer'] : 'Drop here',
                              style: TextStyle(
                                color: hasAnswer ? Colors.white : Colors.black45,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (hasAnswer) ...[
                              const SizedBox(width: 6),
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasAnswer ? 'Tap to remove' : 'Drag name here',
                      style: TextStyle(
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
  // Word pool section with draggable words
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
            textAlign: TextAlign.center,
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
                  child: ElevatedButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Reset'),
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
                    elevation: 4,
                    shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit Answers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build individual word button
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
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 5),
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
          color: isUsed ? Colors.grey.shade100 : const Color(0xFFE1BEE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUsed ? Colors.grey.shade300 : const Color(0xFF9C27B0).withOpacity(0.3),
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


  // Bottom navigation bar
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

  // Individual navigation item
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Container(
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

  // Results screen after game completion
  Widget _buildResultsScreen() {
    final correctCount = _getCorrectCount();
    final wrongCount = _getWrongCount();
    
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
                    const SizedBox(height: 10),
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
            isPerfect ? '🎉 Amazing! 🎉' : '😊 Good Effort! 😊',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You got $correctCount out of $totalCount shapes correct!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
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

  // Results grid showing all shapes with correct/wrong indicators
  Widget _buildResultsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        spacing: 30,
        children: [
          // First row - 2 shapes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              _buildResultCard(0),
              _buildResultCard(1),
            ],
          ),
          // Second row - 2 shapes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              _buildResultCard(2),
              _buildResultCard(3),
            ],
          ),
        ],
      ),
    );
  }

  // Build individual result card
  Widget _buildResultCard(int index) {
    final slot = _shapeSlots[index];
    final answer = slot['answer'] as String?;
    final correctAnswer = slot['correctAnswer'] as String;
    final isCorrect = answer == correctAnswer;
    
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slot['color'] as Color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
          width: 3,
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer ?? 'None',
              style: TextStyle(
                color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE91E63),
            size: 24,
          ),
        ],
      ),
    );
  }

  // Build shape icon for results
  Widget _buildResultShapeIcon(IconData icon, bool isCorrect) {
    Color shapeColor;
    if (icon == Icons.circle) {
      shapeColor = const Color(0xFFD753DD);
    } else if (icon == Icons.square_rounded) {
      shapeColor = const Color(0xFF3C8FF5);
    } else if (icon == Icons.change_history) {
      shapeColor = const Color(0xFFD4D047);
    } else {
      shapeColor = const Color(0xFFD4D047);
    }
    
    return Icon(
      icon,
      size: 80,
      color: shapeColor,
    );
  }

  // Results card with score and back button
  Widget _buildResultsCard(int correctCount, int wrongCount) {
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
          // Title with emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                correctCount >= 3 ? '🎉' : '😊',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 8),
              Text(
                correctCount >= 3 ? 'Great Job!' : 'Keep Trying!',
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
          
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Correct score
              Column(
                children: [
                  Text(
                    '$correctCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF36D399),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xA349596D),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 50),
              
              // Wrong score
              Column(
                children: [
                  Text(
                    '$wrongCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD33636),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xA349596D),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Buttons row
          Row(
            spacing: 12,
            children: [
              // Reset button
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: Color(0xFFF1AD7F),
                          size: 18,
                        ),
                        const Text(
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
              
              // Back to Games button
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

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
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
