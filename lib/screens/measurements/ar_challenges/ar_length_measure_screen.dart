import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

class ARLengthMeasureScreen extends StatefulWidget {
  const ARLengthMeasureScreen({Key? key}) : super(key: key);

  @override
  State<ARLengthMeasureScreen> createState() => _ARLengthMeasureScreenState();
}

class _ARLengthMeasureScreenState extends State<ARLengthMeasureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Measurement points
  Offset? _startPoint;
  Offset? _endPoint;
  double? _measuredLength;
  
  // Calibration factor (pixels per cm at 1 meter distance)
  // This is an approximation - ideally calibrated per device
  final double _pixelsPerCmAt1m = 15.0;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera available');
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onTap(TapDownDetails details) {
    if (!_isInitialized) return;

    setState(() {
      if (_startPoint == null) {
        _startPoint = details.localPosition;
        _endPoint = null;
        _measuredLength = null;
      } else {
        _endPoint = details.localPosition;
        _calculateLength();
      }
    });
  }

  void _calculateLength() {
    if (_startPoint == null || _endPoint == null) return;

    // Calculate pixel distance
    final dx = _endPoint!.dx - _startPoint!.dx;
    final dy = _endPoint!.dy - _startPoint!.dy;
    final pixelDistance = math.sqrt(dx * dx + dy * dy);

    // Convert to cm (simplified - assumes object at ~1m distance)
    // For better accuracy, you could add depth estimation
    final lengthCm = pixelDistance / _pixelsPerCmAt1m;

    setState(() {
      _measuredLength = lengthCm;
    });
  }

  void _reset() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _measuredLength = null;
    });
  }

  void _confirmMeasurement() {
    if (_measuredLength == null) return;
    
    final valueInCm = _measuredLength!.toStringAsFixed(1);
    Get.back(result: valueInCm);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Measure Length"),
        backgroundColor: Colors.black,
        actions: [
          if (_startPoint != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _isInitialized
          ? _buildCameraView()
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
      floatingActionButton: _measuredLength != null
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check),
              label: const Text("Use Measurement"),
              onPressed: _confirmMeasurement,
            )
          : null,
    );
  }

  Widget _buildCameraView() {
    return GestureDetector(
      onTapDown: _onTap,
      child: Stack(
        children: [
          // Camera preview
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // Overlay with measurement guides
          CustomPaint(
            size: Size.infinite,
            painter: MeasurementPainter(
              startPoint: _startPoint,
              endPoint: _endPoint,
            ),
          ),

          // Instructions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _startPoint == null
                        ? "Tap to mark the start point"
                        : _endPoint == null
                            ? "Tap to mark the end point"
                            : "Measurement complete!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hold device ~1m from object for best results",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Measurement result
          if (_measuredLength != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Measured Length",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_measuredLength!.toStringAsFixed(1)} cm",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MeasurementPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;

  MeasurementPainter({
    required this.startPoint,
    required this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    // Draw start point
    if (startPoint != null) {
      // Outer circle
      canvas.drawCircle(startPoint!, 20, paint);
      // Inner filled circle
      canvas.drawCircle(startPoint!, 8, fillPaint);
      
      // Crosshair
      canvas.drawLine(
        Offset(startPoint!.dx - 30, startPoint!.dy),
        Offset(startPoint!.dx + 30, startPoint!.dy),
        paint,
      );
      canvas.drawLine(
        Offset(startPoint!.dx, startPoint!.dy - 30),
        Offset(startPoint!.dx, startPoint!.dy + 30),
        paint,
      );
    }

    // Draw end point and line
    if (endPoint != null && startPoint != null) {
      // Line connecting points
      final dashedPaint = Paint()
        ..color = Colors.greenAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(startPoint!, endPoint!, dashedPaint);

      // End point
      canvas.drawCircle(endPoint!, 20, paint);
      canvas.drawCircle(endPoint!, 8, fillPaint);
      
      // Crosshair
      canvas.drawLine(
        Offset(endPoint!.dx - 30, endPoint!.dy),
        Offset(endPoint!.dx + 30, endPoint!.dy),
        paint,
      );
      canvas.drawLine(
        Offset(endPoint!.dx, endPoint!.dy - 30),
        Offset(endPoint!.dx, endPoint!.dy + 30),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MeasurementPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint;
  }
}