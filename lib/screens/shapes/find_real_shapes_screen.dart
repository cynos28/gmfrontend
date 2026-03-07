import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

/// Kid-Friendly FindRealShapesScreen - Camera screen to detect shapes in real world
class FindRealShapesScreen extends StatefulWidget {
  const FindRealShapesScreen({super.key});

  @override
  State<FindRealShapesScreen> createState() => _FindRealShapesScreenState();
}

class _FindRealShapesScreenState extends State<FindRealShapesScreen> {
  int _currentNavIndex = 0;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found on device');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Hide instructions after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showInstructions = false;
            });
          }
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  void _showError(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Notice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFE9638F))),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera is not ready');
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFFE9638F))),
        barrierDismissible: false,
      );

      final image = await _cameraController!.takePicture();
      await _detectShapeFromImage(image.path);
    } catch (e) {
      Get.back(); // Close loading
      _showError('Failed to capture: $e');
    }
  }

  Future<void> _detectShapeFromImage(String imagePath) async {
    try {
      final url = Uri.parse('${AppConstants.shapeBaseUrl}/detect-shape/');
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('image_file', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Get.back(); // Close loading

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final detectedShape = result['shape'] ?? 'Unknown';
        
        if (detectedShape == 'None' || detectedShape == 'Unknown') {
          _showError('No clear shape detected! 🧐\nTry pointing at a clear object in good light.');
        } else {
          _showShapeDetectionResult(detectedShape);
        }
      } else {
        _showError('Connection error! Status: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      Get.back();
      _showError('Oops! Error detecting shape:\n$e');
    }
  }

  void _showShapeDetectionResult(String shape) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            const Text('Shape Detected!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE9638F).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                shape,
                style: const TextStyle(color: Color(0xFFE9638F), fontSize: 34, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9638F),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Try Another!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
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
      body: SafeArea(
        child: Stack(
          children: [
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(child: CameraPreview(_cameraController!))
            else
              const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),

            Column(
              children: [
                _buildHeader(),
                const Spacer(),
                if (_showInstructions) _buildInstructionOverlay(),
                const SizedBox(height: 40),
                if (!_showInstructions) _buildCaptureButton(),
                const SizedBox(height: 110), // Space for bottom nav
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  if (index == 0) Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 26),
            ),
          ),
          const Text(
            'Find Shapes',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFFE9638F), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 60),
            SizedBox(height: 16),
            Text(
              'Move your camera around to find shapes! 🔍',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
          border: Border.all(color: const Color(0xFFE9638F), width: 6),
        ),
        child: const Center(child: Icon(Icons.camera_rounded, color: Color(0xFFE9638F), size: 54)),
      ),
    );
  }
}
