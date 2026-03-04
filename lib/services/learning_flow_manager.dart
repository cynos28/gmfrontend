import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/services/api/number_api_service.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/number/video_lesson/video_lesson_screen.dart';
import 'package:ganithamithura/screens/number/trace/trace_activity_screen.dart';
import 'package:ganithamithura/screens/number/read/read_activity_screen.dart';
import 'package:ganithamithura/screens/number/say/say_activity_screen.dart';
import 'package:ganithamithura/screens/number/object_detection/object_detection_activity_screen.dart';

/// LearningFlowManager - Manages sequential number-based learning
/// Handles progression through: Video -> Trace -> Show -> Say -> Read
/// Auto-advances to next number after completing all activities
class LearningFlowManager {
  static LearningFlowManager? _instance;
  final _apiService = NumApiService.instance;
  final _storageService = StorageService.instance;

  LearningFlowManager._();

  static LearningFlowManager get instance {
    _instance ??= LearningFlowManager._();
    return _instance!;
  }

  /// Start learning from a specific number
  /// Uses 'easy' difficulty questions for tutorial mode
  Future<void> startLearningFromNumber({
    required int level,
    required int startNumber,
    required LearningLevel levelData,
    bool isTutorial = true,
    String?
    startFromActivityType, // Optional: start from specific activity (for resuming)
  }) async {
    try {
      // Fetch activities for the starting number
      // For tutorial mode, get only easy questions
      final activities = await _apiService.getActivitiesForNumber(
        level,
        startNumber,
        difficulty: isTutorial ? 'easy' : null,
      );

      if (activities.isEmpty) {
        throw Exception('No activities found for number $startNumber');
      }

      // Find the activity to start from
      Activity firstActivity;
      if (startFromActivityType != null) {
        // Resume from specific activity type
        firstActivity = activities.firstWhere(
          (a) => a.type == startFromActivityType,
          orElse: () => activities.first,
        );
        debugPrint('📍 Resuming from activity: ${firstActivity.type}');
      } else {
        // Start from first activity
        firstActivity = activities.first;
      }

      await _navigateToActivity(
        activity: firstActivity,
        allActivities: activities,
        currentNumber: startNumber,
        level: levelData,
        isTutorial: isTutorial,
      );
    } catch (e) {
      debugPrint('Error starting learning: $e');
      rethrow;
    }
  }

  /// Check if there's a saved learning session
  bool hasSavedSession() {
    return _storageService.getLearningSession() != null;
  }

  /// Get the saved learning session (if any)
  LearningSession? getSavedSession() {
    return _storageService.getLearningSession();
  }

  /// Resume learning from saved session
  /// Returns true if there was a session to resume, false otherwise
  Future<bool> resumeLearning({required LearningLevel levelData}) async {
    final session = _storageService.getLearningSession();

    if (session == null) {
      debugPrint('📭 No saved learning session found');
      return false;
    }

    debugPrint('📥 Found saved session: $session');

    // Get the activity to resume from
    final resumeActivityType = session.resumeActivityType;

    if (resumeActivityType == null) {
      // All activities for this number were completed, move to next number
      debugPrint('✅ Previous number completed, starting next number');
      final nextNumber = session.number + 1;

      if (nextNumber <= levelData.maxNumber) {
        await startLearningFromNumber(
          level: session.level,
          startNumber: nextNumber,
          levelData: levelData,
        );
        return true;
      } else {
        // Level completed
        debugPrint('🎉 Level completed!');
        await _storageService.clearLearningSession();
        return false;
      }
    }

    // Resume from the saved position
    debugPrint(
      '▶️ Resuming from: Number ${session.number}, Activity $resumeActivityType',
    );
    await startLearningFromNumber(
      level: session.level,
      startNumber: session.number,
      levelData: levelData,
      startFromActivityType: resumeActivityType,
    );
    return true;
  }

  /// Move to next activity in the sequence
  /// If all activities for current number are complete, move to next number
  Future<void> moveToNextActivity({
    required Activity currentActivity,
    required int currentNumber,
    required LearningLevel level,
    bool isTutorial = true,
  }) async {
    try {
      debugPrint('🔄 Moving to next activity from: ${currentActivity.id}');

      // Mark current activity as completed in session
      await _storageService.markActivityCompleted(currentActivity.type);

      // Get all activities for current number
      final activities = await _apiService.getActivitiesForNumber(
        level.levelNumber,
        currentNumber,
        difficulty: isTutorial ? 'easy' : null,
      );

      debugPrint(
        '📚 Fetched ${activities.length} activities for number $currentNumber',
      );
      for (var act in activities) {
        debugPrint('  - ${act.type} (${act.id})');
      }

      // Find current activity index
      final currentIndex = activities.indexWhere(
        (a) => a.id == currentActivity.id,
      );

      debugPrint('📍 Current activity index: $currentIndex');

      if (currentIndex == -1) {
        debugPrint('❌ Current activity not found in list!');
        throw Exception('Current activity not found');
      }

      // Check if there's a next activity in the sequence
      if (currentIndex < activities.length - 1) {
        // Move to next activity in the same number
        final nextActivity = activities[currentIndex + 1];
        debugPrint(
          '➡️ Moving to next activity: ${nextActivity.type} (${nextActivity.id})',
        );
        await _navigateToActivity(
          activity: nextActivity,
          allActivities: activities,
          currentNumber: currentNumber,
          level: level,
          isTutorial: isTutorial,
        );
      } else {
        // All activities for current number completed
        debugPrint('✅ All activities completed for number $currentNumber');
        await _handleNumberCompletion(
          currentNumber: currentNumber,
          level: level,
        );
      }
    } catch (e) {
      debugPrint('Error moving to next activity: $e');
      rethrow;
    }
  }

