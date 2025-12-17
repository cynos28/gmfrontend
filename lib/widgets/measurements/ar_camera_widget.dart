/// AR Camera Widget - Camera preview with measurement overlay
/// 
/// Features:
/// - Live camera preview
/// - Tap-to-measure functionality
/// - Visual measurement guides
/// - Photo capture button
/// - Measurement display

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/ar_camera_service.dart';
import '../../utils/constants.dart';

class ARCameraWidget extends StatefulWidget {
  final ARCameraService cameraService;
  final Function(double value, String? photoPath) onMeasurementComplete;
  final Color primaryColor;
  final String measurementType;
  
  const ARCameraWidget({
    Key? key,
    required this.cameraService,
    required this.onMeasurementComplete,
    required this.primaryColor,
    required this.measurementType,
  }) : super(key: key);

  @override
  State<ARCameraWidget> createState() => _ARCameraWidgetState();
}

class _ARCameraWidgetState extends State<ARCameraWidget> {
  // Measurement state
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isMeasuring = false;
  String? _capturedPhotoPath;
  
  // Reference distance for calibration (cm)
  double _referenceDistance = 30.0;
  
  @override
  Widget build(BuildContext context) {
    if (!widget.cameraService.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final controller = widget.cameraService.controller!;
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Camera preview
        SizedBox(
          width: size.width,
          height: size.height * 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CameraPreview(controller),
          ),
        ),
        
        // Measurement overlay
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (details) => _onTapDown(details, size),
            onTapUp: (details) => _onTapUp(details, size),
            child: CustomPaint(
              painter: MeasurementOverlayPainter(
                startPoint: _startPoint,
                endPoint: _endPoint,
                primaryColor: widget.primaryColor,
                screenSize: size,
              ),
            ),
          ),
        ),
        
        // Measurement guides
        _buildMeasurementGuides(size),
        
        // Controls overlay
        _buildControls(),
        
        // Instructions
        _buildInstructions(),
      ],
    );
  }
  
  void _onTapDown(TapDownDetails details, Size screenSize) {
    setState(() {
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
      _isMeasuring = true;
    });
  }
  
  void _onTapUp(TapUpDetails details, Size screenSize) {
    if (_startPoint != null && _endPoint != null) {
      // Calculate measurement
      final estimate = widget.cameraService.calculateDistance(
        point1: _startPoint!,
        point2: _endPoint!,
        screenSize: screenSize,
        realReferenceDistance: _referenceDistance,
      );
      
      setState(() {
        _isMeasuring = false;
      });
      
      // Show result dialog
      _showMeasurementResult(estimate.value);
    }
  }
  
  Widget _buildMeasurementGuides(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: GridOverlayPainter(
            primaryColor: widget.primaryColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
  
  Widget _buildControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Capture photo button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gallery button
              _buildControlButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickFromGallery,
              ),
              const SizedBox(width: 20),
              
              // Capture button
              _buildCaptureButton(),
              const SizedBox(width: 20),
              
              // Settings button
              _buildControlButton(
                icon: Icons.settings,
                label: 'Settings',
                onTap: _showCalibrationDialog,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Reference distance slider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Reference Distance (cm)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const Text('10', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Expanded(
                      child: Slider(
                        value: _referenceDistance,
                        min: 10,
                        max: 100,
                        divisions: 18,
                        activeColor: widget.primaryColor,
                        label: '${_referenceDistance.toInt()} cm',
                        onChanged: (value) {
                          setState(() {
                            _referenceDistance = value;
                          });
                        },
                      ),
                    ),
                    const Text('100', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: widget.primaryColor,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt,
          color: widget.primaryColor,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildInstructions() {
    return Positioned(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: widget.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'How to measure:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInstructionStep('1', 'Tap and drag to measure'),
            _buildInstructionStep('2', 'Adjust reference distance if needed'),
            _buildInstructionStep('3', 'Capture photo of the object'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _capturePhoto() async {
    final photoPath = await widget.cameraService.capturePhoto();
    if (photoPath != null) {
      setState(() {
        _capturedPhotoPath = photoPath;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo captured! ✓'),
          backgroundColor: widget.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _pickFromGallery() async {
    final imagePath = await widget.cameraService.pickImageFromGallery();
    if (imagePath != null) {
      setState(() {
        _capturedPhotoPath = imagePath;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image selected! ✓'),
          backgroundColor: widget.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showMeasurementResult(double value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.straighten, color: widget.primaryColor),
            const SizedBox(width: 8),
            const Text('Measurement Result'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${value.toStringAsFixed(1)} cm',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Is this measurement correct?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _startPoint = null;
                _endPoint = null;
              });
            },
            child: const Text('Retry'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onMeasurementComplete(value, _capturedPhotoPath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibration Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For accurate measurements:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('• Measure a known object first'),
            Text('• Adjust reference distance slider'),
            Text('• Keep camera steady'),
            Text('• Good lighting helps accuracy'),
            SizedBox(height: 12),
            Text(
              'Note: This is an estimate. For precise measurements, use a real ruler.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for measurement overlay
class MeasurementOverlayPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;
  final Color primaryColor;
  final Size screenSize;
  
  MeasurementOverlayPainter({
    required this.startPoint,
    required this.endPoint,
    required this.primaryColor,
    required this.screenSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;
    
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw line
    canvas.drawLine(startPoint!, endPoint!, paint);
    
    // Draw start point
    canvas.drawCircle(startPoint!, 8, fillPaint);
    canvas.drawCircle(startPoint!, 8, paint);
    
    // Draw end point
    canvas.drawCircle(endPoint!, 8, fillPaint);
    canvas.drawCircle(endPoint!, 8, paint);
    
    // Draw measurement endpoints
    _drawEndpoint(canvas, startPoint!, paint);
    _drawEndpoint(canvas, endPoint!, paint);
  }
  
  void _drawEndpoint(Canvas canvas, Offset point, Paint paint) {
    const double lineLength = 20;
    canvas.drawLine(
      Offset(point.dx - lineLength, point.dy),
      Offset(point.dx + lineLength, point.dy),
      paint,
    );
    canvas.drawLine(
      Offset(point.dx, point.dy - lineLength),
      Offset(point.dx, point.dy + lineLength),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(MeasurementOverlayPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
           oldDelegate.endPoint != endPoint;
  }
}

/// Grid overlay painter for visual reference
class GridOverlayPainter extends CustomPainter {
  final Color primaryColor;
  
  GridOverlayPainter({required this.primaryColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    const int gridLines = 10;
    final double spacing = size.height / gridLines;
    
    // Horizontal lines
    for (int i = 1; i < gridLines; i++) {
      final y = spacing * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Vertical lines
    final double vSpacing = size.width / gridLines;
    for (int i = 1; i < gridLines; i++) {
      final x = vSpacing * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.6), // Match camera preview height
        paint,
      );
    }
    
    // Center crosshair
    canvas.drawLine(
      Offset(size.width / 2 - 20, size.height * 0.3),
      Offset(size.width / 2 + 20, size.height * 0.3),
      paint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.3 - 20),
      Offset(size.width / 2, size.height * 0.3 + 20),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(GridOverlayPainter oldDelegate) => false;
}
