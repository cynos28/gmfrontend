import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  int _selectedChallengeIndex = 0;
  final List<PlacedShape> _placedShapes = [];
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  PlacedShape? _shapeWithMenu;
  bool _isFullScreen = false;
  Offset _currentLandmarkOffset = Offset.zero;

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

  void _checkBuild() {
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isCorrect ? '🎉 Well Done!' : '🤔 Not Quite Right',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isCorrect ? Colors.green : Colors.orange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? 'Perfect! You\'ve successfully built the ${challenges[_selectedChallengeIndex]['name']}!'
                  : 'Your build doesn\'t match yet. Here\'s what you need:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  feedback,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isCorrect)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Try Again'),
            ),
          if (isCorrect)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _clearCanvas();
                });
              },
              child: const Text('Build Again'),
            ),
          if (isCorrect && _selectedChallengeIndex < challenges.length - 1)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedChallengeIndex++;
                  _clearCanvas();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CEEB2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Next Challenge',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (!isCorrect)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CEEB2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: const Color(0x80D9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Build & Match',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 33),
                child: Column(
                  children: [
                    // Build Challenges Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2E9DB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0x1AA69696),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Build Challenges',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Horizontal scrolling challenges
                          SizedBox(
                            height: 95,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: challenges.length,
                              itemBuilder: (context, index) {
                                final challenge = challenges[index];
                                final isSelected = index == _selectedChallengeIndex;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedChallengeIndex = index;
                                      _clearCanvas();
                                    });
                                  },
                                  child: Container(
                                    width: 71,
                                    margin: const EdgeInsets.only(right: 13),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? const Color(0xFF4CEEB2) 
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          challenge['icon'],
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          challenge['name'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected 
                                                ? Colors.white 
                                                : Colors.black,
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
                          
                          // Hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x80FCFCFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hint: $currentHint',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 31),
                    
                    // Building Canvas
                    Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 282,
                              width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEAEA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF36D399),
                              width: 2,
                            ),
                          ),
                          child: GestureDetector(
                            onTapDown: (details) {
                              // Close menu when tapping outside
                              if (_shapeWithMenu != null) {
                                setState(() {
                                  _shapeWithMenu = null;
                                });
                              }
                            },
                            child: Stack(
                              children: [
                                // Always render landmarks (hide matched ones)
                                ...currentLandmarks.asMap().entries.where((entry) => !_isLandmarkMatched(entry.key)).map((entry) {
                                  final landmark = entry.value;
                                  final rotation = landmark['rotation'] as double? ?? 0.0;
                                  return Positioned(
                                    left: (landmark['position'] as Offset).dx,
                                    top: (landmark['position'] as Offset).dy,
                                    child: Transform.rotate(
                                      angle: rotation * 3.14159 / 180,
                                      child: Opacity(
                                        opacity: 0.5,
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
                                              (landmark['color'] as Color).withOpacity(0.3),
                                              size: 70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                
                                // Show empty state message or placed shapes
                                if (_placedShapes.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Tap shapes below to Start Building!',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0x80000000),
                                      ),
                                    ),
                                  ),
                                
                                // Render placed shapes
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
                                              _shapeWithMenu = null; // Close menu on gesture
                                            });
                                          },
                                          onScaleUpdate: (details) {
                                            setState(() {
                                              // Handle scaling (details.scale is relative to start)
                                              placedShape.scale = (_initialScale * details.scale)
                                                  .clamp(0.5, 3.0);
                                              
                                              // Handle rotation (details.rotation is in radians, relative to start)
                                              placedShape.rotation = _initialRotation + (details.rotation * 180 / 3.14159);
                                              if (placedShape.rotation >= 360) {
                                                placedShape.rotation -= 360;
                                              } else if (placedShape.rotation < 0) {
                                                placedShape.rotation += 360;
                                              }
                                              
                                              // Handle movement
                                              final newX = (placedShape.position.dx + details.focalPointDelta.dx)
                                                  .clamp(0.0, constraints.maxWidth - 60)
                                                  .toDouble();
                                              final newY = (placedShape.position.dy + details.focalPointDelta.dy)
                                                  .clamp(0.0, 282 - 60)
                                                  .toDouble();
                                              placedShape.position = Offset(newX, newY);
                                            });
                                          },
                                          onLongPress: () {
                                            setState(() {
                                              _shapeWithMenu = placedShape;
                                            });
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
                                                          color: Colors.blue,
                                                          width: 3,
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
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
                                    // Action Menu
                                    if (_shapeWithMenu != null)
                                      Positioned(
                                        left: (_shapeWithMenu!.position.dx + 70).clamp(0.0, constraints.maxWidth - 60),
                                        top: _shapeWithMenu!.position.dy,
                                        child: Material(
                                          elevation: 8,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF36D399),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Scale Up
                                                IconButton(
                                                  icon: const Icon(Icons.zoom_in, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _shapeWithMenu!.scale = (_shapeWithMenu!.scale + 0.2).clamp(0.5, 3.0);
                                                    });
                                                  },
                                                  tooltip: 'Scale Up',
                                                ),
                                                const SizedBox(height: 8),
                                                // Scale Down
                                                IconButton(
                                                  icon: const Icon(Icons.zoom_out, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _shapeWithMenu!.scale = (_shapeWithMenu!.scale - 0.2).clamp(0.5, 3.0);
                                                    });
                                                  },
                                                  tooltip: 'Scale Down',
                                                ),
                                                const SizedBox(height: 8),
                                                // Rotate 45°
                                                IconButton(
                                                  icon: const Icon(Icons.rotate_right, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      final index = _placedShapes.indexOf(_shapeWithMenu!);
                                                      if (index != -1) {
                                                        _placedShapes[index].rotation = (_placedShapes[index].rotation + 45) % 360;
                                                      }
                                                    });
                                                  },
                                                  tooltip: 'Rotate 45°',
                                                ),
                                                const SizedBox(height: 8),
                                                // Delete
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _placedShapes.remove(_shapeWithMenu);
                                                      _shapeWithMenu = null;
                                                    });
                                                  },
                                                  tooltip: 'Delete',
                                                ),
                                                const SizedBox(height: 8),
                                                // Close
                                                IconButton(
                                                  icon: const Icon(Icons.close, size: 20),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _shapeWithMenu = null;
                                                    });
                                                  },
                                                  tooltip: 'Close',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        );
                          },
                        ),
                        // Full Screen Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFullScreen = true;
                                _shapeWithMenu = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                size: 20,
                                color: Color(0xFF4CEEB2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Shape Palette
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFAFAFA),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle,
                                color: Color(0xFF4CEEB2),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tap to Add Shapes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Grid of shapes (4 per row)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(
                              currentChallengeShapes.length,
                              (index) {
                                final shapeData = currentChallengeShapes[index];
                                final shapeType = shapeData['type'];
                                final shapeColor = shapeData['color'];
                                final shapeCount = shapeData['count'];
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _placedShapes.add(
                                        PlacedShape(
                                          type: shapeType,
                                          color: shapeColor,
                                          position: Offset(
                                            50.0 + (_placedShapes.length * 10.0),
                                            50.0 + (_placedShapes.length * 10.0),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 83,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAEE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildShape(
                                          shapeType,
                                          shapeColor,
                                          size: 50,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'x$shapeCount',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
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
                    ),
                    
                    const SizedBox(height: 31),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearCanvas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1AD7F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.rotate(
                                  angle: -1.5708,
                                  child: const Icon(
                                    Icons.refresh,
                                    size: 15,
                                    color: Color(0xFFD33636),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD33636),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 21),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _deleteLastShape,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA6ADED),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 15,
                                  color: Color(0x80000000),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0x80000000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Check Build Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkBuild,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1AD7F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'I\'m Done! Check My Build',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
        // Full Screen Overlay
        if (_isFullScreen)
          Container(
          color: const Color(0xFFE5ECF0),
          child: SafeArea(
            child: Column(
              children: [
                // Full Screen Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        challenges[_selectedChallengeIndex]['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CEEB2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fullscreen_exit,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Full Screen Canvas
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
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEAEA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF36D399),
                              width: 2,
                            ),
                          ),
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
                                // Landmarks
                                ...currentLandmarks.asMap().entries.where((entry) => !_isLandmarkMatched(entry.key, offset: landmarkOffset)).map((entry) {
                                  final landmark = entry.value;
                                  final rotation = landmark['rotation'] as double? ?? 0.0;
                                  final originalPos = landmark['position'] as Offset;
                                  final centeredPos = originalPos + landmarkOffset;
                                  return Positioned(
                                    left: centeredPos.dx,
                                    top: centeredPos.dy,
                                    child: Transform.rotate(
                                      angle: rotation * 3.14159 / 180,
                                      child: Opacity(
                                        opacity: 0.5,
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
                                              (landmark['color'] as Color).withOpacity(0.3),
                                              size: 70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                // Empty state
                                if (_placedShapes.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Tap shapes below to Start Building!',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0x80000000),
                                      ),
                                    ),
                                  ),
                                // Placed shapes
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
                                          if (placedShape.rotation >= 360) {
                                            placedShape.rotation -= 360;
                                          } else if (placedShape.rotation < 0) {
                                            placedShape.rotation += 360;
                                          }
                                          final newX = (placedShape.position.dx + details.focalPointDelta.dx)
                                              .clamp(0.0, constraints.maxWidth - 80)
                                              .toDouble();
                                          final newY = (placedShape.position.dy + details.focalPointDelta.dy)
                                              .clamp(0.0, constraints.maxHeight - 80)
                                              .toDouble();
                                          placedShape.position = Offset(newX, newY);
                                        });
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _shapeWithMenu = placedShape;
                                        });
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
                                                      color: Colors.blue,
                                                      width: 3,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
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
                                // Action Menu
                                if (_shapeWithMenu != null)
                                  Positioned(
                                    left: (_shapeWithMenu!.position.dx + 70).clamp(0.0, constraints.maxWidth - 60),
                                    top: _shapeWithMenu!.position.dy,
                                    child: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF36D399),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.zoom_in, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _shapeWithMenu!.scale = (_shapeWithMenu!.scale + 0.2).clamp(0.5, 3.0);
                                                });
                                              },
                                              tooltip: 'Scale Up',
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              icon: const Icon(Icons.zoom_out, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _shapeWithMenu!.scale = (_shapeWithMenu!.scale - 0.2).clamp(0.5, 3.0);
                                                });
                                              },
                                              tooltip: 'Scale Down',
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              icon: const Icon(Icons.rotate_right, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  final index = _placedShapes.indexOf(_shapeWithMenu!);
                                                  if (index != -1) {
                                                    _placedShapes[index].rotation = (_placedShapes[index].rotation + 45) % 360;
                                                  }
                                                });
                                              },
                                              tooltip: 'Rotate 45°',
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _placedShapes.remove(_shapeWithMenu);
                                                  _shapeWithMenu = null;
                                                });
                                              },
                                              tooltip: 'Delete',
                                            ),
                                            const SizedBox(height: 8),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _shapeWithMenu = null;
                                                });
                                              },
                                              tooltip: 'Close',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Shape Palette and Action Buttons in Full Screen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shape Palette
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4CEEB2),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tap to Add Shapes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentChallengeShapes.length,
                          itemBuilder: (context, index) {
                            final shapeData = currentChallengeShapes[index];
                            final shapeType = shapeData['type'];
                            final shapeColor = shapeData['color'];
                            final shapeCount = shapeData['count'];
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _placedShapes.add(
                                    PlacedShape(
                                      type: shapeType,
                                      color: shapeColor,
                                      position: Offset(
                                        50.0 + (_placedShapes.length * 10.0),
                                        50.0 + (_placedShapes.length * 10.0),
                                      ),
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EAEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildShape(
                                      shapeType,
                                      shapeColor,
                                      size: 35,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'x$shapeCount',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _clearCanvas,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1AD7F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD33636),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _deleteLastShape,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA6ADED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0x80000000),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkBuild,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CEEB2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                'Check',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
