import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/learning_flow_manager.dart';
import 'package:ganithamithura/services/camera_service.dart';

// ---------------------------------------------------------------------------
// Learning-mode object map: use practical, affordable, YOLO-detectable items
// instead of apples. Objects rotate so each number has a different item.
// YOLO COCO class names are used as keys for the detection model.
// ---------------------------------------------------------------------------
const Map<int, _LearningObject> _kLearningObjects = {
  1: _LearningObject(yoloClass: 'cup',          display: 'cup',           plural: 'cups'),
  2: _LearningObject(yoloClass: 'bottle',       display: 'bottle',        plural: 'bottles'),
  3: _LearningObject(yoloClass: 'book',         display: 'book',          plural: 'books'),
  4: _LearningObject(yoloClass: 'sports ball',  display: 'ball',          plural: 'balls'),
  5: _LearningObject(yoloClass: 'cup',          display: 'cup',           plural: 'cups'),
  6: _LearningObject(yoloClass: 'bottle',       display: 'bottle',        plural: 'bottles'),
  7: _LearningObject(yoloClass: 'scissors',     display: 'pair of scissors', plural: 'pairs of scissors'),
  8: _LearningObject(yoloClass: 'remote',       display: 'remote control', plural: 'remote controls'),
  9: _LearningObject(yoloClass: 'bowl',         display: 'bowl',          plural: 'bowls'),
  10: _LearningObject(yoloClass: 'chair',       display: 'chair',         plural: 'chairs'),
};

/// Returns the learning object for [number], falling back to a rotating default.
_LearningObject _getLearningObject(int number) {
  if (_kLearningObjects.containsKey(number)) {
    return _kLearningObjects[number]!;
  }
  // For numbers > 10 rotate through the list
  final keys = _kLearningObjects.keys.toList();
  return _kLearningObjects[keys[(number - 1) % keys.length]]!;
}

class _LearningObject {
  final String yoloClass;
  final String display;
  final String plural;
  const _LearningObject(
      {required this.yoloClass, required this.display, required this.plural});
}

/// ObjectDetectionActivityScreen - Real-time object detection with ML
class ObjectDetectionActivityScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const ObjectDetectionActivityScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<ObjectDetectionActivityScreen> createState() =>
      _ObjectDetectionActivityScreenState();
}