  /// Handle completion of all activities for a number
  Future<void> _handleNumberCompletion({
    required int currentNumber,
    required LearningLevel level,
  }) async {
    // Save progress
    await _storageService.saveNumberCompletion(
      level.levelNumber,
      currentNumber,
    );

    // Check if this was the last number in the level
    if (currentNumber >= level.maxNumber) {
      // Level completed
      await _handleLevelCompletion(level);
    } else {
      // Move to next number
      final nextNumber = currentNumber + 1;

      // Show congratulations and move to next number
      await Get.dialog(
        AlertDialog(
          title: Text('Great Job! 🎉'),
          content: Text(
            'You completed number $currentNumber!\nLet\'s learn number $nextNumber now.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                startLearningFromNumber(
                  level: level.levelNumber,
                  startNumber: nextNumber,
                  levelData: level,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  /// Handle level completion
  Future<void> _handleLevelCompletion(LearningLevel level) async {
    // Mark level as completed
    await _storageService.saveLevelCompletion(level.levelNumber);

    // Unlock next level if it exists
    if (level.levelNumber == 1) {
      await _storageService.unlockLevel(2);
    }

    // Show completion dialog
    await Get.dialog(
      AlertDialog(
        title: Text('Level ${level.levelNumber} Completed! 🎊'),
        content: Text(
          'Congratulations! You\'ve mastered all numbers in Level ${level.levelNumber}!\n\n'
          '${level.levelNumber == 1 ? "Level 2 is now unlocked!" : "Keep up the great work!"}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to level selection
            },
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Navigate to the appropriate activity screen
  Future<void> _navigateToActivity({
    required Activity activity,
    required List<Activity> allActivities,
    required int currentNumber,
    required LearningLevel level,
    bool isTutorial = true,
  }) async {
    debugPrint('🚀 Navigating to activity: ${activity.type}');

    // Save the current learning session position
    await _storageService.saveLearningSession(
      level: level.levelNumber,
      number: currentNumber,
      activityType: activity.type,
    );
    debugPrint(
      '💾 Saved learning session: Level ${level.levelNumber}, Number $currentNumber, Activity ${activity.type}',
    );

    // Get the current context from Get
    final context = Get.context;
    if (context == null) {
      debugPrint('❌ Context is null!');
      return;
    }

    Widget screen;

    switch (activity.type) {
      case AppConstants.activityTypeVideo:
        debugPrint('  → Going to VideoLessonScreen');
        screen = VideoLessonScreen(
          activity: activity,
          allActivities: allActivities,
          currentNumber: currentNumber,
          level: level,
        );
        break;

      case AppConstants.activityTypeTrace:
        debugPrint('  → Going to TraceActivityScreen');
        screen = TraceActivityScreen(
          activity: activity,
          allActivities: allActivities,
          currentNumber: currentNumber,
          level: level,
        );
        break;

      case 'show': // New activity type
      case AppConstants.activityTypeObjectDetection:
        debugPrint('  → Going to ObjectDetectionActivityScreen');
        screen = ObjectDetectionActivityScreen(
          activity: activity,
          allActivities: allActivities,
          currentNumber: currentNumber,
          level: level,
        );
        break;

      case AppConstants.activityTypeSay:
        debugPrint('  → Going to SayActivityScreen');
        screen = SayActivityScreen(
          activity: activity,
          allActivities: allActivities,
          currentNumber: currentNumber,
          level: level,
        );
        break;

      case AppConstants.activityTypeRead:
        debugPrint('  → Going to ReadActivityScreen');
        screen = ReadActivityScreen(
          activity: activity,
          allActivities: allActivities,
          currentNumber: currentNumber,
          level: level,
        );
        break;

      default:
        debugPrint('❌ Unknown activity type: ${activity.type}');
        throw Exception('Unknown activity type: ${activity.type}');
    }

    // Replace current screen with new activity
    debugPrint('  ✅ Using Navigator.pushReplacement');
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => screen));
    debugPrint('  ✅ Navigation executed');
  }

  /// Get progress for a specific level
  Future<Map<int, bool>> getNumberCompletionStatus(int level) async {
    final completedNumbers = await _storageService.getCompletedNumbers(level);
    return completedNumbers;
  }

  /// Check if a level is completed
  Future<bool> isLevelCompleted(int level) async {
    return await _storageService.isLevelCompleted(level);
  }

  /// Get the next number to learn for a level
  Future<int> getNextNumberToLearn(int level, int maxNumber) async {
    final completedNumbers = await _storageService.getCompletedNumbers(level);

    // Find first incomplete number
    for (int i = 1; i <= maxNumber; i++) {
      if (completedNumbers[i] != true) {
        return i;
      }
    }

    // All numbers completed
    return maxNumber;
  }
}
