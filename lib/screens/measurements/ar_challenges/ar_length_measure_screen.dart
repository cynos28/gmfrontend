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

class ARLengthMeasureScreen extends StatefulWidget {
  const ARLengthMeasureScreen({Key? key}) : super(key: key);

  @override
  State<ARLengthMeasureScreen> createState() => _ARLengthMeasureScreenState();
}

class _ARLengthMeasureScreenState extends State<ARLengthMeasureScreen> with SingleTickerProviderStateMixin {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  // 3D positions in AR world space
  Vector3? startPoint;
  Vector3? endPoint;
  double? lengthMeters;

  // Which point to set/adjust next
  bool isSettingStart = true;

  // Animation controller for fun effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
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
                  color: const Color(0xFF4ECDC4).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.straighten_rounded,
              size: 24,
              color: Color(0xFF4ECDC4),
            ),
            SizedBox(width: 8),
            Text(
              "Measure Length",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (startPoint != null || endPoint != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
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

          // Animated crosshair for aiming
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
                        color: isSettingStart
                            ? const Color(0xFF4ECDC4)
                            : const Color(0xFFFF6B9D),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSettingStart
                              ? const Color(0xFF4ECDC4)
                              : const Color(0xFFFF6B9D)).withOpacity(0.5),
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
                          color: isSettingStart
                              ? const Color(0xFF4ECDC4)
                              : const Color(0xFFFF6B9D),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Cute character helper
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CuteCharacter(
                    size: 60,
                    color: const Color(0xFF4ECDC4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getInstructionText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  if (startPoint != null || endPoint != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (startPoint != null)
                          _buildFunPointBadge('START', const Color(0xFF4ECDC4)),
                        if (startPoint != null && endPoint != null)
                          const SizedBox(width: 12),
                        if (endPoint != null)
                          _buildFunPointBadge('END', const Color(0xFFFF6B9D)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Big colorful reposition buttons
          if (startPoint != null && endPoint != null)
            Positioned(
              bottom: lengthMeters != null ? 260 : 120,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: _buildFunRepositionButton(
                      'Move START',
                      const Color(0xFF4ECDC4),
                          () => setState(() => isSettingStart = true),
                      isActive: isSettingStart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFunRepositionButton(
                      'Move END',
                      const Color(0xFFFF6B9D),
                          () => setState(() => isSettingStart = false),
                      isActive: !isSettingStart,
                    ),
                  ),
                ],
              ),
            ),

          // Measurement result
          if (lengthMeters != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.celebration_rounded,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Great Job!",
                          style: TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4ECDC4),
                            Color(0xFF3DBDB3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${(lengthMeters! * 100).toStringAsFixed(1)} cm",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "That's ${lengthMeters!.toStringAsFixed(3)} meters!",
                        style: const TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: lengthMeters != null
          ? Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: _confirmMeasurement,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 12,
            shadowColor: const Color(0xFF4ECDC4).withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.check_circle_rounded,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Use This Measurement",
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

  Widget _buildFunPointBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunRepositionButton(
      String label,
      Color color,
      VoidCallback onPressed,
      {bool isActive = false}
      ) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isActive ? 0.4 : 0.15),
              blurRadius: isActive ? 16 : 8,
              offset: Offset(0, isActive ? 6 : 3),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  IconData _getCharacterIcon() {
    if (startPoint == null) {
      return Icons.touch_app_rounded;
    } else if (endPoint == null) {
      return Icons.my_location_rounded;
    } else {
      return Icons.done_all_rounded;
    }
  }

  String _getInstructionText() {
    if (startPoint == null) {
      return "Hi! Let's measure something!\nPoint the blue circle at where you want to START\nThen tap the screen!";
    } else if (endPoint == null) {
      return "Great job!\nNow point the pink circle where you want to END\nThen tap the screen!";
    } else {
      return "Awesome!\nYou can move the points using buttons below\nor tap the confirm button to save!";
    }
  }

  void _onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;
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

    if (isSettingStart || startPoint == null) {
      _setStartPoint(position);
    } else {
      _setEndPoint(position);
    }
  }

  void _setStartPoint(Vector3 point) {
    setState(() {
      startPoint = point;
      isSettingStart = false;
      if (endPoint != null) {
        endPoint = null;
        lengthMeters = null;
      }
    });

    _showFunSnackBar('Awesome! START point is set!', isSuccess: true);
  }

  void _setEndPoint(Vector3 point) {
    if (startPoint == null) return;

    setState(() {
      endPoint = point;
    });

    _updateMeasurement();
    _showFunSnackBar('Yay! END point is set! You did it!', isSuccess: true);
  }

  void _updateMeasurement() {
    if (startPoint == null || endPoint == null) {
      setState(() => lengthMeters = null);
      return;
    }

    final s = startPoint!;
    final e = endPoint!;

    final dx = e.x - s.x;
    final dy = e.y - s.y;
    final dz = e.z - s.z;
    final distance = math.sqrt(dx * dx + dy * dy + dz * dz);

    setState(() {
      lengthMeters = distance;
    });
  }

  void _reset() {
    setState(() {
      startPoint = null;
      endPoint = null;
      lengthMeters = null;
      isSettingStart = true;
    });

    _showFunSnackBar('Let\'s start fresh! Ready to measure again!');
  }

  void _confirmMeasurement() {
    if (lengthMeters == null) {
      _showFunSnackBar('Oops! No measurement yet!', isError: true);
      return;
    }

    final valueInCm = (lengthMeters! * 100).toStringAsFixed(1);

    _showFunSnackBar('Perfect! Measurement saved: $valueInCm cm!', isSuccess: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      Get.back(result: valueInCm);
    });
  }

  void _showFunSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;

    Color bgColor = const Color(0xFF6C63FF);
    if (isSuccess) bgColor = const Color(0xFF4ECDC4);
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

  @override
  void dispose() {
    _pulseController.dispose();
    
    // Workaround for ar_flutter_plugin disposal crash
    // The plugin has a race condition where the surface producer
    // gets disposed before the AR session cleanup completes.
    // We delay disposal slightly to avoid the crash.
    if (arSessionManager != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          arSessionManager?.dispose();
        } catch (e) {
          // Silently catch any disposal errors
          print('AR session disposal error (can be ignored): $e');
        }
      });
    }
    
    super.dispose();
  }
}