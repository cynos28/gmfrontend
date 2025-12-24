import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/ml/yolo_detector.dart';

/// Screen for detecting objects using camera and YOLO model
/// Returns the selected object label to the calling screen
class ObjectDetectScreen extends StatefulWidget {
  const ObjectDetectScreen({super.key});

  @override
  State<ObjectDetectScreen> createState() => _ObjectDetectScreenState();
}

class _ObjectDetectScreenState extends State<ObjectDetectScreen> {
  CameraController? _controller;
  late final YoloDetector _detector;

  List<Detection> _detections = [];
  int _frameCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Detection? _selectedDetection;

  @override
  void initState() {
    super.initState();
    _detector = YoloDetector();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No cameras available';
        });
        return;
      }

      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _detector.load();

      await _controller!.startImageStream((image) async {
        // Throttle: run detection every 3rd frame
        _frameCount++;
        if (_frameCount % 3 != 0) return;

        if (_controller == null || !_controller!.value.isInitialized) return;
        if (_detector.isBusy) return;

        final previewSize = _controller!.value.previewSize;
        if (previewSize == null) return;

        final dets = await _detector.detect(
          image,
          previewW: previewSize.width,
          previewH: previewSize.height,
        );

        if (!mounted) return;
        setState(() => _detections = dets);
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  void _selectDetection(Detection detection) {
    setState(() {
      _selectedDetection = detection;
    });
  }

  void _confirmSelection() {
    if (_selectedDetection != null) {
      // Return the selected object label to the previous screen
      Get.back(result: _selectedDetection!.label);
    }
  }

  void _useManualInput() {
    // Return null to indicate manual input preferred
    Get.back(result: null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading camera and detection model...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _useManualInput,
                  child: const Text('Enter Manually'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(c),
          
          // Detection boxes painter
          CustomPaint(
            painter: _BoxPainter(
              _detections,
              selectedDetection: _selectedDetection,
            ),
          ),
          
          // Instructions overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Point camera at object to measure',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected: ${_detections.length} object${_detections.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          // Detected objects list (bottom sheet)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap to select detected object',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_selectedDetection != null)
                          TextButton.icon(
                            onPressed: _confirmSelection,
                            icon: const Icon(Icons.check),
                            label: const Text('Use'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Detected objects
                  Flexible(
                    child: _detections.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No objects detected yet.\nPoint camera at measurable objects.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _detections.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final det = _detections[index];
                              final isSelected = _selectedDetection == det;
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIconForLabel(det.label),
                                    color: isSelected ? Colors.green : Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  _formatLabel(det.label),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  'Confidence: ${(det.score * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.radio_button_unchecked),
                                onTap: () => _selectDetection(det),
                              );
                            },
                          ),
                  ),
                  
                  // Manual input button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextButton(
                      onPressed: _useManualInput,
                      child: const Text('Enter object name manually'),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Detect Object'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (_selectedDetection != null)
          TextButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  String _formatLabel(String label) {
    // Capitalize first letter and replace hyphens/underscores with spaces
    return label
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData _getIconForLabel(String label) {
    final lowerLabel = label.toLowerCase();
    
    // Classroom objects
    if (lowerLabel.contains('table') || lowerLabel.contains('desk')) {
      return Icons.table_restaurant;
    }
    if (lowerLabel.contains('chair')) return Icons.chair;
    if (lowerLabel.contains('book')) return Icons.book;
    if (lowerLabel.contains('pen') || lowerLabel.contains('pencil')) {
      return Icons.edit;
    }
    if (lowerLabel.contains('ruler')) return Icons.straighten;
    if (lowerLabel.contains('scissor')) return Icons.content_cut;
    if (lowerLabel.contains('bag') || lowerLabel.contains('backpack')) {
      return Icons.backpack;
    }
    if (lowerLabel.contains('laptop')) return Icons.laptop;
    if (lowerLabel.contains('bottle')) return Icons.local_drink;
    if (lowerLabel.contains('clock')) return Icons.access_time;
    if (lowerLabel.contains('fan')) return Icons.air;
    if (lowerLabel.contains('whiteboard')) return Icons.dashboard;
    if (lowerLabel.contains('eraser')) return Icons.cleaning_services;
    if (lowerLabel.contains('sharpener')) return Icons.carpenter;
    if (lowerLabel.contains('remote')) return Icons.settings_remote;
    if (lowerLabel.contains('phone') || lowerLabel.contains('cell')) {
      return Icons.phone_android;
    }
    if (lowerLabel.contains('cup')) return Icons.local_cafe;
    if (lowerLabel.contains('bowl')) return Icons.soup_kitchen;
    if (lowerLabel.contains('keyboard')) return Icons.keyboard;
    if (lowerLabel.contains('mouse')) return Icons.mouse;
    
    return Icons.category;
  }
}

class _BoxPainter extends CustomPainter {
  final List<Detection> dets;
  final Detection? selectedDetection;

  _BoxPainter(this.dets, {this.selectedDetection});

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dets) {
      final isSelected = selectedDetection == d;
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 4 : 2
        ..color = isSelected ? Colors.green : Colors.blue;

      // Scale detection box to canvas size
      // Note: The detection coordinates are relative to the preview size
      // We need to map them to the actual widget size
      final scaleX = size.width / (dets.isEmpty ? size.width : size.width);
      final scaleY = size.height / (dets.isEmpty ? size.height : size.height);

      final rect = Rect.fromLTRB(
        d.box.left * scaleX,
        d.box.top * scaleY,
        d.box.right * scaleX,
        d.box.bottom * scaleY,
      );

      // Draw rounded rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );

      // Draw label background
      final label = '${d.label} ${(d.score * 100).toStringAsFixed(0)}%';
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );
      final textSpan = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final bgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - 20).clamp(0, size.height - 20),
        tp.width + 8,
        18,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = isSelected ? Colors.green : Colors.blue,
      );

      tp.paint(
        canvas,
        Offset(bgRect.left + 4, bgRect.top + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) => true;
}
