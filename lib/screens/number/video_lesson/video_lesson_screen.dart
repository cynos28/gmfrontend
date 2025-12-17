import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/widgets/common/buttons_and_cards.dart';
import 'package:ganithamithura/widgets/common/feedback_widgets.dart';
import 'package:ganithamithura/screens/number/trace/trace_activity_screen.dart';

/// VideoLessonScreen - Display video lesson with Continue button
class VideoLessonScreen extends StatefulWidget {
  final Activity activity;
  final List<Activity> allActivities;
  final int currentNumber;
  final LearningLevel level;
  
  const VideoLessonScreen({
    super.key,
    required this.activity,
    required this.allActivities,
    required this.currentNumber,
    required this.level,
  });
  
  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  bool _videoCompleted = false;
  
  @override
  void initState() {
    super.initState();
    // Simulate video completion after 5 seconds (placeholder)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _videoCompleted = true;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Learn Number ${widget.currentNumber}'),
        backgroundColor: Color(AppColors.numberColor),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video player area
            Expanded(
              child: Center(
                child: _buildVideoPlaceholder(),
              ),
            ),
            
            // Controls
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(AppConstants.standardPadding),
              child: Column(
                children: [
                  // Number display
                  NumberDisplay(
                    number: widget.currentNumber,
                    word: NumberWords.getWord(widget.currentNumber),
                  ),
                  const SizedBox(height: 24),
                  
                  // Continue button
                  ActionButton(
                    text: 'Continue',
                    icon: Icons.arrow_forward,
                    isEnabled: _videoCompleted,
                    onPressed: _onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.standardPadding),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Phase 2 - Integrate actual video player
          // Use video_player or chewie package
          Icon(
            _videoCompleted ? Icons.check_circle : Icons.play_circle_outline,
            size: 100,
            color: _videoCompleted 
                ? Color(AppColors.successColor)
                : Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            _videoCompleted 
                ? 'Video Completed!' 
                : 'Playing video...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Learn about number ${widget.currentNumber}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          if (!_videoCompleted) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
    );
  }
  
  void _onContinue() {
    // Find next activity (should be trace)
    final numberActivities = widget.allActivities
        .where((a) => a.number == widget.currentNumber)
        .toList();
    
    // Sort to get proper order
    numberActivities.sort((a, b) => a.order.compareTo(b.order));
    
    // Find next activity after video
    final currentIndex = numberActivities.indexWhere((a) => a.id == widget.activity.id);
    
    if (currentIndex >= 0 && currentIndex < numberActivities.length - 1) {
      final nextActivity = numberActivities[currentIndex + 1];
      
      // Navigate based on activity type
      _navigateToActivity(nextActivity);
    } else {
      // All activities for this number completed, move to next number or finish
      _handleNumberCompletion();
    }
  }
  
  void _navigateToActivity(Activity activity) {
    Widget screen;
    
    switch (activity.type) {
      case AppConstants.activityTypeTrace:
        screen = TraceActivityScreen(
          activity: activity,
          allActivities: widget.allActivities,
          currentNumber: widget.currentNumber,
          level: widget.level,
        );
        break;
      // TODO: Add other activity type navigations
      default:
        Get.snackbar(
          'Coming Soon',
          'This activity type will be implemented shortly',
          backgroundColor: Color(AppColors.infoColor),
          colorText: Colors.white,
        );
        return;
    }
    
    Get.to(() => screen);
  }
  
  void _handleNumberCompletion() {
    // Show success
    Get.dialog(
      SuccessAnimation(
        message: 'Number ${widget.currentNumber} Completed!',
        onComplete: () {
          Get.back();
          
          // Check if there are more numbers
          if (widget.currentNumber < widget.level.maxNumber) {
            // Move to next number
            _startNextNumber();
          } else {
            // Level completed
            Get.back(); // Return to level selection
            Get.snackbar(
              'Level Complete!',
              'You\'ve mastered all numbers in this level!',
              backgroundColor: Color(AppColors.successColor),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        },
      ),
      barrierDismissible: false,
    );
  }
  
  void _startNextNumber() {
    final nextNumber = widget.currentNumber + 1;
    final nextActivities = widget.allActivities
        .where((a) => a.number == nextNumber)
        .toList();
    
    if (nextActivities.isNotEmpty) {
      nextActivities.sort((a, b) => a.order.compareTo(b.order));
      
      Get.off(() => VideoLessonScreen(
        activity: nextActivities.first,
        allActivities: widget.allActivities,
        currentNumber: nextNumber,
        level: widget.level,
      ));
    }
  }
}