class _ObjectDetectionActivityScreenState
    extends State<ObjectDetectionActivityScreen> {
  final _storageService = StorageService.instance;
  final _apiService = NumApiService.instance;
  final _cameraService = CameraService.instance;
  
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  ObjectDetectionResult? _detectionResult;
  bool? _result;
  String? _targetObject;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _extractTargetObject();
  }
  
  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
  
  /// Extract target object from question metadata.
  /// In learning mode we always use the practical per-number object map
  /// so students use affordable, common items instead of apples.
  void _extractTargetObject() {
    // Always use the learning object map for this screen (learning mode only).
    // The progress test uses ObjectDetectionQuestionWidget separately.
    final learningObj = _getLearningObject(widget.currentNumber);
    _targetObject = learningObj.yoloClass;
    debugPrint('🎯 Target object (learning map): $_targetObject');
  }
  
  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission required';
        });
        return;
      }
      
      await _cameraService.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Object Detection'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
              tooltip: 'Switch Camera',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Instructions
                _buildInstructionCard(),
                
                const SizedBox(height: 8),
                
                // Camera preview or error
                Expanded(
                  child: _errorMessage != null
                      ? _buildErrorWidget()
                      : _isCameraInitialized
                          ? _buildCameraPreview()
                          : _buildLoadingWidget(),
                ),
                
                const SizedBox(height: 8),
                
                // Detection result
                if (_detectionResult != null)
                  _buildDetectionResult(),
                
                const SizedBox(height: 8),
                
                // Control buttons
                _buildControlButtons(),
              ],
            ),
            
            // Result overlay
            if (_result != null)
              _result!
                  ? SuccessAnimation(
                      message: _detectionResult?.validation?.feedback ?? 'Great job!',
                      onComplete: _onSuccess,
                    )
                  : FailureAnimation(
                      message: _detectionResult?.validation?.feedback ?? 'Try again!',
                      onRetry: _resetDetection,
                      onGoBack: _goBackToLearning,
                    ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionCard() {
    final learningObj = _getLearningObject(widget.currentNumber);
    final countLabel = widget.currentNumber == 1
        ? '1 ${learningObj.display}'
        : '${widget.currentNumber} ${learningObj.plural}';
    final instruction = 'Can you show me $countLabel?';
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.standardPadding),
      padding: const EdgeInsets.all(AppConstants.standardPadding),
      decoration: BoxDecoration(
        color: Color(AppColors.numberColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        border: Border.all(
          color: Color(AppColors.numberColor),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.camera_alt,
            color: Color(AppColors.numberColor),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Hold up ${widget.currentNumber == 1 ? "a" : "${widget.currentNumber}"} ${widget.currentNumber == 1 ? learningObj.display : learningObj.plural} in front of the camera',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.standardPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Color(AppColors.errorColor),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ActionButton(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: _initializeCamera,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    final controller = _cameraService.controller;
    if (controller == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.standardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
  
  Widget _buildDetectionResult() {
    final result = _detectionResult!;
    final count = result.targetCount ?? result.totalCount;
    final isCorrect = result.validation?.isCorrect ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.standardPadding),
      padding: const EdgeInsets.all(AppConstants.standardPadding),
      decoration: BoxDecoration(
        color: isCorrect
            ? Color(AppColors.successColor).withOpacity(0.1)
            : Color(AppColors.warningColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        border: Border.all(
          color: isCorrect
              ? Color(AppColors.successColor)
              : Color(AppColors.warningColor),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info,
                color: isCorrect
                    ? Color(AppColors.successColor)
                    : Color(AppColors.warningColor),
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Detected: $count ${_targetObject ?? 'objects'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result.classCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: result.classCounts.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.standardPadding),
      child: Column(
        children: [
          ActionButton(
            text: _isDetecting ? 'Detecting...' : 'Detect Objects',
            icon: _isDetecting ? Icons.hourglass_empty : Icons.search,
            isEnabled: _isCameraInitialized && !_isDetecting,
            onPressed: _performDetection,
          ),
          if (_detectionResult != null && _result == null) ...[
            const SizedBox(height: 8),
            ActionButton(
              text: 'Check Answer',
              icon: Icons.check,
              color: Color(AppColors.successColor),
              onPressed: _checkResult,
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _performDetection() async {
    setState(() {
      _isDetecting = true;
      _detectionResult = null;
    });
    
    try {
      // Capture frame from camera
      final imageBytes = await _cameraService.captureCompressedFrame(quality: 80);
      
      debugPrint('📸 Captured frame: ${imageBytes.length} bytes');
      
      // Perform detection using NumApiService
      final result = await _apiService.detectObjects(
        imageBytes: imageBytes,
        targetObject: _targetObject,
        expectedCount: widget.currentNumber,
        confidenceThreshold: 0.5,
      );
      
      setState(() {
        _detectionResult = result;
        _isDetecting = false;
      });
      
    } catch (e) {
      debugPrint('❌ Detection error: $e');
      setState(() {
        _isDetecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Color(AppColors.errorColor),
          ),
        );
      }
    }
  }
  
  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to switch camera: $e');
    }
  }
  
  void _checkResult() {
    if (_detectionResult == null) return;
    
    final validation = _detectionResult!.validation;
    if (validation == null) return;
    
    final isCorrect = validation.isCorrect;
    
    if (isCorrect) {
      // Save progress
      final progress = Progress(
        activityId: widget.activity.id,
        score: validation.points,
        isCompleted: true,
        completedAt: DateTime.now(),
        additionalData: {
          'detected_count': validation.detectedCount,
          'expected_count': validation.expectedCount,
          'target_object': _targetObject,
        },
      );
      
      _storageService.saveCompletedActivity(progress);
      
      // Submit to backend
      _apiService.submitActivityScore(
        activityId: widget.activity.id,
        score: validation.points,
        isCompleted: true,
        additionalData: progress.additionalData,
      ).catchError((e) {
        debugPrint('Error submitting score: $e');
        return <String, dynamic>{};
      });
    }
    
    setState(() {
      _result = isCorrect;
    });
  }
  
  void _resetDetection() {
    setState(() {
      _detectionResult = null;
      _result = null;
    });
  }
  
  void _onSuccess() async {
    // Use LearningFlowManager to move to next activity
    final learningFlowManager = LearningFlowManager.instance;
    
    try {
      await learningFlowManager.moveToNextActivity(
        currentActivity: widget.activity,
        currentNumber: widget.currentNumber,
        level: widget.level,
        isTutorial: true,
      );
    } catch (e) {
      debugPrint('❌ Error in moveToNextActivity: $e');
      // If there's an error, show a message but don't crash
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed! Error navigating: $e'),
            backgroundColor: Color(AppColors.errorColor),
          ),
        );
      }
    }
  }

  /// Navigate back to the first activity for this number (learning restart)
  void _goBackToLearning() async {
    setState(() {
      _result = null;
      _detectionResult = null;
    });
    final learningFlowManager = LearningFlowManager.instance;
    try {
      await learningFlowManager.startLearningFromNumber(
        level: widget.level.levelNumber,
        startNumber: widget.currentNumber,
        levelData: widget.level,
        isTutorial: true,
      );
    } catch (e) {
      debugPrint('❌ Error going back to learning: $e');
    }
  }
}
