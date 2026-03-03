import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'learn_shapes.dart';

class ShapesSelectionScreen extends StatefulWidget {
  const ShapesSelectionScreen({super.key});

  @override
  State<ShapesSelectionScreen> createState() => _ShapesSelectionScreenState();
}

class _ShapesSelectionScreenState extends State<ShapesSelectionScreen> {
  bool is2DSelected = true;

  final List<ShapeCardData> shapes2D = [
    ShapeCardData(
      name: 'Circle',
      color: const Color(0xFFD946EF),
      backgroundColor: const Color(0xFFCB45D0).withOpacity(0.24),
      borderColor: const Color(0xFFBF41CB),
      shapeIndex: 0,
    ),
    ShapeCardData(
      name: 'Square',
      color: const Color(0xFF5B96E5),
      backgroundColor: const Color(0xFF5B96E5).withOpacity(0.24),
      borderColor: const Color(0xFF5690E1),
      shapeIndex: 1,
    ),
    ShapeCardData(
      name: 'Rectangle',
      color: const Color(0xFFBCA43E),
      backgroundColor: const Color(0xFFBCA43E).withOpacity(0.24),
      borderColor: const Color(0xFFCDAF42),
      shapeIndex: 3,
    ),
    ShapeCardData(
      name: 'Triangle',
      color: const Color(0xFF22B941),
      backgroundColor: const Color(0xFF22B941).withOpacity(0.24),
      borderColor: const Color(0xFF37D55D),
      shapeIndex: 2,
    ),
  ];

  final List<ShapeCardData> shapes3D = [
    ShapeCardData(
      name: 'Sphere',
      color: const Color(0xFFD946EF),
      backgroundColor: const Color(0xFFCB45D0).withOpacity(0.24),
      borderColor: const Color(0xFFBF41CB),
      shapeIndex: 1,
    ),
    ShapeCardData(
      name: 'Cube',
      color: const Color(0xFF5B96E5),
      backgroundColor: const Color(0xFF5B96E5).withOpacity(0.24),
      borderColor: const Color(0xFF5690E1),
      shapeIndex: 0,
    ),
    ShapeCardData(
      name: 'Cylinder',
      color: const Color(0xFFBCA43E),
      backgroundColor: const Color(0xFFBCA43E).withOpacity(0.24),
      borderColor: const Color(0xFFCDAF42),
      shapeIndex: 2,
    ),
    ShapeCardData(
      name: 'Cone',
      color: const Color(0xFF22B941),
      backgroundColor: const Color(0xFF22B941).withOpacity(0.24),
      borderColor: const Color(0xFF37D55D),
      shapeIndex: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentShapes = is2DSelected ? shapes2D : shapes3D;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 10),
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
            const SizedBox(height: 18),
            
            // 2D/3D Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 46),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: is2DSelected
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: 145,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1AD7F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                is2DSelected = true;
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Text(
                                '2D Shapes',
                                style: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: is2DSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                is2DSelected = false;
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: Text(
                                '3D Shapes',
                                style: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: !is2DSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Shapes Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // First Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildShapeCard(currentShapes[0]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildShapeCard(currentShapes[1]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Second Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildShapeCard(currentShapes[2]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildShapeCard(currentShapes[3]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Bottom illustration
            Image.asset(
              'assets/images/learning_illustration.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 60)),
                  ),
                );
              },
            ),
            const SizedBox(height: 38),
            
