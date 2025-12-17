import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/api_service.dart';

/// ObjectDetectionActivityScreen - Placeholder for object detection
/// TODO: Phase 2 - Integrate real ML model
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
  final _apiService = ApiService.instance;
  
  bool _isDetecting = false;
  int? _detectedCount;
  bool? _result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.backgroundColor),
      appBar: AppBar(
        title: const Text('Object Detection'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.standardPadding),
              child: Column(
                children: [
                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.standardPadding),
                      child: Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Color(AppColors.numberColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Find ${widget.currentNumber} objects',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Camera preview placeholder
                  Expanded(
                    child: _buildCameraPlaceholder(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Detection result
                  if (_detectedCount != null)
                    Card(
                      color: _detectedCount == widget.currentNumber
                          ? Color(AppColors.successColor).withOpacity(0.1)
                          : Color(AppColors.warningColor).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.standardPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _detectedCount == widget.currentNumber
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: _detectedCount == widget.currentNumber
                                  ? Color(AppColors.successColor)
                                  : Color(AppColors.warningColor),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Detected: $_detectedCount objects',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Detect button
                  ActionButton(
                    text: _isDetecting ? 'Detecting...' : 'Detect Objects',
                    icon: Icons.search,
                    isEnabled: !_isDetecting,
                    onPressed: _mockDetection,
                  ),
                ],
              ),
            ),
            
            // Result overlay
            if (_result != null)
              _result!
                  ? SuccessAnimation(
                      message: 'Correct count!',
                      onComplete: _onSuccess,
                    )
                  : FailureAnimation(
                      message: 'Count again!',
                      onRetry: _resetDetection,
                    ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Camera Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'TODO: Phase 2 - Integrate camera and ML model for real object detection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _mockDetection() async {
    setState(() {
      _isDetecting = true;
      _detectedCount = null;
    });
    
    // Simulate detection delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock detection result (randomly correct or slightly off)
    final mockCount = widget.currentNumber + (DateTime.now().second % 3 - 1);
    final isCorrect = mockCount == widget.currentNumber;
    
    setState(() {
      _isDetecting = false;
      _detectedCount = mockCount;
    });
    
    // Auto-check after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _detectedCount != null) {
        _checkResult(isCorrect);
      }
    });
  }
  
  void _checkResult(bool isCorrect) {
    if (isCorrect) {
      // Save progress
      final progress = Progress(
        activityId: widget.activity.id,
        score: 100,
        isCompleted: true,
        completedAt: DateTime.now(),
        additionalData: {
          'detected_count': _detectedCount,
          'target_count': widget.currentNumber,
        },
      );
      
      _storageService.saveCompletedActivity(progress);
      
      // Submit to backend
      _apiService.submitActivityScore(
        activityId: widget.activity.id,
        score: 100,
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
      _detectedCount = null;
      _result = null;
    });
  }
  
  void _onSuccess() {
    // Number completed - show success and return to level selection
    Get.back();
    Get.back();
    Get.snackbar(
      'Number ${widget.currentNumber} Complete!',
      'Great job! Moving to next number...',
      backgroundColor: Color(AppColors.successColor),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
