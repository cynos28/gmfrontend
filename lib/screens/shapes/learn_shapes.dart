import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:ganithamithura/models/shape_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// LearnShapesScreen - Interactive shape learning with real-world examples
class LearnShapesScreen extends StatefulWidget {
  final int initialIndex;
  final String shapeType; // "2d" or "3d"
  
  const LearnShapesScreen({
    super.key, 
    this.initialIndex = 0,
    this.shapeType = "2d",
  });

  @override
  State<LearnShapesScreen> createState() => _LearnShapesScreenState();
}

class _LearnShapesScreenState extends State<LearnShapesScreen> {
  late int currentShapeIndex;
  List<ShapeModel> _shapes = [];
  bool _isLoading = true;
  String? _error;
  final FlutterTts _flutterTts = FlutterTts();
  bool _showAllExamples = false;
  
  @override
  void initState() {
    super.initState();
    currentShapeIndex = widget.initialIndex;
    _loadShapes();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakShapeName() async {
    if (_shapes.isNotEmpty) {
      final shapeName = _shapes[currentShapeIndex].name;
      await _flutterTts.speak(shapeName);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadShapes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final shapesApi = ShapesApiService.instance;
      final shapes = await shapesApi.getShapesByType(widget.shapeType);
      
      setState(() {
        _shapes = shapes;
        _isLoading = false;
        
        // Ensure initial index is valid
        if (currentShapeIndex >= shapes.length) {
          currentShapeIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _currentNavIndex = 0;

  void _nextShape() {
    if (currentShapeIndex < _shapes.length - 1) {
      setState(() {
        currentShapeIndex++;
        _showAllExamples = false;
      });
    }
  }

  void _previousShape() {
    if (currentShapeIndex > 0) {
      setState(() {
        currentShapeIndex--;
        _showAllExamples = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate to home
      Get.back();
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFA),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF36D399),
          ),
        ),
      );
    }

    // Show error state
    if (_error != null || _shapes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'No shapes found',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadShapes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36D399),
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentShape = _shapes[currentShapeIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  children: [
                    // Back button to shapes selection
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Navigation arrows for previous/next shape
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous shape button
                          GestureDetector(
                            onTap: _previousShape,
                            child: Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                color: currentShapeIndex > 0
                                    ? const Color(0xFFD9D9D9).withOpacity(0.5)
                                    : const Color(0xFFD9D9D9).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                size: 18,
                                color: currentShapeIndex > 0
                                    ? Colors.black
                                    : Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                          // Sound button to speak shape name
                          GestureDetector(
                            onTap: _speakShapeName,
                            child: Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                color: const Color(0xFF36D399),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.volume_up,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Shape Display Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 21),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 105,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFBEB6B6).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Shape icon
                          Container(
                            width: 139,
                            height: 139,
                            child: _getShapeImage(currentShape),
                          ),
                          const SizedBox(height: 28),
                          // Shape name
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentShape.name,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Shape properties
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 55,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9BA9F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        currentShape.propertiesText,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Real examples section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Real example',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 33),

                    // Examples grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        children: [
                          if (currentShape.realWorldExamples.length >= 2)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildExampleCard(
                                      currentShape.realWorldExamples[0]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildExampleCard(
                                      currentShape.realWorldExamples[1]),
                                ),
                              ],
                            ),
                          if (_showAllExamples && currentShape.realWorldExamples.length >= 4)
                            const SizedBox(height: 30),
                          if (_showAllExamples && currentShape.realWorldExamples.length >= 4)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildExampleCard(
                                      currentShape.realWorldExamples[2]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildExampleCard(
                                      currentShape.realWorldExamples[3]),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 33),

                    // More examples button
                    if (currentShape.realWorldExamples.length > 2)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllExamples = !_showAllExamples;
                          });
                        },
                        child: Container(
                          width: 219,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1AD7F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showAllExamples ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _showAllExamples ? 'Show less' : 'More examples',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(RealWorldExample example) {
    return AspectRatio(
      aspectRatio: 1.05, // Slightly wider than tall
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              example.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 4),
            Text(
              example.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: 'Be Vietnam Pro',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getShapeImage(ShapeModel shape) {
    // Map shape names to asset paths
    final String imagePath = _getShapeImagePath(shape.name, shape.type);
    
    return Image.asset(
      imagePath,
      width: 139,
      height: 139,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to colored container if image not found
        return Container(
          width: 139,
          height: 139,
          decoration: BoxDecoration(
            color: shape.colorValue,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              shape.name[0],
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getShapeImagePath(String shapeName, String shapeType) {
    final name = shapeName.toLowerCase();
    
    // Check if image exists in type-specific folder
    if (shapeType == '2d') {
      switch (name) {
        case 'circle':
          return 'assets/images/2d_shapes/circle.png';
        case 'square':
          return 'assets/images/2d_shapes/square.png';
        case 'triangle':
          return 'assets/images/2d_shapes/triangle.png';
        case 'rectangle':
          return 'assets/images/2d_shapes/rectangle.png';
        default:
          // Try root images folder
          return 'assets/images/$name.png';
      }
    } else {
      // 3D shapes
      switch (name) {
        case 'cube':
          return 'assets/images/3d_shapes/cube.png';
        case 'sphere':
          return 'assets/images/3d_shapes/sphere.png';
        case 'cylinder':
          return 'assets/images/3d_shapes/cylinder.png';
        case 'cone':
          return 'assets/images/3d_shapes/cone.png';
        default:
          // Try root images folder
          return 'assets/images/$name.png';
      }
    }
  }
}