            // Bottom Navigation Bar
            _buildBottomNavBar(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildShapeCard(ShapeCardData shapeData) {
    return GestureDetector(
      onTap: () {
        // Navigate to learn shapes screen with the selected shape index and type
        Get.to(
          () => LearnShapesScreen(
            initialIndex: shapeData.shapeIndex,
            shapeType: is2DSelected ? '2d' : '3d',
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 0.92,
        child: Container(
          decoration: BoxDecoration(
            color: shapeData.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: shapeData.borderColor,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shape
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.asset(
                        _getShapeImagePath(shapeData.name),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to custom painter if image not found
                          return CustomPaint(
                            painter: ShapePainter(
                              shapeName: shapeData.name,
                              color: shapeData.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Shape Name
                Text(
                  shapeData.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Color(0xFF273444),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            offset: const Offset(6, 6),
            blurRadius: 54,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', true),
          _buildNavItem(Icons.school_outlined, 'Learn', false),
          _buildNavItem(Icons.trending_up, 'Progress', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  String _getShapeImagePath(String shapeName) {
    final name = shapeName.toLowerCase();
    final type = is2DSelected ? '2d' : '3d';
    
    if (type == '2d') {
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
          return 'assets/images/$name.png';
      }
    } else {
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
          return 'assets/images/$name.png';
      }
    }
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: isActive
              ? const Color(0xFF8CA9FF)
              : const Color(0xFF49596E).withOpacity(0.64),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isActive
                ? const Color(0xFF8CA9FF)
                : const Color(0xFF49596E).withOpacity(0.64),
          ),
        ),
      ],
    );
  }
}

class ShapeCardData {
  final String name;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final int shapeIndex;

  ShapeCardData({
    required this.name,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.shapeIndex,
  });
}

class ShapePainter extends CustomPainter {
  final String shapeName;
  final Color color;

  ShapePainter({
    required this.shapeName,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    switch (shapeName) {
      case 'Circle':
        canvas.drawCircle(center, size.width * 0.35, paint);
        break;
      case 'Square':
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * 0.6,
          height: size.width * 0.6,
        );
        canvas.drawRect(rect, paint);
        break;
      case 'Rectangle':
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * 0.7,
          height: size.width * 0.45,
        );
        canvas.drawRect(rect, paint);
        break;
      case 'Triangle':
        final path = Path();
        path.moveTo(center.dx, center.dy - size.height * 0.3);
        path.lineTo(center.dx - size.width * 0.35, center.dy + size.height * 0.25);
        path.lineTo(center.dx + size.width * 0.35, center.dy + size.height * 0.25);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'Sphere':
        // Draw a circle with gradient effect for 3D look
        canvas.drawCircle(center, size.width * 0.35, paint);
        break;
      case 'Cube':
        // Simple cube representation
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * 0.5,
          height: size.width * 0.5,
        );
        canvas.drawRect(rect, paint);
        // Draw simple 3D edges
        paint.color = color.withOpacity(0.6);
        final path = Path();
        path.moveTo(rect.right, rect.top);
        path.lineTo(rect.right + 15, rect.top - 15);
        path.lineTo(rect.right + 15, rect.bottom - 15);
        path.lineTo(rect.right, rect.bottom);
        canvas.drawPath(path, paint);
        break;
      case 'Cylinder':
        // Draw cylinder
        final topEllipse = Rect.fromCenter(
          center: Offset(center.dx, center.dy - size.height * 0.2),
          width: size.width * 0.5,
          height: size.height * 0.15,
        );
        canvas.drawOval(topEllipse, paint);
        
        final bodyRect = Rect.fromLTRB(
          center.dx - size.width * 0.25,
          center.dy - size.height * 0.2,
          center.dx + size.width * 0.25,
          center.dy + size.height * 0.3,
        );
        canvas.drawRect(bodyRect, paint);
        
        final bottomEllipse = Rect.fromCenter(
          center: Offset(center.dx, center.dy + size.height * 0.3),
          width: size.width * 0.5,
          height: size.height * 0.15,
        );
        canvas.drawOval(bottomEllipse, paint);
        break;
      case 'Cone':
        // Draw cone
        final path = Path();
        path.moveTo(center.dx, center.dy - size.height * 0.3);
        path.lineTo(center.dx - size.width * 0.35, center.dy + size.height * 0.3);
        path.lineTo(center.dx + size.width * 0.35, center.dy + size.height * 0.3);
        path.close();
        canvas.drawPath(path, paint);
        
        // Base ellipse
        final baseEllipse = Rect.fromCenter(
          center: Offset(center.dx, center.dy + size.height * 0.3),
          width: size.width * 0.7,
          height: size.height * 0.15,
        );
        canvas.drawOval(baseEllipse, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
