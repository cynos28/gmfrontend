import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:ganithamithura/widgets/cute_character.dart';

// Measurement steps for area calculation
enum AreaMeasurementStep { lengthStart, lengthEnd, widthStart, widthEnd, complete }

class ARAreaMeasureScreen extends StatefulWidget {
  const ARAreaMeasureScreen({Key? key}) : super(key: key);

  @override
  State<ARAreaMeasureScreen> createState() => _ARAreaMeasureScreenState();
}

class _ARAreaMeasureScreenState extends State<ARAreaMeasureScreen> with SingleTickerProviderStateMixin {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  // Current step
  AreaMeasurementStep currentStep = AreaMeasurementStep.lengthStart;

  // Length measurement points
  Vector3? lengthStartPoint;
  Vector3? lengthEndPoint;
  double? lengthCm;

  // Width measurement points
  Vector3? widthStartPoint;
  Vector3? widthEndPoint;
  double? widthCm;

  // Calculated area
  double? areaCm2;

  // Animation controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Colors for different steps
  static const Color lengthColor = Color(0xFF4CAF50);    // Green
  static const Color widthColor = Color(0xFF2196F3);     // Blue  
  static const Color areaColor = Color(0xFFFF9800);      // Orange
  static const Color startColor = Color(0xFF4ECDC4);     // Teal
  static const Color endColor = Color(0xFFFF6B9D);       // Pink

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (arSessionManager != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          arSessionManager?.dispose();
        } catch (e) {
          print('AR session disposal error (can be ignored): $e');
        }
      });
    }
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    arObjectManager!.onInitialize();
    arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
  }

  void _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) {
      _showFunSnackBar('Oops! Point at a flat surface and try again!', isError: true);
      return;
    }

    final hitResult = hitTestResults.first;
    final position = Vector3(
      hitResult.worldTransform.getColumn(3).x,
      hitResult.worldTransform.getColumn(3).y,
      hitResult.worldTransform.getColumn(3).z,
    );

    setState(() {
      switch (currentStep) {
        case AreaMeasurementStep.lengthStart:
          lengthStartPoint = position;
          currentStep = AreaMeasurementStep.lengthEnd;
          _showFunSnackBar('Length START set! Now tap the END point.', isSuccess: true);
          break;

        case AreaMeasurementStep.lengthEnd:
          lengthEndPoint = position;
          lengthCm = _calculateDistance(lengthStartPoint!, lengthEndPoint!) * 100;
          currentStep = AreaMeasurementStep.widthStart;
          _showFunSnackBar('Length: ${lengthCm!.toStringAsFixed(1)} cm! Now measure the WIDTH.', isSuccess: true);
          break;

        case AreaMeasurementStep.widthStart:
          widthStartPoint = position;
          currentStep = AreaMeasurementStep.widthEnd;
          _showFunSnackBar('Width START set! Now tap the END point.', isSuccess: true);
          break;

        case AreaMeasurementStep.widthEnd:
          widthEndPoint = position;
          widthCm = _calculateDistance(widthStartPoint!, widthEndPoint!) * 100;
          _calculateArea();
          currentStep = AreaMeasurementStep.complete;
          _showFunSnackBar('Awesome! Area calculated!', isSuccess: true);
          break;

        case AreaMeasurementStep.complete:
          // Do nothing, measurement is complete
          break;
      }
    });
  }

  double _calculateDistance(Vector3 start, Vector3 end) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final dz = end.z - start.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  void _calculateArea() {
    if (lengthCm != null && widthCm != null) {
      areaCm2 = lengthCm! * widthCm!;
    }
  }

  void _reset() {
    setState(() {
      currentStep = AreaMeasurementStep.lengthStart;
      lengthStartPoint = null;
      lengthEndPoint = null;
      lengthCm = null;
      widthStartPoint = null;
      widthEndPoint = null;
      widthCm = null;
      areaCm2 = null;
    });
    _showFunSnackBar('Let\'s start fresh! Ready to measure again!');
  }

  void _confirmMeasurement() {
    if (areaCm2 == null) {
      _showFunSnackBar('Oops! No measurement yet!', isError: true);
      return;
    }

    final valueInCm2 = areaCm2!.toStringAsFixed(2);
    _showFunSnackBar('Perfect! Area saved: $valueInCm2 cm²!', isSuccess: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      Get.back(result: valueInCm2);
    });
  }

  Color _getCurrentCrosshairColor() {
    switch (currentStep) {
      case AreaMeasurementStep.lengthStart:
        return startColor;
      case AreaMeasurementStep.lengthEnd:
        return endColor;
      case AreaMeasurementStep.widthStart:
        return startColor;
      case AreaMeasurementStep.widthEnd:
        return endColor;
      case AreaMeasurementStep.complete:
        return areaColor;
    }
  }

  String _getInstructionText() {
    switch (currentStep) {
      case AreaMeasurementStep.lengthStart:
        return "Hi! Let's measure the AREA!\nFirst, point at the START of the LENGTH\nThen tap the screen!";
      case AreaMeasurementStep.lengthEnd:
        return "Great!\nNow tap the END of the LENGTH";
      case AreaMeasurementStep.widthStart:
        return "Length measured!\nNow point at the START of the WIDTH\nThen tap the screen!";
      case AreaMeasurementStep.widthEnd:
        return "Almost done!\nNow tap the END of the WIDTH";
      case AreaMeasurementStep.complete:
        return "Awesome! Area calculated!\nTap confirm to save it!";
    }
  }

  String _getCurrentStepLabel() {
    switch (currentStep) {
      case AreaMeasurementStep.lengthStart:
        return 'LENGTH START';
      case AreaMeasurementStep.lengthEnd:
        return 'LENGTH END';
      case AreaMeasurementStep.widthStart:
        return 'WIDTH START';
      case AreaMeasurementStep.widthEnd:
        return 'WIDTH END';
      case AreaMeasurementStep.complete:
        return 'COMPLETE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: lengthColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: lengthColor, size: 24),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.square_foot_rounded, size: 24, color: lengthColor),
            SizedBox(width: 8),
            Text(
              "Measure Area",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: lengthColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (lengthStartPoint != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: lengthColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: lengthColor, size: 24),
                  onPressed: _reset,
                  tooltip: 'Start Over',
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // Animated crosshair
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getCurrentCrosshairColor(),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getCurrentCrosshairColor().withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCurrentCrosshairColor(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Current step indicator badge
          if (currentStep != AreaMeasurementStep.complete)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getCurrentCrosshairColor(),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentCrosshairColor().withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _getCurrentStepLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),

          // Instruction card with cute character
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: lengthColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CuteCharacter(size: 50, color: lengthColor),
                  const SizedBox(height: 12),
                  Text(
                    _getInstructionText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress badges
                  _buildProgressBadges(),
                ],
              ),
            ),
          ),

          // Measurement results card
          if (lengthCm != null || widthCm != null)
            Positioned(
              bottom: areaCm2 != null ? 100 : 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Visual diagram showing Length x Width
                    if (lengthCm != null)
                      _buildAreaDiagram(),
                    
                    if (lengthCm != null) const SizedBox(height: 16),
                    
                    // Length result
                    _buildMeasurementRow(
                      'Length',
                      lengthCm,
                      lengthColor,
                      Icons.straighten_rounded,
                    ),
                    
                    if (widthCm != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Width result
                      _buildMeasurementRow(
                        'Width',
                        widthCm,
                        widthColor,
                        Icons.height_rounded,
                      ),
                    ],

                    if (areaCm2 != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              areaColor.withOpacity(0.1),
                              areaColor.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: areaColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.celebration_rounded, color: areaColor, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'TOTAL AREA',
                                  style: TextStyle(
                                    color: areaColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${areaCm2!.toStringAsFixed(2)} cm²',
                              style: const TextStyle(
                                color: areaColor,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lengthCm!.toStringAsFixed(1)} cm × ${widthCm!.toStringAsFixed(1)} cm',
                              style: TextStyle(
                                color: areaColor.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: areaCm2 != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _confirmMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: areaColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 12,
                  shadowColor: areaColor.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Use This Area",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProgressBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Length badge
        _buildBadge(
          'L',
          lengthCm != null,
          lengthColor,
          currentStep == AreaMeasurementStep.lengthStart || currentStep == AreaMeasurementStep.lengthEnd,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.close,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        // Width badge
        _buildBadge(
          'W',
          widthCm != null,
          widthColor,
          currentStep == AreaMeasurementStep.widthStart || currentStep == AreaMeasurementStep.widthEnd,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.drag_handle,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        // Area badge
        _buildBadge(
          'A',
          areaCm2 != null,
          areaColor,
          currentStep == AreaMeasurementStep.complete,
        ),
      ],
    );
  }

  Widget _buildBadge(String label, bool isComplete, Color color, bool isActive) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isComplete ? color : (isActive ? color.withOpacity(0.2) : Colors.grey[200]),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isComplete
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                label,
                style: TextStyle(
                  color: isActive ? color : Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double? value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value != null ? '${value.toStringAsFixed(2)} cm' : '--',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: value != null ? color : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Visual diagram showing length and width with lines
  Widget _buildAreaDiagram() {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 120),
        painter: AreaDiagramPainter(
          lengthCm: lengthCm,
          widthCm: widthCm,
          areaCm2: areaCm2,
          lengthColor: lengthColor,
          widthColor: widthColor,
          areaColor: areaColor,
        ),
      ),
    );
  }

  void _showFunSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;

    Color bgColor = const Color(0xFF6C63FF);
    if (isSuccess) bgColor = lengthColor;
    if (isError) bgColor = const Color(0xFFFF6B9D);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : 
                isError ? Icons.warning_rounded : 
                Icons.info_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }
}

