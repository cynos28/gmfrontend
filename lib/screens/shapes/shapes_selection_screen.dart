import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'learn_shapes.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/shapes/animated_shape_background.dart';

class ShapesSelectionScreen extends StatefulWidget {
  const ShapesSelectionScreen({super.key});

  @override
  State<ShapesSelectionScreen> createState() => _ShapesSelectionScreenState();
}

class _ShapesSelectionScreenState extends State<ShapesSelectionScreen> with TickerProviderStateMixin {
  bool is2DSelected = true;
  late AnimationController _floatingController;

  final List<ShapeCardData> shapes2D = [
    ShapeCardData(
      name: 'Circle',
      color: const Color(0xFFD946EF),
      bgColor: const Color(0xFFFFEBFF),
      borderColor: const Color(0xFFD946EF),
      shapeIndex: 0,
    ),
    ShapeCardData(
      name: 'Square',
      color: const Color(0xFF2196F3),
      bgColor: const Color(0xFFE3F2FD),
      borderColor: const Color(0xFF2196F3),
      shapeIndex: 1,
    ),
    ShapeCardData(
      name: 'Rectangle',
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFF9800),
      shapeIndex: 3,
    ),
    ShapeCardData(
      name: 'Triangle',
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF4CAF50),
      shapeIndex: 2,
    ),
  ];

  final List<ShapeCardData> shapes3D = [
    ShapeCardData(
      name: 'Sphere',
      color: const Color(0xFFD946EF),
      bgColor: const Color(0xFFFFEBFF),
      borderColor: const Color(0xFFD946EF),
      shapeIndex: 0,
    ),
    ShapeCardData(
      name: 'Cube',
      color: const Color(0xFF2196F3),
      bgColor: const Color(0xFFE3F2FD),
      borderColor: const Color(0xFF2196F3),
      shapeIndex: 1,
    ),
    ShapeCardData(
      name: 'Cylinder',
      color: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFFF3E0),
      borderColor: const Color(0xFFFF9800),
      shapeIndex: 2,
    ),
    ShapeCardData(
      name: 'Cone',
      color: const Color(0xFF4CAF50),
      bgColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF4CAF50),
      shapeIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentShapes = is2DSelected ? shapes2D : shapes3D;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA),
                  Color(0xFFF3E5F5),
                  Color(0xFFFFF9C4),
                ],
              ),
            ),
          ),

          // 2. Animated Background Shapes
          Positioned.fill(
            child: AnimatedShapeBackground(animation: _floatingController),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildToggle(),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 25,
                      mainAxisSpacing: 25,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: currentShapes.length,
                    itemBuilder: (context, index) {
                      return _ShapeCard(
                        shapeData: currentShapes[index],
                        is2D: is2DSelected,
                        index: index,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Choose a Shape',
            style: GoogleFonts.fredoka(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEC76A0),
              shadows: [
                const Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _buildToggleButton('2D Shapes', is2DSelected, () {
            setState(() => is2DSelected = true);
          }),
          _buildToggleButton('3D Shapes', !is2DSelected, () {
            setState(() => is2DSelected = false);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFB199), Color(0xFFFF0844)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF0844).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeCard extends StatelessWidget {
  final ShapeCardData shapeData;
  final bool is2D;
  final int index;

  const _ShapeCard({
    required this.shapeData,
    required this.is2D,
    required this.index,
  });


  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 150)),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value.clamp(0, 1), child: child),
      ),
      child: GestureDetector(
        onTap: () {
          debugPrint('Tapped shape: ${shapeData.name}');
          Get.to(
            () => LearnShapesScreen(
              initialShapeName: shapeData.name,
              shapeType: is2D ? '2d' : '3d',
            ),
            transition: Transition.circularReveal,
            duration: const Duration(milliseconds: 600),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: shapeData.color.withOpacity(0.2), width: 4),
            boxShadow: [
              BoxShadow(
                color: shapeData.color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Hero(
                    tag: 'shape_${is2D ? "2d" : "3d"}_${shapeData.name}',
                    child: Image.asset(
                      _getShapeImagePath(shapeData.name, is2D),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_rounded,
                        size: 60,
                        color: shapeData.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shapeData.name,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getShapeImagePath(String shapeName, bool is2D) {
    final name = shapeName.toLowerCase();
    return is2D ? 'assets/images/2d_shapes/$name.png' : 'assets/images/3d_shapes/$name.png';
  }
}

class ShapeCardData {
  final String name;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final int shapeIndex;

  ShapeCardData({
    required this.name,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.shapeIndex,
  });
}
