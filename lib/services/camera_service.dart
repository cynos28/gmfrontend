import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Camera Service for object detection
/// Handles camera initialization, frame capture, and image processing
class CameraService {
  static CameraService? _instance;
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  CameraService._();

  static CameraService get instance {
    _instance ??= CameraService._();
    return _instance!;
  }

  /// Initialize camera service
  Future<void> initialize() async {
    try {
      debugPrint('📷 Initializing camera service...');
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras found on device');
      }

      // Use back camera by default
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Better for processing
      );

      await _controller!.initialize();
      _isInitialized = true;

      debugPrint('✅ Camera initialized successfully');
      debugPrint('   Camera: ${camera.name}');
      debugPrint('   Resolution: ${_controller!.value.previewSize}');
    } catch (e) {
      debugPrint('❌ Camera initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized && _controller != null;

  /// Get camera controller for preview
  CameraController? get controller => _controller;

  /// Capture current frame as image
  Future<Uint8List> captureFrame() async {
    if (!isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      final bytes = await imageFile.readAsBytes();

      debugPrint('📸 Frame captured: ${bytes.length} bytes');

      return bytes;
    } catch (e) {
      debugPrint('❌ Failed to capture frame: $e');
      rethrow;
    }
  }

  /// Capture and compress frame for API transmission
  Future<Uint8List> captureCompressedFrame({int quality = 80}) async {
    final bytes = await captureFrame();

    try {
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 1024px on longest side)
      img.Image resized = image;
      if (image.width > 1024 || image.height > 1024) {
        final scale =
            1024 / (image.width > image.height ? image.width : image.height);
        resized = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
        );
        debugPrint(
          '📏 Image resized: ${image.width}x${image.height} → ${resized.width}x${resized.height}',
        );
      }

      // Compress as JPEG
      final compressed = img.encodeJpg(resized, quality: quality);
      debugPrint(
        '🗜️ Image compressed: ${bytes.length} → ${compressed.length} bytes',
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      return bytes;
    }
  }

  /// Start streaming frames (for continuous detection)
  Stream<CameraImage> startImageStream() {
    if (!isInitialized) {
      throw Exception('Camera not initialized');
    }

    // Note: This requires custom implementation
    // For now, return empty stream
    // In real implementation, use controller.startImageStream()
    throw UnimplementedError('Image streaming not yet implemented');
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      debugPrint('⚠️ Only one camera available');
      return;
    }

    final currentDirection = _controller?.description.lensDirection;
    final newDirection = currentDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == newDirection,
      orElse: () => _cameras.first,
    );

    await _controller?.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    debugPrint(
      '🔄 Switched to ${newDirection == CameraLensDirection.back ? 'back' : 'front'} camera',
    );
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized) {
      throw Exception('Camera not initialized');
    }

    await _controller!.setFlashMode(mode);
    debugPrint('💡 Flash mode set to: $mode');
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    debugPrint('🗑️ Camera service disposed');
  }

  /// Get list of available cameras
  List<CameraDescription> get availableCamerasList => _cameras;

  /// Check if device has flash
  Future<bool> hasFlash() async {
    if (!isInitialized) return false;

    try {
      // Try to set flash mode to test if available
      await _controller!.setFlashMode(FlashMode.torch);
      await _controller!.setFlashMode(FlashMode.off);
      return true;
    } catch (e) {
      return false;
    }
  }
}