/// Custom painter to draw the area diagram with length and width lines
class AreaDiagramPainter extends CustomPainter {
  final double? lengthCm;
  final double? widthCm;
  final double? areaCm2;
  final Color lengthColor;
  final Color widthColor;
  final Color areaColor;

  AreaDiagramPainter({
    required this.lengthCm,
    required this.widthCm,
    required this.areaCm2,
    required this.lengthColor,
    required this.widthColor,
    required this.areaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 20;
    final double rectWidth = size.width - padding * 2 - 60;
    final double rectHeight = size.height - padding * 2 - 20;
    final double left = padding + 30;
    final double top = padding;

    // Draw filled rectangle (area)
    if (areaCm2 != null) {
      final areaPaint = Paint()
        ..color = areaColor.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, rectWidth, rectHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, areaPaint);
    }

    // Draw rectangle border (dashed if width not measured yet)
    final borderPaint = Paint()
      ..color = widthCm != null ? areaColor : Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, borderPaint);

    // Draw LENGTH line (bottom of rectangle) - GREEN
    final lengthPaint = Paint()
      ..color = lengthColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Length line at bottom
    final lengthY = top + rectHeight + 10;
    canvas.drawLine(
      Offset(left, lengthY),
      Offset(left + rectWidth, lengthY),
      lengthPaint,
    );

