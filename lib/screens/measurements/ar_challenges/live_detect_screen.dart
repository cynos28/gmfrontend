import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../ml/yolo_detector.dart';

class LiveDetectScreen extends StatefulWidget {
  const LiveDetectScreen({super.key});

  @override
  State<LiveDetectScreen> createState() => _LiveDetectScreenState();
}

class _LiveDetectScreenState extends State<LiveDetectScreen> {
  CameraController? _controller;
  late final YoloDetector _detector;

  List<Detection> _detections = [];
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _detector = YoloDetector();
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    final cam = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);

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

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = c.value.previewSize!;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(c),
          CustomPaint(
            painter: _BoxPainter(_detections),
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                'Detections: ${_detections.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Detection> dets;
  _BoxPainter(this.dets);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textStyle = const TextStyle(color: Colors.white, fontSize: 14);

    for (final d in dets) {
      final r = Rect.fromLTRB(
        d.box.left / (dets.isEmpty ? 1 : 1),
        d.box.top / (dets.isEmpty ? 1 : 1),
        d.box.right / (dets.isEmpty ? 1 : 1),
        d.box.bottom / (dets.isEmpty ? 1 : 1),
      );

      // Map from preview coordinates to screen size
      final sx = size.width / (dets.isEmpty ? size.width : size.width);
      final sy = size.height / (dets.isEmpty ? size.height : size.height);

      final rr = Rect.fromLTRB(r.left * sx, r.top * sy, r.right * sx, r.bottom * sy);

      canvas.drawRect(rr, paint);

      final label = '${d.label} ${(d.score * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(rr.left, (rr.top - 18).clamp(0, size.height)));
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) => true;
}