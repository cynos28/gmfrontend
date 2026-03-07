import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';
import 'package:ganithamithura/services/api/shapes_api_service.dart';
import 'package:ganithamithura/models/shape_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

/// Kid-Friendly LearnShapesScreen - Interactive shape learning with real-world examples
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
  List<RealWorldExample> _selectedExamples = [];
  final Random _random = Random();
  int _currentNavIndex = 1; // Default to 'Learn'
  
  @override
  void initState() {
    super.initState();
    currentShapeIndex = widget.initialIndex;
    _loadShapes();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45); // Slightly slower for kids
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
      
      if (!mounted) return;
      setState(() {
        _shapes = shapes;
        _isLoading = false;
        
        if (currentShapeIndex >= shapes.length) {
          currentShapeIndex = 0;
        }
        _selectRandomExamples();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectRandomExamples() {
    if (_shapes.isEmpty || currentShapeIndex >= _shapes.length) {
      _selectedExamples = [];
      return;
    }

    final currentShape = _shapes[currentShapeIndex];
    final allExamples = currentShape.realWorldExamples;

    if (allExamples.length <= 4) {
      _selectedExamples = List.from(allExamples);
      return;
    }

    final indices = List.generate(allExamples.length, (i) => i);
    indices.shuffle(_random);
    _selectedExamples = indices.take(4).map((i) => allExamples[i]).toList();
  }

  void _nextShape() {
    if (currentShapeIndex < _shapes.length - 1) {
      setState(() {
        currentShapeIndex++;
        _selectRandomExamples();
      });
      _speakShapeName();
    }
  }

  void _previousShape() {
    if (currentShapeIndex > 0) {
      setState(() {
        currentShapeIndex--;
        _selectRandomExamples();
      });
      _speakShapeName();
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Get.back();
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFBFD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF36D399)),
              const SizedBox(height: 20),
              const Text('Finding Shapes...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _shapes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFBFD),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Oops! Something went wrong.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadShapes,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1AD7F)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentShape = _shapes[currentShapeIndex];
    final Color shapeThemeColor = currentShape.colorValue;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopNavigation(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        children: [
                          _buildShapeHeroCard(currentShape, shapeThemeColor),
                          const SizedBox(height: 24),
                          _buildPropertiesBox(currentShape, shapeThemeColor),
                          const SizedBox(height: 24),
                          _buildExamplesHeader(),
                          _buildExamplesGrid(shapeThemeColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 26),
            ),
          ),
          Row(
            children: [
              _buildNavArrow(Icons.chevron_left_rounded, currentShapeIndex > 0, _previousShape),
              const SizedBox(width: 12),
              _buildNavArrow(Icons.chevron_right_rounded, currentShapeIndex < _shapes.length - 1, _nextShape),
            ],
          ),
          GestureDetector(
            onTap: _speakShapeName,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF1AD7F),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF1AD7F).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.grey.withOpacity(0.2) : Colors.transparent),
        ),
        child: Icon(icon, color: active ? Colors.black87 : Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildShapeHeroCard(ShapeModel shape, Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 4),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/Shapes/kids7.png',
                height: 80,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: GridPainter(color: themeColor),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'shape_${widget.shapeType}_${shape.name}',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: _getShapeImage(shape),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  shape.name,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesBox(ShapeModel shape, Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withOpacity(0.4), width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.black54, size: 28),
              SizedBox(width: 10),
              Text('Properties', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shape.propertiesText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Real World Examples',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildExamplesGrid(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _selectedExamples.length,
        itemBuilder: (context, index) {
          final example = _selectedExamples[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(example.emoji, style: const TextStyle(fontSize: 54)),
                const SizedBox(height: 8),
                Text(
                  example.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getShapeImage(ShapeModel shape) {
    final String imagePath = _getShapeImagePath(shape.name, shape.type);
    return Image.asset(
      imagePath,
      width: 160,
      height: 160,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.category_rounded, size: 100, color: shape.colorValue),
    );
  }

  String _getShapeImagePath(String shapeName, String shapeType) {
    final name = shapeName.toLowerCase();
    return shapeType == '2d' ? 'assets/images/2d_shapes/$name.png' : 'assets/images/3d_shapes/$name.png';
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