    // Draw length endpoints (circles)
    final pointPaint = Paint()
      ..color = lengthColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(left, lengthY), 6, pointPaint);
    canvas.drawCircle(Offset(left + rectWidth, lengthY), 6, pointPaint);

    // Draw LENGTH label
    if (lengthCm != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${lengthCm!.toStringAsFixed(1)} cm',
          style: TextStyle(
            color: lengthColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + rectWidth / 2 - textPainter.width / 2, lengthY + 4),
      );
    }

    // Draw WIDTH line (left side of rectangle) - BLUE
    if (widthCm != null || 
        (lengthCm != null && widthCm == null)) {
      final widthPaint = Paint()
        ..color = widthCm != null ? widthColor : Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = widthCm != null ? 4 : 2
        ..strokeCap = StrokeCap.round;

      // Width line on left side
      final widthX = left - 10;
      canvas.drawLine(
        Offset(widthX, top),
        Offset(widthX, top + rectHeight),
        widthPaint,
      );

      // Draw width endpoints if measured
      if (widthCm != null) {
        final widthPointPaint = Paint()
          ..color = widthColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(widthX, top), 6, widthPointPaint);
        canvas.drawCircle(Offset(widthX, top + rectHeight), 6, widthPointPaint);

        // Draw WIDTH label
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${widthCm!.toStringAsFixed(1)}',
            style: TextStyle(
              color: widthColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // Rotate and draw text vertically
        canvas.save();
        canvas.translate(widthX - 8, top + rectHeight / 2 + textPainter.width / 2);
        canvas.rotate(-math.pi / 2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // Draw AREA text in center if complete
    if (areaCm2 != null) {
      final areaPainter = TextPainter(
        text: TextSpan(
          text: 'Area',
          style: TextStyle(
            color: areaColor.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      areaPainter.layout();
      areaPainter.paint(
        canvas,
        Offset(left + rectWidth / 2 - areaPainter.width / 2, top + rectHeight / 2 - 16),
      );

      final valuePainter = TextPainter(
        text: TextSpan(
          text: '${areaCm2!.toStringAsFixed(1)} cm²',
          style: TextStyle(
            color: areaColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas,
        Offset(left + rectWidth / 2 - valuePainter.width / 2, top + rectHeight / 2 + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant AreaDiagramPainter oldDelegate) {
    return oldDelegate.lengthCm != lengthCm ||
           oldDelegate.widthCm != widthCm ||
           oldDelegate.areaCm2 != areaCm2;
  }
}
