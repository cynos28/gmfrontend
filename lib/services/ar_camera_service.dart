/// AR Camera Service - Handles camera initialization and AR measurement
/// 
/// This service provides:
/// - Camera initialization and lifecycle management
/// - AR measurement overlays
/// - Distance/size estimation using camera parameters
/// - Photo capture of measured objects

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ARCameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  
  // Camera calibration constants (can be adjusted per device)
  // These are approximations - for production, use device-specific calibration
  static const double _defaultFocalLength = 4.0; // mm
  static const double _defaultSensorHeight = 4.8; // mm (typical phone sensor)
  static const double _referenceDistance = 30.0; // cm (calibration distance)
  
  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  
  /// Initialize camera
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      // Use back camera by default
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      
      print('📷 Camera initialized: ${camera.name}');
      
    } catch (e) {
      print('❌ Error initializing camera: $e');
      rethrow;
    }
  }
  
  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    print('📷 Camera disposed');
  }
  
  /// Take a photo and save it
  Future<String?> capturePhoto() async {
    if (!_isInitialized || _controller == null) {
      print('❌ Camera not initialized');
      return null;
    }
    
    try {
      final XFile photo = await _controller!.takePicture();
      
      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${appDir.path}/ar_measurement_$timestamp.jpg';
      
      await File(photo.path).copy(filePath);
      
      print('📸 Photo saved: $filePath');
      return filePath;
      
    } catch (e) {
      print('❌ Error capturing photo: $e');
      return null;
    }
  }
  
  /// Pick image from gallery (for testing without camera)
  Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        print('📷 Image picked from gallery: ${image.path}');
        return image.path;
      }
      
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }
  
  /// Estimate object size using camera parameters
  /// 
  /// This is a simplified estimation. For accurate AR measurements,
  /// use ARCore/ARKit or implement proper camera calibration
  /// 
  /// Parameters:
  /// - pixelHeight: Height of object in pixels on screen
  /// - screenHeight: Total screen height in pixels
  /// - realDistance: Real distance to object in cm (user input or sensor)
  /// 
  /// Returns estimated height in cm
  double estimateSize({
    required double pixelHeight,
    required double screenHeight,
    required double realDistance,
  }) {
    // Simple proportional calculation
    // More accurate with device calibration and depth sensors
    
    final double pixelRatio = pixelHeight / screenHeight;
    final double fov = 60.0; // Typical phone camera FOV in degrees
    final double fovRadians = fov * 3.14159 / 180.0;
    
    // Calculate field of view height at the given distance
    final double fovHeightAtDistance = 2 * realDistance * (fovRadians / 2);
    
    // Object height is proportional to pixel ratio
    final double estimatedHeight = fovHeightAtDistance * pixelRatio;
    
    return estimatedHeight;
  }
  
  /// Convert screen coordinates to measurement
  /// 
  /// Takes two tap points and estimates distance between them
  /// Requires user to specify real distance for calibration
  MeasurementEstimate calculateDistance({
    required Offset point1,
    required Offset point2,
    required Size screenSize,
    required double realReferenceDistance, // User provides this in cm
  }) {
    // Calculate pixel distance
    final double dx = point2.dx - point1.dx;
    final double dy = point2.dy - point1.dy;
    final double pixelDistance = (dx * dx + dy * dy) / 2; // Simplified
    
    // Screen diagonal in pixels
    final double screenDiagonal = (screenSize.width * screenSize.width + 
                                   screenSize.height * screenSize.height) / 2;
    
    // Proportion of screen
    final double proportion = pixelDistance / screenDiagonal;
    
    // Rough estimate (requires calibration)
    final double estimatedCm = proportion * realReferenceDistance * 2;
    
    return MeasurementEstimate(
      value: estimatedCm,
      confidence: 0.7, // Lower confidence without proper calibration
      pixelDistance: pixelDistance,
    );
  }
  
  /// Simple auto-measurement using object detection
  /// This is a placeholder - implement with ML model for production
  Future<MeasurementEstimate?> autoMeasure({
    required Size screenSize,
  }) async {
    // TODO: Implement with object detection model (e.g., TensorFlow Lite)
    // For now, return null - use manual measurement
    print('⚠️ Auto-measurement not yet implemented');
    return null;
  }
}

/// Measurement estimate result
class MeasurementEstimate {
  final double value; // In cm
  final double confidence; // 0.0 - 1.0
  final double pixelDistance;
  
  MeasurementEstimate({
    required this.value,
    required this.confidence,
    required this.pixelDistance,
  });
  
  @override
  String toString() => 'MeasurementEstimate(${value.toStringAsFixed(1)}cm, '
      'confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}
