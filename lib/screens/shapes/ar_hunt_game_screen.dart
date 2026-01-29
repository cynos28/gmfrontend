import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ArHuntGameScreen extends StatefulWidget {
  const ArHuntGameScreen({super.key});

  @override
  State<ArHuntGameScreen> createState() => _ArHuntGameScreenState();
}

class _ArHuntGameScreenState extends State<ArHuntGameScreen> {
  int _currentShapeIndex = 0;
  bool _isModelLoading = true;
  
  String get currentShape => shapes[_currentShapeIndex]['name'] as String;
  String get shapeDescription => shapes[_currentShapeIndex]['description'] as String;
  String get modelUrl => shapes[_currentShapeIndex]['modelUrl'] as String;
  
  final List<Map<String, dynamic>> shapes = [
    {
      'name': 'Cube',
      'description': 'A cube has 6 flat faces and 8 corners!',
      'color': Colors.blue,
      'modelUrl': 'https://modelviewer.dev/shared-assets/models/cube.gltf',
    },
    {
      'name': 'Sphere',
      'description': 'A sphere is perfectly round like a ball!',
      'color': Colors.red,
      'modelUrl': 'https://modelviewer.dev/shared-assets/models/reflective-sphere.gltf',
    },
    {
      'name': 'Cone',
      'description': 'A cone has a circular base and comes to a point!',
      'color': Colors.orange,
      'modelUrl': 'assets/models/cone.glb',
    },
    {
      'name': 'Cylinder',
      'description': 'A cylinder has 2 circular ends and a curved surface!',
      'color': Colors.cyan,
      'modelUrl': 'assets/models/cylinder.glb',
    },
    {
      'name': 'Pyramid',
      'description': 'A pyramid has a square base and 4 triangular faces!',
      'color': Colors.yellow,
      'modelUrl': 'assets/models/pyramid.glb',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Reset loading state when first loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  void _loadRandomShape() {
    setState(() {
      _isModelLoading = true;
      // Cycle through shapes sequentially to ensure all shapes are seen
      _currentShapeIndex = (_currentShapeIndex + 1) % shapes.length;
    });
    // Reset loading after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  Color _getCurrentShapeColor() {
    return shapes[_currentShapeIndex]['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF2FFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    'AR Hunt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // 3D Model Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Stack(
                  children: [
                    // Main 3D Model Viewer - Full clickable area
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ModelViewer(
                          key: ValueKey(modelUrl),
                          backgroundColor: const Color(0xFFEEEEEE),
                          src: modelUrl,
                          alt: 'A 3D model of $currentShape',
                          ar: true,
                          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                          autoRotate: true,
                          autoRotateDelay: 500,
                          rotationPerSecond: '30deg',
                          cameraControls: true,
                          disableZoom: false,
                          shadowIntensity: 1.0,
                          shadowSoftness: 1.0,
                          exposure: 1.0,
                          autoPlay: true,
                          cameraOrbit: '0deg 75deg 105%',
                          minCameraOrbit: 'auto auto 5%',
                          maxCameraOrbit: 'auto auto 200%',
                          touchAction: TouchAction.panY,
                          interactionPrompt: InteractionPrompt.auto,
                          interactionPromptThreshold: 500,
                        ),
                      ),
                    ),
                    
                    // Instruction text - Positioned to not block AR button
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '👆 Touch to rotate • 📱 Tap AR button (bottom right)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    // Corner brackets - Non-interactive
                    Positioned(
                      top: 20,
                      left: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.topLeft,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.topRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                    // Removed bottom-right bracket to avoid blocking AR button
                  ],
                ),
              ),
            ),
            
            // Shape info card
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x33827D7D),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Shape name
                  Text(
                    currentShape,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Shape description
                  Text(
                    shapeDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0x80000000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Try Another Shape button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loadRandomShape,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1AD7F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: -math.pi / 2,
                            child: const Icon(
                              Icons.refresh,
                              color: Color(0xFFD33636),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Try Another Shape',
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
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;

  CornerBracketPainter({
    required this.color,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    
    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(size.width, 0);
        path.lineTo(0, 0);
        path.lineTo(0, size.height);
        break;
      case CornerPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
