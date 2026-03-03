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
      'color': const Color(0x3DCB45D0),
      'borderColor': const Color(0xFFBF41CB),
      'icon': Icons.circle,
      'correctAnswer': 'Circle',
      'answer': null,
    },
    {
      'color': const Color(0x3D5B96E5),
      'borderColor': const Color(0xFF5690E1),
      'icon': Icons.square_rounded,
      'correctAnswer': 'Square',
      'answer': null,
    },
    {
      'color': const Color(0x3DBCA43E),
      'borderColor': const Color(0xFFCDAF42),
      'icon': Icons.change_history,
      'correctAnswer': 'Triangle',
      'answer': null,
    },
    {
      'color': const Color(0x3D22B941),
      'borderColor': const Color(0xFF37D55D),
      'icon': Icons.rectangle_rounded,
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
      backgroundColor: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Level 1 - Match Shapes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.10,
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
        
        return Container(
          height: 200,
          decoration: ShapeDecoration(
            color: isDraggingOver 
                ? (slot['color'] as Color).withOpacity(0.7)
                : slot['color'] as Color,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: isDraggingOver ? 2.5 : 1.5,
                color: slot['borderColor'] as Color,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                // Shape icon
                Icon(
                  slot['icon'] as IconData,
                  size: 100,
                  color: (slot['borderColor'] as Color).withOpacity(0.8),
                ),
                
                // Answer box
                GestureDetector(
                  onTap: hasAnswer ? () {
                    setState(() {
                      _usedWords.remove(slot['answer']);
                      slot['answer'] = null;
                    });
                  } : null,
                  child: Container(
                    width: 107,
                    height: 26,
                    decoration: ShapeDecoration(
                      color: hasAnswer 
                          ? (isCorrect 
                              ? const Color(0xFF36D399) 
                              : const Color(0xFFA6ADED))
                          : const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: hasAnswer
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot['answer'],
                                  style: TextStyle(
                                    color: isCorrect ? Colors.white : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isCorrect) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                
                // Drop here text
                Text(
                  isDraggingOver ? 'Drop here!' : (hasAnswer ? 'Tap to remove' : 'Drop here'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withOpacity(hasAnswer ? 0.3 : 0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Word pool section with draggable words
  Widget _buildWordPool() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 7,
            offset: Offset(0, 3),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Word Pool',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.29,
            ),
          ),
          const SizedBox(height: 20),
          
          // Word buttons in 2x2 grid - First row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              _buildWordButton(_wordPool[0]),
              _buildWordButton(_wordPool[1]),
            ],
          ),
          const SizedBox(height: 16),
          
          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              _buildWordButton(_wordPool[2]),
              _buildWordButton(_wordPool[3]),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Buttons row - Reset and Submit
          Row(
            spacing: 12,
            children: [
              // Reset/Clear button
              if (_usedWords.isNotEmpty)
                Expanded(
                  child: GestureDetector(
                    onTap: _resetGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 2,
                            color: Color(0xFFFF6B6B),
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
                            color: Color(0xFFFF6B6B),
                            size: 18,
                          ),
                          const Text(
                            'Clear All',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
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
              
              // Submit button
              Expanded(
                child: GestureDetector(
                  onTap: _submitAnswers,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: ShapeDecoration(
                      color: _usedWords.length == 4
                          ? const Color(0xFFF1AD7F)
                          : const Color(0xFFCCCCCC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Submit Answers',
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

  // Build individual word button
  Widget _buildWordButton(String word) {
    final isUsed = _usedWords.contains(word);
    
    return Draggable<String>(
                data: word,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 120,
                    height: 39,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF8A38F5).withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        word,
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
                childWhenDragging: Container(
                  width: 120,
                  height: 39,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE0E0E0).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.2),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.57,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  width: 120,
                  height: 39,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: ShapeDecoration(
                    color: isUsed 
                        ? const Color(0xFFE0E0E0).withOpacity(0.5)
                        : const Color(0xFFA6ADED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isUsed 
                            ? Colors.black.withOpacity(0.3)
                            : const Color(0xFF111213),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.57,
                      ),
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
      backgroundColor: const Color(0xFFE5ECF0),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100, top: 20),
                child: Column(
                  children: [
                    // Header with back button and title
                    _buildAppBar(),
                    
                    const SizedBox(height: 30),
                    
                    // Results Grid
                    _buildResultsGrid(),
                    
                    const SizedBox(height: 40),
                    
                    // Results Card
                    _buildResultsCard(correctCount, wrongCount),
                    
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
          // Shape Icon
          Positioned(
            left: 49,
            top: 12,
            child: _buildResultShapeIcon(slot['icon'] as IconData, isCorrect),
          ),
          
          // Answer Label
          Positioned(
            left: 28,
            top: 101,
            child: Container(
              width: 121,
              height: 26,
              decoration: ShapeDecoration(
                color: const Color(0xFF36D399),
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
          
          // Checkmark icon
          if (isCorrect)
            Positioned(
              left: 81,
              top: 131,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF36D399),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            
          // X icon for wrong answers
          if (!isCorrect)
            Positioned(
              left: 81,
              top: 131,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFD33636),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
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
