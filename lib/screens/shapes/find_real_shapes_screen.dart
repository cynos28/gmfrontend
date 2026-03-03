import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/widgets/home/home_widgets.dart';

/// FindRealShapesScreen - Camera screen to detect shapes in real world
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
        
        // Hide instructions after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Detection Notice',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
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
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Capture the image
      final image = await _cameraController!.takePicture();
      
      // Send image to shape detection API
      await _detectShapeFromImage(image.path);
      
    } catch (e) {
      Get.back(); // Close loading dialog
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _detectShapeFromImage(String imagePath) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/shapes-patterns/detect-shape/');
      
      var request = http.MultipartRequest('POST', url);
      
      // Add the image file as JPEG
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_file',
          imagePath,
          filename: 'shape_image.jpg',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Get.back(); // Close loading dialog

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final detectedShape = result['shape'] ?? 'Unknown';
        
        // Check if no shape was detected
        if (detectedShape == 'None' || detectedShape == 'Unknown') {
          _showError(
            'No clear shape detected!\n\n'
            'Tips:\n'
            '• Point camera at a clear geometric shape\n'
            '• Ensure good lighting\n'
            '• Try simple shapes: Circle, Square, Triangle\n'
            '• Keep the shape centered and in focus'
          );
        } else {
          // Show result dialog
          _showShapeDetectionResult(detectedShape);
        }
      } else {
        _showError('Failed to detect shape: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      _showError('Error detecting shape: $e');
    }
  }

  void _showShapeDetectionResult(String shape) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Shape Detected!',
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Detected Shape:',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shape,
              style: const TextStyle(
                color: Color(0xFFE9638F),
                fontSize: 24,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: Color(0xFFE9638F),
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9638F),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Be Vietnam Pro',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Navigate to home
      Get.back();
      return;
    }

    if (index == _currentNavIndex) {
      // Already on current tab
      return;
    }

    // TODO: Navigate to other screens when ready
    Get.snackbar(
      'Coming Soon',
      'This feature will be available soon',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5ECF0),
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview background
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              // Loading or placeholder background
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFE5ECF0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing camera...',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.50),
                            fontSize: 17,
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main content overlay
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        width: 31,
                        height: 31,
                        decoration: ShapeDecoration(
                          color: const Color(0x7FD9D9D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Colors.black,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      const Expanded(
                        child: Text(
                          'Find Real Shapes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: 'Be Vietnam Pro',
                            fontWeight: FontWeight.w700,
                            height: 1.10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info button
                      Container(
                        width: 31,
                        height: 31,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE9638F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Camera preview area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Instruction text overlay
                        if (_showInstructions)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Point at objects to detect shapes!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontFamily: 'Be Vietnam Pro',
                                fontWeight: FontWeight.w600,
                                height: 1.29,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Hint card
                if (_showInstructions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '🔍 Look for circles, squares, triangles around you!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.70),
                          fontSize: 14,
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w400,
                          height: 1.57,
                        ),
                      ),
                    ),
                  ),

                // Capture button
                if (!_showInstructions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    child: Center(
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE9638F),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 32,
                            color: Color(0xFFE9638F),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
