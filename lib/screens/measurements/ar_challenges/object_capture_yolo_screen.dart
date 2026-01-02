import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../ml/detection.dart';
import '../../../ml/yolo_detector.dart';

class ObjectCaptureYoloScreen extends StatefulWidget {
  const ObjectCaptureYoloScreen({super.key});

  @override
  State<ObjectCaptureYoloScreen> createState() => _ObjectCaptureYoloScreenState();
}

class _ObjectCaptureYoloScreenState extends State<ObjectCaptureYoloScreen> {
  CameraController? _controller;
  late final YoloDetectorFile _detector;
  bool _loading = true;
  bool _scanning = false;
  List<Detection> _detections = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _detector = YoloDetectorFile();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception("No camera found");
      
      _controller = CameraController(
        cams.first, 
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      await _detector.load();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oops! Camera error: $e')),
        );
      }
    }
  }

  Future<void> _scan() async {
    if (_scanning || _controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _scanning = true;
      _detections = [];
      _selectedIndex = null;
    });
    
    try {
      final image = await _controller!.takePicture();
      final detections = await _detector.detectFile(image.path);
      if (mounted) {
        setState(() {
          _detections = detections;
          // Auto-select if only one detection
          if (_detections.length == 1) {
            _selectedIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _handleTapOnDetection(Offset tapPosition) {
    for (int i = 0; i < _detections.length; i++) {
      final box = _detections[i].box;
      if (box.contains(tapPosition)) {
        setState(() => _selectedIndex = i);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFBEE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 6, color: Colors.orangeAccent),
              SizedBox(height: 24),
              Text('🌟 Getting ready...', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEE),
      appBar: AppBar(
        title: const Text('✨ Find Treasures!', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orangeAccent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 30, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // 1. Camera Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.orangeAccent, width: 8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_controller != null) CameraPreview(_controller!),
                          if (_detections.isNotEmpty)
                            GestureDetector(
                              onTapDown: (details) {
                                _handleTapOnDetection(details.localPosition);
                              },
                              child: CustomPaint(
                                painter: SelectableDetectionPainter(
                                  _detections,
                                  _selectedIndex,
                                ),
                              ),
                            ),
                          if (_scanning)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Text("🔭 Looking...", 
                                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Interaction Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Result Labels
                    SizedBox(
                      height: 50,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _detections.isEmpty 
                          ? const Text("Point & tap the button!", 
                              style: TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.w600))
                          : _detections.length > 1 && _selectedIndex == null
                            ? const Text("👆 Tap on the object you want!", 
                                style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _detections.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final d = entry.value;
                                    final isSelected = idx == _selectedIndex;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedIndex = idx),
                                        child: Chip(
                                          backgroundColor: isSelected ? Colors.purpleAccent : Colors.grey,
                                          label: Text(
                                            d.label, 
                                            style: TextStyle(
                                              color: Colors.white, 
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Big Round Capture Button
                    GestureDetector(
                      onTap: _scanning ? null : _scan,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: _scanning ? Colors.grey : Colors.greenAccent[400],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                          border: Border.all(color: Colors.white, width: 6),
                        ),
                        child: Icon(
                          _scanning ? Icons.hourglass_bottom : Icons.camera_alt,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Success Confirmation Button
                    if (_detections.isNotEmpty && !_scanning && _selectedIndex != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, _detections[_selectedIndex!].label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                          ),
                          child: const Text(
                            "YES! THAT'S IT! 🌟", 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w900, // Fixed the .black error
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SelectableDetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final int? selectedIndex;
  
  SelectableDetectionPainter(this.detections, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final isSelected = i == selectedIndex;
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 8.0 : 4.0
        ..color = isSelected ? Colors.greenAccent : Colors.yellowAccent
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromLTWH(
        detection.box.left, 
        detection.box.top, 
        detection.box.width, 
        detection.box.height
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(15)), 
        paint
      );
      
      // Draw label background for selected item
      if (isSelected) {
        final textSpan = TextSpan(
          text: detection.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final labelRect = Rect.fromLTWH(
          detection.box.left,
          detection.box.top - 30,
          textPainter.width + 16,
          24,
        );
        
        final labelPaint = Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.fill;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(12)),
          labelPaint,
        );
        
        textPainter.paint(
          canvas,
          Offset(detection.box.left + 8, detection.box.top - 28),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleDetectionPainter extends CustomPainter {
  final List<Detection> detections;
  SimpleDetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.yellowAccent
      ..strokeCap = StrokeCap.round;

    for (var detection in detections) {
      final rect = Rect.fromLTWH(
        detection.box.left, 
        detection.box.top, 
        detection.box.width, 
        detection.box.height
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(15)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}