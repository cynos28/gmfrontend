import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:ganithamithura/models/shape_models.dart';

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    // Create dashed path
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance);
        distance += dashWidth;
        final end = metric.getTangentForOffset(distance);
        if (start != null && end != null) {
          dashPath.moveTo(start.position.dx, start.position.dy);
          dashPath.lineTo(end.position.dx, end.position.dy);
        }
        distance += dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

class BuildAndMatchScreen extends StatefulWidget {
  const BuildAndMatchScreen({super.key});

  @override
  State<BuildAndMatchScreen> createState() => _BuildAndMatchScreenState();
}

class _BuildAndMatchScreenState extends State<BuildAndMatchScreen> {
  final _apiService = ShapesApiService.instance;
  final String userId = 'user1'; // Hardcoded user for now
  int _selectedChallengeIndex = 0;
  final List<PlacedShape> _placedShapes = [];
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  PlacedShape? _shapeWithMenu;
  bool _isFullScreen = false;
  Offset _currentLandmarkOffset = Offset.zero;
  int _highestUnlockedChallenge = 0; // Track highest unlocked challenge (0-based)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuildChallengeProgress();
  }

  /// Fetch user's build challenge progress from database
  Future<void> _fetchBuildChallengeProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final buildProgress = await _apiService.getBuildMatchProgress();
      final highestChallenge = buildProgress['highest_build_challenge'] as int? ?? 0;
      
      setState(() {
        _highestUnlockedChallenge = highestChallenge;
        _isLoading = false;
      });
      
      print('Loaded build challenge progress: $highestChallenge challenges completed');
    } catch (e) {
      print('Error fetching build challenge progress: $e');
      // On error, start with only first challenge unlocked
      setState(() {
        _highestUnlockedChallenge = 0; // Index 0 = 1st challenge only
        _isLoading = false;
      });
    }
  }

  bool _isChallengeLocked(int challengeIndex) {
    // Only first challenge (index 0) is unlocked by default
    // Additional challenges unlock as you complete previous ones
    return challengeIndex > _highestUnlockedChallenge;
  }

  void _handleChallengeTap(int index) {
    if (_isChallengeLocked(index)) {
      // Tell user which challenge they need to complete to progress
      final challengeToComplete = _highestUnlockedChallenge; // The current edge challenge
      
      Get.snackbar(
        '🔒 Challenge Locked',
        'Complete the "${challenges[challengeToComplete]['name']}" challenge first to unlock more challenges!',
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.lock, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } else {
      setState(() {
        _selectedChallengeIndex = index;
        _clearCanvas();
      });
    }
  }

  /// Save challenge completion to database and unlock next challenge
  Future<void> _saveChallengeCompletionAndUnlock() async {
    // Always save if completing an unlocked challenge (new or replay)
    if (_selectedChallengeIndex <= _highestUnlockedChallenge) {
      try {
        // Build challenges are levels 7-13 (after 6 shape game levels)
        final levelNum = _selectedChallengeIndex + 7; // level0=7, level1=8, etc.
        final gameId = 'level$levelNum';
        
        // Submit a "completed" answer to save progress
        final gameAnswer = GameAnswer(
          gameId: gameId,
          answers: {'challenge': 'completed'}, // Simple completion marker
        );
        
        print('Saving build challenge ${_selectedChallengeIndex + 1} completion (level $levelNum)...');
        final result = await _apiService.checkAnswers(gameAnswer);
        
        if (result.isPassed) {
          print('✅ Build challenge ${_selectedChallengeIndex + 1} saved to database');
          
          // Unlock next challenge if this is at the current edge and not the last
          if (_selectedChallengeIndex == _highestUnlockedChallenge && 
              _selectedChallengeIndex < challenges.length - 1) {
            setState(() {
              _highestUnlockedChallenge = _selectedChallengeIndex + 1;
              print('🔓 Unlocked challenge ${_highestUnlockedChallenge + 1}');
            });
          }
        }
      } catch (e) {
        print('⚠️ Error saving build challenge progress: $e');
        // Still unlock locally even if save fails (only if current edge)
        if (_selectedChallengeIndex == _highestUnlockedChallenge && 
            _selectedChallengeIndex < challenges.length - 1) {
          setState(() {
            _highestUnlockedChallenge = _selectedChallengeIndex + 1;
            print('🔓 Unlocked challenge ${_highestUnlockedChallenge + 1} (local only)');
          });
        }
      }
    }
  }

  final List<Map<String, dynamic>> challenges = [
    {
      'name': 'House',
      'icon': '🏠',
      'hint': 'Use a square and a triangle',
      'shapes': [
        {'type': 'square', 'color': Color(0xFFE76E50), 'count': 1},
        {'type': 'triangle', 'color': Color(0xFFF1C933), 'count': 1},
      ],
      'landmarks': [
        {'type': 'square', 'color': Color(0xFFE76E50), 'position': Offset(110, 130)},
        {'type': 'triangle', 'color': Color(0xFFF1C933), 'position': Offset(110, 50)},
      ],
    },
    {
      'name': 'Tree',
      'icon': '🌳',
      'hint': 'Use circles and a rectangle',
      'shapes': [
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'count': 4},
        {'type': 'rectangle', 'color': Color(0xFF8B4513), 'count': 1},
      ],
      'landmarks': [
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(110, 40)},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(60, 80)},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(160, 80)},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(110, 120)},
        {'type': 'rectangle', 'color': Color(0xFF8B4513), 'position': Offset(110, 170), 'rotation': 90.0},
      ],
    },
    {
      'name': 'Sun',
      'icon': '☀️',
      'hint': 'Use a circle and triangles',
      'shapes': [
        {'type': 'circle', 'color': Color(0xFFFFA500), 'count': 1},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'count': 8},
      ],      'landmarks': [
        {'type': 'circle', 'color': Color(0xFFFFA500), 'position': Offset(110, 100)},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(110, 20), 'rotation': 0.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(170, 45), 'rotation': 45.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(195, 100), 'rotation': 90.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(170, 155), 'rotation': 135.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(110, 180), 'rotation': 180.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(50, 155), 'rotation': 225.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(25, 100), 'rotation': 270.0},
        {'type': 'triangle', 'color': Color(0xFFFFA500), 'position': Offset(50, 45), 'rotation': 315.0},
      ],    },
    {
      'name': 'Flower',
      'icon': '🌸',
      'hint': 'Use circles',
      'shapes': [
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'count': 5},
        {'type': 'circle', 'color': Color(0xFFF1C933), 'count': 1},
        {'type': 'rectangle', 'color': Color(0xFF4CEEB2), 'count': 1},
      ],      'landmarks': [
        {'type': 'circle', 'color': Color(0xFFF1C933), 'position': Offset(110, 85)},
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'position': Offset(110, 25)},
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'position': Offset(165, 55)},
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'position': Offset(165, 115)},
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'position': Offset(110, 145)},
        {'type': 'circle', 'color': Color(0xFFFF69B4), 'position': Offset(55, 115)},
        {'type': 'rectangle', 'color': Color(0xFF4CEEB2), 'position': Offset(105, 185)},
      ],    },
    {
      'name': 'Cat',
      'icon': '🐱',
      'hint': 'Use circles and triangles',
      'shapes': [
        {'type': 'circle', 'color': Color(0xFFD3D3D3), 'count': 1},
        {'type': 'triangle', 'color': Color(0xFFD3D3D3), 'count': 2},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'count': 2},
      ],
      'landmarks': [
        {'type': 'circle', 'color': Color(0xFFD3D3D3), 'position': Offset(110, 110)},
        {'type': 'triangle', 'color': Color(0xFFD3D3D3), 'position': Offset(60, 50)},
        {'type': 'triangle', 'color': Color(0xFFD3D3D3), 'position': Offset(160, 50)},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(85, 95)},
        {'type': 'circle', 'color': Color(0xFF4CEEB2), 'position': Offset(135, 95)},
      ],
    },
    {
      'name': 'Butterfly',
      'icon': '🦋',
      'hint': 'Use circles and ovals',
      'shapes': [
        {'type': 'circle', 'color': Color(0xFF9370DB), 'count': 4},
        {'type': 'rectangle', 'color': Color(0xFF000000), 'count': 1},
      ],
      'landmarks': [
        {'type': 'rectangle', 'color': Color(0xFF000000), 'position': Offset(110, 80)},
        {'type': 'circle', 'color': Color(0xFF9370DB), 'position': Offset(40, 40)},
        {'type': 'circle', 'color': Color(0xFF9370DB), 'position': Offset(40, 120)},
        {'type': 'circle', 'color': Color(0xFF9370DB), 'position': Offset(180, 40)},
        {'type': 'circle', 'color': Color(0xFF9370DB), 'position': Offset(180, 120)},
      ],
    },
    {
      'name': 'Car',
      'icon': '🚗',
      'hint': 'Use rectangles and circles',
      'shapes': [
        {'type': 'rectangle', 'color': Color(0xFFE76E50), 'count': 1},
        {'type': 'rectangle', 'color': Color(0xFF4CEEB2), 'count': 2},
        {'type': 'circle', 'color': Color(0xFF000000), 'count': 2},
      ],
      'landmarks': [
        {'type': 'rectangle', 'color': Color(0xFFE76E50), 'position': Offset(90, 90)},
        {'type': 'rectangle', 'color': Color(0xFF4CEEB2), 'position': Offset(60, 140)},
        {'type': 'rectangle', 'color': Color(0xFF4CEEB2), 'position': Offset(150, 140)},
        {'type': 'circle', 'color': Color(0xFF000000), 'position': Offset(70, 190)},
        {'type': 'circle', 'color': Color(0xFF000000), 'position': Offset(150, 190)},
      ],
    },
  ];

  List<Map<String, dynamic>> get currentChallengeShapes => 
      challenges[_selectedChallengeIndex]['shapes'];

  String get currentHint => challenges[_selectedChallengeIndex]['hint'];

  List<Map<String, dynamic>> get currentLandmarks =>
      challenges[_selectedChallengeIndex]['landmarks'] ?? [];

  Offset _getLandmarkOffset(double canvasWidth, double canvasHeight) {
    if (currentLandmarks.isEmpty) return Offset.zero;
    
    // Calculate center of all landmarks
    double sumX = 0;
    double sumY = 0;
    for (var landmark in currentLandmarks) {
      final pos = landmark['position'] as Offset;
      sumX += pos.dx + 40; // Add half shape size (70/2 + 5 padding)
      sumY += pos.dy + 40;
    }
    final landmarksCenterX = sumX / currentLandmarks.length;
    final landmarksCenterY = sumY / currentLandmarks.length;
    
    // Calculate canvas center
    final canvasCenterX = canvasWidth / 2;
    final canvasCenterY = canvasHeight / 2;
    
    // Return offset to center landmarks
    return Offset(
      canvasCenterX - landmarksCenterX,
      canvasCenterY - landmarksCenterY,
    );
  }

  bool _isLandmarkMatched(int landmarkIndex, {Offset offset = Offset.zero}) {
    final landmarks = currentLandmarks;
    if (landmarkIndex >= landmarks.length) return false;
    
    final landmark = landmarks[landmarkIndex];
    final landmarkPos = landmark['position'] as Offset;
    final landmarkType = landmark['type'] as String;
    final landmarkColor = landmark['color'] as Color;
    
    // Apply offset for full-screen mode and calculate landmark center
    final adjustedPos = landmarkPos + offset;
    // Shapes are 70px with 5px padding, so center offset is 40px (5 + 70/2)
    final landmarkCenter = Offset(adjustedPos.dx + 40, adjustedPos.dy + 40);
    
    const positionTolerance = 7.0;
    
    for (var placedShape in _placedShapes) {
      if (placedShape.type == landmarkType && 
          placedShape.color.value == landmarkColor.value) {
        // Calculate placed shape center
        final shapeCenter = Offset(placedShape.position.dx + 40, placedShape.position.dy + 40);
        
        // Check if centers are aligned within tolerance
        final distance = (shapeCenter - landmarkCenter).distance;
        if (distance <= positionTolerance) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _validateBuild() {
    // Get the required shapes for current challenge
    final requiredShapes = currentChallengeShapes;
    final landmarks = currentLandmarks;
    
    // First check if correct number of shapes are placed
    final placedShapesCount = <String, int>{};
    for (var shape in _placedShapes) {
      final key = '${shape.type}_${shape.color.value}';
      placedShapesCount[key] = (placedShapesCount[key] ?? 0) + 1;
    }
    
    final requiredShapesCount = <String, int>{};
    for (var shape in requiredShapes) {
      final key = '${shape['type']}_${(shape['color'] as Color).value}';
      final count = shape['count'] as int;
      requiredShapesCount[key] = count;
    }
    
    // Check if count matches
    if (placedShapesCount.length != requiredShapesCount.length) {
      return false;
    }
    
    for (var entry in requiredShapesCount.entries) {
      if (placedShapesCount[entry.key] != entry.value) {
        return false;
      }
    }
    
    // Now check if shapes are placed near landmarks (within 7 pixels tolerance)
    if (landmarks.isEmpty) {
      return true; // No landmarks defined, just check count
    }
    
    const positionTolerance = 7.0;
    final matchedLandmarks = <int>{};
    
    for (var placedShape in _placedShapes) {
      bool foundMatch = false;
      
      for (int i = 0; i < landmarks.length; i++) {
        if (matchedLandmarks.contains(i)) continue; // Already matched
        
        final landmark = landmarks[i];
        final landmarkPos = landmark['position'] as Offset;
        final landmarkType = landmark['type'] as String;
        final landmarkColor = landmark['color'] as Color;
        
        // Check if type and color match
        if (placedShape.type == landmarkType && 
            placedShape.color.value == landmarkColor.value) {
          
          // Calculate center-to-center distance (same as _isLandmarkMatched)
          // Apply current landmark offset (used in full-screen mode)
          // Shapes are 70px with 5px padding, so center offset is 40px (5 + 70/2)
          final adjustedLandmarkPos = landmarkPos + _currentLandmarkOffset;
          final landmarkCenter = Offset(adjustedLandmarkPos.dx + 40, adjustedLandmarkPos.dy + 40);
          final shapeCenter = Offset(placedShape.position.dx + 40, placedShape.position.dy + 40);
          final distance = (shapeCenter - landmarkCenter).distance;
          
          if (distance <= positionTolerance) {
            matchedLandmarks.add(i);
            foundMatch = true;
            break;
          }
        }
      }
      
      if (!foundMatch) {
        return false; // This shape is not placed correctly
      }
    }
    
    return matchedLandmarks.length == landmarks.length;
  }

  String _getDetailedFeedback() {
    final requiredShapes = currentChallengeShapes;
    final landmarks = currentLandmarks;
    
    // Count placed shapes
    final placedShapesCount = <String, Map<String, dynamic>>{};
    for (var shape in _placedShapes) {
      final key = '${shape.type}_${shape.color.value}';
      placedShapesCount[key] = {
        'count': (placedShapesCount[key]?['count'] ?? 0) + 1,
        'type': shape.type,
        'color': shape.color,
      };
    }
    
    // Count required shapes
    final requiredShapesCount = <String, Map<String, dynamic>>{};
    for (var shape in requiredShapes) {
      final key = '${shape['type']}_${(shape['color'] as Color).value}';
      requiredShapesCount[key] = {
        'count': shape['count'],
        'type': shape['type'],
        'color': shape['color'],
      };
    }
    
    final feedback = <String>[];
    
    // Check what's missing
    for (var entry in requiredShapesCount.entries) {
      final required = entry.value['count'] as int;
      final placed = placedShapesCount[entry.key]?['count'] as int? ?? 0;
      final type = entry.value['type'] as String;
      
      if (placed < required) {
        final missing = required - placed;
        feedback.add('Need $missing more ${type}${missing > 1 ? 's' : ''}');
      }
    }
    
    // Check what's extra
    for (var entry in placedShapesCount.entries) {
      final placed = entry.value['count'] as int;
      final required = requiredShapesCount[entry.key]?['count'] as int? ?? 0;
      final type = entry.value['type'] as String;
      
      if (placed > required) {
        final extra = placed - required;
        feedback.add('Remove $extra ${type}${extra > 1 ? 's' : ''} (wrong color or extra)');
      }
    }
    
    // Check position matching if landmarks exist
    if (landmarks.isNotEmpty && feedback.isEmpty) {
      const positionTolerance = 7.0;
      final matchedLandmarks = <int>{};
      int incorrectlyPlaced = 0;
      
      for (var placedShape in _placedShapes) {
        bool foundMatch = false;
        
        for (int i = 0; i < landmarks.length; i++) {
          if (matchedLandmarks.contains(i)) continue;
          
          final landmark = landmarks[i];
          final landmarkPos = landmark['position'] as Offset;
          final landmarkType = landmark['type'] as String;
          final landmarkColor = landmark['color'] as Color;
          
          if (placedShape.type == landmarkType && 
              placedShape.color.value == landmarkColor.value) {
            final distance = (placedShape.position - landmarkPos).distance;
            if (distance <= positionTolerance) {
              matchedLandmarks.add(i);
              foundMatch = true;
              break;
            }
          }
        }
        
        if (!foundMatch) {
          incorrectlyPlaced++;
        }
      }
      
      if (incorrectlyPlaced > 0) {
        feedback.add('Some shapes are not placed on the landmarks! Move them to match the dotted guides.');
      }
    }
    
    if (feedback.isEmpty) {
      return 'Perfect match!';
    }
    
    return feedback.join('\n');
  }

  void _clearCanvas() {
    setState(() {
      _placedShapes.clear();
    });
  }

  void _deleteLastShape() {
    if (_placedShapes.isNotEmpty) {
      setState(() {
        _placedShapes.removeLast();
      });
    }
  }

  Future<void> _checkBuild() async {
    if (_placedShapes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Not Yet!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: const Text(
            'You haven\'t placed any shapes yet. Try building the challenge first!',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final isCorrect = _validateBuild();
    final feedback = _getDetailedFeedback();
    
    // Track if we'll unlock a new challenge before saving
    final willUnlockNext = isCorrect && 
                           _selectedChallengeIndex == _highestUnlockedChallenge && 
                           _selectedChallengeIndex < challenges.length - 1;
    
    // Save challenge completion to database and unlock next challenge
    if (isCorrect) {
      await _saveChallengeCompletionAndUnlock();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(
          isCorrect ? '🎉 AMAZING!' : '🤔 ALMOST THERE!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isCorrect ? const Color(0xFF36D399) : const Color(0xFFF1AD7F),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCorrect) const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            Text(
              isCorrect
                  ? 'Great job! You built the ${challenges[_selectedChallengeIndex]['name']}!'
                  : 'Your build needs a little more work. Try this:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1AD7F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1AD7F).withOpacity(0.3)),
                ),
                child: Text(
                  feedback,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isCorrect)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1AD7F),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              if (isCorrect)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_selectedChallengeIndex < challenges.length - 1) {
                      _handleChallengeTap(_selectedChallengeIndex + 1);
                    } else {
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36D399),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _selectedChallengeIndex < challenges.length - 1 ? 'Next!' : 'Done!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE5ECF0),
          body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildAppBar(),

            // Scrollable content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 33),
                      child: Column(
                        children: [
                          // Build Challenges Section
                          _buildChallengeSection(),
                    
                          const SizedBox(height: 31),
                          _buildCanvas(height: 280),
                          const SizedBox(height: 24),
                          _buildShapePalette(),
                          const SizedBox(height: 31),
                          _buildActionButtons(),
                          const SizedBox(height: 35),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
        ),
        if (_isFullScreen) _buildFullScreenOverlay(),
      ],
    );
  }

  Widget _buildFullScreenOverlay() {
    final currentChallenge = challenges[_selectedChallengeIndex];
    
    return Container(
      color: const Color(0xFFE5ECF0),
      child: SafeArea(
        child: Column(
          children: [
             // Full Screen Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentChallenge['icon']} ${currentChallenge['name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D4059),
                        ),
                      ),
                      const Text(
                        'BUILDING MODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF1AD7F),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFullScreen = false;
                        _shapeWithMenu = null;
                        _currentLandmarkOffset = Offset.zero;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE76E50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.fullscreen_exit_rounded,
                        size: 24,
                        color: Color(0xFFE76E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final landmarkOffset = _getLandmarkOffset(constraints.maxWidth, constraints.maxHeight);
                    
                    // Store offset in state for validation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_currentLandmarkOffset != landmarkOffset) {
                        setState(() {
                          _currentLandmarkOffset = landmarkOffset;
                        });
                      }
                    });
                    
                    return _buildCanvas(landmarkOffset: landmarkOffset);
                  },
                ),
              ),
            ),

            // Bottom Panel
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShapePalette(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF1AD7F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFE76E50), size: 22),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build & Match',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Challenge Your Creativity!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Win Stars!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Select a Challenge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D4059),
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final isSelected = index == _selectedChallengeIndex;
              final isLocked = _isChallengeLocked(index);
              
              return GestureDetector(
                onTap: () => _handleChallengeTap(index),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF1AD7F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? const Color(0xFFF1AD7F).withOpacity(0.3) 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              challenge['icon'],
                              style: TextStyle(
                                fontSize: 32,
                                color: isLocked ? Colors.grey.withOpacity(0.5) : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              challenge['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isLocked 
                                    ? Colors.grey 
                                    : (isSelected ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildHintSection(),
      ],
    );
  }

  Widget _buildHintSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF36D399).withOpacity(0.1),
            const Color(0xFF2196F3).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF36D399).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF36D399),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION TIP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF36D399),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  currentHint,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4059),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(String shapeType, Color color, {double size = 40}) {
    switch (shapeType) {
      case 'circle':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case 'square':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case 'rectangle':
        return Container(
          width: size,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case 'triangle':
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(color),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildCanvas({Offset? landmarkOffset, double? height}) {
    final currentChallenge = challenges[_selectedChallengeIndex];
    final currentLandmarks = currentChallenge['landmarks'] as List<Map<String, dynamic>>;

    Widget mainCanvas = LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFF1AD7F).withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: GestureDetector(
              onTapDown: (details) {
                if (_shapeWithMenu != null) {
                  setState(() {
                    _shapeWithMenu = null;
                  });
                }
              },
              child: Stack(
                children: [
                   // Grid background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(
                        color: const Color(0xFFF1AD7F).withOpacity(0.05),
                        spacing: 20,
                      ),
                    ),
                  ),
                  
                  // Landmarks (targets)
                  ...currentLandmarks.asMap().entries.where((entry) => !_isLandmarkMatched(entry.key, offset: landmarkOffset ?? Offset.zero)).map((entry) {
                    final landmark = entry.value;
                    final rotation = landmark['rotation'] as double? ?? 0.0;
                    return Positioned(
                      left: (landmark['position'] as Offset).dx + (landmarkOffset?.dx ?? 0),
                      top: (landmark['position'] as Offset).dy + (landmarkOffset?.dy ?? 0),
                      child: Transform.rotate(
                        angle: rotation * 3.14159 / 180,
                        child: Opacity(
                          opacity: 0.6,
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: landmark['color'] as Color,
                              strokeWidth: 2,
                              dashWidth: 5,
                              dashSpace: 3,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              child: _buildShape(
                                landmark['type'] as String,
                                (landmark['color'] as Color).withOpacity(0.2),
                                size: 70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  if (_placedShapes.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.architecture_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'Tap shapes below to START BUILDING!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.withOpacity(0.4),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Placed Shapes
                  ..._placedShapes.map((placedShape) {
                    return Positioned(
                      left: placedShape.position.dx,
                      top: placedShape.position.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (details) {
                          setState(() {
                            _initialScale = placedShape.scale;
                            _initialRotation = placedShape.rotation;
                            _shapeWithMenu = null;
                          });
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            placedShape.scale = (_initialScale * details.scale).clamp(0.5, 3.0);
                            placedShape.rotation = _initialRotation + (details.rotation * 180 / 3.14159);
                            
                            final newX = (placedShape.position.dx + details.focalPointDelta.dx)
                                .clamp(0.0, constraints.maxWidth - 60)
                                .toDouble();
                            final newY = (placedShape.position.dy + details.focalPointDelta.dy)
                                .clamp(0.0, constraints.maxHeight - 60)
                                .toDouble();
                            placedShape.position = Offset(newX, newY);
                          });
                        },
                        onLongPress: () {
                          setState(() => _shapeWithMenu = placedShape);
                        },
                        onTap: () {
                          setState(() => _shapeWithMenu = placedShape);
                        },
                        child: Transform.scale(
                          scale: placedShape.scale,
                          child: Transform.rotate(
                            angle: placedShape.rotation * 3.14159 / 180,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: _shapeWithMenu == placedShape
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF36D399),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : null,
                              child: _buildShape(
                                placedShape.type,
                                placedShape.color,
                                size: 70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // Full Screen Button (only in standard view)
                  if (height != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFullScreen = true;
                            _shapeWithMenu = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 24,
                            color: Color(0xFF36D399),
                          ),
                        ),
                      ),
                    ),

                  // Modification Menu
                  if (_shapeWithMenu != null)
                    _buildModificationMenu(constraints),
                ],
              ),
            ),
          ),
        );
      },
    );

    return height != null 
        ? SizedBox(height: height, child: mainCanvas) 
        : Expanded(child: mainCanvas);
  }

  Widget _buildModificationMenu(BoxConstraints constraints) {
    return Positioned(
      left: (_shapeWithMenu!.position.dx + 80).clamp(0.0, constraints.maxWidth - 70),
      top: _shapeWithMenu!.position.dy,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1AD7F).withOpacity(0.5), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuIcon(Icons.zoom_in_rounded, () {
                setState(() => _shapeWithMenu!.scale = (_shapeWithMenu!.scale + 0.2).clamp(0.5, 3.0));
              }),
              _menuDivider(),
              _menuIcon(Icons.zoom_out_rounded, () {
                setState(() => _shapeWithMenu!.scale = (_shapeWithMenu!.scale - 0.2).clamp(0.5, 3.0));
              }),
              _menuDivider(),
              _menuIcon(Icons.rotate_right_rounded, () {
                setState(() {
                  final index = _placedShapes.indexOf(_shapeWithMenu!);
                  if (index != -1) _placedShapes[index].rotation = (_placedShapes[index].rotation + 45) % 360;
                });
              }),
              _menuDivider(),
              _menuIcon(Icons.delete_forever_rounded, () {
                setState(() {
                  _placedShapes.remove(_shapeWithMenu);
                  _shapeWithMenu = null;
                });
              }, color: Colors.redAccent),
              _menuDivider(),
              _menuIcon(Icons.check_circle_rounded, () {
                setState(() => _shapeWithMenu = null);
              }, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuIcon(IconData icon, VoidCallback onTap, {Color color = const Color(0xFFF1AD7F)}) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _menuDivider() => Container(height: 24, width: 1, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _buildShapePalette() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_box_rounded, color: Color(0xFFF1AD7F), size: 22),
              SizedBox(width: 8),
              Text(
                'Shape Inventory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D4059),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentChallengeShapes.length,
              itemBuilder: (context, index) {
                final shapeData = currentChallengeShapes[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _placedShapes.add(PlacedShape(
                        type: shapeData['type'],
                        color: shapeData['color'],
                        position: Offset(50.0 + (_placedShapes.length * 10.0), 50.0 + (_placedShapes.length * 10.0)),
                      ));
                    });
                  },
                  child: Container(
                    width: 75,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1AD7F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1AD7F).withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildShape(shapeData['type'], shapeData['color'], size: 45),
                        const SizedBox(height: 4),
                        Text(
                          'x${shapeData['count']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2D4059)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _actionButton(
          'Clear',
          Icons.refresh_rounded,
          const Color(0xFFFF7675),
          _clearCanvas,
        ),
        const SizedBox(width: 12),
        _actionButton(
          'Delete',
          Icons.backspace_rounded,
          const Color(0xFF74B9FF),
          _deleteLastShape,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF36D399), Color(0xFF2DB67C)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF36D399).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _checkBuild,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'CHECK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlacedShape {
  String type;
  Color color;
  Offset position;
  double rotation;
  double scale;

  PlacedShape({
    required this.type,
    required this.color,
    required this.position,
    this.rotation = 0,
    this.scale = 1.0,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, this.spacing = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => 
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}
