import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/ml/detection.dart';
import 'package:ganithamithura/ml/yolo_detector.dart';

class ObjectCaptureYoloScreen extends StatefulWidget {
  const ObjectCaptureYoloScreen({super.key});

  @override
  State<ObjectCaptureYoloScreen> createState() => _ObjectCaptureYoloScreenState();
}

class _ObjectCaptureYoloScreenState extends State<ObjectCaptureYoloScreen> {
  CameraController? _controller;
  late final YoloDetectorFile _detector;

  bool _loading = true;
  bool _running = false;
  List<Detection> _detections = [];

  @override
  void initState() {
    super.initState();
    _detector = YoloDetectorFile();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _detector.load();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Init failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  Future<void> _captureAndDetect() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_running) return;

    setState(() {
      _running = true;
      _detections = [];
    });

    try {
      final shot = await c.takePicture();
      debugPrint('✅ captured: ${shot.path}');

      final dets = await _detector.detectFile(
        shot.path,
        confThreshold: 0.35,
        iouThreshold: 0.45,
      );

      debugPrint('✅ dets: ${dets.length}');

      if (!mounted) return;
      setState(() => _detections = dets);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detect failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _useTopDetection() {
    if (_detections.isEmpty) return;
    Get.back(result: _detections.first.label);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(body: Center(child: Text('Camera not ready')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture and Identify'),
        actions: [
          if (_detections.isNotEmpty)
            TextButton(
              onPressed: _useTopDetection,
              child: const Text('Use', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: CameraPreview(c),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _running ? null : _captureAndDetect,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_running ? 'Detecting...' : 'Capture and Identify'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _detections.isEmpty
                ? const Center(child: Text('No detections yet'))
                : ListView.builder(
                    itemCount: _detections.length,
                    itemBuilder: (_, i) {
                      final d = _detections[i];
                      return ListTile(
                        title: Text(d.label),
                        subtitle: Text('Confidence: ${(d.score * 100).toStringAsFixed(1)}%'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

